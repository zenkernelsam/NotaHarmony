// Phase 1390 — 1.4.2 CALLIGRAPHY 凿尖设置面板（原版 ij1.java / hri 模型）。
// 原版为选中凿尖工具时的选项区内容：角度滑块（-60°..60° 步 15°，9 档）、
// 扁率滑块（0.00..0.95 步 0.05，20 档）+ Reset、Stabilization 开关。
// 角度显示为相对竖直（nibAngle=π/2）的度数偏移；内部存弧度制。
import { EditorViewModel } from '../editor/EditorViewModel';
import { ThemeTokens, ThemeMode } from '../theme/EditorTheme';
import { ThemeStore, THEME_MODE_KEY, THEME_SYSTEM_DARK_KEY } from '../theme/ThemeStore';

// 原版 ij1 静态块：a = o6k.a0(15, ju7(-60,60,1)) → 角度刻度 -60..60 步 15°（9 档）。
const NIB_ANGLE_MIN_DEG: number = -60;
const NIB_ANGLE_MAX_DEG: number = 60;
const NIB_ANGLE_STEP_DEG: number = 15;
// 原版 ij1：b = 0.00..0.95 步 0.05（20 档），扁率显示 "Flatness: %.2f"。
const NIB_FLATNESS_MIN: number = 0;
const NIB_FLATNESS_MAX: number = 0.95;
const NIB_FLATNESS_STEP: number = 0.05;
const DEFAULT_FLATNESS: number = 0.75;  // aj1() 缺省 nibFlatness。

@Component
export struct CalligraphyNibPanel {
  @ObjectLink viewModel: EditorViewModel;
  @Prop photoImportLeaseActive: boolean = false;
  @StorageLink(THEME_MODE_KEY) themeMode: string = 'system';
  @StorageLink(THEME_SYSTEM_DARK_KEY) systemDark: boolean = false;

  private resolveTokens(): ThemeTokens {
    return ThemeStore.resolve(this.themeMode as ThemeMode, this.systemDark);
  }

  // nibAngle（弧度）→ 相对竖直的度数偏移；q6i:117 = Math.toDegrees(a - π/2)。
  private nibOffsetDeg(): number {
    return (this.viewModel.calligraphyNibAngle - Math.PI / 2) * 180 / Math.PI;
  }

  private offsetDegToRadians(offsetDeg: number): number {
    return Math.PI / 2 + offsetDeg * Math.PI / 180;
  }

  build() {
    Column() {
      // 角度：ui_tools__calligraphy_angle = "Angle: %1$d°"。
      Text($r('app.string.calligraphy_angle', Math.round(this.nibOffsetDeg())))
        .fontSize(14)
        .fontColor(this.resolveTokens().textPrimary)
        .margin({ bottom: 4 })
      Slider({
        value: this.nibOffsetDeg(),
        min: NIB_ANGLE_MIN_DEG,
        max: NIB_ANGLE_MAX_DEG,
        step: NIB_ANGLE_STEP_DEG,
      })
        .width(220)
        .enabled(!this.photoImportLeaseActive)
        .onChange((value: number) => {
          if (this.photoImportLeaseActive) {
            return;
          }
          this.viewModel.setCalligraphyNibAngle(this.offsetDegToRadians(value))
            .catch((e: Object): void => {
              console.error(`calligraphy nib angle failed: ${JSON.stringify(e)}`);
            });
        })

      // 扁率：ui_tools__calligraphy_flatness = "Flatness: %1$.2f"，附 Reset。
      Row() {
        Text($r('app.string.calligraphy_flatness',
          this.viewModel.calligraphyNibFlatness))
          .fontSize(14)
          .fontColor(this.resolveTokens().textPrimary)
          .layoutWeight(1)
        // 原版 ui_tools__reset：Reset 复位扁率至缺省 0.75（ij1 内 fjcVar4 重置）。
        Button($r('app.string.reset'))
          .height(24)
          .fontSize(11)
          .enabled(!this.photoImportLeaseActive)
          .accessibilityText($r('app.string.reset'))
          .onClick(() => {
            if (this.photoImportLeaseActive) {
              return;
            }
            this.viewModel.setCalligraphyNibFlatness(DEFAULT_FLATNESS)
              .catch((e: Object): void => {
                console.error(`calligraphy nib reset failed: ${JSON.stringify(e)}`);
              });
          })
      }
        .width(220)
        .margin({ top: 8, bottom: 4 })
      Slider({
        value: this.viewModel.calligraphyNibFlatness,
        min: NIB_FLATNESS_MIN,
        max: NIB_FLATNESS_MAX,
        step: NIB_FLATNESS_STEP,
      })
        .width(220)
        .enabled(!this.photoImportLeaseActive)
        .onChange((value: number) => {
          if (this.photoImportLeaseActive) {
            return;
          }
          this.viewModel.setCalligraphyNibFlatness(value)
            .catch((e: Object): void => {
              console.error(`calligraphy nib flatness failed: ${JSON.stringify(e)}`);
            });
        })

      // 防抖：ui_tools__stabilization = "Stabilization"（ij1 末行 c(label,z,pxi) 开关）。
      Row() {
        Text($r('app.string.stabilization'))
          .fontSize(14)
          .fontColor(this.resolveTokens().textPrimary)
          .layoutWeight(1)
        Toggle({ type: ToggleType.Switch, isOn: this.viewModel.calligraphyStabilization })
          .enabled(!this.photoImportLeaseActive)
          .accessibilityText($r('app.string.stabilization'))
          .onChange((enabled: boolean) => {
            if (this.photoImportLeaseActive) {
              return;
            }
            this.viewModel.setCalligraphyStabilization(enabled)
              .catch((e: Object): void => {
                console.error(`calligraphy stabilization failed: ${JSON.stringify(e)}`);
              });
          })
      }
        .width(220)
        .margin({ top: 8 })
    }
    .padding(16)
    .backgroundColor(this.resolveTokens().surface)
    .borderRadius(12)
    .shadow({ radius: 8, color: this.resolveTokens().shadow, offsetY: 4 })
  }
}
