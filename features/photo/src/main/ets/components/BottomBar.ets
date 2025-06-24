import { CommonConstants } from "utils"

@Component
export struct BottomBar {
  searchClick: () => void = () => {
  }
  @Prop ButtonWidth: string | number = CommonConstants.EIGHTY_PERCENT
  @Prop searchText: string = ''

  build() {
    Stack() {
      Text(this.searchText || $r('app.string.search_again'))
        .fontSize($r('app.float.font_size_18fp'))
        .fontColor($r('app.color.start_window_background'))
        .borderRadius(50)
        .textAlign(TextAlign.Center)
        .align(Alignment.Center)
        .width(this.ButtonWidth)
        .height($r('app.float.float_48vp'))
        .margin({ left: '10%', right: '10%' })
        .backgroundColor($r('app.color.c_f75a23'))
        .onClick(() => this.searchClick())
    }
    .padding({ top: $r('app.float.float_20vp') })
    .align(Alignment.BottomStart)
    .alignContent(Alignment.Center)
  }
}