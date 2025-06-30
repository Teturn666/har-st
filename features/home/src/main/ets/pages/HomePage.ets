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
import HomeConstants from '../Constants/HomeConstants'
import common from '@ohos.app.ability.common'
import router from '@ohos.router'
import { PayView } from 'view/Index'
import lottie from '@ohos/lottie'
import { taskpool } from '@kit.ArkTS'
import { onEventObject } from '@umeng/analytics'
import HomeMobClickConstants from '../Constants/HomeMobClickConstants'
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

const TAG = '[HomePage]'

// 定义UI状态接口
interface UIState {
  loading: boolean;
  topHeight: number;
}

// 定义业务状态接口
interface BusinessState {
  bankList: BankListRes[];
  agreementChecked: boolean;
  isVip: number;
  pipAnswer: string;
}

// 定义广告状态接口
interface AdState {
  csjCode: number;
  csjId: string;
  csjIsShow: boolean;
  typeSearch: boolean;
}

@Builder
export function HomePageBuilder() {
  HomePage()
}

@Entry()
@Component
export struct HomePage {
  // 合并UI相关状态
  @State uiState: UIState = {
    loading: false,
    topHeight: 0
  }
  // 合并业务逻辑相关状态
  @State businessState: BusinessState = {
    bankList: [],
    agreementChecked: false,
    isVip: 0,
    pipAnswer: '暂未搜索到该题'
  }
  // 合并广告相关状态
  @State adState: AdState = {
    csjCode: 0,
    csjId: "",
    csjIsShow: false,
    typeSearch: false
  }
  // 保留必要的单独状态
  private homeModel: HomeModel = HomeModel.getInstance()
  private dialogController: CustomDialogController | null = null;
  private executeScreenReading: () => void = () => {
  }
  private csjHmAD: ConfigRes = { hmAd: new HmAdInfo() }
  // 事件监听器管理
  private eventListeners: Map<string, (event: ESObject) => void> = new Map()
  AdDialogController = new CustomDialogController({
    builder: AdCustomDialog({
      isShowDialog: (() => {
        this.AdDialogController?.close()
      }),
      readSearch: () => this.executeScreenReading(),
      CsjId: this.adState.csjId,
      CsjIsShow: this.adState.csjIsShow,
      TypeSearch: this.adState.typeSearch
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

  /**
   * 页面初始化生命周期方法
   * 异步加载页面所需的基础数据和配置
   */
  async aboutToAppear() {
    try {
      // 更新状态
      this.businessState.isVip = preferencesUtils.getNumber(PreferencesConstants.SP_IS_VIP);
      this.csjHmAD = preferencesUtils.getGenerics(PreferencesConstants.CSJ_AD_PARAMS);
      this.adState.csjCode = preferencesUtils.getNumber(PreferencesConstants.CSJ_AD_CODE);

      // 注册事件监听器
      this.registerAllEventListeners();

      // 加载资源
      await this.loadPageResources();

      // 异步加载共享数据
      this.preloadSharedSearchData();
    } catch (error) {
      Logger.error(`HomePage initialization failed: ${error}`);
    }
  }

  /**
   * 注册页面所需的所有事件监听器
   * 统一管理事件监听器的注册，便于维护和清理
   */
  private registerAllEventListeners() {
    // 首页刷新事件
    const handleHomeRefresh = () => {
      this.loadPageResources();
    };
    this.eventListeners.set(EmitterConstants.EM_REFRESH_HOME, handleHomeRefresh);
    emitter.on(EmitterConstants.EM_REFRESH_HOME, handleHomeRefresh);
  }

  /**
   * 清理所有注册的事件监听器
   * 防止内存泄漏，在页面销毁时调用
   */
  private unregisterAllEventListeners() {
    this.eventListeners.forEach((handler, eventType) => {
      emitter.off(eventType, handler);
    });
    this.eventListeners.clear();
  }

  /**
   * 预加载搜索相关的共享数据
   * 根据用户选择的题库范围，异步加载对应的搜索数据到内存
   */
  private async preloadSharedSearchData() {
    try {
      let mdataText: SharedArrayBuffer | null = null;
      if (GetAllSelectedUtil.isUserBankAllSelected()) {
        mdataText = await SearchMapManage.getInstance()
          .loadSharedArrayBufferFromFile(getContext(this), SearchConstants.SEARCH_FILE_ALL);
      } else {
        mdataText = await SearchMapManage.getInstance()
          .loadSharedArrayBufferFromFile(getContext(this), SearchConstants.SEARCH_FILE_SOME);
      }
      MDataTextManage.getInstance().saveDataText(mdataText);
    } catch (error) {
      Logger.error(`Failed to load shared data: ${error}`);
    }
  }

  /**
   * 页面销毁生命周期方法
   * 清理资源和状态，防止内存泄漏
   */
  aboutToDisappear(): void {
    // 完善资源清理
    try {
      // 清理事件监听器
      this.unregisterAllEventListeners();

      // 清理其他资源
      lottie.destroy();
      screenManager.exitFull(getContext());

      // 重置状态
      this.uiState.topHeight = 0;
    } catch (error) {
      Logger.error(`HomePage cleanup failed: ${error}`);
    }
  }

  /**
   * 拦截系统返回键
   * @returns 返回true表示拦截返回操作
   */
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
                this.navigateToWebTutorial()
              }
            })
          }

          ListItem() {
            SearchList({
              onScanSearchClick: this.handleScanSearchClick,
              onScreenReadSearchClick: this.handleScreenReadSearchClick
            })
          }

          ListItem() {
            SearchHelper({
              isLoading: this.uiState.loading,
              handleClick: () => {
                accessManager.CheckCamera(['ohos.permission.CAMERA',], () => {
                  router.pushNamedRoute({
                    name: HomeConstants.ROUTER_PHOTO_SEARCH,
                  })
                })
              }
            })
          }

          ListItem() {
            BankHelper({
              onDownloadClick: async () => {
                this.navigateToMyDownload()
              },
              onCustomQuestionClick: async () => {
                this.navigateToCustomQuestion()
              }
            })
          }

          ListItem() {
            ExerciseHelper({
              onBankClick: async () => {
                this.navigateToBankList(1)
              },
              onWrongClick: async () => {
                this.navigateToBankList(2)
              },
              onCollectionClick: async () => {
                this.navigateToBankList(3)
              },
            })
          }
        }
        .scrollBar(BarState.Off)
        .height(Const.FULL_PERCENT)
        .width(Const.FULL_PERCENT)
        .padding({
          left: $r('app.float.float_15vp'),
          right: $r('app.float.float_15vp')
        })
      }

      Column() {
        if (this.uiState.loading) {
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
      top: this.uiState.topHeight
    })
  }

  /**
   * 加载页面所需的资源数据
   * 包括题库列表等基础数据的获取
   */
  private async loadPageResources() {
    try {
      this.checkShouldShowSelectDialog();
      const banks = await this.homeModel.getBankList();
      this.businessState.bankList = banks;
    } catch (error) {
      Logger.error(`Failed to load resources: ${error}`);
    }
  }

  /**
   * 显示题库选择对话框
   * @param onVipDialogCallback VIP相关操作的回调函数
   * @param onTextChangeCallback 文本变化的回调函数
   */
  private async showBankSelectionDialog(onVipDialogCallback: Function, onTextChangeCallback: Function) {
    this.dialogController = new CustomDialogController({
      builder: selectBankDialog({
        agreementChecked: this.businessState.agreementChecked,
        onConfirm: (selected: string[]) => {
          this.businessState.agreementChecked = this.businessState.agreementChecked;
        },
        isVipDialog: () => {
          this.dialogController?.close()
          if (!this.businessState.isVip && this.businessState.bankList.length > 0 &&
          this.adState.csjIsShow && !this.adState.csjCode) {
            this.AdDialogController?.open()
          } else {
            if (this.businessState.bankList.length > 0) {
              onVipDialogCallback()
            }
          }
        },
        isChangeText: () => {
          onTextChangeCallback()
        }
      })
    });
    this.dialogController.open();
  }

  /**
   * 处理扫描搜题点击事件
   * 根据用户VIP状态和广告配置决定是否显示广告或直接跳转
   */
  private handleScanSearchClick = () => {
    if (!this.checkShouldShowSelectDialog()) {
      this.adState.csjId = this.csjHmAD?.hmAd?.rewardScan?.csj
      this.adState.csjIsShow = this.csjHmAD?.hmAd?.rewardScan?.switchOff
      this.adState.typeSearch = false
      this.showBankSelectionDialog(() => {
        router.pushNamedRoute({
          name: HomeConstants.ROUTER_SEARCH_INTRODUCTION,
        })
      }, () => {
        router.pushNamedRoute({
          name: HomeConstants.ROUTER_SEARCH_INTRODUCTION,
        })
      })
    } else {
      if (!this.businessState.isVip && this.csjHmAD?.hmAd?.rewardScan?.switchOff && !this.adState.csjCode) {
        this.adState.csjId = this.csjHmAD?.hmAd?.rewardScan?.csj
        this.adState.csjIsShow = this.csjHmAD?.hmAd?.rewardScan?.switchOff
        this.adState.typeSearch = false
        this.AdDialogController?.open()
      } else {
        if (this.businessState.bankList.length > 0) {
          router.pushNamedRoute({
            name: HomeConstants.ROUTER_SEARCH_INTRODUCTION,
          })
        }
      }
    }
  }
  /**
   * 处理读屏搜题点击事件
   * 设置OCR文本监听器，并根据用户状态决定后续操作流程
   */
  private handleScreenReadSearchClick = async () => {
    // 清理已存在的数据文本监听器
    const existingHandler = this.eventListeners.get(EmitterConstants.EM_DATA_TEXT);
    if (existingHandler) {
      emitter.off(EmitterConstants.EM_DATA_TEXT, existingHandler);
    }

    // 注册新的数据文本监听器
    const handleOcrTextData = async (event: ESObject) => {
      const ocrText: string = event.data!["text"].replace(/\r?\n/g, '');
      const mDataText = MDataTextManage.getInstance().getDataText();

      if (mDataText && mDataText?.byteLength !== 0) {
        this.executeSearchTask(ocrText, this.businessState.pipAnswer, mDataText);
      }
    };

    this.eventListeners.set(EmitterConstants.EM_DATA_TEXT, handleOcrTextData);
    emitter.on(EmitterConstants.EM_DATA_TEXT, handleOcrTextData);

    if (!this.checkShouldShowSelectDialog()) {
      this.adState.csjId = this.csjHmAD?.hmAd?.rewardRead?.csj
      this.adState.csjIsShow = this.csjHmAD?.hmAd?.rewardRead?.switchOff
      this.executeScreenReading = () => {
        this.initializeScreenCapture()
      }
      this.adState.typeSearch = true
      await this.showBankSelectionDialog(this.initializeScreenCapture, this.initializeScreenCapture)
    } else {
      if (!this.businessState.isVip && this.csjHmAD?.hmAd?.rewardRead?.switchOff && !this.adState.csjCode) {
        this.adState.csjId = this.csjHmAD?.hmAd?.rewardRead?.csj
        this.adState.csjIsShow = this.csjHmAD?.hmAd?.rewardRead?.switchOff
        this.adState.typeSearch = true
        this.executeScreenReading = () => {
          this.initializeScreenCapture()
        }
        this.AdDialogController?.open()
      } else {
        if (this.businessState.bankList.length > 0) {
          this.initializeScreenCapture()
        }
      }
    }
  }

  /**
   * 执行读屏搜题任务
   * 使用TaskPool在后台线程执行搜索任务，避免阻塞UI线程
   * @param ocrText OCR识别的文本内容
   * @param pipAnswer 悬浮窗答案内容
   * @param mDataText 搜索数据的共享内存缓冲区
   */
  private async executeSearchTask(ocrText: string, pipAnswer: string, mDataText: SharedArrayBuffer) {
    try {
      const task: taskpool.Task = new taskpool.Task(readSearchCurrent, getContext(this), ocrText, pipAnswer, mDataText);
      const res = await taskpool.execute(task) as ReadSearchResult;

      if (!res.answer || !res.question) {
        return
      }

      PipManager.getInstance().updatePipUI(new Params({
        answer: res.answer,
        question: res.question
      }));

      this.businessState.pipAnswer = res.answer + res.question
    } catch (error) {
      Logger.error(`TaskPool 执行失败: ${error}`);
    }
  }

  /**
   * 初始化屏幕截图功能
   * 设置截图回调并启动屏幕捕获
   */
  private initializeScreenCapture = async () => {
    const screenCaptureManager = ScreenCaptureManager.getInstance(getContext(this) as common.ApplicationContext);

    screenCaptureManager.setCallback({
      onPixelMapReady: async (pixelMap: image.PixelMap) => {
        ocrToText.loadImage(pixelMap)
      }
    });

    screenCaptureManager.startScreenCapture();
  }

  /**
   * 检查是否需要显示选择对话框
   * @returns 返回是否应该显示对话框的布尔值
   */
  private checkShouldShowSelectDialog(): boolean {
    return this.businessState.agreementChecked =
      preferencesUtils.getBoolean(PreferencesConstants.SP_SELECT_DIALOG_SHOW, false)
  }

  /**
   * 跳转到题库列表页面
   * @param type 练习类型 1=题库练习，2=错题练习，3=收藏练习
   */
  private navigateToBankList(type: number) {
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

  /**
   * 跳转到我的下载页面
   */
  private navigateToMyDownload() {
    router.pushNamedRoute({
      name: HomeConstants.ROUTER_MY_DOWNLOAD
    })
  }

  /**
   * 跳转到自定义题库页面
   */
  private navigateToCustomQuestion() {
    router.pushNamedRoute({
      name: HomeConstants.ROUTER_CUSTOM_QUESTION
    })
  }

  /**
   * 跳转到使用教程网页
   */
  private navigateToWebTutorial() {
    router.pushNamedRoute({
      name: HomeConstants.ROUTER_WEB, params: {
        url: HomeConstants.USE_TEACH_URL,
        title: '使用教程'
      }
    })
    onEventObject(HomeMobClickConstants.PLAY_GUIDE_VIDEO)
  }
}

/**
 * 搜题助手组件
 * 提供万能搜题功能的入口
 */
@Component
struct SearchHelper {
  @State isShow: boolean = false
  @Prop isLoading: boolean = false
  handleClick: () => void = () => {
  }

  @Builder
  buildPayView() {
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

/**
 * 轮播图组件
 * 展示首页横幅广告或推广内容
 */
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

/**
 * 搜索功能列表组件
 * 提供扫描搜题和读屏搜题两个主要功能入口
 */
@Component
struct SearchList {
  onScanSearchClick: () => void = () => {
  }
  onScreenReadSearchClick: () => void = () => {
  }

  async aboutToAppear() {
  }

  /**
   * 组件销毁时的清理工作
   * 清理PIP管理器和屏幕捕获相关资源
   */
  aboutToDisappear(): void {
    console.log(TAG, "aboutToDisappear")
    PipManager.getInstance().unregisterPipStateChangeListener();
    PipManager.getInstance().setAutoStart(false);
    ScreenCaptureManager.stopScreenCapture();
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
          .margin({ top: 4 })
      }
      .onClick(() => this.onScanSearchClick())

      Column() {
        Image($r('app.media.ic_read_search'))
          .width(82)
          .height(82)
        Text($r('app.string.read_search'))
          .fontColor($r('app.color.c_8a8a8a'))
          .fontSize(14)
          .margin({ top: 4 })
      }
      .onClick(async () => {
        PipManager.getInstance().setPipManagerStyles()
        this.onScreenReadSearchClick()
      })
    }
    .margin({ left: 15 })
    .width(Const.FULL_PERCENT)
  }
}

/**
 * 题库助手组件
 * 提供下载和自定义题库功能入口
 */
@Component
struct BankHelper {
  onDownloadClick: () => void = () => {
  }
  onCustomQuestionClick: () => void = () => {
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
          .onClick(() => this.onDownloadClick())
        Image($r('app.media.ic_custom_question'))
          .width(90)
          .height(90)
          .onClick(() => this.onCustomQuestionClick())
      }
      .width(Const.FULL_PERCENT)
      .margin(15)
    }
    .width(Const.FULL_PERCENT)
    .margin({ top: $r('app.float.float_10vp') })
  }
}

/**
 * 练习助手组件
 * 提供题库练习、错题练习、收藏练习三种练习模式入口
 */
@Component
struct ExerciseHelper {
  onBankClick: () => void = () => {
  }
  onWrongClick: () => void = () => {
  }
  onCollectionClick: () => void = () => {
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
          .onClick(() => this.onBankClick())
        Image($r('app.media.ic_fault_exercise'))
          .width(90)
          .height(90)
          .onClick(() => this.onWrongClick())
        Image($r('app.media.ic_collect_exercise'))
          .width(90)
          .height(90)
          .onClick(() => this.onCollectionClick())
      }
      .width(Const.FULL_PERCENT)
      .margin(15)
    }
    .width(Const.FULL_PERCENT)
  }
}