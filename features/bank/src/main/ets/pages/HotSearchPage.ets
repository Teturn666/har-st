import router from "@ohos.router";
import { BankModel } from "../model/BankModel";
import { Logger } from 'utils'
const TAG = '[BankNet]'

@Entry({ routeName: 'hotSearchPage' })


@Component
export struct HotSearchPage {
  @State searchText: string = '';
  private controller: TextInputController = new TextInputController();
  @State bankModel: BankModel = BankModel.getInstance();
  @State hotSearchItems: string[] = [];

  aboutToAppear(): void {
    this.loadResources();
  }

  async loadResources(): Promise<void> {
    let list = await this.bankModel.getHotSearchList();
    if (list.length > 0) {
      this.hotSearchItems = list;
    }
  }

  build() {
    Column() {

      Text("Demo")
        .onClick(() =>{
          // Logger.info(TAG, 'Search bank hhh: ');
          this.bankModel.getSearchBankList("保密",20)
        })


      Row() {
        Image($r('sys.media.ohos_ic_public_arrow_left'))
          .width(24)
          .height(24)
          .fillColor('#666666')
          .margin({ right: 8 })
          .onClick(() => {
            router.back();
          })

        Stack({ alignContent: Alignment.Start }) {
          Image($r('app.media.search'))
            .objectFit(ImageFit.Contain)
            .width(310)
            .height(36)

          Row() {
            Image($r('app.media.ic_search'))
              .objectFit(ImageFit.Cover)
              .width(24)
              .height(24)
              .margin({ left: 10 })

            TextInput({ placeholder: '请输入题库名称或关键词', controller: this.controller })
              .width('65%')
              .height(36)
              .fontSize(14)
              .fontColor(0xFF9D9D9D)
              .backgroundColor('transparent')
              .onChange((value: string) => {
                this.searchText = value;
              })

            Image($r('app.media.ic_del'))
              .width(24)
              .height(24)
              .visibility(this.searchText.length > 0 ? Visibility.Visible : Visibility.Hidden)
              .onClick(() => {
                this.controller.deleteText();
                this.searchText = '';
              })
          }
        }
      }
      .height(76)

      Row() {
        Image($r('app.media.ic_fire'))
          .width(20)
          .height(20)
          .margin({ right: 8 })

        Image($r('app.media.ic_hotsearch'))
          .width(80)
      }
      .width('90%')
      .height('auto')
      .padding({ left: 16, top: 16, bottom: 10 }) // 调整标题边距

      List() {
        ForEach(this.hotSearchItems, (item: string, index: number) => {
          ListItem() {
            Row() {
              Text(`${index + 1}`) // 动态生成排名（从 1 开始）
                .fontSize(16)
                .fontColor(index < 3 ? '#F75A23' : '#9D9D9D') // 前三名橙色，其余灰色
                .fontStyle(FontStyle.Italic) // 添加倾斜感
                .width(30) // 固定宽度，确保对齐
                .textAlign(TextAlign.Start)

              Text(item) // 文本内容
                .fontSize(16)
                .fontColor(index < 3 ? '#3E3E3E' : '#9D9D9D') // 前三名深灰色，其余灰色
                .textAlign(TextAlign.Start)
            }
            .width('100%')
            .padding({ left: 38, right: 16, top: 15 }) // 每项的内边距
            .onClick(() => {
              console.info(`Clicked on: ${item}`);
            })
          }
        }, (item: string, index: number) => index.toString())
      }
      .width('100%')
      .height('auto')
    }
    .height('100%')
    .width('100%')
    .backgroundColor(Color.White) // 确保背景为白色
  }
}