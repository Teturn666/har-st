///题库列表
import { BankModel } from '../model/BankModel'
import BankRes from '../model/BankRes'
import TiKuRes from '../model/TikuRes';
import { Logger } from '@ohos/utils';
import { BankListRes } from '@ohos/db'

const TAG = '[BankList]'


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
      ForEach(this.bankRes.newsData, (item: BankListRes) => {
        ListItem() {
          Column() {
            Flex({
              direction: FlexDirection.Row,
              justifyContent: FlexAlign.SpaceAround,
              alignItems: ItemAlign.Center
            }) {
              Column() {
                Row() {
                  // Image($r('app.media.ic_feed'))
                  //   .objectFit(ImageFit.Contain)
                  //   .size({ width: $r('app.float.float_16vp'), height: $r('app.float.float_16vp') })
                  Text(item.name)
                    .fontColor($r('app.color.c_3e3e3e'))
                    .fontSize($r('app.float.font_size_16fp'))
                    .fontWeight(FontWeight.Bold)
                  // .margin({
                  //   left: $r('app.float.float_5vp'),
                  // })
                }

                Text(item.desc)
                  .fontColor($r('app.color.c_3e3e3e'))
                  .fontSize($r('app.float.font_size_12fp'))
                  .margin({ top: $r('app.float.float_10vp'), bottom: $r('app.float.float_10vp') })

                Row() {
                  Text("题库状态：")
                    .fontColor($r('app.color.c_9d9d9d'))
                    .fontSize($r('app.float.font_size_10fp'))
                  Text("未下载")
                    .fontColor(Color.Blue)
                    .fontSize($r('app.float.font_size_10fp'))
                    .margin({ right: $r('app.float.float_30vp') })

                  Text("题库更新时间：" + item.time)
                    .fontColor($r('app.color.c_9d9d9d'))
                    .fontSize($r('app.float.font_size_10fp'))
                }
              }
              .width('85%')
              .alignItems(HorizontalAlign.Start)
              .margin({
                left: $r('app.float.float_20vp'),
                top: $r('app.float.float_20vp'),
                right: $r('app.float.float_20vp'),
              })

              Column() {
                Image($r('app.media.ic_download'))
                  .objectFit(ImageFit.Contain)
                  .size({ width: $r('app.float.float_50vp'), height: $r('app.float.float_50vp') })
                Text("下载")
                  .fontColor(Color.Black)
                  .fontSize($r('app.float.font_size_10fp'))
              }
              .margin({
                right: $r('app.float.float_20vp'),
              })
              .onClick(
                () => {
                  Logger.info(TAG, '题库内容--------' + item)
                  this.bankModel.downLoadBank(item)
                }
              )
            }

            Divider()
              .strokeWidth(0.5)
              .color($r('app.color.c_ebebeb'))
              .margin({
                left: $r('app.float.float_20vp'),
                top: $r('app.float.float_10vp'),
                right: $r('app.float.float_20vp'),
              })
          }
        }

      }, (item: BankListRes) => JSON.stringify(item))
    }
  }

  async loadFeedData(): Promise<void> {
    let list = await this.bankModel.getBankList(this.aid.toString(), 20, 1)
    this.bankRes.newsData = list
  }
}