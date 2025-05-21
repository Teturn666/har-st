import { router } from '@kit.ArkUI';

import promptAction from '@ohos.promptAction';
import { PointsModel } from '../model/PointsModel';

@Entry({ routeName: 'myBoundPage' })
@Component
struct BoundPage {
  @State title: string = "绑定邀请码";
  @State boundCode: string = "";
  @State PointsModel: PointsModel = PointsModel.getInstance()
  @State imageWidth: number = 200; // 固定宽度
  @State imageHeight: number = 200; // 自动计算高度
  @State inputValue: string = ''
  @State promptText: string = ''
  @State showToast: boolean = false;
  @State toastMessage: string = '';
  aboutToAppear(): void {
    this.loadResource()
  }
  async loadResource(): Promise<void>{
    // 获取数据
    this.boundCode = await this.PointsModel.getBoundCode()
    this.boundCode = ''
  }

  async submitBoundCode(code:string):Promise<void>{
    this.promptText = await this.PointsModel.submitBoundCode(code)
    if(this.promptText == "done"){
      this.boundCode = code
    }else{
      this.showToastMessage(this.promptText)
    }
  }
  // 显示 Toast 的方法
  showToastMessage(message: string) {
    this.toastMessage = message;
    this.showToast = true;

    // 3秒后自动隐藏
    setTimeout(() => {
      this.showToast = false;
    }, 3000);
  }

  build() {
    Column() {
      if(this.boundCode == ''){


        Column(){
          Text('').height('100')
          Image($r('app.media.hand'))
            .width(150)
            .height(150)
            .margin({ bottom: 70, top: 10 })
          Row() {
            TextInput({ placeholder: '好友邀请码你和好友都可获得',text:$$this.inputValue})
              .height(40)
              .fontSize(16)
              .placeholderColor('#ffcbcac6')
              .backgroundColor(Color.Transparent)
              .borderRadius(20)
              .padding({ left: 12, })
              .layoutWeight(1)

            Text('20积分')
              .width(100)
              .fontSize(23)
              .fontWeight(FontWeight.Bold)
              .fontColor('#F1CAC2')

          }
          .width('90%')
          .height(50)
          .border({ width: 1, color: '#E6C97A' })
          .borderRadius(20)
          .alignItems(VerticalAlign.Center)
          .backgroundColor(Color.White)
          .padding({ left: 10, right: 0 })

          Column(){
            Text("绑定邀请码")
              .fontSize(22)
              .fontWeight(FontWeight.Bold)
              .fontColor('#7B6008')
              .margin({ top: 16, bottom: 4 })
            Text("绑定后不可更改和解绑")
              .fontSize(15)
              .fontColor('#B8860B')
              .margin({ bottom: 16 })
          }
          .width('90%')
          .height(80)
          .linearGradient({
            angle: 90, // 横向渐变
            colors: [
              ['#EDCF8F', 0.1],   // 左
              ['#FFFFD6', 0.4],   // 中
              ['#F1D691', 0.7]    // 右
            ]
          })
          .borderRadius(16)
          .margin({ top: 20 })
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
          .onClick(async ()=>{
            await this.submitBoundCode(this.inputValue)
          })

          // Toast 组件
          if (this.showToast) {
            Column() {
              Text(this.toastMessage)
                .fontSize(14)
                .fontColor(Color.White)
                .padding({ left: 16, right: 16, top: 10, bottom: 10 })
            }
            .backgroundColor('#333333') // 半透明黑色背景
            .borderRadius(24) // 圆角矩形
            .position({ x: '10%', y: '85%' }) // 屏幕底部
            .alignItems(HorizontalAlign.Center)
            .width('fit-content')
            .height('fit-content')
            .opacity(0.9) // 透明度
            .zIndex(999) // 确保在最上层
            .onClick(() => this.showToast = false) // 点击可提前关闭
          }


          Text("暂不填写/无邀请码")
            .fontSize(15)
            .fontColor('#9F9E9C')
            .margin({ top: 25 })
            .decoration({ type: TextDecorationType.Underline, color: '#9F9E9C' })
            .onClick(() => {
              router.back()
            })
          Row(){
            Text("积分可用于兑换会员权益")
              .fontSize(12)
              .fontColor('#ff0c0c0c')
              .margin({ top: 130 })

            Text("会员权益")
              .fontSize(12)
              .fontColor('#B77558')
              .margin({ top: 130 })
              .onClick(() => {
                router.back()
              })
          }

          Row(){
            Text("30天内")
              .fontSize(12)
              .fontColor('#B77558')
              .margin({ top: 1 })
              .onClick(() => {
                router.back()
              })
            Text("可到")
              .fontSize(12)
              .fontColor('#ff131211')
              .margin({ top: 1 })

            Text("我的积分-我的邀请码")
              .fontSize(12)
              .fontColor('#B77558')
              .margin({ top: 1 })
              .onClick(() => {
                router.back()
              })
            Text("页面进行绑定")
              .fontSize(12)
              .fontColor('#ff131211')
              .margin({ top: 1 })

          }


        }.alignItems(HorizontalAlign.Center)







      }else {
        Column(){
          Text('').height('100')
          Image($r('app.media.hand'))
            .width(100)
            .height(100)

          Text("已绑定邀请码")
            .fontSize(25)
            .fontWeight(FontWeight.Bold)
            .fontColor('#fdcf8d')
            .margin({ left: 8, top:25 })
          Text(this.boundCode)
            .fontSize(30)
            .fontWeight(FontWeight.Bold)
            .fontColor('#fdcf8d')
            .margin({ left: 8,top:30 })

          Button("返回")
            .width('100')
            .height('70')
            .borderColor('#fff1e4d1')
            .backgroundColor('#fff1e4d1')
            .margin({ left: 8,top:30 })
            .onClick(()=>{
              router.back()
            })
        }.alignItems(HorizontalAlign.Center)
      }
    }
    .linearGradient({
      angle: 90,
      colors: [
        ['#FFFBEF', 0.0],
        ['#FFF5F4F2', 1.0]
      ]
    })
    .height('100%')
    .width('100%')
  }

}

@ComponentV2
struct HistoryCard {
  @Param points: string = ''; // e.g., "1积分", "2积分"
  @Param name: string = '';
  @Param time: string = '';

  build() {
    Row() {
      Column() {
        Text(this.name)
          .fontColor('#565656')
          .fontSize(18)

        Text("操作时间: "+this.time)
          .fontColor('#565656')
          .fontSize(13)
          .margin({ top: 5 })
      }
      .alignItems(HorizontalAlign.Start)
      .justifyContent(FlexAlign.Center)
      .width('70%')
      .padding({left:20})

      Column(){
        Text(this.points + "积分")
          .fontColor('#fff11818')
          .fontSize(18)
      }
      .width('30%')
    }
    .borderRadius(12)
    .margin({top:0})
    .padding({ top: 5,bottom:5,})
    .backgroundColor(Color.Gray)
    .width('100%')
    .height(70)
  }
}