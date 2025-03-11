///题库列表

import { BankModel } from '../model/BankModel'
import BankRes from '../model/BankRes'
import TiKuRes from '../model/TikuRes';


@Component
export struct BankList {
  @State bankRes: BankRes = new BankRes();
  @State bankModel: BankModel = BankModel.getInstance()
  aid: String = ""

  aboutToAppear(): void {
    this.loadFeedData()
  }

  build() {
    List() {
      ForEach(this.bankRes.newsData, (item: TiKuRes) => {
        ListItem() {
          Column() {
            Row() {
              Text(item.name)
                .fontColor(Color.Black)
                .fontSize(14)
                .fontWeight(FontWeight.Bold)
              Blank()
            }.justifyContent(FlexAlign.Start)

            Text(item.desc)
              .fontSize(16)
              .margin({ left: 5, right: 5, bottom: 10 })
          }.justifyContent(FlexAlign.Start).width('100%')
        }
      }, (item: TiKuRes) => JSON.stringify(item))
    }.width('100%')
  }

  async loadFeedData(): Promise<void> {
    let list = await this.bankModel.getBankList(this.aid.toString(), 20, 1)
    this.bankRes.newsData = list
  }
}