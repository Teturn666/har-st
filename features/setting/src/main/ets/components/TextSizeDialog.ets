import { PreferencesConstants, preferencesUtils } from "utils";

@CustomDialog
export struct TextSizeDialog {
  controller?: CustomDialogController;
  @State fontSize: number = 16;
  // 进度条数值，用于控制滑块位置和字体大小关联，可按需调整范围
  @State sliderValue: number = 16;

  aboutToAppear(): void {
    let size = preferencesUtils.getNumber(PreferencesConstants.FLOATING_TEXT_SIZE,)
    if (size) {
      this.sliderValue = size
    }
  }

  build() {
    RelativeContainer() {
      Column() {
        // 标题栏区域
        Row() {
          Text("调整字体大小")
            .fontSize(18)
          Image($r('sys.media.ohos_ic_public_close'))
            .onClick(() => {

              this.controller?.close()
            })
            .width(23)
            .aspectRatio(1)
        }
        .id('TopTitle')
        .width('100%')
        .justifyContent(FlexAlign.SpaceBetween)
        .height(40)
        .backgroundColor('#F5F5F5')

        Column() {
          Row() {
            Image($r("app.media.scan"))
              .fillColor(Color.White)
              .width(20)
              .aspectRatio(1)

            Image($r("sys.media.ohos_ic_public_close"))
              .fillColor(Color.White)
              .width(20)
              .aspectRatio(1)
          }
          .alignItems(VerticalAlign.Bottom)
          .margin(10)
          .width('100%')
          .justifyContent(FlexAlign.SpaceBetween)

          Column({ space: 10 }) {
            Text('世界上第一个永久极地考察站是________。')
              .fontSize(this.fontSize)
              .fontColor(Color.White)
            Text('A长城站')
              .fontSize(this.fontSize)
              .fontColor(Color.White)
            Text('B奥尔卡德斯站')
              .fontSize(this.fontSize)
              .fontColor('#E6D296')


            Text('C俄罗斯')
              .fontSize(this.fontSize)
              .fontColor(Color.White)
            Text('D阿蒙森-斯科特站')
              .fontSize(this.fontSize)
              .fontColor(Color.White)
          }
          .width('100%')
          .margin({ top: 5 })
          .alignItems(HorizontalAlign.Start)

        }
        .padding(10)
        .height(220)
        .backgroundColor('#766C7C')
        .margin({ top: 10 })

        Row() {
          Slider({
            value: this.sliderValue,
            min: 13,
            max: 20
          })
            .selectedColor('#000')// 已选择部分颜色
            .trackThickness(1)// 轨道粗细
            .blockColor('#CCC')// 滑块颜色
            .blockBorderColor('#ffeff0f3')// 滑块边框颜色
            .blockBorderWidth(2)// 滑块边框宽度
            .blockSize({ width: 15, height: 15 })// 滑块大小
            .width('86%')// 自定义滑块样式
            .onChange((value: number) => {
              this.fontSize = value;
            })
            .margin({ left: 5, right: 5 });

        }
        .id('slider')
        .margin({ top: 28, bottom: 15 });

        Text('确认')
          .width(80)
          .height(40)
          .backgroundColor('#ffdfd2f1')
          .textAlign(TextAlign.Center)
          .fontColor('#5B4894')
          .shadow({
            radius: 5,
            color: '#ccc',
            offsetX: 5,
            offsetY: 5
          })
          .onClick(() => {
            preferencesUtils.putNumber(PreferencesConstants.FLOATING_TEXT_SIZE, this.fontSize)
            this.controller?.close()
          })
      }

      .padding(15)
      .width('100%')
      .backgroundColor('#F8F8F8')


      Text('B-奥尔卡德斯站')
        .fontSize(this.fontSize)
        .margin({ top: 90 })
        .fontColor('#E6D296')
        .alignRules({
          middle: { anchor: '__container__', align: HorizontalAlign.Center }
        })
      Image($r('app.media.stretching'))
        .id('stretchingImage')
        .width(20)
        .aspectRatio(1)
        .fillColor(Color.White)
        .alignRules({
          center: { anchor: '__container__', align: VerticalAlign.Center },
          right: { anchor: '__container__', align: HorizontalAlign.End }
        })
        .margin({
          top: 100,
          right: 20
        })


      Row() {
        Text('小')
          .width('36%')
          .fontSize(12)
          .fontColor('#ccc')
        Text('标准')
          .fontSize(14)
          .fontColor('#ccc')

          .layoutWeight(1)
        Text('大')
          .fontSize(16)
          .fontColor('#ccc')
      }
      .margin({ top: 30 })
      .width('75%')

      .alignRules({
        top: { anchor: 'stretchingImage', align: VerticalAlign.Bottom },
        middle: { anchor: '__container__', align: HorizontalAlign.Center }
      })

    }
  }
}
