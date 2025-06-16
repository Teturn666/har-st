import { ColorUtil } from "../utils/ColorUtil"


@Component
export struct HPTOpacity {
  @Require @Prop hsvColor: [number, number, number]
  // 透明度组件高度
  @Prop opacityHeight: number = 0
  // 透明度输入宽度
  @Prop opacityInputWidth: number = 0
  @Link @Watch('updateSelOpacity') selOpacity: number
  @State @Watch('updateInputOpacity') private inputOpacity: string = '100%'
  @State private inputCaretPosition: number = 2

  updateSelOpacity() {
    const inputOpacityValue = Math.round(Number(this.inputOpacity.replace('%', '')))
    if (inputOpacityValue == this.selOpacity) {
      return
    }
    this.inputOpacity = `${this.selOpacity}%`
  }

  updateInputOpacity() {
    const inputOpacityValue = Math.round(Number(this.inputOpacity.replace('%', '')))
    if (inputOpacityValue == this.selOpacity) {
      return
    }
    this.selOpacity = inputOpacityValue
    if (this.inputOpacity.length > 0 && this.inputOpacity != '%') {
      this.inputOpacity = `${inputOpacityValue}%`
    }
  }

  aboutToAppear(): void {
    this.updateSelOpacity()
  }

  build() {
    Row() {
      Stack() {
        Stack() {
          Text()
            .backgroundImage($r('app.media.opacity'), ImageRepeat.XY)
            .width('100%')
            .height(this.opacityHeight)
            .borderRadius(10)
            .borderRadius(this.opacityHeight / 2)
        }
        .padding({ left: 5, right: 10 })

        Slider({
          value: $$this.selOpacity,
          min: 0,
          max: 100,
          step: 1,
          style: SliderStyle.InSet,
        })
          .blockColor(ColorUtil.aHsvToHex(this.selOpacity / 100 * 255, this.hsvColor[0], this.hsvColor[1],
            this.hsvColor[2]))
          .trackColor(new LinearGradient([
            {
              color: '#00ffffff',
              offset: 0
            },
            {
              color: ColorUtil.hsvToHex(this.hsvColor[0], this.hsvColor[1], this.hsvColor[2]),
              offset: 1
            }
          ]))
          .trackBorderRadius(this.opacityHeight / 2)
          .blockStyle({
            type: SliderBlockType.SHAPE,
            shape: new Circle().width(this.opacityHeight).height(this.opacityHeight)
          })
          .selectedColor(Color.Transparent)
          .blockBorderColor(Color.White)
          .blockBorderWidth(3)
          .trackThickness(this.opacityHeight)
      }
      .layoutWeight(1)

      Blank()
        .width(10)
      TextInput({
        // text: $$this.inputOpacity
      })
        .padding(0)
        .textAlign(TextAlign.Center)
        .height(this.opacityHeight)
        .width(this.opacityInputWidth)
        .borderRadius(6)
        .backgroundColor(Color.White)
        .type(InputType.Number)
        .caretPosition(this.inputCaretPosition)
        .inputFilter('^(100|[1-9]?[0-9])(\\.[0-9]+)?%?$|^%$', (e) => {
          const value = Number(e.replace('%', ''))
          if (value > 100) {
            this.selOpacity = 100
            this.inputCaretPosition = 3
          }
        })
        .onFocus(() => {
          console.log("xxxx")
        })
        .onTextSelectionChange((selectionStart: number, _: number) => {
          console.log("xxxx")
          this.inputCaretPosition = selectionStart
          if (selectionStart == this.inputOpacity.length
            && this.inputOpacity.indexOf("%") > -1) {
            this.inputCaretPosition = selectionStart - 1
          }
        })
        .onEditChange((isEditing: boolean) => {
          if (!isEditing && this.inputOpacity == '%') {
            this.selOpacity = 1
          }
        })
    }
    .padding(0)
  }
}