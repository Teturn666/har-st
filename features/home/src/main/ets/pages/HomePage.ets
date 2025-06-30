import {
  CommonConstants as Const,
  EmitterConstants,
  GetAllSelectedUtil,
  Logger,
  PreferencesConstants,
  preferencesUtils
} from 'utils/Index'
import { hilog } from '@kit.PerformanceAnalysisKit'
import { emitter } from '@kit.BasicServicesKit'

import { image } from '@kit.ImageKit'

import { HomeModel } from '../model/HomeModel'
import { HomeBankListRes } from '../model/HomeBankListRes'
import { LoadingStatus } from 'utils'
import HomeConstants from '../Constants/HomeConstants'
import common from '@ohos.app.ability.common'
import router from '@ohos.router'
import { PayView } from 'view/Index'
import lottie, { AnimationItem } from '@ohos/lottie'
import { taskpool, util } from '@kit.ArkTS'
import { onEventObject } from '@umeng/analytics'
import HomeMobClickConstants from '../Constants/HomeMobClickConstants'
import { window } from '@kit.ArkUI'
import { selectImage } from '../utils/SelectImage'
import { ProgressLoading } from 'utils/src/main/ets/components/ProgressLoading'
import { screenManager } from '../utils/ScreenManager'
import { selectBankDialog } from 'setting/src/main/ets/pages/SelectBankDialog'
import { BankListRes } from 'db'
import { AdCustomDialog } from '../components/AdCustomDialog'
import { ConfigRes } from 'utils/src/main/ets/model/ConfigRes'
import { HmAdInfo } from 'utils/src/main/ets/model/HmAdInfo'
import { Params, PipManager } from '../manage/PipManage'
import { ocrToText } from '../utils/OcrToText'
import { ScreenCaptureManager } from '../manage/ScreenCaptureManager'
import { readSearchCurrent, ReadSearchResult } from '../manage/ConcurrentManage'
import { MDataTextManage } from 'search/src/main/ets/manage/MDataTextManage'
import { accessManager } from '../utils/AccessManager'
import { SearchMapManage } from 'search/src/main/ets/manage/SearchMapManage'
import SearchConstants from 'search/src/main/ets/constants/SearchConstants'
import { NavDoubleString } from '../model/NavGenericType'

import('photo/src/main/ets/pages/SearchResultPage')
import('web/src/main/ets/pages/ChWebPage')
import('./BankListPage')
import('./MyDownloadPage')
import('./CustomQuestionPage')
import('./SearchQuestions')
import('./SearchIntroductionPage')
import('./PhotoSearchPage')
const SWIPER_ASPECT_RATIO = 2.4
const SWIPER_MARGIN = 220
let arr: number[] = [1]
const context = (getContext(this) as common.UIAbilityContext)

// 录屏状态枚举
enum RecordingState {
  IDLE = 0,
  RECORDING = 1,
  PROCESSING = 2
}

const TAG = '[HomePage]'

let jsonData = null

// 定义搜题模式枚举
enum SearchMode {
  SCAN = 'scan', // 扫描搜题
  SCREEN_READ = 'screen_read' // 读屏搜题
}

@Builder
export function HomePageBuilder() {
  HomePage()
}

@Entry()
@Component
export struct HomePage {
  @State chooseImage: PixelMap | undefined = undefined
  @State dataValues: string = ''
  @State homeModel: HomeModel = HomeModel.getInstance()
  @State loadingStatus: LoadingStatus = LoadingStatus.OFF
  @State accounts: Array<HomeBankListRes> = []
  testString: number[] = []
  private resStr = util.TextDecoder.create('utf-8', { ignoreBOM: true })
  @State hasLoadData: boolean = false
  @State loading: boolean = false
  @State TopHeight: number = 0
  win: window.Window | null = null
  @State bankList: BankListRes[] = [];
  private dialogController: CustomDialogController | null = null;
  @State agreementChecked: boolean = false;
  @State isVip: number = 0
  @State CsjCode: number = 0
  @State CsjId: string = ""
  @State CsjIsShow: boolean = false
  @State currentSearchMode: SearchMode | null = null; // 当前搜题模式
  @State TypeSearch: boolean = false
  @Consume appPathStack: NavPathStack
  TypeRead: () => void = () => {
  }
  CsjHmAD: ConfigRes = {
    hmAd: new HmAdInfo()
  }
  @State pipAnswer: string = '暂未搜索到该题'
  AdDialogController = new CustomDialogController({
    builder: AdCustomDialog({
      isShowDialog: (() => {
        this.AdDialogController?.close()
      }),
      readSearch: this.TypeRead,
      CsjId: this.CsjId,
      CsjIsShow: this.CsjIsShow,
      TypeSearch: this.TypeSearch
    }),
    autoCancel: false,
    alignment: DialogAlignment.Center,
    offset: { dx: 0, dy: -20 },
    gridCount: 4,
    customStyle: false,
    backgroundColor: 0xd9ffffff,
    cornerRadius: 5,
    width: 300,
    height: 350,
    maskColor: "#88000000",
    borderStyle: BorderStyle.Dashed,
    shadow: ({
      radius: 20,
      color: Color.Grey,
      offsetX: 10,
      offsetY: 10
    }),
  });

  async aboutToAppear() {
    this.isVip = preferencesUtils.getNumber(PreferencesConstants.SP_IS_VIP)
    this.CsjHmAD = preferencesUtils.getGenerics(PreferencesConstants.CSJ_AD_PARAMS);
    this.CsjCode = preferencesUtils.getNumber(PreferencesConstants.CSJ_AD_CODE)
    this.loadResource()
    emitter.on(EmitterConstants.EM_REFRESH_HOME, () => {
      this.loadResource()
    })

    // 判断是否为全选,如果是全选设置mdataText给唯一变量
    let mdataText: SharedArrayBuffer | null = null
    if (GetAllSelectedUtil.isUserBankAllSelected()) {
      mdataText = await SearchMapManage.getInstance()
        .loadSharedArrayBufferFromFile(getContext(this), SearchConstants.SEARCH_FILE_ALL)
    } else {
      // 赋值mdataText给全局变量
      mdataText = await SearchMapManage.getInstance()
        .loadSharedArrayBufferFromFile(getContext(this), SearchConstants.SEARCH_FILE_SOME)
    }
    MDataTextManage.getInstance().saveDataText(mdataText)
  }

  aboutToDisappear(): void {
    lottie.destroy()
    screenManager.exitFull(getContext())
    this.TopHeight = 0
  }

  onBackPress(): boolean | void {
    return true
  }

  build() {
    RelativeContainer() {
      Column() {
        List({ space: Const.SPACE_16 }) {
          ListItem() {
            Banner({
              swiperData: arr,
              handleClick: (item: number) => {
                hilog.info(0x0001, "testTag", "---->" + item);
                this.jumpToWeb()
              }
            })
          }

          ListItem() {
            SearchList({
              nClick: this.handleScanSearch,
              ScreenReader: this.handleScreenReadSearch
            })
          }


          ListItem() {
            SearchHelper({
              isLoading: this.loading,
              handleClick: () => {
                //'ohos.permission.READ_IMAGEVIDEO'
                accessManager.CheckCamera(['ohos.permission.CAMERA',], () => {
                  this.appPathStack.pushPathByName(HomeConstants.ROUTER_PHOTO_SEARCH,null)
                })
              }
            })
          }

          ListItem() {
            BankHelper({
              downloadClick: async () => {
                //跳转到我的下载页面
                this.jumpToDownloadResult()
              },
              customQuestionClick: async () => {
                //跳转到自定义题库
                this.jumpToCustomResult()
              }
            })
          }

          ListItem() {
            ExerciseHelper({
              bankClick: async () => {
                //跳转练习列表页面
                this.jumpToBankList(1)
              },
              wrongClick: async () => {
                //跳转错题列表练习页面
                this.jumpToBankList(2)
              },
              collectionClick: async () => {
                //跳转收藏列表练习页面
                this.jumpToBankList(3)
              },
            })
          }

          //测试显示ocr的文本
          // ListItem() {
          //   Text(this.dataValues)
          //     .fontSize($r('app.float.font_size_10fp'))
          //     .fontColor($r('app.color.c_black'))
          // }
        }
        .scrollBar(BarState.Off)

        // } else if (this.loadingStatus === LoadingStatus.FAILED) {
        //   Text('数据插入失败').fontSize(18)
        // }

        .height(Const.FULL_PERCENT)
        .width(Const.FULL_PERCENT)
        .padding({
          left: $r('app.float.float_15vp'), right: $r('app.float.float_15vp')
        })

      }

      Column() {
        if (this.loading) {
          Row() {
            ProgressLoading()
          }

          .width("100%")
          .height("100%")

        }

      }
      .alignRules({
        center: { anchor: '__container__', align: VerticalAlign.Center },
        middle: { anchor: '__container__', align: HorizontalAlign.Center }
      })
    }
    .margin({
      top: this.TopHeight
    })
  }

  private async loadResource() {
    this.getIsShowDialog()
    const banks = await this.homeModel.getBankList();
    this.bankList = banks
  }

  // 打开选择题库对话框的方法
  private async showSelectBankDialog(isVipDialogCallBack: Function, isChangeTextCallBack: Function) {
    this.dialogController = new CustomDialogController({
      builder: selectBankDialog({
        agreementChecked: this.agreementChecked,
        onConfirm: (selected: string[]) => {
          this.agreementChecked = this.agreementChecked;
        },
        isVipDialog: () => {
          this.dialogController?.close()
          //弹窗
          if (!this.isVip && this.bankList.length > 0 && this.CsjIsShow &&
            !this.CsjCode) {
            this.AdDialogController?.open()
          } else {
            if (this.bankList.length > 0) {
              isVipDialogCallBack()
            }
          }
        },
        isChangeText: () => {
          isChangeTextCallBack()
        }
      })
    });
    this.dialogController.open();
  }

  // 扫描搜题处理逻辑
  private handleScanSearch = () => {
    this.currentSearchMode = SearchMode.SCAN;

    if (!this.getIsShowDialog()) {
      this.CsjId = this.CsjHmAD?.hmAd?.rewardScan?.csj
      this.CsjIsShow = this.CsjHmAD?.hmAd?.rewardScan?.switchOff
      this.TypeSearch = false
      this.showSelectBankDialog(() => {
        this.appPathStack.pushPathByName(HomeConstants.ROUTER_SEARCH_INTRODUCTION,null)
      }, () => {
        this.appPathStack.pushPathByName(HomeConstants.ROUTER_SEARCH_INTRODUCTION,null)

      })
    } else {

      if (!this.isVip && this.CsjHmAD?.hmAd?.rewardScan?.switchOff && !this.CsjCode) {
        this.CsjId = this.CsjHmAD?.hmAd?.rewardScan?.csj
        this.CsjIsShow = this.CsjHmAD?.hmAd?.rewardScan?.switchOff
        this.TypeSearch = false

        this.AdDialogController?.open()
      } else {
        if (this.bankList.length > 0) {
          this.appPathStack.pushPathByName(HomeConstants.ROUTER_SEARCH_INTRODUCTION,null)

        }
      }
    }
  }
  // 读屏搜题处理逻辑
  private handleScreenReadSearch = async () => {
    // 方案1: 移除已存在的监听器
    emitter.off(EmitterConstants.EM_DATA_TEXT);

    // 注册回调，从ocr拿到文字信息
    emitter.on(EmitterConstants.EM_DATA_TEXT, async (event) => {
      const ocrText: string = event.data!["text"].replace(/\r?\n/g, '')
      const mDataText = MDataTextManage.getInstance().getDataText()

      // 多线程入参 ocrText mDataText pipAnswer 返回参数 resultSearchRes pipAnswer
      if (mDataText && mDataText?.byteLength !== 0) {
        // 调用多线程函数
        this.readSearchTask(ocrText, this.pipAnswer, mDataText)
      }
    })

    this.currentSearchMode = SearchMode.SCREEN_READ;

    if (!this.getIsShowDialog()) {
      this.CsjId = this.CsjHmAD?.hmAd?.rewardRead?.csj
      this.CsjIsShow = this.CsjHmAD?.hmAd?.rewardRead?.switchOff
      this.TypeRead = () => {
        this.startScreenCapture()
      }
      this.TypeSearch = true
      await this.showSelectBankDialog(this.startScreenCapture, this.startScreenCapture)
    } else {
      // 判断是否为vip,不是vip则看广告，是vip则直接跳转
      if (!this.isVip && this.CsjHmAD?.hmAd?.rewardRead?.switchOff && !this.CsjCode) {
        this.CsjId = this.CsjHmAD?.hmAd?.rewardRead?.csj
        this.CsjIsShow = this.CsjHmAD?.hmAd?.rewardRead?.switchOff
        this.TypeSearch = true
        this.TypeRead = () => {
          this.startScreenCapture()
        }
        this.AdDialogController?.open()
      } else {
        if (this.bankList.length > 0) {
          this.startScreenCapture()
        }
      }
    }
  }

  /**
   * 读屏搜题
   * @param qStr 搜索内容
   * @returns 返回结果
   */
  private async readSearchTask(ocrText: string, pipAnswer: string,
    mDataText: SharedArrayBuffer) {
    try {
      // 在这里读取内容
      // 创建任务并在 TaskPool 中执行
      const task: taskpool.Task = new taskpool.Task(readSearchCurrent, getContext(this), ocrText, pipAnswer, mDataText);
      const res = await taskpool.execute(task) as ReadSearchResult;

      if (!res.answer || !res.question) {
        return
      }
      PipManager.getInstance()
        .updatePipUI(new Params({
          answer: res.answer,
          question: res.question
        }));

      this.pipAnswer = res.answer + res.question
    } catch (error) {
      Logger.error(`TaskPool 执行失败: ${error}`);
    }
  }

  /**
   * 点击读屏搜题处理逻辑
   */
  private startScreenCapture = async () => {
    // 读屏搜题
    const screenCaptureManager = ScreenCaptureManager.getInstance(getContext(this) as common.ApplicationContext);

    // 设置回调
    screenCaptureManager.setCallback({
      onPixelMapReady: async (pixelMap: image.PixelMap) => {
        ocrToText.loadImage(pixelMap)
      }
    });

    // 开启读屏幕
    screenCaptureManager.startScreenCapture();
  }

  //获取是否显示弹窗
  private getIsShowDialog(): boolean {
    return this.agreementChecked = preferencesUtils.getBoolean(PreferencesConstants.SP_SELECT_DIALOG_SHOW, false)
  }

  //跳转到练习列表共用的页面，1=题库练习，2=错题练习，3=收藏练习
  private jumpToBankList(type: number) {
    let title = ''
    if (type === 2) {
      title = '错题练习'
    } else if (type === 3) {
      title = '收藏练习'
    } else {
      title = '题库练习'
    }
this.appPathStack.pushPathByName(HomeConstants.ROUTER_BANK_LIST,{
      title,
      type: String(type)
    } as  NavDoubleString)
    // router.pushNamedRoute({
    //   name: HomeConstants.ROUTER_BANK_LIST,
    //   params: {
    //     title,
    //     type: String(type)
    //   }

    // }, router.RouterMode.Single)
  }

  //跳转到我的下载
  private jumpToDownloadResult() {
    router.pushNamedRoute({
      name: HomeConstants.ROUTER_MY_DOWNLOAD
    })
  }

  //跳转到自定义题库
  private jumpToCustomResult() {
    router.pushNamedRoute({
      name: HomeConstants.ROUTER_CUSTOM_QUESTION
    })
  }

  //跳转到H5页面
  private jumpToWeb() {
    router.pushNamedRoute({
      name: HomeConstants.ROUTER_WEB, params: {
        url: HomeConstants.USE_TEACH_URL,
        title: '使用教程'
      }
    })
    onEventObject(HomeMobClickConstants.PLAY_GUIDE_VIDEO)
  }

  //加载 lottie 动画
  private initLottie() {
    // loading.json需要放到lottie包下的rawfile中
    context.resourceManager.getRawFileContent('loading.json', async (err: Error, data: Uint8Array) => {
      if (data === null || data === undefined || data.buffer === undefined) {
        return;
      }
      let lottieStr = await this.resStr.decodeWithStream(new Uint8Array(data.buffer))
      jsonData = JSON.parse(lottieStr);
      this.hasLoadData = true
    })
  }
}

//搜题助手
@Component
struct SearchHelper {
  @State isShow: boolean = false
  @Prop isLoading: boolean = false
  handleClick: () => void = () => {
  }

  @Builder
  payViewBuilder() {
    Column() {
      PayView()
    }
  }

  build() {
    Column() {
      Stack({ alignContent: Alignment.Center }) {
        Image($r('app.media.ic_bg_almighty'))
          .objectFit(ImageFit.Contain)
        Text($r('app.string.almighty_search'))
          .fontSize($r('app.float.font_size_24fp'))
          .fontColor('#7B6008')

      }.onClick(() => this.handleClick())

    }
    .enabled(!this.isLoading)
  }
}

//banner
@Component
struct Banner {
  @Prop swiperData: number[];
  handleClick: (item: number) => void = () => {
  };
  private swiperController: SwiperController = new SwiperController();

  build() {
    Swiper(this.swiperController) {
      ForEach(this.swiperData, (item: number) => {
        Row() {
          Image($r('app.media.bg_banner'))
            .width(Const.FULL_PERCENT)
            .height(Const.FULL_PERCENT)
            .borderRadius($r('app.float.float_16vp'))
            .onClick(() => this.handleClick(item))
        }
        .width(Const.FULL_PERCENT)
        .aspectRatio(SWIPER_ASPECT_RATIO)
        .padding({ right: $r('app.float.float_12vp') })
      }, (item: number) => item + "")
    }
    .width(Const.FULL_PERCENT)
    .displayCount(1)
    .displayMode(SwiperDisplayMode.AUTO_LINEAR)
    .nextMargin(SWIPER_MARGIN)
    .indicator(Indicator.dot()
      .color($r('app.color.c_cccccc'))
      .selectedColor($r('app.color.c_0a59f0')))
    .autoPlay(true)
    .loop(true)
  }
}

@Component
struct SearchList {
  nClick: () => void = () => {
  }
  ScreenReader: () => void = () => {
  }

  async aboutToAppear() {

  }

  // app销毁才会触发
  aboutToDisappear(): void {
    console.log(TAG, "aboutToDisappear")
    PipManager.getInstance().unregisterPipStateChangeListener(); // 解注册画中画生命周期及状态回调
    PipManager.getInstance().setAutoStart(false);
    // 停止屏幕录制
    ScreenCaptureManager?.getInstance().stopScreenCapture();
  }

  build() {
    Row({ space: 20 }) {
      Column() {
        Image($r('app.media.ic_scan_search'))
          .width(82)
          .height(82)
        Text($r('app.string.scan_search'))
          .fontColor($r('app.color.c_8a8a8a'))
          .fontSize(14)
          .margin({
            top: 4
          })

      }
      .onClick(() => this.nClick())

      Column() {
        Image($r('app.media.ic_read_search'))
          .width(82)
          .height(82)
        Text($r('app.string.read_search'))
          .fontColor($r('app.color.c_8a8a8a'))
          .fontSize(14)
          .margin({
            top: 4
          })
      }
      .onClick(async () => {
        // 获取首选戏的题目颜色 选项颜色 悬浮窗颜色
        PipManager.titleColor = preferencesUtils.getString(PreferencesConstants.TITLE_COLOR_SETTING)
        PipManager.optionColor = preferencesUtils.getString(PreferencesConstants.OPTION_COLOR_SETTING)
        PipManager.floatingColor = preferencesUtils.getString(PreferencesConstants.FLOATING_COLOR_SETTING)
        PipManager.fontSize = preferencesUtils.getNumber(PreferencesConstants.FLOATING_TEXT_SIZE)
        // 执行传入的逻辑
        this.ScreenReader()
      })
    }


    .margin({
      left: 15
    })
    .width(Const.FULL_PERCENT)
  }
}

//题库
@Component
struct BankHelper {
  downloadClick: () => void = () => {
  }
  customQuestionClick: () => void = () => {
  }

  build() {
    Column() {
      Row({ space: Const.SPACE_4 }) {
        Image($r('app.media.ic_question_bank'))
          .width(18)
          .height(18)
        Image($r('app.media.ic_question_bank_txt'))
          .height(15)
      }
      .width(Const.FULL_PERCENT)
      .alignItems(VerticalAlign.Top)
      .justifyContent(FlexAlign.Start)

      Row({ space: Const.SPACE_5 }) {
        Image($r('app.media.ic_my_download'))
          .width(90)
          .height(90)
          .onClick(() => this.downloadClick())
        Image($r('app.media.ic_custom_question'))
          .width(90)
          .height(90)
          .onClick(() => this.customQuestionClick())
      }
      .width(Const.FULL_PERCENT)
      .margin(15)
    }
    .width(Const.FULL_PERCENT)
    .margin({ top: $r('app.float.float_10vp') })
  }
}

//练习
@Component
struct ExerciseHelper {
  bankClick: () => void = () => {
  }
  wrongClick: () => void = () => {
  }
  collectionClick: () => void = () => {
  }

  build() {
    Column() {
      Row({ space: Const.SPACE_4 }) {
        Image($r('app.media.ic_exercise'))
          .width(18)
          .height(18)
        Image($r('app.media.ic_exercise_txt'))
          .height(15)
      }
      .alignItems(VerticalAlign.Top)
      .justifyContent(FlexAlign.Start)
      .width(Const.FULL_PERCENT)

      Row({ space: Const.SPACE_5 }) {
        Image($r('app.media.ic_question_bank_exercise'))
          .width(90)
          .height(90)
          .onClick(() => this.bankClick())
        Image($r('app.media.ic_fault_exercise'))
          .width(90)
          .height(90)
          .onClick(() => this.wrongClick())
        Image($r('app.media.ic_collect_exercise'))
          .width(90)
          .height(90)
          .onClick(() => this.collectionClick())
      }
      .width(Const.FULL_PERCENT)
      .margin(15)
    }
    .width(Const.FULL_PERCENT)
  }
}
