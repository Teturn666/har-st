import { EmitterConstants, PreferencesConstants, preferencesUtils } from "utils";
import { ColorUtil } from "../utils/ColorUtil";
import { HPTLightSpectrum } from "./HPTLightSpectrum";
import { emitter } from "@kit.BasicServicesKit";


@CustomDialog
export struct SettingColorDialog {
  controller?: CustomDialogController;
  private myHexColor?: string
  @State @Watch("updateColor") selHsv: [number, number, number] = [0, 1, 1]
  @State @Watch("updateColor") selOpacity: number = 100
  @State opacityHeight: number = 20
  @State opacityInputWidth: number = 40
  changeColorBlock?: (value: string) => void
  @State IsColor: string = ""
  @Prop TypeSetting: number = 0

  updateColor() {
    let hexColor = ColorUtil.aHsvToHex(this.selOpacity / 100 * 255, this.selHsv[0], this.selHsv[1], this.selHsv[2])

    this.IsColor = hexColor
    this.myHexColor = hexColor
    this.changeColorBlock?.(hexColor)
  }

  aboutToAppear(): void {
    this.myHexColor = ColorUtil.aHsvToHex(this.selOpacity / 100 * 255, this.selHsv[0], this.selHsv[1], this.selHsv[2])
    this.updateColor()
  }

  build() {

    Column({ space: 15 }) {
      Text('选择题目/答案颜色')
        .width('100%')
        .textAlign(TextAlign.Start)
      HPTLightSpectrum({
        lightSpectrumSpotSize: 20,
        selHsv: this.selHsv,
        selOpacity: this.selOpacity,
        opacityHeight: 20,
        opacityInputWidth: 10
      })
      Row({ space: 15 }) {
        Text('取消')
          .fontSize(14)
          .fontColor('#ffbed789')
          .onClick(() => {
            this.controller?.close()
          })
        Text('确认')
          .fontColor('#ffbed789')
          .fontSize(14)
          .onClick(() => {
            this.controller?.close()
            if (this.TypeSetting === 0) {
              preferencesUtils.putString(PreferencesConstants.TITLE_COLOR_SETTING, this.IsColor)
            } else if (this.TypeSetting === 1) {
              preferencesUtils.putString(PreferencesConstants.OPTION_COLOR_SETTING, this.IsColor)

            } else if (this.TypeSetting === 2) {
              preferencesUtils.putString(PreferencesConstants.FLOATING_COLOR_SETTING, this.IsColor)

            }
            emitter.emit(EmitterConstants.SETTING_COLOR)

          })
      }
      .width('100%')
      .justifyContent(FlexAlign.End)
    }

    .padding(20)
  }
}