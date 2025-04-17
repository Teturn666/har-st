import { TitleBar } from 'widget/Index'
import router from '@ohos.router'
import MainConstants from "../Constants/MineConstants";

@Entry({ routeName: 'aboutUsPage' })
@Component
export struct AboutUsPage {
  build() {
    Column() {
      TitleBar({
        title: '关于我们', backClick: () => {
          router.back()
        }
      }).width('100%')
      Image($r('app.media.ic_app_icon'))
        .width('70%').margin({ top: 54 })
      Column() {
        Row() {
          Text("用户协议")
            .fontSize(16)
            .fontColor($r("app.color.c_3e3e3e"))
            .textAlign(TextAlign.Start)
            .padding({ left: 16, top: 16, bottom: 16 })
            .lineHeight(20)
          Blank()
          Image($r('app.media.ic_enter')).width(6).height(10)
            .margin({ right: 12 })
        }.width('100%').onClick(() => {
          router.pushNamedRoute({
            name: MainConstants.ROUTER_WEB, params: {
              url: MainConstants.USER_AGREEMENT_URL,
              title: "用户协议"
            }
          })
        }).width('100%')

        Row() {
          Text("隐私政策")
            .fontSize(16)
            .fontColor($r("app.color.c_3e3e3e"))
            .textAlign(TextAlign.Start)
            .padding({ left: 16, top: 16, bottom: 16 })
            .lineHeight(20)
          Blank()
          Image($r('app.media.ic_enter'))
            .width(6).height(10)
            .margin({ right: 12 })
        }.width('100%').onClick(() => {
          router.pushNamedRoute({
            name: MainConstants.ROUTER_WEB, params: {
              url: MainConstants.USER_PRIVACY_URL,
              title: "隐私政策"
            }
          })
        })
      }
      .width('90%')
      .margin({ top: 54 })
      .alignItems(HorizontalAlign.Start)
      .backgroundColor($r('app.color.c_f9f9f9'))
      .borderRadius(5)

      Blank()
      Text("快搜搜题").fontSize(16)
        .fontColor($r("app.color.c_9d9d9d"))
        .textAlign(TextAlign.Start).margin({ bottom: 4 })
      Text("版本号1.0.0").fontSize(16)
        .fontColor($r("app.color.c_9d9d9d"))
        .textAlign(TextAlign.Start).margin({ bottom: 4 })
      Text("粤ICP备2021067372号-2A").fontSize(12)
        .fontColor($r("app.color.c_9d9d9d"))
        .textAlign(TextAlign.Start).margin({ bottom: 40 })

    }.alignItems(HorizontalAlign.Center)
    .width('100%')
    .height('100%')
  }
}