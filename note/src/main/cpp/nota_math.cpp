#include <algorithm>
#include <cmath>
#include <cstdint>
#include <cstring>
#include <memory>
#include <mutex>
#include <string>

#include "napi/native_api.h"
#include "native_drawing/drawing_bitmap.h"
#include "native_drawing/drawing_brush.h"
#include "native_drawing/drawing_canvas.h"
#include "native_drawing/drawing_font.h"
#include "native_drawing/drawing_pen.h"
#include "native_drawing/drawing_rect.h"
#include "native_drawing/drawing_round_rect.h"
#include "native_drawing/drawing_text_blob.h"
#include "native_drawing/drawing_typeface.h"

#include "graphic/graphic.h"
#include "latex.h"
#include "render.h"
#include "utils/utf.h"

namespace {
constexpr int MAX_LATEX_BYTES = 64 * 1024;
constexpr int MAX_BITMAP_EDGE = 4096;
constexpr int MAX_BITMAP_BYTES = 16 * 1024 * 1024;
constexpr float DEFAULT_LINE_SPACE = 4.0f;

std::mutex gMathMutex;
bool gInitialized = false;
std::string gResourceRoot;

struct BitmapDeleter {
    void operator()(OH_Drawing_Bitmap *bitmap) const
    {
        if (bitmap != nullptr) OH_Drawing_BitmapDestroy(bitmap);
    }
};

struct CanvasDeleter {
    void operator()(OH_Drawing_Canvas *canvas) const
    {
        if (canvas != nullptr) OH_Drawing_CanvasDestroy(canvas);
    }
};

using BitmapHandle = std::unique_ptr<OH_Drawing_Bitmap, BitmapDeleter>;
using CanvasHandle = std::unique_ptr<OH_Drawing_Canvas, CanvasDeleter>;

class HarmonyFont final : public tex::Font {
public:
    HarmonyFont(std::string file, float size) : file_(std::move(file)), size_(size)
    {
        typeface_ = file_.empty() ? OH_Drawing_TypefaceCreateDefault() :
            OH_Drawing_TypefaceCreateFromFile(file_.c_str(), 0);
        if (typeface_ == nullptr) {
            typeface_ = OH_Drawing_TypefaceCreateDefault();
        }
        font_ = OH_Drawing_FontCreate();
        if (font_ != nullptr) {
            if (typeface_ != nullptr) OH_Drawing_FontSetTypeface(font_, typeface_);
            OH_Drawing_FontSetTextSize(font_, size_);
            OH_Drawing_FontSetSubpixel(font_, true);
            OH_Drawing_FontSetEdging(font_, FONT_EDGING_ANTI_ALIAS);
        }
    }

    ~HarmonyFont() override
    {
        if (font_ != nullptr) OH_Drawing_FontDestroy(font_);
        if (typeface_ != nullptr) OH_Drawing_TypefaceDestroy(typeface_);
    }

    float getSize() const override { return size_; }

    tex::sptr<tex::Font> deriveFont(int) const override
    {
        return std::make_shared<HarmonyFont>(file_, size_);
    }

    bool operator==(const tex::Font &other) const override
    {
        const auto *font = dynamic_cast<const HarmonyFont *>(&other);
        return font != nullptr && font->file_ == file_ && font->size_ == size_;
    }

    bool operator!=(const tex::Font &other) const override { return !(*this == other); }

    OH_Drawing_Font *native() const { return typeface_ == nullptr ? nullptr : font_; }
    const std::string &file() const { return file_; }

private:
    std::string file_;
    float size_;
    OH_Drawing_Typeface *typeface_ = nullptr;
    OH_Drawing_Font *font_ = nullptr;
};

class HarmonyTextLayout final : public tex::TextLayout {
public:
    HarmonyTextLayout(std::wstring text, tex::sptr<tex::Font> font)
        : text_(std::move(text)), font_(std::move(font)) {}

    void getBounds(tex::Rect &bounds) override
    {
        const auto *font = dynamic_cast<const HarmonyFont *>(font_.get());
        const std::string utf8 = tex::wide2utf8(text_);
        OH_Drawing_Rect *rect = OH_Drawing_RectCreate(0, 0, 0, 0);
        float width = 0;
        if (font == nullptr || font->native() == nullptr || rect == nullptr ||
            OH_Drawing_FontMeasureText(font->native(), utf8.data(), utf8.size(), TEXT_ENCODING_UTF8,
                rect, &width) != OH_DRAWING_SUCCESS) {
            bounds = tex::Rect();
        } else {
            bounds.x = OH_Drawing_RectGetLeft(rect);
            bounds.y = OH_Drawing_RectGetTop(rect);
            bounds.w = std::max(width, OH_Drawing_RectGetWidth(rect));
            bounds.h = OH_Drawing_RectGetHeight(rect);
        }
        if (rect != nullptr) OH_Drawing_RectDestroy(rect);
    }

    void draw(tex::Graphics2D &graphics, float x, float y) override
    {
        const tex::Font *previous = graphics.getFont();
        graphics.setFont(font_.get());
        graphics.drawText(text_, x, y);
        graphics.setFont(previous);
    }

private:
    std::wstring text_;
    tex::sptr<tex::Font> font_;
};

class HarmonyGraphics final : public tex::Graphics2D {
public:
    explicit HarmonyGraphics(OH_Drawing_Canvas *canvas) : canvas_(canvas)
    {
        if (canvas_ == nullptr) return;
        pen_ = OH_Drawing_PenCreate();
        brush_ = OH_Drawing_BrushCreate();
        if (pen_ == nullptr || brush_ == nullptr) return;
        OH_Drawing_PenSetAntiAlias(pen_, true);
        OH_Drawing_BrushSetAntiAlias(brush_, true);
        setColor(tex::black);
        setStroke(tex::Stroke());
    }

    ~HarmonyGraphics()
    {
        if (canvas_ != nullptr && pen_ != nullptr) OH_Drawing_CanvasDetachPen(canvas_);
        if (canvas_ != nullptr && brush_ != nullptr) OH_Drawing_CanvasDetachBrush(canvas_);
        if (pen_ != nullptr) OH_Drawing_PenDestroy(pen_);
        if (brush_ != nullptr) OH_Drawing_BrushDestroy(brush_);
    }

    bool valid() const { return canvas_ != nullptr && pen_ != nullptr && brush_ != nullptr; }

    void setColor(tex::color color) override
    {
        color_ = color;
        if (pen_ == nullptr || brush_ == nullptr) return;
        OH_Drawing_PenSetColor(pen_, color);
        OH_Drawing_BrushSetColor(brush_, color);
    }

    tex::color getColor() const override { return color_; }

    void setStroke(const tex::Stroke &stroke) override
    {
        stroke_ = stroke;
        if (pen_ == nullptr) return;
        OH_Drawing_PenSetWidth(pen_, stroke.lineWidth);
        OH_Drawing_PenSetMiterLimit(pen_, stroke.miterLimit);
        OH_Drawing_PenSetCap(pen_, stroke.cap == tex::CAP_ROUND ? LINE_ROUND_CAP :
            (stroke.cap == tex::CAP_SQUARE ? LINE_SQUARE_CAP : LINE_FLAT_CAP));
        OH_Drawing_PenSetJoin(pen_, stroke.join == tex::JOIN_ROUND ? LINE_ROUND_JOIN :
            (stroke.join == tex::JOIN_BEVEL ? LINE_BEVEL_JOIN : LINE_MITER_JOIN));
    }

    const tex::Stroke &getStroke() const override { return stroke_; }
    void setStrokeWidth(float width) override
    {
        stroke_.lineWidth = width;
        if (pen_ != nullptr) OH_Drawing_PenSetWidth(pen_, width);
    }
    const tex::Font *getFont() const override { return font_; }
    void setFont(const tex::Font *font) override { font_ = font; }

    void translate(float dx, float dy) override
    {
        tx_ += sx_ * dx;
        ty_ += sy_ * dy;
        if (canvas_ != nullptr) OH_Drawing_CanvasTranslate(canvas_, dx, dy);
    }

    void scale(float sx, float sy) override
    {
        sx_ *= sx;
        sy_ *= sy;
        if (canvas_ != nullptr) OH_Drawing_CanvasScale(canvas_, sx, sy);
    }

    void rotate(float angle) override { rotate(angle, 0, 0); }
    void rotate(float angle, float px, float py) override
    {
        if (canvas_ != nullptr) {
            OH_Drawing_CanvasRotate(canvas_, angle * 180.0f / static_cast<float>(M_PI), px, py);
        }
    }

    void reset() override
    {
        sx_ = sy_ = 1;
        tx_ = ty_ = 0;
        if (canvas_ != nullptr) OH_Drawing_CanvasResetMatrix(canvas_);
    }

    float sx() const override { return sx_; }
    float sy() const override { return sy_; }

    void drawChar(wchar_t character, float x, float y) override
    {
        drawText(std::wstring(1, character), x, y);
    }

    void drawText(const std::wstring &text, float x, float y) override
    {
        const auto *font = dynamic_cast<const HarmonyFont *>(font_);
        if (canvas_ == nullptr || brush_ == nullptr || font == nullptr || font->native() == nullptr) return;
        const std::string utf8 = tex::wide2utf8(text);
        OH_Drawing_TextBlob *blob = OH_Drawing_TextBlobCreateFromText(
            utf8.data(), utf8.size(), font->native(), TEXT_ENCODING_UTF8);
        if (blob == nullptr) return;
        OH_Drawing_CanvasAttachBrush(canvas_, brush_);
        OH_Drawing_CanvasDrawTextBlob(canvas_, blob, x, y);
        OH_Drawing_CanvasDetachBrush(canvas_);
        OH_Drawing_TextBlobDestroy(blob);
    }

    void drawLine(float x1, float y1, float x2, float y2) override
    {
        if (canvas_ == nullptr || pen_ == nullptr) return;
        OH_Drawing_CanvasAttachPen(canvas_, pen_);
        OH_Drawing_CanvasDrawLine(canvas_, x1, y1, x2, y2);
        OH_Drawing_CanvasDetachPen(canvas_);
    }

    void drawRect(float x, float y, float width, float height) override
    {
        drawRectInternal(x, y, width, height, false);
    }
    void fillRect(float x, float y, float width, float height) override
    {
        drawRectInternal(x, y, width, height, true);
    }
    void drawRoundRect(float x, float y, float width, float height, float rx, float ry) override
    {
        drawRoundRectInternal(x, y, width, height, rx, ry, false);
    }
    void fillRoundRect(float x, float y, float width, float height, float rx, float ry) override
    {
        drawRoundRectInternal(x, y, width, height, rx, ry, true);
    }

private:
    void drawRectInternal(float x, float y, float width, float height, bool fill)
    {
        if (canvas_ == nullptr || (fill ? brush_ == nullptr : pen_ == nullptr)) return;
        OH_Drawing_Rect *rect = OH_Drawing_RectCreate(x, y, x + width, y + height);
        if (rect == nullptr) return;
        if (fill) OH_Drawing_CanvasAttachBrush(canvas_, brush_);
        else OH_Drawing_CanvasAttachPen(canvas_, pen_);
        OH_Drawing_CanvasDrawRect(canvas_, rect);
        if (fill) OH_Drawing_CanvasDetachBrush(canvas_);
        else OH_Drawing_CanvasDetachPen(canvas_);
        OH_Drawing_RectDestroy(rect);
    }

    void drawRoundRectInternal(float x, float y, float width, float height, float rx, float ry, bool fill)
    {
        if (canvas_ == nullptr || (fill ? brush_ == nullptr : pen_ == nullptr)) return;
        OH_Drawing_Rect *rect = OH_Drawing_RectCreate(x, y, x + width, y + height);
        if (rect == nullptr) return;
        OH_Drawing_RoundRect *round = OH_Drawing_RoundRectCreate(rect, rx, ry);
        if (round == nullptr) {
            OH_Drawing_RectDestroy(rect);
            return;
        }
        if (fill) OH_Drawing_CanvasAttachBrush(canvas_, brush_);
        else OH_Drawing_CanvasAttachPen(canvas_, pen_);
        OH_Drawing_CanvasDrawRoundRect(canvas_, round);
        if (fill) OH_Drawing_CanvasDetachBrush(canvas_);
        else OH_Drawing_CanvasDetachPen(canvas_);
        OH_Drawing_RoundRectDestroy(round);
        OH_Drawing_RectDestroy(rect);
    }

    OH_Drawing_Canvas *canvas_ = nullptr;
    OH_Drawing_Pen *pen_ = nullptr;
    OH_Drawing_Brush *brush_ = nullptr;
    const tex::Font *font_ = nullptr;
    tex::Stroke stroke_;
    tex::color color_ = tex::black;
    float sx_ = 1;
    float sy_ = 1;
    float tx_ = 0;
    float ty_ = 0;
};

bool ReadString(napi_env env, napi_value value, std::string &result)
{
    size_t length = 0;
    if (napi_get_value_string_utf8(env, value, nullptr, 0, &length) != napi_ok ||
        length == 0 || length > MAX_LATEX_BYTES) return false;
    result.resize(length + 1);
    size_t copied = 0;
    if (napi_get_value_string_utf8(env, value, result.data(), result.size(), &copied) != napi_ok) return false;
    result.resize(copied);
    return copied == length;
}

bool ReadDouble(napi_env env, napi_value value, double &result)
{
    return napi_get_value_double(env, value, &result) == napi_ok && std::isfinite(result);
}

void SetNumber(napi_env env, napi_value object, const char *name, double value)
{
    napi_value number;
    napi_create_double(env, value, &number);
    napi_set_named_property(env, object, name, number);
}

void SetBoolean(napi_env env, napi_value object, const char *name, bool value)
{
    napi_value boolean;
    napi_get_boolean(env, value, &boolean);
    napi_set_named_property(env, object, name, boolean);
}

void SetString(napi_env env, napi_value object, const char *name, const std::string &value)
{
    napi_value string;
    napi_create_string_utf8(env, value.c_str(), value.size(), &string);
    napi_set_named_property(env, object, name, string);
}

napi_value ErrorResult(napi_env env, const std::string &message)
{
    napi_value result;
    napi_create_object(env, &result);
    SetBoolean(env, result, "valid", false);
    SetString(env, result, "error", message);
    return result;
}

std::unique_ptr<tex::TeXRender> Parse(const std::string &latex, int width, float fontSize, uint32_t color)
{
    return std::unique_ptr<tex::TeXRender>(tex::LaTeX::parse(
        tex::utf82wide(latex), width, fontSize, DEFAULT_LINE_SPACE, color));
}

napi_value Initialize(napi_env env, napi_callback_info info)
{
    size_t argc = 1;
    napi_value arguments[1] = {nullptr};
    napi_get_cb_info(env, info, &argc, arguments, nullptr, nullptr);
    std::string root;
    if (argc != 1 || !ReadString(env, arguments[0], root)) {
        napi_throw_type_error(env, nullptr, "initialize requires a non-empty resource root path");
        return nullptr;
    }
    std::lock_guard<std::mutex> lock(gMathMutex);
    if (!gInitialized) {
        tex::LaTeX::init(root);
        gResourceRoot = tex::LaTeX::getResRootPath();
        gInitialized = true;
    }
    napi_value result;
    napi_get_boolean(env, gInitialized && !gResourceRoot.empty(), &result);
    return result;
}

napi_value Measure(napi_env env, napi_callback_info info)
{
    size_t argc = 3;
    napi_value arguments[3] = {nullptr};
    napi_get_cb_info(env, info, &argc, arguments, nullptr, nullptr);
    std::string latex;
    double width = 0;
    double fontSize = 0;
    if (argc != 3 || !ReadString(env, arguments[0], latex) ||
        !ReadDouble(env, arguments[1], width) || !ReadDouble(env, arguments[2], fontSize) ||
        width <= 0 || width > 100000 || fontSize <= 0 || fontSize > 512) {
        return ErrorResult(env, "invalid arguments");
    }
    std::lock_guard<std::mutex> lock(gMathMutex);
    if (!gInitialized) return ErrorResult(env, "math engine is not initialized");
    try {
        const auto render = Parse(latex, static_cast<int>(std::ceil(width)), static_cast<float>(fontSize), tex::black);
        if (!render) return ErrorResult(env, "formula produced no layout");
        napi_value result;
        napi_create_object(env, &result);
        SetBoolean(env, result, "valid", true);
        SetNumber(env, result, "width", render->getWidth());
        SetNumber(env, result, "height", render->getHeight() + render->getDepth());
        SetNumber(env, result, "baseline", render->getBaseline());
        return result;
    } catch (const std::exception &error) {
        return ErrorResult(env, error.what());
    } catch (...) {
        return ErrorResult(env, "formula parser failed");
    }
}

napi_value Render(napi_env env, napi_callback_info info)
{
    size_t argc = 6;
    napi_value arguments[6] = {nullptr};
    napi_get_cb_info(env, info, &argc, arguments, nullptr, nullptr);
    std::string latex;
    double width = 0, height = 0, fontSize = 0, color = 0, pixelScale = 0;
    if (argc != 6 || !ReadString(env, arguments[0], latex) ||
        !ReadDouble(env, arguments[1], width) || !ReadDouble(env, arguments[2], height) ||
        !ReadDouble(env, arguments[3], fontSize) || !ReadDouble(env, arguments[4], color) ||
        !ReadDouble(env, arguments[5], pixelScale) || width <= 0 || height <= 0 ||
        fontSize <= 0 || pixelScale <= 0 || pixelScale > 4) {
        return ErrorResult(env, "invalid arguments");
    }
    const int pixelWidth = static_cast<int>(std::ceil(width * pixelScale));
    const int pixelHeight = static_cast<int>(std::ceil(height * pixelScale));
    if (pixelWidth <= 0 || pixelHeight <= 0 || pixelWidth > MAX_BITMAP_EDGE ||
        pixelHeight > MAX_BITMAP_EDGE || pixelWidth * pixelHeight * 4 > MAX_BITMAP_BYTES) {
        return ErrorResult(env, "formula bitmap exceeds budget");
    }
    std::lock_guard<std::mutex> lock(gMathMutex);
    if (!gInitialized) return ErrorResult(env, "math engine is not initialized");
    try {
        const auto render = Parse(latex, static_cast<int>(std::ceil(width)), static_cast<float>(fontSize),
            static_cast<uint32_t>(color));
        if (!render) return ErrorResult(env, "formula produced no layout");
        BitmapHandle bitmap(OH_Drawing_BitmapCreate());
        if (!bitmap) return ErrorResult(env, "formula bitmap allocation failed");
        OH_Drawing_BitmapFormat format = {COLOR_FORMAT_RGBA_8888, ALPHA_FORMAT_PREMUL};
        OH_Drawing_BitmapBuild(bitmap.get(), pixelWidth, pixelHeight, &format);
        void *source = OH_Drawing_BitmapGetPixels(bitmap.get());
        if (source == nullptr ||
            OH_Drawing_BitmapGetWidth(bitmap.get()) != static_cast<uint32_t>(pixelWidth) ||
            OH_Drawing_BitmapGetHeight(bitmap.get()) != static_cast<uint32_t>(pixelHeight)) {
            return ErrorResult(env, "formula bitmap storage allocation failed");
        }
        CanvasHandle canvas(OH_Drawing_CanvasCreate());
        if (!canvas) return ErrorResult(env, "formula canvas allocation failed");
        OH_Drawing_CanvasBind(canvas.get(), bitmap.get());
        OH_Drawing_CanvasClear(canvas.get(), 0x00000000);
        OH_Drawing_CanvasScale(canvas.get(), pixelScale, pixelScale);
        HarmonyGraphics graphics(canvas.get());
        if (!graphics.valid()) return ErrorResult(env, "formula drawing resources allocation failed");
        render->draw(graphics, 0, 0);
        const size_t byteLength = static_cast<size_t>(pixelWidth) * pixelHeight * 4;
        void *destination = nullptr;
        napi_value pixels = nullptr;
        if (napi_create_arraybuffer(env, byteLength, &destination, &pixels) != napi_ok ||
            destination == nullptr || pixels == nullptr) {
            return ErrorResult(env, "formula pixel transfer allocation failed");
        }
        std::memcpy(destination, source, byteLength);

        napi_value result;
        napi_create_object(env, &result);
        SetBoolean(env, result, "valid", true);
        SetNumber(env, result, "width", pixelWidth);
        SetNumber(env, result, "height", pixelHeight);
        napi_set_named_property(env, result, "pixels", pixels);
        return result;
    } catch (const std::exception &error) {
        return ErrorResult(env, error.what());
    } catch (...) {
        return ErrorResult(env, "formula renderer failed");
    }
}

void Cleanup(void *)
{
    std::lock_guard<std::mutex> lock(gMathMutex);
    if (gInitialized) tex::LaTeX::release();
    gInitialized = false;
    gResourceRoot.clear();
}

napi_value Init(napi_env env, napi_value exports)
{
    napi_property_descriptor descriptors[] = {
        {"initialize", nullptr, Initialize, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"measure", nullptr, Measure, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"render", nullptr, Render, nullptr, nullptr, nullptr, napi_default, nullptr},
    };
    napi_define_properties(env, exports, sizeof(descriptors) / sizeof(descriptors[0]), descriptors);
    napi_add_env_cleanup_hook(env, Cleanup, nullptr);
    return exports;
}
} // namespace

namespace tex {
Font *Font::create(const std::string &file, float size)
{
    return new HarmonyFont(file, size);
}

sptr<Font> Font::_create(const std::string &, int, float size)
{
    return std::make_shared<HarmonyFont>(std::string(), size);
}

sptr<TextLayout> TextLayout::create(const std::wstring &text, const sptr<Font> &font)
{
    return std::make_shared<HarmonyTextLayout>(text, font);
}
} // namespace tex

static napi_module gModule = {
    .nm_version = 1,
    .nm_flags = 0,
    .nm_filename = nullptr,
    .nm_register_func = Init,
    .nm_modname = "nota_math",
    .nm_priv = nullptr,
    .reserved = {nullptr},
};

extern "C" __attribute__((constructor)) void RegisterNotaMathModule()
{
    napi_module_register(&gModule);
}
