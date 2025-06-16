import { ColorUtil } from "../utils/ColorUtil"
import { HPTOpacity } from "./HPTOpacity"


@Component
export struct HPTLightSpectrum {
  private settings: RenderingContextSettings = new RenderingContextSettings(true)
  private context: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings)
  private canvasWidth: number = 30
  private canvasHeight: number = 30
  // 网格宽高比
  lightSpectrumAspectRatio: number = 1
  // 光谱原点大小
  lightSpectrumSpotSize: number = 30
  // 透明度组件高度
  @Prop opacityHeight: number = 40
  // 透明度输入宽度
  @Prop opacityInputWidth: number = 60
  @Link selOpacity: number
  @Link selHsv: [number, number, number]
  @State private touchPosition?: Position = undefined

  build() {
    Column() {
      Column() {
        Stack() {
          Canvas(this.context)
            .width(270)
            .height(270)
            .borderRadius('50%')
            .aspectRatio(1)
            .onReady(() => {
              this.canvasWidth = this.context.width
              this.canvasHeight = this.context.height
              let grad = this.context.createLinearGradient(this.context.width / 2, 0, this.context.width / 2,
                this.context.height)
              grad.addColorStop(0.0, '#FFFF0000')
              grad.addColorStop(1 / 6, '#FFFFFF00')
              grad.addColorStop(2 / 6, '#FF00FF00')
              grad.addColorStop(3 / 6, '#FF00FFFF')
              grad.addColorStop(4 / 6, '#FF0000FF')
              grad.addColorStop(5 / 6, '#FFFF00FF')
              grad.addColorStop(1.0, '#FFFF0000')
              this.context.fillStyle = grad
              this.context.fillRect(0, 0, this.context.width, this.context.height)

              // 计算 pointY
              let pointY = (this.selHsv[0] / 360.0) * this.canvasHeight;

              // 计算 pointX
              let pointX: number
              if (this.selHsv[1] === 1) {
                // 饱和度为 1，亮度从 1 逐渐减小到 0
                pointX = (1 - this.selHsv[2]) * (this.canvasWidth / 2) + (this.canvasWidth / 2);
              } else {
                if (this.selHsv[0] == 0 && this.selHsv[2] == 1) {
                  // 白色
                  pointX = 0;
                } else if (this.selHsv[0] == 0 && this.selHsv[2] == 0) {
                  // 黑色
                  pointX = this.canvasWidth;
                } else if (this.selHsv[0] == 0 && this.selHsv[1] == 0) {
                  return;
                } else {
                  // 饱和度从 0 逐渐增加到 1，亮度为 1
                  pointX = this.selHsv[1] * (this.canvasWidth / 2);
                }
              }

              // 确保 pointX 和 pointY 在有效范围内
              pointX = Math.max(0, Math.min(pointX, this.canvasWidth));
              pointY = Math.max(0, Math.min(pointY, this.canvasHeight));

              // 计算 touchPosition
              this.touchPosition = {
                x: pointX - this.lightSpectrumSpotSize / 2,
                y: pointY - this.lightSpectrumSpotSize / 2
              }
            })
            .width(270)
            .height(270)
            .borderRadius('50%')


          if (this.touchPosition) {
            Stack() {
              Text()
                .width(this.lightSpectrumSpotSize - 6)
                .aspectRatio(1)
                .borderRadius((this.lightSpectrumSpotSize - 6) / 2)
                .backgroundColor(ColorUtil.aHsvToHex(this.selOpacity / 100 * 255, this.selHsv[0], this.selHsv[1],
                  this.selHsv[2]))
                .shadow({
                  color: ColorUtil.argbToHex(this.selOpacity / 100 * 255, 0, 0, 0),
                  radius: 2
                })
            }
            .backgroundColor(Color.White)
            .shadow({
              color: Color.Black,
              radius: 3
            })
            .width(this.lightSpectrumSpotSize)
            .aspectRatio(1)
            .borderRadius(this.lightSpectrumSpotSize / 2)
            .alignContent(Alignment.Center)
            .position(this.touchPosition)
          }
        }
        .width(270)
        .height(270)
        .clip(true)
        .borderRadius('50%')
        .onTouch((event) => {
          console.log(`x: ${event.touches[0].x}, y:${event.touches[0].y}`)

          // 获取触摸点坐标
          let pointX = event.touches[0].x
          let pointY = event.touches[0].y

          // 计算圆心和半径
          const centerX = this.canvasWidth / 2
          const centerY = this.canvasHeight / 2
          const radius = centerX

          // 计算触摸点到圆心的距离
          const dx = pointX - centerX
          const dy = pointY - centerY
          const distance = Math.sqrt(dx * dx + dy * dy)

          // 如果触摸点在圆外，将其投影到圆边上
          if (distance > radius) {
            const angle = Math.atan2(dy, dx)
            pointX = centerX + Math.cos(angle) * radius
            pointY = centerY + Math.sin(angle) * radius
          }

          // 计算相对于圆心的位置
          const relX = pointX - centerX
          const relY = pointY - centerY

          // 计算色相 (0-360)
          this.selHsv[0] = pointY / this.canvasHeight * 360.0

          // 计算饱和度和亮度
          if (pointX >= centerX) {
            // 右侧区域：亮度降低
            this.selHsv[1] = 1
            this.selHsv[2] = 1 - (pointX - centerX) / (this.canvasWidth / 2)
          } else {
            // 左侧区域：饱和度增加
            this.selHsv[1] = pointX / (this.canvasWidth / 2)
            this.selHsv[2] = 1
          }

          // 更新圆点位置
          this.touchPosition = {
            x: pointX - this.lightSpectrumSpotSize / 2,
            y: pointY - this.lightSpectrumSpotSize / 2
          }
        })

        .backgroundColor(Color.Pink)

      }
      .alignItems(HorizontalAlign.Start)
      .width(270)
      .height(270)
      .borderRadius('50%')
      .margin({ bottom: 10 })

      HPTOpacity({
        hsvColor: this.selHsv,
        selOpacity: this.selOpacity,
        opacityHeight: this.opacityHeight,
        opacityInputWidth: this.opacityInputWidth
      })
    }

  }
}