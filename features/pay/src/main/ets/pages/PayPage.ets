import { PayModel } from '../model/PayModel';
import { PriceInfoRes } from '../model/PriceInfoRes';

@Entry
@Component
export struct PayPage {
  @State message: string = 'Hello World';
  @State payModel: PayModel = PayModel.getInstance()
  @State priceList: PriceInfoRes[] = [];

  aboutToAppear(): void {
    this.loadData()
  }

  build() {
    RelativeContainer() {
      Text(this.message)
        .id('HelloWorld')
        .fontSize($r('app.float.page_text_font_size'))
        .fontWeight(FontWeight.Bold)
        .alignRules({
          center: { anchor: '__container__', align: VerticalAlign.Center },
          middle: { anchor: '__container__', align: HorizontalAlign.Center }
        })
        .onClick(() => {
          this.message = 'Welcome';
        })
    }
    .height('100%')
    .width('100%')
  }

  async loadData() {
    let list = await this.payModel.getPayPriceList()
    this.priceList = list
  }
}


