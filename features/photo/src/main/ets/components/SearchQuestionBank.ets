import { SearchResultRes } from '../model/SearchResultRes'
import { BottomBar } from './BottomBar'
import { router } from '@kit.ArkUI'
import { routerHome } from '../constants/RouterHome'
import { ProgressLoading } from 'utils/src/main/ets/components/ProgressLoading'
import { SearchModel } from '../model/SearchModel'
import { emitter } from '@kit.BasicServicesKit'

@Component
export struct SearchQuestionBank {
  @State isLoading: boolean = true
  @State resultList: SearchResultRes[] = []
  @StorageProp("ocr_text")
  @Watch('SearchChange') text: string = ""

  SearchChange() {
    this.getData()
  }

  aboutToAppear(): void {
    emitter.on('search', () => {
      this.getData()
    })
    setTimeout(() => {
      this.getData()
    })

  }

  getData() {
    SearchModel.getInstance().searchResultList(this.text.replace(/\r?\n/g, '')).then((data) => {
      this.resultList = data
      this.isLoading = false

    })
  }

  build() {
    if (this.isLoading) {
      ProgressLoading()
    } else {
      if (this.resultList?.length > 0) {

        // ListItem() {
        //   //TODO 显示ocr识别后的文本，上线后需删除
        //   Text(this.ocrTxt)
        //     .fontSize(14)
        //     .align(Alignment.Start)
        //     .fontColor($r('app.color.c_ff0000'))
        // }


        List() {

          ForEach(this.resultList,
            (item: SearchResultRes, index: number) => {
              ListItem() {
                Column() {
                  Text("答案: " + item.ans)
                    .fontSize(16)
                    .fontColor($r('app.color.c_f75a23'))
                    .margin({ bottom: 15 })
                    .align(Alignment.Start)
                  Text(item.q)
                    .fontSize(16)
                    .align(Alignment.Start)
                  ForEach(item.ASlice, (optionTxt: string, index: number) => {
                    Text(`${String.fromCharCode(65 + index)}、${optionTxt}`)
                      .fontSize(16)
                      .fontColor(
                        item.ans.toLowerCase().includes(String.fromCharCode(97 + index))
                          ? $r('app.color.c_f75a23')
                          : $r('app.color.c_3e3e3e')
                      )
                      .margin({ top: 10 })
                  })
                  Flex({
                    direction: FlexDirection.Row,
                    justifyContent: FlexAlign.SpaceBetween,
                    alignItems: ItemAlign.Center,
                    wrap: FlexWrap.Wrap
                  }) {

                    Text(item.Name)
                      .fontSize(14)
                      .fontColor($r('app.color.c_3e3e3e'))
                      .margin({ top: 30 })
                      .align(Alignment.Start)
                      .width('100%')
                  }
                }
                .padding(15)
                .alignItems(HorizontalAlign.Start)

              }
              .width('92%')
              .shadow({
                radius: 15,
                color: $r('app.color.c_d3d3d3'),
              })
              .borderRadius(10)
              .margin({ left: 15, top: 15 })
              .align(Alignment.Start)
              .onAppear(() => {
                if (index === this.resultList.length - 1) {
                  this.isLoading = false
                }
              })
            }
          )
          //  }
          ListItem() {
            BottomBar({
              searchClick: () => {
                router.replaceUrl({
                  url: routerHome.ROUTER_PhotoSearch_Page
                })
              }
            })
          }
        }
        .cachedCount(5)

      } else {
        Text($r('app.string.search_nodata'))
          .fontSize(16)
          .align(Alignment.Start)
          .fontColor($r('app.color.c_f75a23'))
          .onAppear(() => {
            this.isLoading = false
          })
      }
    }
  }
}