import { TitleBar } from 'widget'
import { router } from '@kit.ArkUI'
import HomeConstants from '../Constants/HomeConstants'

@Entry({ routeName: HomeConstants.ROUTER_CUSTOM_QUESTION })
@Component
struct CustomQuestionPage {
  @Builder
  rightBuilder() {
    Text('帮助')
      .fontColor($r('app.color.c_F75A23'))
      .onClick(() => {
        // 点击跳转对应h5
      })
  }

  build() {
    Column() {
      TitleBar({
        title: '自定义题库',
        backClick: () => {
          router.back()
        },
        rightBuilderParam: this.rightBuilder
      }).width('100%')

      // 题库制作助手
      Row() {
        Row({ space: 10 }) {
          // 左侧图标和文字部分
          Row() {
            Image($r('app.media.ic_likes'))
              .size({ width: 70, height: 70 })
          }

          Column({ space: 5 }) {
            Text('题库制作助手')
              .fontSize(16)
            Text('官方智能题库制作工具')
              .fontSize(14)
              .fontColor($r('app.color.c_4E4E4E'))
          }
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Start)
        }

        // 右侧按钮
        Button('去制作', {type: ButtonType.Normal})
          .backgroundColor('#F75A23')
          .borderRadius(6)
          .width(70)
          .height(25)
          .onClick(() => {
            // 这里可以添加按钮点击后的逻辑
          })
      }
      .width('90%')
      .height(90)
      .justifyContent(FlexAlign.SpaceBetween)
      .padding(10)
      .backgroundColor(0xf5f5f5)
      .borderRadius(10)
      .margin({
        top: 10
      })

    }
  }
}