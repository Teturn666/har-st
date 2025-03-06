//顶部统一的标题栏
@Component
export struct TitleBar {
  @Prop title: string
  backClick: () => void = () => {
  };

  build() {
    Row() {
      Image($r('app.media.ic_back'))
        .objectFit(ImageFit.Contain)
        .size({ width: $r('app.float.float_32vp'), height: $r('app.float.float_32vp') })
        .onClick(() => this.backClick())
      Text(this.title)
        .fontSize($r('app.float.font_size_18fp'))
        .fontColor($r('app.color.c_black'))
        .textAlign(TextAlign.Center)
        .width('85%')
    }
  }
}