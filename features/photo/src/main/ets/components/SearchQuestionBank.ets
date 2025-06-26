import { SearchResultRes } from '../model/SearchResultRes'
import { BottomBar } from './BottomBar'
import { router } from '@kit.ArkUI'
import { routerHome } from '../constants/RouterHome'
import { ProgressLoading } from 'utils/src/main/ets/components/ProgressLoading'
import { SearchModel } from '../model/SearchModel'

@Component
export struct SearchQuestionBank {
  @State isLoading: boolean = true
  @State resultList: SearchResultRes[] = []
  @StorageProp("ocr_text")
  @Watch('SearchChange') text: string = ""
  @StorageProp("select_question_type")
  @Watch('SearchChange') questionType: number = 0
  scroller: Scroller = new Scroller();

  SearchChange() {
    this.isLoading = true
    this.getData()
  }
  aboutToAppear(): void {
    setTimeout(() => {
      this.getData()
    })
  }

  getData() {
    SearchModel.getInstance().searchResultList(this.text.replace(/\r?\n/g, '')).then((data) => {
      this.resultList = []
      for (let i = 0; i < data.length; i++) {
        let item = data[i]
        let aslice = item.ASlice
        if (aslice != null && aslice.length > 1) {
          switch (this.questionType) {
            //单选
            case 1:
              if (item.ans.length === 1) {
                this.resultList.push(item)
              }
              break
          //多选
            case 2:
              if (item.ans.length > 1) {
                this.resultList.push(item)
              }
              break
          //判断
            case 3:
              if ("正确" === aslice[0]) {
                this.resultList.push(item)
              }
              break
            default:
              this.resultList = data
              break
          }
        }
      }
      this.scroller.scrollEdge(Edge.Top)
      this.isLoading = false
    })
  }

  build() {
    if (this.isLoading) {
      ProgressLoading()
    } else {
      if (this.resultList?.length > 0) {
        Column() {
          List({ scroller: this.scroller }) {
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


          }
          .cachedCount(5)
          .layoutWeight(1)

          BottomBar({
            searchClick: () => {
              router.replaceUrl({
                url: routerHome.ROUTER_PhotoSearch_Page
              })
            },
            ButtonWidth: '100%'
          })

        }
        .height('100%')
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