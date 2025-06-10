import { TitleBar } from 'widget/Index'
import { PointsModel } from '../model/PointsModel';
import CheckDataRes, { showSingle } from '../model/CheckDataRes';
import { promptAction, router } from '@kit.ArkUI';
import PointsConstants from '../../../Constants/PointsConstants';
import { uniformTypeDescriptor as utd } from '@kit.ArkData';
import { common, Want } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { PreferencesConstants, preferencesUtils } from 'utils';
import { systemShare } from '@kit.ShareKit';

import('./MyHistoryPage')
import('./MyInvitationPage')
import('./PointExchangePage')

@Entry({ routeName: 'pointsPage' })
@Component
export struct PointsPage {
  @State title: string = "我的积分";
  @State PointsModel: PointsModel = PointsModel.getInstance()
  @State myPoints: string = PointsConstants.POINTS_DAYS_DEFAULT_POINTS
  @State signDays: string = PointsConstants.POINTS_DAYS_DEFAULT_SIGN_DAYS
  @State toShowList: showSingle[] = []
  @State toSignToday: boolean = false
  @State loadingStatus: boolean = false
  @State AppScore: boolean = false
  @State adTimes: string = ''
  @State myCode: string = ''
  static readonly APP_STORE_URL = 'https://appgallery.huawei.com/app/detail?id=com.chznai.ikst&channelId=SHARE'

  //获取是否已经评分
  getIsAppScore(): void {
    this.AppScore = preferencesUtils.getBoolean(PreferencesConstants.SP_APP_RATING, false)
  }

  //获取广告次数
  async getAdTimes(): Promise<void> {
    this.adTimes = await this.PointsModel.getAdCount()
  }

  //应用评分
  jumpToApplication() {
    let link = `store://appgallery.huawei.com/app/detail?id=com.chznai.ikst`
    let want: Want = {
      action: 'ohos.want.action.appdetail',
      uri: link,
    };
    let context = getContext(this) as common.UIAbilityContext
    context.startAbility(want).then(async () => {
      hilog.info(0x0001, 'TAG', "Succeeded in starting Ability successfully.")
      //调用应用商店加分接口
      const scoreResult = await this.PointsModel.getScoreAction();
      if (scoreResult) {
        preferencesUtils.putBoolean(PreferencesConstants.SP_APP_RATING, true)
        this.AppScore = true
        await this.gettingPointsInfo();
        promptAction.showToast({
          message: '感谢您的评分支持！积分已到账',
          duration: 3000
        });
      }


    }).catch((error: BusinessError) => {
      hilog.error(0x0001, 'TAG', `Failed to startAbility.Code: ${error.code}, message is ${error.message}`);
    });
  }

  //邀请好友
  private async share() {
    let shareData: systemShare.SharedData = new systemShare.SharedData({
      utd: utd.UniformDataType.TEXT,
      content: `我正在使用快搜答题神器，支持各类答题平台，快来一起轻松答题吧！填写我的邀请码 ${this.myCode} 领取20积分，积分可兑换VIP哦！官方下载链接：` +
      PointsPage.APP_STORE_URL,
      title: '快搜搜题',
      description: '我正在使用快搜答题神器，支持各类答题平台，快来一起轻松答题吧！',
      thumbnail: new Uint8Array()
    });

    let controller: systemShare.ShareController = new systemShare.ShareController(shareData);
    let context = getContext(this) as common.UIAbilityContext;
    controller.show(context, {
      selectionMode: systemShare.SelectionMode.SINGLE,
      previewMode: systemShare.SharePreviewMode.DEFAULT,
    }).then(() => {

    }).catch((error: BusinessError) => {

    });
  }

  aboutToAppear(): void {
    this.loadResources()
    this.getIsAppScore()
  }

  async actionSigning(): Promise<void> {
    let action = false
    action = await this.PointsModel.getTodayPoint()
    if (action == true) {
      await this.gettingPointsInfo()
    }
  }

  async loadResources(): Promise<void> {
    await this.gettingPointsInfo();
    await this.getAdTimes();
    this.myCode = await this.PointsModel.getMyCode();
    console.log('所有资源加载完成, adTimes:', this.adTimes);
  }

  async gettingPointsInfo(): Promise<boolean> {
    this.loadingStatus = false
    try {
      // 获得签到天数
      let sign_days = await this.PointsModel.getSignState()
      sign_days = Math.round(sign_days)
      if (sign_days > 0) {
        this.toSignToday = true
        this.signDays = String(sign_days - 1)
      } else {
        this.signDays = String(Math.abs(sign_days))
      }
      // 获得签到展示
      this.toShowList = []
      let mapLists = await this.PointsModel.getSignMapList()
      let totalDays = Math.abs(sign_days)
      let cycleDay = totalDays % 7 === 0 ? 7 : totalDays % 7
      for (let i = 0; i < mapLists.length; i++) {
        let days = mapLists[i].days
        let point = mapLists[i].point
        if (i + 1 <= cycleDay) {
          this.toShowList.push(new showSingle(days, point, 1))
        } else {
          this.toShowList.push(new showSingle(days, point, 3))
        }
      }
      if (sign_days > 0) {
        this.toShowList[cycleDay - 1].type = 2
      }

      // 获得我的积分
      this.myPoints = await this.PointsModel.getMyNumb()
      this.loadingStatus = true
    } catch (error) {
    }
    return this.loadingStatus
  }

  private jumpToHistoryPoints() {
    router.pushNamedRoute({
      name: PointsConstants.ROUTE_DETAILS_POINTS_HISTORY, params: {
        myPoints: this.myPoints
      }
    })
  }

  private jumpToMyInvitation() {
    router.pushNamedRoute({ name: PointsConstants.ROUTE_DETAILS_INVITATION })
  }

  private jumpToPointExchange() {
    router.pushNamedRoute({ name: PointsConstants.ROUTE_EXCHANGE_POINTS })
  }

  build() {
    Column() {
      TitleBar({
        title: this.title, backClick: () => {
          router.back()
        }
      }).width('100%')
      Stack() {
        Image($r('app.media.ic_bu'))
          .width(160)
          .height(60)
        Text(this.myPoints)
          .fontSize(32)
          .fontColor('#F75A23')
        Text("积分明细")
          .fontSize(12)
          .fontColor('#F75A23')
          .margin({ top: 100 })
          .decoration({ type: TextDecorationType.Underline, color: '#F75A23' })
          .onClick(() => {
            this.jumpToHistoryPoints();
          })
        Column() {
          Stack() {
            Image($r('app.media.ic_rectangle'))
              .width(80)
              .height(28)
            Text("我的邀请码")
              .fontColor('#3E3E3E')
              .fontSize(12)

          }.onClick(() => {
            this.jumpToMyInvitation()

          })

          Stack() {
            Image($r('app.media.ic_rectangls'))
              .width(80)
              .height(28)
            Text("积分兑换")
              .fontColor('#3E3E3E')
              .fontSize(12)
          }
          .onClick(() => {
            this.jumpToPointExchange()
          })
        }
        .height('70')
        .width('100%')
        .justifyContent(FlexAlign.SpaceBetween)
        .alignItems(HorizontalAlign.End)

      }
      .width('100%')
      .alignContent(Alignment.Center)

      Column() {
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
        .margin({ left: 18, top: 10 })
        .width('100%')


        if (this.loadingStatus == false) {

        } else {
          Stack() {
            Image($r('app.media.ic_bg'))
              .width(330)
              .height(108)

            // Points Cards Row
            Row({ space: 5 }) {
              ForEach(this.toShowList, (item: showSingle) => {
                PointsCard({
                  points: item.point + '积分',
                  status: item.type == PointsConstants.POINTS_DAYS_STATUS_GOT ? "已领取" :
                    (item.type == PointsConstants.POINTS_DAYS_STATUS_ACTION ? "点击领取" : "未领取"),
                  isClaimed: item.type == PointsConstants.POINTS_DAYS_STATUS_GOT ? true : false,
                  canClaim: item.type == PointsConstants.POINTS_DAYS_STATUS_ACTION ? true : false,
                  onClaim: item.type == PointsConstants.POINTS_DAYS_STATUS_ACTION ? this.actionSigning : () => {
                  }
                }).onClick(async () => {
                  if (item.type == PointsConstants.POINTS_DAYS_STATUS_ACTION) {
                    await this.actionSigning()
                  }
                })
              })
            }
            .height(78)
            .alignItems(VerticalAlign.Top)

            Row() {
              Text("说明：连续中断后重新开始计算")
                .fontSize(10)
                .fontColor('#BABABA')

              Text("已连续签到" + this.signDays + "天")
                .fontColor(Color.White)
                .fontSize(12)
                .fontWeight(FontWeight.Medium)
            }
            .height(12)
            .width(313)
            .margin({ top: 60 })
            .alignItems(VerticalAlign.Bottom)
            .justifyContent(FlexAlign.SpaceBetween)
            .padding({ bottom: 10 })
          }
          .margin({ top: 8 })
          .width('100%')
          .height('auto')

        }

        Row() {
          Image($r('app.media.ic_task'))
            .width(18)
            .height(18)
          Image($r('app.media.ic_tasking'))
            .width(122)
            .height(18)
        }
        .margin({ left: 18, top: 10 })
        .width('100%')

        TaskCard({
          points: "+20积分",
          unit: "/人",
          title: "邀请好友",
          description: "  (分享好友完成注册)",
          buttonImage: $r('app.media.ic_share'),
          nClick: () => {
            this.share()
          }
        })

        TaskCard({
          points: "+5积分",
          unit: "/个",
          title: "看广告赚积分",
          description: "  (看20个可兑换一天VIP)",
          buttonImage:  $r('app.media.ic_complete'),
          nClick: () => {

          }
        })

        TaskCard({
          points: "+10积分",
          unit: "/周",
          title: "应用评分",
          description: "  (应用商店评分，我们需要您的支持)",
          buttonImage: this.AppScore ? $r('app.media.ic_comple') : $r('app.media.ic_share'),
          nClick: () => {
            if (!this.AppScore) {
              this.jumpToApplication()
            }
          }
        })

      }
      .borderRadius(12)
      .padding({ top: 8 })
      .justifyContent(FlexAlign.Start)
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

@ComponentV2
struct PointsCard {
  @Param points: string = ''; // e.g., "1积分", "2积分"
  @Param status?: string = ''; // e.g., "已领取", "点击领取", "未领取"
  @Param isClaimed?: boolean = false; // Determines if the card is claimed
  @Param canClaim?: boolean = false; // Determines if the card can be claimed today
  @Event onClaim: () => void; // Callback for claiming points

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

  }
}

@Component
struct TaskCard {
  @State points: string = '';
  @State unit: string = '';
  @State title: string = '';
  @State description: string = '';
  @State buttonImage: Resource = $r('app.media.ic_share');
  nClick: () => void = () => {
  }

  build() {
    Row() {
      Column() {
        Row() {
          Text(this.points)
            .fontSize(16)
            .fontColor('#F75A23')
          Text(this.unit)
            .fontSize(12)
            .fontColor($r('app.color.c_9d9d9d'))
        }

        Row() {
          Text(this.title)
            .fontSize(12)
            .fontColor($r('app.color.c_3e3e3e'))
          Text(this.description)
            .fontSize(12)
            .fontColor($r('app.color.c_9d9d9d'))
        }
      }
      .width('70%')
      .height('50')
      .justifyContent(FlexAlign.SpaceAround)
      .alignItems(HorizontalAlign.Start)

      Image(this.buttonImage)
        .width(63)
        .height(24)
        .onClick(() => this.nClick())
    }
    .justifyContent(FlexAlign.SpaceBetween)
    .alignItems(VerticalAlign.Center)
    .margin({ top: 8 })
    .padding({ left: 18, right: 8 })
    .width('95%')
    .height('70')
    .borderRadius(5)
    .backgroundColor('#ecebeb')
  }
}