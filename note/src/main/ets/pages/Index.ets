// T-016 应用入口：自动重定向到资料库（replaceUrl 不保留 Index 在栈中）
import { router } from '@kit.ArkUI';
import { BusinessError } from '@kit.BasicServicesKit';

@Entry
@Component
struct Index {
  aboutToAppear(): void {
    router.replaceUrl({ url: 'ui/library/LibraryPage' }).catch((err: BusinessError) => {
      console.error(`replaceUrl failed: ${err.code}`);
    });
  }

  build() {
    Column() {
      Text('Loading...')
        .fontSize(18)
        .fontColor('#666666')
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }
}
