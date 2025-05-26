import { TitleBar } from 'widget'
import { router } from '@kit.ArkUI'
import HomeConstants from '../Constants/HomeConstants'
import { WebParseExcel } from '../components/WebParseExcel'

import('./HelpPage')
import('./CustomizedBankPage')

const TAG = 'CustomQuestionPage'

@Entry({ routeName: "customQuestionPage" })
@Component
struct CustomQuestionPage {
  @Builder
  rightBuilder() {
    Text('帮助')
      .fontColor($r('app.color.c_F75A23'))
      .onClick(() => {
        router.pushNamedRoute({
          name: HomeConstants.ROUTER_HELP_PAGE,
        })
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
            Text('题库导入')
              .fontSize(16)
            // Text('官方智能题库制作工具')
            //   .fontSize(14)
            //   .fontColor($r('app.color.c_4E4E4E'))
          }
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Start)
        }

        // 右侧按钮
        Button('去导入', { type: ButtonType.Normal })
          .backgroundColor('#F75A23')
          .borderRadius(6)
          .width(70)
          .height(25)
          .onClick(() => {
            // 这里可以添加按钮点击后的逻辑
            router.pushNamedRoute({
              name: HomeConstants.ROUTER_CUSTOMIZED_BANK_PAGE,
            })
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

      //我的导入
      Row() {
        Image($r('app.media.ic_import'))
          .width(85)
      }
      .width('90%')
      .margin({ top: 10, left: 10 })
      .alignItems(VerticalAlign.Top)
      .justifyContent(FlexAlign.Start)

      Flex({
        direction: FlexDirection.Row,
        justifyContent: FlexAlign.SpaceAround,
        alignItems: ItemAlign.Center
      }) {
        Column() {
          Row() {
            Image($r('app.media.ic_question_bank'))
              .size({ width: $r('app.float.float_16vp'), height: $r('app.float.font_size_16fp') })
            Text("二十大党建知识竞赛")
              .fontColor($r('app.color.c_3e3e3e'))
              .fontSize($r('app.float.font_size_16fp'))
              .fontWeight(400)
              .margin({ left: 8 })
          }

          Row() {
            Text("题目数量：900")
              .fontColor($r('app.color.c_9d9d9d'))
              .fontSize($r('app.float.font_size_10fp'))
              .margin({ top: $r('app.float.float_10vp'), bottom: $r('app.float.float_10vp') })

            Text("导入时间：2022-11-28")
              .fontColor($r('app.color.c_9d9d9d'))
              .fontSize($r('app.float.font_size_10fp'))
              .margin({ top: $r('app.float.float_10vp'), bottom: $r('app.float.float_10vp') })
          }
          .width('85%')
          .justifyContent(FlexAlign.SpaceBetween)
        }
        .width('85%')
        .alignItems(HorizontalAlign.Start)
        .margin({
          left: $r('app.float.float_20vp'),
          top: $r('app.float.float_20vp'),
          right: $r('app.float.float_20vp'),
        })

        Column() {
          Image($r('app.media.ic_remove'))
            .objectFit(ImageFit.Contain)
            .size({ width: $r('app.float.float_50vp'), height: $r('app.float.float_50vp') })
        }
        .margin({
          right: $r('app.float.float_20vp'),
        })

      }

      WebParseExcel()
    }
  }
}





