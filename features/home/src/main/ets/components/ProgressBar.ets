@Component
export struct ProgressBar {
  @Prop current: number;
  @Prop total: number;
  onReset: () => void = () => {
  };

  build() {
    Flex({ direction: FlexDirection.Row, justifyContent: FlexAlign.SpaceBetween, alignItems: ItemAlign.Center }) {
      Progress({
        type: ProgressType.Linear,
        value: this.current,
        total: this.total
      })
        .color(Color.Orange)
        .width('60%')
        .height($r('app.float.float_16vp'))
        .backgroundColor($r('app.color.c_dadada'))
        .style({ strokeWidth: 15 })

      Text(`${this.current}/${this.total}`)
        .fontSize($r('app.float.font_size_12fp'))
        .fontColor(Color.Black)

      Text('重置进度')
        .fontSize($r('app.float.font_size_12fp'))
        .onClick(() => this.onReset())
    }
    .backgroundColor($r('app.color.c_f5f3f4'))
    .borderRadius(8)
    .width('90%')
    .height($r('app.float.float_50vp'))
    .margin({ top: 10, left: 15, right: 15 })
    .padding(10)
  }
}