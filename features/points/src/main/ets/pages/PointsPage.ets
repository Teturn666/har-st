import { TitleBar } from 'widget/Index'
import router from '@ohos.router';


@Entry()
@Component
struct PointsPage {
  @State title:string = "我的积分";

  build() {
    Column() {
      TitleBar({
        title: this.title, backClick: () => {
          router.back()
        }
      })
        .width('100%')

      Stack(){
        Image($r('app.media.ic_bu'))
          .width(160)
          .height(60)
        Text("1688")
          .fontSize(32)
          .fontColor('#F75A23')

        Text("积分明细")
          .fontSize(12)
          .fontColor('#F75A23')
          .margin({top:100})
          .decoration({type:TextDecorationType.Underline,color:'#F75A23'})
        Column(){
          Stack(){
            Image($r('app.media.ic_rectangle'))
              .width(80)
              .height(28)
            Text("我的邀请码")
              .fontColor('#3E3E3E')
              .fontSize(12)
          }
          Stack(){
            Image($r('app.media.ic_rectangls'))
              .width(80)
              .height(28)
            Text("积分兑换")
              .fontColor('#3E3E3E')
              .fontSize(12)
          }
        }
        .height('70')
        .width('100%')
        .justifyContent(FlexAlign.SpaceBetween)
        .alignItems(HorizontalAlign.End)

      }
      .width('100%')
      .alignContent(Alignment.Center)

      Column()
      {
        Row() {
          Image($r('app.media.ic_gold'))
            .width(18)
            .height(18)

          Text("签到赚积分")
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor('#333333')
            .margin({ left: 8 })
        }
        .margin({ left: 15, top: 10 })

        Stack() {
          Image($r('app.media.ic_bg'))
            .width(330)
            .height(108)

          // Points Cards Row
          Row({ space: 5 }) {
            PointsCard({
              points: "1积分",
              status: "已领取",
              isClaimed: true,
              canClaim: false,
              onClaim: () => {}
            })
            PointsCard({
              points: "1积分",
              status: "点击领取",
              isClaimed: false,
              canClaim: true,
              onClaim: () => {
                // Update state or backend to mark as claimed
              }
            })
            PointsCard({
              points: "2积分",
              status: "未领取",
              isClaimed: false,
              canClaim: false,
              onClaim: () => {}
            })
            PointsCard({
              points: "2积分",
              status: "未领取",
              isClaimed: false,
              canClaim: false,
              onClaim: () => {}
            })
            PointsCard({
              points: "2积分",
              status: "未领取",
              isClaimed: false,
              canClaim: false,
              onClaim: () => {}
            })
            PointsCard({
              points: "2积分",
              status: "未领取",
              isClaimed: false,
              canClaim: false,
              onClaim: () => {}
            })
            PointsCard({
              points: "2积分",
              status: "未领取",
              isClaimed: false,
              canClaim: false,
              onClaim: () => {}
            })
          }
          .height(78)
          .alignItems(VerticalAlign.Top)

         Row() {
                      Text("说明：连续中断后重新开始计算")
                        .fontSize(10)
                        .fontColor('#BABABA')

                      Text("已连续签到1天")
                        .fontColor(Color.White)
                        .fontSize(12)
                        .fontWeight(FontWeight.Medium)
                    }
                    .height(98)
                    .width(313)
                    .alignItems(VerticalAlign.Bottom)
                    .justifyContent(FlexAlign.SpaceBetween)
                    .padding({ bottom: 10 })
        }
        .margin({top:8})
        .width('100%')
        .height('auto')


      }
      .borderRadius(12)
      .padding({ top: 8 })
      .justifyContent(FlexAlign.Start)
      .alignItems(HorizontalAlign.Start)
      .margin({ top: 15 })
      .width('95%')
      .height('100%')
      .backgroundColor(Color.White)
    }
    .backgroundColor('#fdcf8d')
    .height('100%')
    .width('100%')
  }
}

@Component
struct PointsCard {
  points?: string; // e.g., "1积分", "2积分"
  status?: string; // e.g., "已领取", "点击领取", "未领取"
  isClaimed?: boolean; // Determines if the card is claimed
  canClaim?: boolean; // Determines if the card can be claimed today
  onClaim?: () => void; // Callback for claiming points

  build() {
    Stack() {
      Image(this.isClaimed ? $r('app.media.ic_pointsbgs') : $r('app.media.ic_pointsbg'))
        .width(41)
        .height(50)

      Column() {
        Text(this.points)
          .fontColor('#565656')
          .fontSize(10)

        Text(this.status)
          .fontColor(this.canClaim ? '#F75A23' : '#565656')
          .fontSize(8)
          .margin({ top: 8 })
      }
      .alignItems(HorizontalAlign.Center)
      .justifyContent(FlexAlign.Center)
    }
    .width(41)
    .height(50)
    .onClick(() => {
      if (this.canClaim) {
        // this.onClaim();
        // promptAction.showToast({ message: '积分已领取', duration: 1500 });
      }
    })
  }
}