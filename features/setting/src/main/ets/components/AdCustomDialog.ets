
import { router } from "@kit.ArkUI";

@CustomDialog
export  struct AdCustomDialog {
  @State isVerify:boolean=false
  controller?: CustomDialogController;
  isShowDia:()=>void=()=>{}
  aboutToAppear(): void {

  }
  build() {
    Column({space:10}){
      Row(){
        Image($r('sys.media.ohos_ic_public_close'))
          .width(20)
          .height(20)

          .onClick(()=>{
            this.isShowDia()
          })
      }  .margin({bottom:9})
      .justifyContent(FlexAlign.End)
      .width('100%')
      Row(){
        Image($r('app.media.vip'))
          .width(120)
          .height(90)
      }

      .margin({bottom:20})
      Column(){
        Text('看一小段视频广告')
          .fontSize(14)
          .fontColor('#A3885D')
        Text('本次免费使用')
          .fontSize(14)
          .fontColor('#A3885D')
      }
      Text('看广告继续使用')
        .shadow({
          radius: 8,
          color: '#EBE2D5',
          offsetX: 0,
          offsetY: 4
        })
        .onClick(()=>{

          this.controller?.close()


        })
        .margin({bottom:13,top:10})
        .fontColor('#AF8050')
        .textAlign(TextAlign.Center)
        .borderRadius(5)
        .width(195)
        .height(40)
        .linearGradient({
          angle: 90, // 横向渐变
          colors: [
            ['#F6EFE4', 0.2],
            ['#FEFEFC', 0.7]
          ]
        })

      Text('升级VIP无线次数使用')
        .fontColor('#B8860B')
        .width(195)
        .height(40)
        .textAlign(TextAlign.Center)
        .borderRadius(5)
        .linearGradient({
          angle: 90, // 横向渐变
          colors: [
            ['#EDCF8F', 0.1],   // 左
            ['#FFFFD6', 0.4],   // 中
            ['#cdcf9c34', 0.7]    // 右
          ]
        })
    }
    .linearGradient({
      angle: 180, // 横向渐变
      colors: [
        ['#FEFCEF', 0.1],   // 左

        ['#FFFFFF', 0.9]    // 右
      ]
    })
    .borderRadius(5)
    .justifyContent(FlexAlign.Center)
    .padding(15)
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFEFA')
    // .alignRules({
    //   center: { anchor: '__container__', align: VerticalAlign.Center },
    //   middle: { anchor: '__container__', align: HorizontalAlign.Center }
    // })
  }
}