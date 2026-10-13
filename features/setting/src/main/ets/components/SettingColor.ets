import { EmitterConstants, PreferencesConstants, preferencesUtils } from "utils"
import { SettingColorDialog } from "./ColorDialog"
import { emitter } from "@kit.BasicServicesKit"

@Component
export struct SettingColor {
  @State titleColor: string = ''
  @State optionColor: string = ''
  @State floatingColor: string = ''
  @State defaultColor: ResourceColor = ''
  @Prop TypeSetting: number = 0
  @Prop TextColorSetting: string = ''
  @Prop Usage: string = ''
  ShowColor: boolean = false //是否展示颜色
  ColorDialogController: CustomDialogController | null = new CustomDialogController({
    builder: SettingColorDialog({
      TypeSetting: this.TypeSetting

    }),
    autoCancel: false,
    alignment: DialogAlignment.Center,
    offset: { dx: 0, dy: -20 },
    gridCount: 4,
    customStyle: false,
    backgroundColor: 0xd9ffffff,
    cornerRadius: 5,
    width: 300,
    height: 430,
    maskColor: "#88000000",
    borderStyle: BorderStyle.Dashed,
    shadow: ({
      radius: 20,
      color: Color.Grey,
      offsetX: 10,
      offsetY: 10
    }),
  })

  aboutToAppear(): void {
    this.ColorSetting()
    emitter.on(EmitterConstants.SETTING_COLOR, (data) => {
      this.ColorSetting()
    })
  }

  ColorSetting() {
    this.titleColor = preferencesUtils.getString(PreferencesConstants.TITLE_COLOR_SETTING)
    this.optionColor = preferencesUtils.getString(PreferencesConstants.OPTION_COLOR_SETTING)
    this.floatingColor = preferencesUtils.getString(PreferencesConstants.FLOATING_COLOR_SETTING)
  }

  getColor() {
    switch (this.TypeSetting) {
      case 0:
        return this.titleColor
      case 1:
        return this.optionColor
      case 2:
        return this.floatingColor
      default:
        return '#000'; // 添加默认返回值
    }
  }

  build() {
    Row() {
      Column({ space: 5 }) {
        Text(this.TextColorSetting)
          .fontSize(17)
        Text(this.Usage)
          .fontSize(12)
          .fontColor('#999999')
      }
      .alignItems(HorizontalAlign.Start)

      if (this.ShowColor) {
        Text()
          .width(30)
          .height(30)
          .borderRadius(18)
          .onClick(() => {
            this.ColorDialogController?.open()
          })
          .backgroundColor(this.getColor() || this.defaultColor)
      }
    }
    .width('100%')
    .justifyContent(FlexAlign.SpaceBetween)
  }
}