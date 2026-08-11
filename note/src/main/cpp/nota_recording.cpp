#include <cstdint>
#include <cstring>
#include <mutex>
#include <string>

#include "multimedia/player_framework/native_avscreen_capture.h"
#include "napi/native_api.h"

namespace {
constexpr int32_t EVENT_STATE = 1;
constexpr int32_t EVENT_ERROR = 2;
constexpr int32_t SAMPLE_RATE = 44100;
constexpr int32_t CHANNELS = 1;
constexpr int32_t BITRATE = 96000;

struct CaptureEvent {
    int32_t kind;
    int32_t code;
};

std::mutex gMutex;
OH_AVScreenCapture *gCapture = nullptr;
std::string gOutputUrl;
napi_threadsafe_function gEventFunction = nullptr;
bool gStopping = false;
bool gExternallyStopped = false;

bool IsTerminalStop(OH_AVScreenCaptureStateCode state)
{
    return state == OH_SCREEN_CAPTURE_STATE_STOPPED_BY_USER ||
        state == OH_SCREEN_CAPTURE_STATE_INTERRUPTED_BY_OTHER ||
        state == OH_SCREEN_CAPTURE_STATE_STOPPED_BY_CALL ||
        state == OH_SCREEN_CAPTURE_STATE_STOPPED_BY_USER_SWITCHES;
}

void CallJavaScript(napi_env env, napi_value jsCallback, void *, void *data)
{
    auto *event = static_cast<CaptureEvent *>(data);
    if (env != nullptr && jsCallback != nullptr && event != nullptr) {
        napi_value undefined;
        napi_value arguments[2];
        napi_get_undefined(env, &undefined);
        napi_create_int32(env, event->kind, &arguments[0]);
        napi_create_int32(env, event->code, &arguments[1]);
        napi_call_function(env, undefined, jsCallback, 2, arguments, nullptr);
    }
    delete event;
}

void SendEvent(int32_t kind, int32_t code)
{
    napi_threadsafe_function function = nullptr;
    {
        std::lock_guard<std::mutex> lock(gMutex);
        function = gEventFunction;
        if (function == nullptr || napi_acquire_threadsafe_function(function) != napi_ok) {
            return;
        }
    }
    auto *event = new CaptureEvent{kind, code};
    if (napi_call_threadsafe_function(function, event, napi_tsfn_nonblocking) != napi_ok) {
        delete event;
    }
    napi_release_threadsafe_function(function, napi_tsfn_release);
}

void OnStateChange(OH_AVScreenCapture *capture, OH_AVScreenCaptureStateCode state, void *)
{
    bool suppress = false;
    {
        std::lock_guard<std::mutex> lock(gMutex);
        if (capture != gCapture) {
            return;
        }
        if (IsTerminalStop(state)) {
            gExternallyStopped = !gStopping;
            suppress = gStopping;
        }
    }
    if (!suppress) {
        SendEvent(EVENT_STATE, static_cast<int32_t>(state));
    }
}

void OnError(OH_AVScreenCapture *capture, int32_t errorCode, void *)
{
    {
        std::lock_guard<std::mutex> lock(gMutex);
        if (capture != gCapture) {
            return;
        }
    }
    SendEvent(EVENT_ERROR, errorCode);
}

void ReleaseCapture(bool stop)
{
    OH_AVScreenCapture *capture = nullptr;
    bool alreadyStopped = false;
    {
        std::lock_guard<std::mutex> lock(gMutex);
        capture = gCapture;
        alreadyStopped = gExternallyStopped;
        gStopping = stop && capture != nullptr && !alreadyStopped;
    }
    if (capture == nullptr) {
        return;
    }
    if (stop && !alreadyStopped) {
        OH_AVScreenCapture_StopScreenRecording(capture);
    }
    OH_AVScreenCapture_Release(capture);
    {
        std::lock_guard<std::mutex> lock(gMutex);
        if (gCapture == capture) {
            gCapture = nullptr;
            gOutputUrl.clear();
            gStopping = false;
            gExternallyStopped = false;
        }
    }
}

napi_value SetEventCallback(napi_env env, napi_callback_info info)
{
    size_t argc = 1;
    napi_value arguments[1] = {nullptr};
    napi_get_cb_info(env, info, &argc, arguments, nullptr, nullptr);
    if (argc != 1) {
        napi_throw_type_error(env, nullptr, "setEventCallback requires one argument");
        return nullptr;
    }

    napi_threadsafe_function replacement = nullptr;
    napi_valuetype type = napi_undefined;
    napi_typeof(env, arguments[0], &type);
    if (type == napi_function) {
        napi_value resourceName;
        napi_create_string_utf8(env, "nota-recording-events", NAPI_AUTO_LENGTH, &resourceName);
        napi_status status = napi_create_threadsafe_function(env, arguments[0], nullptr, resourceName,
            0, 1, nullptr, nullptr, nullptr, CallJavaScript, &replacement);
        if (status != napi_ok) {
            napi_throw_error(env, nullptr, "could not create recording event bridge");
            return nullptr;
        }
    } else if (type != napi_null) {
        napi_throw_type_error(env, nullptr, "recording event callback must be a function or null");
        return nullptr;
    }

    napi_threadsafe_function previous = nullptr;
    {
        std::lock_guard<std::mutex> lock(gMutex);
        previous = gEventFunction;
        gEventFunction = replacement;
    }
    if (previous != nullptr) {
        napi_release_threadsafe_function(previous, napi_tsfn_abort);
    }
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    return undefined;
}

bool ReadUtf8(napi_env env, napi_value value, std::string &result)
{
    size_t length = 0;
    if (napi_get_value_string_utf8(env, value, nullptr, 0, &length) != napi_ok || length == 0) {
        return false;
    }
    result.resize(length + 1);
    size_t copied = 0;
    if (napi_get_value_string_utf8(env, value, result.data(), length + 1, &copied) != napi_ok ||
        copied != length) {
        return false;
    }
    result.resize(copied);
    return true;
}

napi_value IntResult(napi_env env, int32_t value)
{
    napi_value result;
    napi_create_int32(env, value, &result);
    return result;
}

napi_value IsCaptureActive(napi_env env, napi_callback_info)
{
    bool active = false;
    {
        std::lock_guard<std::mutex> lock(gMutex);
        active = gCapture != nullptr;
    }
    napi_value result;
    napi_get_boolean(env, active, &result);
    return result;
}

napi_value StartCapture(napi_env env, napi_callback_info info)
{
    size_t argc = 1;
    napi_value arguments[1] = {nullptr};
    napi_get_cb_info(env, info, &argc, arguments, nullptr, nullptr);
    std::string outputUrl;
    if (argc != 1 || !ReadUtf8(env, arguments[0], outputUrl)) {
        napi_throw_type_error(env, nullptr, "startCapture requires a non-empty output URL");
        return nullptr;
    }
    {
        std::lock_guard<std::mutex> lock(gMutex);
        if (gCapture != nullptr) {
            return IntResult(env, AV_SCREEN_CAPTURE_ERR_OPERATE_NOT_PERMIT);
        }
        gOutputUrl = outputUrl;
        gExternallyStopped = false;
        gStopping = false;
    }

    OH_AVScreenCapture *capture = OH_AVScreenCapture_Create();
    if (capture == nullptr) {
        std::lock_guard<std::mutex> lock(gMutex);
        gOutputUrl.clear();
        return IntResult(env, AV_SCREEN_CAPTURE_ERR_NO_MEMORY);
    }
    {
        std::lock_guard<std::mutex> lock(gMutex);
        gCapture = capture;
    }

    OH_AVScreenCaptureConfig config;
    std::memset(&config, 0, sizeof(config));
    config.captureMode = OH_CAPTURE_HOME_SCREEN;
    config.dataType = OH_CAPTURE_FILE;
    config.audioInfo.micCapInfo.audioSource = OH_SOURCE_INVALID;
    config.audioInfo.innerCapInfo.audioSampleRate = SAMPLE_RATE;
    config.audioInfo.innerCapInfo.audioChannels = CHANNELS;
    config.audioInfo.innerCapInfo.audioSource = OH_ALL_PLAYBACK;
    config.audioInfo.audioEncInfo.audioBitrate = BITRATE;
    config.audioInfo.audioEncInfo.audioCodecformat = OH_AAC_LC;
    config.videoInfo.videoCapInfo.videoSource = OH_VIDEO_SOURCE_BUTT;
    config.videoInfo.videoEncInfo.videoCodec = OH_VIDEO_CODEC_FORMAT_BUTT;
    config.recorderInfo.url = gOutputUrl.data();
    config.recorderInfo.urlLen = static_cast<uint32_t>(gOutputUrl.size());
    config.recorderInfo.fileFormat = CFT_MPEG_4A;

    OH_AVSCREEN_CAPTURE_ErrCode result = OH_AVScreenCapture_Init(capture, config);
    if (result == AV_SCREEN_CAPTURE_ERR_OK) {
        result = OH_AVScreenCapture_SetStateCallback(capture, OnStateChange, nullptr);
    }
    if (result == AV_SCREEN_CAPTURE_ERR_OK) {
        result = OH_AVScreenCapture_SetErrorCallback(capture, OnError, nullptr);
    }
    if (result == AV_SCREEN_CAPTURE_ERR_OK) {
        result = OH_AVScreenCapture_StartScreenRecording(capture);
    }
    if (result != AV_SCREEN_CAPTURE_ERR_OK) {
        ReleaseCapture(false);
    }
    return IntResult(env, static_cast<int32_t>(result));
}

napi_value StopCapture(napi_env env, napi_callback_info)
{
    OH_AVScreenCapture *capture = nullptr;
    bool alreadyStopped = false;
    {
        std::lock_guard<std::mutex> lock(gMutex);
        capture = gCapture;
        alreadyStopped = gExternallyStopped;
        gStopping = capture != nullptr && !alreadyStopped;
    }
    if (capture == nullptr) {
        return IntResult(env, AV_SCREEN_CAPTURE_ERR_OPERATE_NOT_PERMIT);
    }
    OH_AVSCREEN_CAPTURE_ErrCode result = AV_SCREEN_CAPTURE_ERR_OK;
    if (!alreadyStopped) {
        result = OH_AVScreenCapture_StopScreenRecording(capture);
    }
    OH_AVScreenCapture_Release(capture);
    {
        std::lock_guard<std::mutex> lock(gMutex);
        if (gCapture == capture) {
            gCapture = nullptr;
            gOutputUrl.clear();
            gStopping = false;
            gExternallyStopped = false;
        }
    }
    return IntResult(env, static_cast<int32_t>(result));
}

napi_value AbortCapture(napi_env env, napi_callback_info)
{
    ReleaseCapture(true);
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    return undefined;
}

void Cleanup(void *)
{
    ReleaseCapture(true);
    napi_threadsafe_function function = nullptr;
    {
        std::lock_guard<std::mutex> lock(gMutex);
        function = gEventFunction;
        gEventFunction = nullptr;
    }
    if (function != nullptr) {
        napi_release_threadsafe_function(function, napi_tsfn_abort);
    }
}

napi_value Init(napi_env env, napi_value exports)
{
    napi_property_descriptor descriptors[] = {
        {"setEventCallback", nullptr, SetEventCallback, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"isCaptureActive", nullptr, IsCaptureActive, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"startCapture", nullptr, StartCapture, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"stopCapture", nullptr, StopCapture, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"abortCapture", nullptr, AbortCapture, nullptr, nullptr, nullptr, napi_default, nullptr},
    };
    napi_define_properties(env, exports, sizeof(descriptors) / sizeof(descriptors[0]), descriptors);
    napi_add_env_cleanup_hook(env, Cleanup, nullptr);
    return exports;
}
} // namespace

static napi_module gModule = {
    .nm_version = 1,
    .nm_flags = 0,
    .nm_filename = nullptr,
    .nm_register_func = Init,
    .nm_modname = "nota_recording",
    .nm_priv = nullptr,
    .reserved = {nullptr},
};

extern "C" __attribute__((constructor)) void RegisterNotaRecordingModule()
{
    napi_module_register(&gModule);
}
