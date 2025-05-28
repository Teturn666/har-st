@Component
export struct DotLoading {
  @Prop @Watch('onAnimatingChanged')animating: boolean = false
 @State activeCount: number = 0
  private timer: number|null = null
  private dotCount: number = 6


  onAnimatingChanged() {

    if (this.animating) {
      this.startTimer()
    } else {
      this.stopTimer()
    }

  }

  aboutToAppear() {
    if (this.animating) {
      this.startTimer()
    }
  }
onPageHide(): void {
  this.stopTimer()
}
  aboutToDisappear() {
    this.stopTimer()
    this.dotCount=0
  }

  private startTimer() {
    if (this.timer === null) {
      this.timer = setInterval(() => {
        if (this.activeCount < this.dotCount) {
          this.activeCount += 1
        } else {
          this.activeCount = 0
        }
      }, 100)
    }
  }

  private stopTimer() {
    if (this.timer !== null) {
      clearInterval(this.timer)
      this.timer = null
      this.activeCount = 0
    }
  }

  private getDotArray(): number[] {
    let arr: number[] = []
    for (let i = 0; i < this.dotCount; i++) {
      arr.push(i)
    }
    return arr
  }

  build() {
    Row() {
      ForEach(this.getDotArray(), (idx: number) => {
        Circle()
          .width(10)
          .height(10)
          .fill(idx < this.activeCount ? 0xFFFF9900 : 0x33FF9900)
          .margin({ right: idx < this.dotCount - 1 ? 10 : 0 })
      })
    }
    .width(120)
    .height(24)
    .justifyContent(FlexAlign.Center)
    .alignItems(VerticalAlign.Center)
  }
}