import { TitleBar } from 'widget/Index'
import { SettingConstants } from "../Constants/SettingConstants";
import { promptAction, router } from '@kit.ArkUI';
import { preferencesUtils, PreferencesConstants, EmitterConstants } from 'utils/Index'
import { emitter } from '@kit.BasicServicesKit';
import { BankListRes } from 'db';
import { SettingModel } from '../model/SettingModel';
import { selectBankDialog } from './SelectBankDialog';
import { SettingColor } from '../components/SettingColor';
import { TextSizeDialog } from '../components/TextSizeDialog';

@Entry({ routeName: 'settingPage' })
@Component
export struct SettingPage {
  @State maskOpacity: number = 0;
  @State title: string = '关于设置'
  @State isDialogVisible: boolean = false;
  @State questionCounts: string[] = SettingConstants.DIALOG_QUESTIONS;
  @State v: string = SettingConstants.DIALOG_QUESTIONS[0];
  private select: number | number[] = 0;
  @State loginState: string = "0"
  @State settingModel: SettingModel = SettingModel.getInstance()
  @State bankList: BankListRes[] = [];
  private dialogController: CustomDialogController | null = null;
  @State agreementChecked: boolean = false;
  TextDialogController: CustomDialogController | null = new CustomDialogController({
    builder: TextSizeDialog({}),
    autoCancel: false,
    alignment: DialogAlignment.Center,
    offset: { dx: 0, dy: -20 },
    gridCount: 4,
    customStyle: false,
    backgroundColor: 0xd9ffffff,
    cornerRadius: 5,
    width: 310,
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

  // 打开选择题库对话框的方法
  async showSelectBankDialog() {
    await this.getIsShowDialog()
    this.dialogController = new CustomDialogController({
      builder: selectBankDialog({
        bankList: this.bankList,
        agreementChecked: this.agreementChecked,
        onConfirm: (selected: string[]) => {
          this.agreementChecked = this.agreementChecked;
        },
      })
    });
    this.dialogController.open();
  }

  // 初始化时加载保存的题目数量
  aboutToAppear() {
    this.loadResource()
    this.loginState = preferencesUtils.getString(PreferencesConstants.SP_IS_LOGIN, '0')
    this.getIsShowDialog()

  }

  //获取是否显示弹窗
  getIsShowDialog() {
    this.agreementChecked = preferencesUtils.getBoolean(PreferencesConstants.SP_SELECT_DIALOG_SHOW, false)
    console.log("初始 agreementChecked 值: " + this.agreementChecked)
  }

  async loadResource() {
    this.questionCounts = SettingConstants.DIALOG_QUESTIONS
    let count = preferencesUtils.getString(PreferencesConstants.SP_SELECT_INDEX, '0')
    this.v = this.questionCounts[Number(count)]
    this.select = Number(count)

    const banks = await this.settingModel.getBankList();
    this.bankList = banks
    console.log("查看题库列表" + JSON.stringify(this.bankList))
  }

  // 保存题目数量设置
  saveQuestionCount() {
    preferencesUtils.putString(PreferencesConstants.SP_SELECT_INDEX, String(this.select))
    preferencesUtils.putString(PreferencesConstants.SP_SELECT_VALUE, this.v)
  }

  private isLogin() {
    return this.loginState === '1'
  }

  private loginOut() {
    preferencesUtils.deleteData(PreferencesConstants.SP_IS_LOGIN)
    preferencesUtils.deleteData(PreferencesConstants.SP_NICK_NAME)
    preferencesUtils.deleteData(PreferencesConstants.SP_AVATAR_URL)
    preferencesUtils.deleteData(PreferencesConstants.SP_UNION_ID)
    preferencesUtils.deleteData(PreferencesConstants.SP_OPEN_ID)
    preferencesUtils.deleteData(PreferencesConstants.SP_IS_VIP)
    preferencesUtils.deleteData(PreferencesConstants.SP_VIP_TIME)
    preferencesUtils.deleteData(PreferencesConstants.SP_U_ID)

    emitter.emit(EmitterConstants.EM_USER_LOGIN, {
      data: {
        'nickName': '',
        'avatarUrl': '',
        'isLogin': '0',
        'isVip': 0,
        'vipTime': ''
      }
    })

    router.back()
  }

  build() {
    Column() {
      // 标题栏
      TitleBar({
        title: this.title, backClick: () => {
          router.back()
        }
      }).width('100%')
      Column() {
        Text('显示设置')
          .fontWeight(FontWeight.Bold)
          .fontSize(18)
          .fontColor("#3e3e3e")
          .textAlign(TextAlign.Start)
          .padding({ left: 16, top: 16, bottom: 16 })
          .lineHeight(20)
          .margin({ left: 20 })
      }
      .margin({ top: 5 })
      .width('100%')
      .alignItems(HorizontalAlign.Start)
      .justifyContent(FlexAlign.Start)

      Column() {
        Row() {
          SettingColor({ TextColorSetting: '题目颜色设置', Usage: '设置悬浮窗普通文本颜色', TypeSetting: 0 })
        }
        .justifyContent(FlexAlign.Center)
        .height(55)
         Divider()
        Row() {
          SettingColor({ TextColorSetting: '悬浮窗字体大小设置', ShowColor: false })
        }
        .onClick(() => {
          this.TextDialogController?.open()
        })
        .justifyContent(FlexAlign.Center)
        .height(55)
         Divider()
        // SettingColor({TextColorSetting:'选项颜色设置',Usage:'设置悬浮窗答案文本颜色',TypeSetting:1})
        // SettingColor({TextColorSetting:'题目颜色设置',Usage:'设置悬浮窗颜色和透明度',TypeSetting:2})


      }
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Start)
      .padding({ left: 16, right: 16, })
      .width('90%')
      .backgroundColor('#f9f9f9')

      // 考试设置标题
      Column() {
        Text('考试设置')
          .fontWeight(FontWeight.Bold)
          .fontSize(18)
          .fontColor("#3e3e3e")
          .textAlign(TextAlign.Start)
          .padding({ left: 16, top: 16, bottom: 16 })
          .lineHeight(20)
          .margin({ left: 20 })
      }
      .margin({ top: 5 })
      .width('100%')
      .alignItems(HorizontalAlign.Start)
      .justifyContent(FlexAlign.Start)

      // 用户协议行（显示当前题目数量）
      Column() {
        Row() {
          Text("考试一轮题目数量")
            .fontSize(16)
            .fontColor("#3e3e3e")
            .textAlign(TextAlign.Start)
            .padding({ left: 16, top: 16, bottom: 16 })
            .lineHeight(20)
          Blank()
          Text(`${this.v} 题`)
            .fontSize(16)
            .fontColor("#007DFF")
            .textAlign(TextAlign.Start)
            .padding({ left: 16, top: 16, bottom: 16 })
            .lineHeight(20)
            .margin({ right: 10 })
          Image($r('app.media.ic_enter')).width(6).height(10)
            .margin({ right: 12 })
        }
        .width('100%')
        .onClick(() => {
          TextPickerDialog.show({
            // 建议使用 this.getUIContext().showTextPickerDialog()接口
            range: this.questionCounts,
            selected: this.select,
            disappearTextStyle: { color: Color.Red, font: { size: 15, weight: FontWeight.Lighter } },
            textStyle: { color: Color.Black, font: { size: 20, weight: FontWeight.Normal } },
            selectedTextStyle: { color: Color.Blue, font: { size: 30, weight: FontWeight.Bolder } },
            onAccept: (value: TextPickerResult) => {
              // 设置select为按下确定按钮时候的选中项index，这样当弹窗再次弹出时显示选中的是上一次确定的选项
              this.select = value.index;
              console.log(this.select + '');
              // 点击确定后，被选到的文本数据展示到页面
              this.v = value.value as string;

              // 数据持久化
              this.saveQuestionCount()

              console.info("TextPickerDialog:onAccept()" + JSON.stringify(value));
            },
            onCancel: () => {
              console.info("TextPickerDialog:onCancel()");
            },
            onChange: (value: TextPickerResult) => {
              console.info("TextPickerDialog:onChange()" + JSON.stringify(value));
            },
            onScrollStop: (value: TextPickerResult) => {
              console.info("TextPickerDialog:onScrollStop()" + JSON.stringify(value));
            },
            onDidAppear: () => {
              console.info("TextPickerDialog:onDidAppear()");
            },
            onDidDisappear: () => {
              console.info("TextPickerDialog:onDidDisappear()");
            },
            onWillAppear: () => {
              console.info("TextPickerDialog:onWillAppear()");
            },
            onWillDisappear: () => {
              console.info("TextPickerDialog:onWillDisappear()");
            }
          });
          this.isDialogVisible = true
        })
      }
      .width('90%')
      .alignItems(HorizontalAlign.Start)
      .backgroundColor('#f9f9f9')
      .borderRadius(5)


      //搜索设置
      Column() {
        Text('搜索设置')
          .fontWeight(FontWeight.Bold)
          .fontSize(18)
          .fontColor("#3e3e3e")
          .textAlign(TextAlign.Start)
          .padding({ left: 16, top: 16, bottom: 16 })
          .lineHeight(20)
          .margin({ left: 20 })
      }
      .margin({ top: 5 })
      .width('100%')
      .alignItems(HorizontalAlign.Start)
      .justifyContent(FlexAlign.Start)

      Column() {
        Row() {
          Text("指定搜索题库")
            .fontSize(16)
            .fontColor("#3e3e3e")
            .textAlign(TextAlign.Start)
            .padding({ left: 16, top: 16, bottom: 16 })
            .lineHeight(20)
          Image($r('app.media.ic_vip'))
            .width($r('app.float.float_16vp'))
            .height($r('app.float.float_16vp'))
            .margin({ left: 8 })
          Blank()
          Image($r('app.media.ic_enter')).width(6).height(10)
            .margin({ right: 12 })
        }
        .width('100%')
        .onClick(() => {
          this.showSelectBankDialog();
        })
      }
      .width('90%')
      .alignItems(HorizontalAlign.Start)
      .backgroundColor('#f9f9f9')
      .borderRadius(5)

      // 登录设置标题
      Column() {
        Text('登录设置')
          .fontWeight(FontWeight.Bold)
          .fontSize(18)
          .fontColor("#3e3e3e")
          .textAlign(TextAlign.Start)
          .padding({ left: 16, top: 16, bottom: 16 })
          .lineHeight(20)
          .margin({ left: 20 })
      }
      .visibility(this.isLogin() ? Visibility.Visible : Visibility.Hidden)
      .margin({ top: 5 })
      .width('100%')
      .alignItems(HorizontalAlign.Start)
      .justifyContent(FlexAlign.Start)

      // Column() {
      //   Text('登录设置')
      //     .fontWeight(FontWeight.Bold)
      //     .fontSize(18)
      //     .fontColor("#3e3e3e")
      //     .textAlign(TextAlign.Start)
      //     .padding({ left: 16, top: 16, bottom: 16 })
      //     .lineHeight(20)
      //     .margin({ left: 20 })
      // }
      // .visibility(this.isLogin() ? Visibility.Visible : Visibility.Hidden)
      // .margin({ top: 5 })
      // .width('90%')
      // .alignItems(HorizontalAlign.Start)
      // .justifyContent(FlexAlign.Start)

      Column() {
        Row() {
          Text("退出登录")
            .fontSize(16)
            .fontColor("#3e3e3e")
            .textAlign(TextAlign.Start)
            .padding({ left: 16, top: 16, bottom: 16 })
            .lineHeight(20)

          Blank()
          Image($r('app.media.ic_enter')).width(6).height(10)
            .margin({ right: 12 })
        }
        .width('100%')
        .onClick(() => {
          this.loginDialog('退出登录', '你确定要退出登录吗？')
        })
      }
      .visibility(this.isLogin() ? Visibility.Visible : Visibility.Hidden)
      .width('90%')
      .alignItems(HorizontalAlign.Start)
      .backgroundColor('#f9f9f9')
      .borderRadius(5)


      Column() {
        Row() {
          Text("注销登录")
            .fontSize(16)
            .fontColor("#3e3e3e")
            .textAlign(TextAlign.Start)
            .padding({ left: 16, top: 16, bottom: 16 })
            .lineHeight(20)

          Blank()
          Image($r('app.media.ic_enter')).width(6).height(10)
            .margin({ right: 12 })
        }
        .width('100%')
        .onClick(() => {
          this.loginDialog('注销登录', '你确定要注销登录吗？')
        })

      }
      .visibility(this.isLogin() ? Visibility.Visible : Visibility.Hidden)
      .margin({ top: 8 })
      .width('90%')
      .alignItems(HorizontalAlign.Start)
      .backgroundColor('#f9f9f9')
      .borderRadius(5)
    }
    .alignItems(HorizontalAlign.Center)
    .width('100%')
    .height('100%')
  }

  //退出弹窗
  private loginDialog(title: string, content: string) {
    promptAction.showDialog({
      title: title,
      message: content,
      buttons: [
        { text: '取消', color: '#666666' },
        { text: '确定', color: '#d2a129' },
      ],
    }).then(async (data) => {
      if (data.index === 1) {
        this.loginOut()
        preferencesUtils.putString(PreferencesConstants.SP_QUESTION_BANK_, '1')
      }
    })
  }
}