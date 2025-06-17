import { CommonConstants as Const, EmitterConstants, Logger, PreferencesConstants, preferencesUtils } from 'utils/Index'
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
import { util } from '@kit.ArkTS'
import { onEventObject } from '@umeng/analytics'
import HomeMobClickConstants from '../Constants/HomeMobClickConstants'
import { window } from '@kit.ArkUI'
import { selectImage } from '../utils/SelectImage'
import { ProgressLoading } from 'utils/src/main/ets/components/ProgressLoading'
import { screenManager } from '../utils/ScreenManager'
import { selectBankDialog } from 'setting/src/main/ets/pages/SelectBankDialog'
import { BankListRes, QuestionRes } from 'db'
import { AdCustomDialog } from '../components/AdCustomDialog'
import { ConfigRes } from 'utils/src/main/ets/model/ConfigRes'
import { HmAdInfo } from 'utils/src/main/ets/model/HmAdInfo'
import { SearchEngine } from 'search'
import { SearchMapManage } from 'search/src/main/ets/manage/SearchMapManage'
import SearchConstants from 'search/src/main/ets/constants/SearchConstants'
import { Params, PipManager } from '../manage/PipManage'
import { CSJStartResult } from 'utils/src/main/ets/model/StartResult'
import { ocrToText } from '../utils/OcrToText'
import { ScreenCaptureManager } from '../manage/ScreenCaptureManager'
import { QuestionUtil } from '../utils/QuestionUtil'
import { Log } from '@tencent/wechat_open_sdk'

import('photo/src/main/ets/pages/SearchResultPage')
import('web/src/main/ets/pages/ChWebPage')
import('./BankListPage')
import('./MyDownloadPage')
import('./CustomQuestionPage')
import('./SearchQuestions')
import('./SearchIntroductionPage')
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
  private imageSource: image.ImageSource | undefined = undefined
  @State chooseImage: PixelMap | undefined = undefined
  @State dataValues: string = ''
  @State homeModel: HomeModel = HomeModel.getInstance()
  @State loadingStatus: LoadingStatus = LoadingStatus.OFF
  @State accounts: Array<HomeBankListRes> = []
  testString: number[] = []
  private mainRenderingSettings: RenderingContextSettings = new RenderingContextSettings(true)
  private controller: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.mainRenderingSettings)
  private animateName = "loading"
  private resStr = util.TextDecoder.create('utf-8', { ignoreBOM: true })
  private animateItem: AnimationItem | null = null
  @State hasLoadData: boolean = false
  @State loading: boolean = false
  @State TopHeight: number = 0
  win: window.Window | null = null
  @State bankList: BankListRes[] = [];
  private dialogController: CustomDialogController | null = null;
  @State agreementChecked: boolean = false;
  @State isVip: number = 0
  @State CsjId: string = ""
  @State CsjIsShow: boolean = false
  @State currentSearchMode: SearchMode | null = null; // 当前搜题模式
  CsjHmAD: ConfigRes = {
    hmAd: new HmAdInfo()
  }
  @StorageProp("isInit")
  AdInit: CSJStartResult = {
    code: 0,
    msg: ""
  }
  private AdDialogController: CustomDialogController | null = null
  // 更新广告弹窗控制器
  private updateAdDialogController = (isCloseFun: () => void) => {
    this.AdDialogController = new CustomDialogController({
      builder: AdCustomDialog({
        isShowDialog: (() => {
          this.AdDialogController?.close()
        }),
        isCloseFun: isCloseFun, // 使用传入的回调
        CsjId: this.CsjId,
        CsjIsShow: this.CsjIsShow
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
  }

  // 打开选择题库对话框的方法
  async showSelectBankDialog(callBack: Function) {
    this.dialogController = new CustomDialogController({
      builder: selectBankDialog({
        bankList: this.bankList,
        agreementChecked: this.agreementChecked,
        onConfirm: (selected: string[]) => {
          this.agreementChecked = this.agreementChecked;
        },
        isVipDialog: () => {
          this.dialogController?.close()
          //弹窗
          if (!this.isVip && this.bankList.length > 0 && !!this.CsjHmAD?.hmAd?.rewardScan?.switchOff &&
            !this.AdInit?.code) {
            this.AdDialogController?.open()
          } else {
            if (this.bankList.length > 0) {
              callBack()
            }
          }
        },
        isChangeText: () => {
          router.pushNamedRoute({
            name: HomeConstants.ROUTER_SEARCH_INTRODUCTION,
          })
        }
      })

    });
    this.dialogController.open();
  }

  // 扫描搜题处理逻辑
  private handleScanSearch = () => {
    this.currentSearchMode = SearchMode.SCAN;

    if (!this.getIsShowDialog()) {
      this.showSelectBankDialog(() => {
        router.pushNamedRoute({
          name: HomeConstants.ROUTER_SEARCH_INTRODUCTION,
        })
      })
    } else {
      // 判断是否为vip,不是vip则看广告，是vip则直接跳转
      if (!this.isVip && this.CsjHmAD?.hmAd?.rewardScan?.switchOff && !this.AdInit?.code) {
        this.CsjId = this.CsjHmAD?.hmAd?.rewardScan?.csj
        this.CsjIsShow = this.CsjHmAD?.hmAd?.rewardScan?.switchOff
        this.AdDialogController?.open()
      } else {
        if (this.bankList.length > 0) {
          // 关闭广告弹窗执行回调事件
          this.updateAdDialogController(() => {
            // 跳转到扫描搜题页面
            router.pushNamedRoute({
              name: HomeConstants.ROUTER_SEARCH_INTRODUCTION,
            })
          })
        }
      }
    }
  }

  private async readSearch() {
    // 读屏搜题
    const screenCaptureManager = ScreenCaptureManager.getInstance(getContext(this) as common.ApplicationContext);

    // 设置回调
    screenCaptureManager?.setCallback({
      onPixelMapReady: async (pixelMap: image.PixelMap) => {
        console.log(TAG, '收到截图');
        ocrToText.loadImage(pixelMap)
      }
    });

    // 开启读屏幕
    screenCaptureManager?.startScreenCapture();

    await PipManager.getInstance().init(getContext(this));
    // 创建画中画控制器
    PipManager.getInstance().setAutoStart(true);
    PipManager.getInstance().startPip();
    PipManager.getInstance().stopCallBack = () => {
      // 设置回调，关闭画中画时停止读屏幕
      console.log(TAG, '画中画关闭')
      screenCaptureManager?.stopScreenCapture();
    };
  }

  // 读屏搜题处理逻辑
  private handleScreenReadSearch = async () => {
    this.currentSearchMode = SearchMode.SCREEN_READ;

    if (!this.getIsShowDialog()) {
      this.showSelectBankDialog(this.readSearch)
    } else {
      // 判断是否为vip,不是vip则看广告，是vip则直接跳转
      if (!this.isVip && this.CsjHmAD?.hmAd?.rewardScan?.switchOff && !this.AdInit?.code) {
        this.CsjId = this.CsjHmAD?.hmAd?.rewardScan?.csj
        this.CsjIsShow = this.CsjHmAD?.hmAd?.rewardScan?.switchOff
        this.AdDialogController?.open()
      } else {
        if (this.bankList.length > 0) {
          this.readSearch()
        }
      }
    }
  }

  //获取是否显示弹窗
  getIsShowDialog(): boolean {
    return this.agreementChecked = preferencesUtils.getBoolean(PreferencesConstants.SP_SELECT_DIALOG_SHOW, false)
  }

  aboutToAppear(): void {
    this.isVip = preferencesUtils.getNumber(PreferencesConstants.SP_IS_VIP)
    this.CsjHmAD = preferencesUtils.getGenerics(PreferencesConstants.CSJ_AD_PARAMS);
    this.loadResource()
    emitter.on(EmitterConstants.EM_REFRESH_HOME, () => {
      this.loadResource()
    })
  }

  async loadResource() {
    this.getIsShowDialog()
    const banks = await this.homeModel.getBankList();
    this.bankList = banks
  }

  aboutToDisappear(): void {
    lottie.destroy()
    screenManager.exitFull(getContext())
    this.TopHeight = 0
  }

  build() {
    RelativeContainer() {


      Column() {
        // if (this.hasLoadData && this.loadingStatus === LoadingStatus.LOADING) {
        //   Flex({ direction: FlexDirection.Column, alignItems: ItemAlign.Center, justifyContent: FlexAlign.Center }) {
        //     Canvas(this.controller)
        //       .width('30%')
        //       .height('20%')
        //       .onReady(() => {
        //         this.animateItem = lottie.loadAnimation({
        //           container: this.controller,
        //           renderer: 'canvas',
        //           loop: true,
        //           autoplay: true,
        //           context: context,
        //           name: this.animateName,
        //           animationData: jsonData,
        //         })
        //       })
        //   }
        //
        // } else if (this.loadingStatus === LoadingStatus.SUCCESS) {


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
              handleClick: async () => {
                // this.selectImage()
                this.loading = true

                selectImage.selectImg().then(() => {
                  this.loading = false
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

    router.pushNamedRoute({
      name: HomeConstants.ROUTER_BANK_LIST,
      params: {
        title,
        type: String(type)
      }
    }, router.RouterMode.Single)
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

  // private async ocrToText() {
  //   if (!this.chooseImage) {
  //     return
  //   }
  //   // 调用文本识别接口
  //   let visionInfo: textRecognition.VisionInfo = {
  //     pixelMap: this.chooseImage
  //   };
  //   let textConfiguration: textRecognition.TextRecognitionConfiguration = {
  //     isDirectionDetectionSupported: false
  //   };
  //   textRecognition.recognizeText(visionInfo, textConfiguration,
  //     (error: BusinessError, data: textRecognition.TextRecognitionResult) => {
  //       // 识别成功，获取对应的结果
  //       if (error.code == 0) {
  //         let recognitionString = data.toString()
  //         hilog.info(0x0000, 'OCRDemo', `Succeeded in recognizing text：${recognitionString}`)
  //         // 将结果更新到Text中显示
  //         this.dataValues = data.value
  //         this.jumpToSearchResult(data.value)
  //       }
  //       if (this.chooseImage && this.imageSource) {
  //         this.chooseImage.release()
  //         this.imageSource.release()
  //       }
  //     })
  // }
  //
  // private async selectImage() {
  //   let uri = await this.openPhoto()
  //   if (uri === undefined) {
  //     hilog.error(0x0000, 'OCRDemo', "Failed to get uri.")
  //     return
  //   }
  //   this.loadImage(uri)
  // }

  // private openPhoto(): Promise<string> {
  //   return new Promise<string>((resolve, reject) => {
  //     let photoPicker = new picker.PhotoViewPicker()
  //     photoPicker.select({
  //       MIMEType: picker.PhotoViewMIMETypes.IMAGE_TYPE, maxSelectNumber: 1
  //     }).then((res: picker.PhotoSelectResult) => {
  //       resolve(res.photoUris[0])
  //     }).catch((err: BusinessError) => {
  //
  //       hilog.error(0x0000, 'OCRDemo', `Failed to get photo image uri. code：${err.code}，message：${err.message}`)
  //       resolve('')
  //     })
  //   })
  // }

  // private loadImage(name: string) {
  //   setTimeout(async () => {
  //     let fileSource = await fileIo.open(name, fileIo.OpenMode.READ_ONLY)
  //     this.imageSource = image.createImageSource(fileSource.fd)
  //     this.chooseImage = await this.imageSource.createPixelMap()
  //     this.ocrToText()
  //   }, 100)
  // }

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
  @State pipAnswer: string = ''

  async aboutToAppear() {
    // 判断从哪个文件里取 mDataText 以及 mDataSize
    let mDataText: SharedArrayBuffer | null = null

    let isAllNum = preferencesUtils.getString(PreferencesConstants.SP_QUESTION_BANK_, '1')
    if (isAllNum === '1') {
      mDataText =
        await SearchMapManage.getInstance()
          .loadSharedArrayBufferFromFile(getContext(this), SearchConstants.SEARCH_FILE_ALL)
    } else {
      mDataText =
        await SearchMapManage.getInstance()
          .loadSharedArrayBufferFromFile(getContext(this), SearchConstants.SEARCH_FILE_SOME)
    }
    // 注册回调，从ocr拿到文字信息
    emitter.on("dataText", async (event) => {
      const ocrText: string = event.data!["text"].replace(/\r?\n/g, '')

      console.log(TAG, "ocrText = " + ocrText)
      // 进行搜索，然后返回给画中画
      if (mDataText && mDataText?.byteLength !== 0) {
        // 过滤掉画中画的text
        const filterData = QuestionUtil.analyzeTextMatch(ocrText, this.pipAnswer, 0.7);
        // console.log(TAG, "ocrText = " + ocrText)
        // console.log(TAG, "data.remainingText = " + data.remainingText)
        // console.log(TAG, "this.answerAndQuestion = " + this.answerAndQuestion)
        this.searchResult(filterData.remainingText, mDataText)
      }
    })
  }

  // app销毁才会触发
  aboutToDisappear(): void {
    console.log(TAG, "aboutToDisappear")
    PipManager.getInstance().unregisterPipStateChangeListener(); // 解注册画中画生命周期及状态回调
    PipManager.getInstance().setAutoStart(false);
    // 停止屏幕录制
    ScreenCaptureManager?.getInstance().stopScreenCapture();
  }

  private async searchResult(ocrText: string, mDataText: SharedArrayBuffer) {
    const resultSearchRes = await SearchEngine.getInstance().queryTextWithIndexInThread(ocrText, mDataText)

    // 将结果返回给画中画
    if (resultSearchRes?.answer && resultSearchRes?.question) {
      let answer = QuestionUtil.filterOptionsByAnswer(resultSearchRes)
      PipManager.getInstance()
        .updatePipUI(new Params({
          answer: answer,
          question: resultSearchRes?.question
        }));

      this.pipAnswer = answer + resultSearchRes.question
    }
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
        // 弹出广告
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
