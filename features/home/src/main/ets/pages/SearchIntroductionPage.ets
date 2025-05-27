import { router, } from "@kit.ArkUI";
import { TitleBar } from "widget";
import HomeConstants from "../Constants/HomeConstants";


@Entry({ routeName: "searchIntroductionPage" })
@Component
export struct SearchIntroductionPage {
     build() {
    RelativeContainer() {
      // 标题
      TitleBar({
        title: '扫描搜题',
        backClick: () => {
          router.back()
          // this.textValue = "备注导入的题库名称"
          // this.textContent = "导入成功：导入数据129条"
          // this.isRemarkBank = true
          // this.dialogController?.open();
        },
      }).width('100%')



      // 使用说明行
      Row() {
        Image($r('app.media.ic_searcmini'))
          .width(20)
          .height(20)
        Text("使用说明")
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .margin({ left: 6 })
      }
      .id("descRow")
      .alignRules({
        top: { anchor: 'title', align: VerticalAlign.Bottom },
        left: { anchor: '__container__', align: HorizontalAlign.Start }
      })
      .margin({ top: 68, left: 26 })

      // 说明内容
      Column({ space: 8 }) {
        // 1
        Row() {
          Text("1.扫描前")
            .fontSize(12)
          Text("必须")
            .fontColor('#D77555')
            .fontSize(12)
          Text("先下载或导入对应题库。")
            .fontSize(12)
        }
        // 2
        Row() {
          Text("2.锁定题目：屏幕中显示正确答案时，点击")
            .fontSize(12)
          Text("锁定题目")
            .fontColor('#D77555')
            .fontSize(12)
          Text("可以让搜索")
            .fontSize(12)
        }
        Row(){
          Text("结果不再变化。")
            .fontSize(12)
        }
        // 3
        Row() {
          Text("3.点击右上角")
            .fontSize(12)
          Text("切换屏幕方向。")
            .fontSize(12)
            .fontColor('#D77555')
        }
      }


      .alignItems(HorizontalAlign.Start)
      .id("content")
      .alignRules({
        top: { anchor: 'descRow', align: VerticalAlign.Bottom },
        left: { anchor: '__container__', align: HorizontalAlign.Start }
      })
      .margin({ top: 16, left: 18, right: 18 })

      // 图片部分
      Image($r('app.media.search_image'))
        .id('searchImage')
        .width(220)
        .height(450)
        .borderRadius(13)
        .objectFit(ImageFit.Cover)
        .alignRules({
          top: { anchor: 'content', align: VerticalAlign.Bottom },
          middle: { anchor: '__container__', align: HorizontalAlign.Center }
        })
        .margin({ top: 25 })

      // 按钮部分
      Text("扫描搜题")
        .fontSize(15)
        .id('scanBtn')
        .width(220)
        .height(48)
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .fontColor(Color.White)
        .linearGradient({
          angle: 90, // 横向渐变
          colors: [
            ['#ffddac54', 0],   // 左

            ['#ffc3622e', 1]    // 右
          ]
        })

        .borderRadius(6)
        .textAlign(TextAlign.Center)
        .alignRules({
          top: { anchor: 'searchImage', align: VerticalAlign.Bottom },
          middle: { anchor: '__container__', align: HorizontalAlign.Center }
        })
        .margin({ top: 32 })
        .onClick(() => {
          // TODO: 扫描搜题逻辑
          router.pushNamedRoute({
            name: HomeConstants.ROUTER_SEARCH_QUESTIONS,

          })
        })
    }

    .width('100%')
    .height('100%')

  }
}