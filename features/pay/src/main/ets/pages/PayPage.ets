import { PayModel } from '../model/PayModel';
import { PriceInfoRes } from '../model/PriceInfoRes';
import router from '@ohos.router';
const TAG = '[PayPage]';

@Entry
@Component
export struct PayPage {
  @State payModel: PayModel = PayModel.getInstance();
  @State priceList: PriceInfoRes[] = [];
  @State selectedCard: string = '3';
  @State totalPrice: number = 60.0;
  @State savePrice: number = 60.0;
  @State autoRenew: boolean = false;
  @State agreementChecked: boolean = false;
  @State isVip: boolean = true;
  @State isLoading: boolean = true;
  @State errorMessage: string = '';
  private scroller: Scroller = new Scroller();
  aboutToAppear(): void {
    console.info(`${TAG} aboutToAppear called`);
    this.loadData();
  }
  private jumpToHelpCenter() {
    try {
      router.pushNamedRoute({
        name: "webPage",
        params: {
          url: "https://ti.iksdt.com/static/doc/fwxy.html",
          title: "快搜搜题会员服务协议"
        }
      });
      console.info(`${TAG} Navigation attempted`);
    } catch (error) {
      console.error(`${TAG} Navigation failed:`, error);
    }
  }
  async loadData() {
    try {
      console.info(`${TAG} Loading price list...`);
      this.isLoading = true;
      this.errorMessage = '';
      // 使用死数据，直接定义为 PriceInfoRes[]
      const mockData: PriceInfoRes[] = [
        {
          id: "4",
          name: "快搜搜题周（7天）会员",
          showtext: "周卡",
          days: 7,
          price: 290,
          amount: 290,
          priceTr: 290 / 100,
          priceOrigin: 290 / 100
        },
        {
          id: "1",
          name: "快搜搜题月（30天）会员",
          showtext: "月卡",
          days: 30,
          price: 1000,
          amount: 800,
          priceTr: 800 / 100,
          priceOrigin: 1000 / 100
        },
        {
          id: "2",
          name: "快搜搜题季（90天）会员",
          showtext: "季卡",
          days: 90,
          price: 3000,
          amount: 1800,
          priceTr: 1800 / 100,
          priceOrigin: 3000 / 100
        },
        {
          id: "3",
          name: "快搜搜题年（366天）会员",
          showtext: "年卡",
          days: 366,
          price: 12000,
          amount: 6000,
          priceTr: 6000 / 100,
          priceOrigin: 12000 / 100
        }
      ];
      // 赋值并触发响应式更新
      this.priceList = [...mockData];
      if (this.priceList.length > 0) {
        const defaultCard = this.priceList.find(card => card.id === this.selectedCard);
        if (defaultCard) {
          this.totalPrice = defaultCard.priceTr;
          this.savePrice = defaultCard.priceOrigin - defaultCard.priceTr;
          console.info(`${TAG} Default card selected: id=${defaultCard.id}, totalPrice=${this.totalPrice}, savePrice=${this.savePrice}`);
        }
        const selectedIndex = this.priceList.findIndex(card => card.id === this.selectedCard);
        console.info(`${TAG} Selected index: ${selectedIndex}, selectedCard: ${this.selectedCard}`);
        if (selectedIndex >= 0) {
          setTimeout(() => {
            console.info(`${TAG} Scrolling to index: ${selectedIndex}`);
            this.scroller.scrollToIndex(selectedIndex, true);
          }, 100);
        } else {
          console.warn(`${TAG} Selected card not found: ${this.selectedCard}`);
        }
      } else {
        console.warn(`${TAG} Price list is empty`);
        this.errorMessage = '无会员卡数据';
      }
    } catch (e) {
      console.error(`${TAG} loadData failed:`, e);
      this.priceList = [];
      this.errorMessage = '加载失败，请重试';
    } finally {
      this.isLoading = false;
      console.info(`${TAG} Loading finished, isLoading: ${this.isLoading}, priceList length: ${this.priceList.length}`);
    }
  }
  // async loadData() {
  //   try {
  //     console.info(`${TAG} Loading price list...`);
  //     const list = await this.payModel.getPayPriceList();
  //     console.info(`${TAG} Price list loaded: ${JSON.stringify(list)}`);
  //
  //     if (list && Array.isArray(list) && list.length > 0) {
  //       this.priceList = list;
  //       const defaultCard = this.priceList.find(card => card.id === this.selectedCard);
  //       if (defaultCard) {
  //         this.totalPrice = defaultCard.priceTr;
  //         this.savePrice = defaultCard.priceOrigin - defaultCard.priceTr;
  //         console.info(`${TAG} Default card selected: id=${defaultCard.id}, totalPrice=${this.totalPrice}, savePrice=${this.savePrice}`);
  //       }
  //
  //       const selectedIndex = this.priceList.findIndex(card => card.id === this.selectedCard);
  //       if (selectedIndex >= 0) {
  //         console.info(`${TAG} Scrolling to index: ${selectedIndex}`);
  //         this.scroller.scrollToIndex(selectedIndex, true);
  //       } else {
  //         console.warn(`${TAG} Selected card not found: ${this.selectedCard}`);
  //       }
  //     } else {
  //       console.warn(`${TAG} Price list is empty or invalid`);
  //       this.priceList = [];
  //     }
  //   } catch (e) {
  //     console.error(`${TAG} loadData failed:`, e);
  //     this.priceList = [];
  //   }
  // }

  private selectCard(card: PriceInfoRes): void {
    console.info(`${TAG} Selecting card: id=${card.id}, priceTr=${card.priceTr}, priceOrigin=${card.priceOrigin}`);
    this.selectedCard = card.id;
    this.totalPrice = card.priceTr;
    this.savePrice = card.priceOrigin - card.priceTr;
    const selectedIndex = this.priceList.findIndex(item => item.id === card.id);
    if (selectedIndex >= 0) {
      console.info(`${TAG} Scrolling to index: ${selectedIndex}`);
      this.scroller.scrollToIndex(selectedIndex, true);
    }
  }
  // 获取卡的背景图片
  private getCardBackground(card: PriceInfoRes, isSelected: boolean): string {
    if (isSelected) {
      return card.id === '3' ? 'ic_yearbg' : 'ic_bg';
    }
    return card.id === '3' ? 'ic_yearedbg' : 'ic_bged';
  }
  build() {
    Column() {
      // 顶部导航栏
      Row() {
        Image($r('app.media.ic_back'))
          .width(32)
          .height(32)
          .margin({ left: 16, top: 12 })
          .onClick(() => {
            router.back();
          })

        Text('会员中心')
          .fontSize(18)
          .textAlign(TextAlign.Center)
          .fontWeight(400)
          .flexGrow(1)
          .margin({ top: 12 })

        Blank()
          .width(32)
          .margin({ right: 16, top: 12 })
      }
      .width('100%')
      .height(48)
      .backgroundColor(Color.White)
      .justifyContent(FlexAlign.SpaceBetween)

      // 用户信息
      Row() {
        Image($r('app.media.ic_head'))
          .width(40)
          .height(40)
          .borderRadius(20)
          .margin({ left: 28 })

        Column() {
          Row() {
            Text('用户xxx')
              .fontSize(14)
              .fontColor('#3E3E3E')
            if (this.isVip) {
              Image($r('app.media.ic_vip'))
                .width(16)
                .height(16)
                .margin({ left: 4 })
            }
          }
          .justifyContent(FlexAlign.Center)
          .alignItems(VerticalAlign.Center)

          if (this.isVip) {
            Text('VIP 2023-01-01 到期')
              .fontSize(10)
              .fontColor('#9D9D9D')
              .margin({ top: 5 })
          }
        }
        .margin({ left: 18 })
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')
      .height(72)
      .backgroundColor(Color.White)
      // 会员卡
      List({ space: 10, scroller: this.scroller }) {
        if (this.isLoading) {
          ListItem() {
            Text('加载中...')
              .fontSize(14)
              .fontColor('#9D9D9D')
              .width('100%')
              .textAlign(TextAlign.Center)
          }
        } else if (this.priceList.length === 0) {
          ListItem() {
            Column() {
              Text(this.errorMessage || '无会员卡数据')
                .fontSize(14)
                .fontColor('#9D9D9D')
                .width('100%')
                .textAlign(TextAlign.Center)
              if (this.errorMessage) {
                Button('重试')
                  .fontSize(14)
                  .margin({ top: 10 })
                  .onClick(() => {
                    this.loadData();
                  })
              }
            }
          }
        } else {
          ForEach(this.priceList, (card: PriceInfoRes) => {
            ListItem() {
              Stack() {
                Image($r(`app.media.${this.getCardBackground(card, this.selectedCard === card.id)}`))
                  .width(105)
                  .height(78)
                  .onError(() => {
                    console.error(`${TAG} Failed to load image: app.media.${this.getCardBackground(card, this.selectedCard === card.id)}`);
                  })
                Column() {
                  Text(card.showtext)
                    .fontWeight(600)
                    .fontSize(20)
                    .fontColor('#967d25')
                    .fontStyle(FontStyle.Italic)
                  Text(`¥${card.priceTr.toFixed(1)}`)
                    .fontSize(16)
                    .fontColor('#F75A23')
                    .margin({ top: 5 })
                  if (card.id === '4') {
                    Text('限时尝鲜')
                      .fontSize(8)
                      .fontColor('#9D9D9D')
                  } else if (card.priceOrigin > card.priceTr) {
                    Text(`原价：¥${card.priceOrigin.toFixed(1)}`)
                      .fontSize(8)
                      .fontColor('#9D9D9D')
                      .decoration({ type: TextDecorationType.LineThrough })
                  }
                }
                .margin({ left: 10 })
              }
              .alignContent(Alignment.Start)
              .onClick(() => {
                this.selectCard(card);
              })
            }
          }, (card: PriceInfoRes) => card.id)
        }
      }
      .width('100%')
      .height(100)
      .listDirection(Axis.Horizontal)
      .scrollBar(BarState.Off)
      .friction(0.6)
      .padding({ left: 16, right: 16 })

      Row() {
        Image(this.agreementChecked ? $r('app.media.ic_protocoled') : $r('app.media.ic_protocol'))
          .width(12)
          .height(12)
          .margin({ left: 18, top: 8 })
          .onClick(() => {
            this.agreementChecked = !this.agreementChecked;
          })
        Text('我已阅读并同意')
          .fontSize(12)
          .fontColor('#3E3E3E')
          .margin({ left: 8, top: 8 })
        Text('《快搜搜题会员购买协议》')
          .fontSize(12)
          .fontColor('#F75A23')
          .margin({ left: 2, top: 8 })
          .onClick(() => {
            this.jumpToHelpCenter();
          })
      }
      .width('100%')
      .height('auto')
      .backgroundColor(Color.White)

      Row() {

      }
      .width('90%')
      .height(0.8)
      .backgroundColor('#ebebeb')
      .margin({ left: 32, right: 32 ,top:20})
      // 底部支付
      Row() {
        Column() {
          Row() {
            Text(`总计：`)
              .fontSize(20)
              .fontColor('#3E3E3E')
              .margin({ left: 16, top: 12 })
            Text(`¥${this.totalPrice.toFixed(1)}`)
              .fontSize(20)
              .fontColor('#F75A23')
              .fontWeight(600)
              .margin({ left: 0, top: 12 })
          }
          if (this.savePrice > 0.0) {
            Text(`已优惠：¥${this.savePrice.toFixed(1)}`)
              .fontSize(12)
              .fontColor('#9D9D9D')
              .fontWeight(400)
              .margin({ left: 16, top: 8 })
          }
        }
        .justifyContent(FlexAlign.Start)
        .alignItems(HorizontalAlign.Start)
        Blank()
        Stack() {
          Image($r('app.media.ic_button'))
            .width(113)
            .height(48)
          Text("立即开通")
            .fontSize(14)
            .fontColor(Color.White)
        }
        .alignContent(Alignment.Center)
        .margin({ right: 18 })
      }
      .width('100%')
      .height(64)
      .backgroundColor(Color.White)
      .position({ bottom: 0 })
    }
    .height('100%')
    .width('100%')
  }
}