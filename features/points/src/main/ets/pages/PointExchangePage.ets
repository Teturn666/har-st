import { TitleBar } from 'widget'
import { promptAction } from '@kit.ArkUI'
import { PointsModel } from '../model/PointsModel';
import { ExchangeRes } from '../model/ExchangeRes';
import { EmitterConstants, Logger, PreferencesConstants, preferencesUtils } from 'utils';
import { emitter } from '@kit.BasicServicesKit';


@Component
export struct PointExchangePage {
  @State pointsModel: PointsModel = PointsModel.getInstance()
  @State exchangeList: ExchangeRes[] = []
  @State userName: string = "用户名字"
  @State userVip: boolean = false
  @State userPoints: string = ''
  @State isLoading: boolean = false
  @State errorMessage: string = ''
  @Consume PathStack: NavPathStack

  aboutToAppear(): void {
    this.getExchangeList()
  }

  private showExchange(item: ExchangeRes) {
    promptAction.showDialog({
      title: '温馨提示',
      message: `确认使用 ${item.cost} 积分兑换 ${item.quantity} 天 VIP 吗？`,
      buttons: [
        { text: '取消', color: '#666666' },
        { text: '确定', color: '#d2a129' },
      ],
    }).then(async (data) => {
      if (data.index === 1) {
        const result = await this.pointsModel.getExchangeVip(item.id.toString());
        if (result) {
          // 兑换成功提示
          promptAction.showToast({
            message: `兑换成功，恭喜获得 ${item.id} 天 VIP！`,
            duration: 2000
          });
          // 刷新积分
          this.userPoints = await this.pointsModel.getMyNumb()

          this.loadUser()
        } else {
          Logger.info('兑换失败或已提示用户');
        }
      }
    });
  }

  private async loadUser() {
    let usrInfo = await this.pointsModel.getUser()
    let nickName = preferencesUtils.getString(PreferencesConstants.SP_NICK_NAME)
    let avatarUrl = preferencesUtils.getString(PreferencesConstants.SP_AVATAR_URL)
    let loginState = preferencesUtils.getString(PreferencesConstants.SP_IS_LOGIN, '0')
    preferencesUtils.putNumber(PreferencesConstants.SP_IS_VIP, usrInfo.vip)
    preferencesUtils.putString(PreferencesConstants.SP_VIP_TIME, usrInfo.vip_expire)
    emitter.emit(EmitterConstants.EM_USER_LOGIN, {
      data: {
        'nickName': nickName,
        'avatarUrl': avatarUrl,
        'isLogin': loginState,
        'isVip': usrInfo.vip,
        'vipTime': usrInfo.vip_expire
      }
    })
  }

  async getExchangeList(): Promise<void> {
    try {
      this.isLoading = true
      const data = await this.pointsModel.getExchangeList()
      this.exchangeList = data
      this.userPoints = await this.pointsModel.getMyNumb()
      this.userName = preferencesUtils.getString(PreferencesConstants.SP_NICK_NAME, '')
      this.userVip = preferencesUtils.getBoolean(PreferencesConstants.SP_IS_VIP, false)

    } catch (error) {
      this.errorMessage = 'Failed to load exchange list: ' + error.message
    } finally {
      this.isLoading = false
    }
  }

  build() {
    Column() {
      // Title Bar
      TitleBar({
        title: '积分兑换',
        backClick: () => {
        this.PathStack.pop()
        }
      }).width('100%')

      // User Info Section
      Row() {
        Image($r('app.media.user_icon'))
          .alt($r('app.media.user_icon'))
          .objectFit(ImageFit.Contain)
          .width(48)
          .height(48)
          .borderRadius($r('app.float.float_24vp'))

        Column() {
          Row() {
            Text(this.userName)
              .fontSize(14)
              .fontColor($r("app.color.c_3e3e3e"))
              .textAlign(TextAlign.Start)
              .padding({ left: 16, right: 8 })
              .lineHeight(20)

            if (this.userVip) {
              Image($r('app.media.ic_VIP'))
                .width(18)
                .height(12)
            }

          }

          Text(this.userVip ? "VIP用户" : "普通用户")
            .fontSize(10)
            .fontColor($r("app.color.c_9d9d9d"))
            .textAlign(TextAlign.Start)
            .padding({ left: 16 })
            .lineHeight(20)
        }
        .alignItems(HorizontalAlign.Start)
        .width('60%')

        Column() {
          Text(this.userPoints.toString())
            .fontSize(20)
            .fontColor('#F75A23')
            .lineHeight(22)
            .textAlign(TextAlign.Start)
          Text("可用积分")
            .fontSize(10)
            .fontColor($r("app.color.c_9d9d9d"))
            .textAlign(TextAlign.Start)
            .lineHeight(20)
        }
        .justifyContent(FlexAlign.Start)
        .width('30%')
      }
      .alignItems(VerticalAlign.Top)
      .padding({ left: 18, top: 10, right: 18 })

      // Exchange Content Section
      Column() {
        Row() {
          Image($r('app.media.ic_exchange'))
            .width(78)
            .height(18)
        }
        .margin({ left: 15, top: 10 })

        // Loading State
        if (this.isLoading) {
          Column() {
            Text('加载中...')
              .fontSize(16)
              .fontColor($r('app.color.c_3e3e3e'))
              .textAlign(TextAlign.Center)
          }
          .width('100%')
          .padding(20)
        } else if (this.errorMessage) {
          Column() {
            Text(this.errorMessage)
              .fontSize(16)
              .textAlign(TextAlign.Center)
            Button('重试')
              .fontSize(14)
              .padding(10)
              .margin({ top: 10 })
              .onClick(() => {
                this.getExchangeList()
              })
          }
          .width('100%')
          .padding(20)
        } else {
          ForEach(this.exchangeList, (item: ExchangeRes) => {
            Stack() {
              Image($r('app.media.ic_exchangebg'))
                .objectFit(ImageFit.Contain)
                .width(340)
                .height(70)

              Row() {
                Row() {
                  Column() {
                    Text(`${item.quantity}天VIP`)
                      .fontSize(14)
                      .fontColor('#564c3c')
                    Text(`${item.quantity}天VIP权益`)
                      .fontSize(12)
                      .fontColor('#F75A23')
                      .margin({ top: 10 })
                  }
                  .margin({ left: 15 })
                  .alignItems(HorizontalAlign.Start)

                  Blank()

                  Column() {
                    Text(`${item.cost}积分`)
                      .fontSize(16)
                      .fontColor('#F75A23')
                    Text(`原价${item.original}积分`)
                      .fontSize(12)
                      .fontColor('#9D9D9D')
                      .margin({ top: 10 })
                      .decoration({ type: TextDecorationType.LineThrough })
                  }
                  .margin({ left: 15, right: 15 })
                  .alignItems(HorizontalAlign.Center)
                }
                .width('80%')

                Row() {
                  Text("兑换")
                    .fontSize(14)
                    .fontColor('#564c3c')
                    .padding(5)
                    .borderRadius(8)
                    .onClick(() => {
                      if (Number(this.userPoints) >= item.cost) {
                        this.showExchange(item)
                      } else {
                        promptAction.showToast({ message: '积分不足，无法兑换' })
                      }
                    })
                }
                .justifyContent(FlexAlign.Center)
                .width('20%')

                // .opacity(this.userPoints >= item.cost ? 1.0 : 0.5)
              }
              .justifyContent(FlexAlign.SpaceAround)
              .width('100%')
            }
            .width('100%')
            .margin({ top: 10 })
          }, (item: ExchangeRes) => item.id.toString())
        }
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
    .backgroundColor($r('app.color.c_fff9ed'))
    .width('100%')
    .height('100%')
  }
}

