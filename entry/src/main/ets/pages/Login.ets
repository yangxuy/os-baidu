import { router } from '@kit.ArkUI';

@Entry
@Component
struct Login {
  @State message: string = 'Hello World';

  build() {
    Column({ space: 24 }) {
      TextInput({ placeholder: "请输入用户名" })
        .backgroundColor('#fff')
      TextInput({ placeholder: "请输入密码" })
        .backgroundColor('#fff')
      Button("确定")
        .width('100%')
        .onClick(() => {
          router.pushUrl({
            url: 'pages/Index'
          })
        })
    }
    .alignItems(HorizontalAlign.Center)
    .justifyContent(FlexAlign.Center)
    .backgroundImage("https://ai-public.mastergo.com/ai/img_res/4fccd618675aee5f21d5285dc87502bc.jpg",
      ImageRepeat.NoRepeat)
    .backgroundImageSize(ImageSize.Cover)
    .padding(16)
    .height('100%')
    .width('100%')
  }
}