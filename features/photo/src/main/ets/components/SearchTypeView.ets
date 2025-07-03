import { SearchLocalResult } from './SearchLocalResult'
import { SearchQuestionBank } from './SearchQuestionBank'
import { CommonModifier } from '@kit.ArkUI'

@Component
export struct SearchTypeView {
  controller: TabsController = new TabsController()
  @State activeTabIndex: number = 0 // 当前激活的 tab 索引
  @Prop list: string[] = ["题库广场", "本地"]
  @State tabBarModifier: CommonModifier = new CommonModifier();
  @Prop TypeFlex: boolean = false

  @Builder
  getTabItemBuilder(item: string, index: number) {
    Column() {
      Text(item)
        .margin({ right: 10 })
        .fontColor(this.activeTabIndex === index ? $r('app.color.c_f75a23') : Color.Black)
      if (this.TypeFlex) {
        Row() {
        }
        .margin({ right: 10 })
        .width(28)
        .height(2)
        .border({
          width: 2,
          color: this.activeTabIndex === index ? $r('app.color.c_f75a23') : '#00000000'
        })
      }
    }
    .justifyContent(FlexAlign.Center)

  }

  aboutToAppear(): void {
    if (this.TypeFlex) {
      this.tabBarModifier.align(Alignment.Start);
    }
  }

  build() {
    Column() {
      Tabs({
        controller: this.controller,
        index: this.activeTabIndex,
        barPosition: BarPosition.Start,
        barModifier: this.tabBarModifier
      }) {
        ForEach(this.list, (item: string, index: number) => {
          TabContent() {
            // 根据索引切换内容
            if (index === 0) {
              Column() {
                SearchQuestionBank()

              }
              .height("100%")
              .justifyContent(FlexAlign.Start)
            } else {
              Column() {
                SearchLocalResult()
              }
              .height("100%")
              .justifyContent(FlexAlign.Start)
            }
          }
          .tabBar(this.getTabItemBuilder(item, index))
        })
      }
      .barMode(this.TypeFlex ? BarMode.Scrollable : BarMode.Fixed)
      .onChange((index: number) => {
        this.activeTabIndex = index
      })
    }
    .height('100%')
  }
}