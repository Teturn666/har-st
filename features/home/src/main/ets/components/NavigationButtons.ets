@Component
export struct NavigationButtons {
  @Prop canGoPrevious: boolean;
  @Prop canGoNext: boolean;
  onPrevious: () => void = () => {
  };
  onNext: () => void = () => {
  };

  build() {
    Row() {
      // 只有当canGoPrevious为true时才显示上一题按钮
      if (this.canGoPrevious) {
        Button() {
          Text('上一题')
            .fontSize($r('app.float.font_size_16fp'))
            .fontColor($r('app.color.c_F2B771'))
        }
        .width(100)
        .height($r('app.float.float_30vp'))
        .backgroundColor(Color.White)
        .borderRadius(20)
        .border({ width: 1, color: $r('app.color.c_F2B771') })
        .margin({ left: this.canGoPrevious ? 20 : 0 })
        .onClick(() => this.onPrevious())
      } else {
        Blank()
      }

      // 只有当canGoNext为true时才显示下一题按钮
      if (this.canGoNext) {
        Button() {
          Text('下一题')
            .fontSize($r('app.float.font_size_16fp'))
            .fontColor($r('app.color.c_F2B771'))
        }
        .backgroundColor(Color.White)
        .width(100)
        .height($r('app.float.float_30vp'))
        .borderRadius(20)
        .border({ width: 1, color: $r('app.color.c_F2B771') })
        .margin({ right: this.canGoNext ? 20 : 0 })
        .onClick(() => this.onNext())
      } else {
        Blank()
      }
    }
    .justifyContent(FlexAlign.SpaceBetween)
    .alignItems(VerticalAlign.Center)
    .padding(10)
    .width('100%')
    .margin({ top: 18, bottom: 20 })
  }
}