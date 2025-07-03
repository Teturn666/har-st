@Component
export struct ProgressLoading {
  @Prop
  pWidth: number = 40
  @Prop
  strokeWidth: number = 4
  @Prop
  color: ResourceColor = '#fff6605e'
  @Prop
  angle: number = 0
  @Prop
  value: number = 40
  isRight: boolean = true
  timer: number = -1

  aboutToAppear(): void {
    this.beginRun()
  }

  beginRun() {
    this.timer = setInterval(() => {
      if (this.value === 80) {
        this.isRight = false
      }
      if (this.value === 40) {
        this.isRight = true
      }
      if (this.isRight) {
        this.value++
      } else {
        this.value--
      }

    }, 100)
  }

  aboutToDisappear(): void {
    clearInterval(this.timer)
  }

  build() {
    RelativeContainer() {

      Progress({
        total: 100,
        value: this.value,
        type: ProgressType.Ring
      })
        .color(this.color)
        .rotate({
          angle: this.angle
        })
        .style({
          strokeWidth: this.strokeWidth
        })
        .width(this.pWidth)
        .aspectRatio(1)
        .id("pro")
        .alignRules({
          center: { anchor: '__container__', align: VerticalAlign.Center },
          middle: { anchor: '__container__', align: HorizontalAlign.Center }
        })
        .onAppear(() => {
          animateTo({ iterations: -1, duration: 1500 }, () => {
            this.angle = 360
          })

        })
      Text("加载中")
        .fontSize(14)
        .fontColor(this.color)
        .margin({
          top: 20
        })
        .alignRules({
          center: { anchor: 'pro', align: VerticalAlign.Bottom },
          middle: { anchor: 'pro', align: HorizontalAlign.Center }
        })
    }
  }
}