import { CommonConstants, Logger } from '@ohos/utils/Index'
import { hilog } from '@kit.PerformanceAnalysisKit'
import { BusinessError } from '@kit.BasicServicesKit'
import { fileIo, picker } from '@kit.CoreFileKit'
import { image } from '@kit.ImageKit'
import { textRecognition } from '@kit.CoreVisionKit'
import { HomeModel } from '../model/HomeModel'
import { HomeBankListRes } from '../model/HomeBankListRes'
import { LoadingStatus } from '@ohos/utils'
import HomeConstants from '../Constants/HomeConstants'
import common from '@ohos.app.ability.common'
import router from '@ohos.router'
import { PayView } from '@ohos/view/Index'
import lottie, { AnimationItem } from '@ohos/lottie'
import { util } from '@kit.ArkTS'

import('@ohos/photo/src/main/ets/pages/SearchResultPage')
import('@ohos/web/src/main/ets/pages/ChWebPage')

const SWIPER_ASPECT_RATIO = 2.4
const SWIPER_MARGIN = 220
let arr: number[] = [1, 2, 3]
const context = (getContext(this) as common.UIAbilityContext)

const TAG = '[HomePage]'

let jsonData = null

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

  aboutToAppear(): void {
    this.initLottie()
    this.homeModel.createTable()
    this.homeModel.createSp(context)
    this.loadResources()
  }

  aboutToDisappear(): void {
    lottie.destroy()
  }

  build() {
    Column() {
      if (this.hasLoadData && this.loadingStatus === LoadingStatus.LOADING) {
        Flex({ direction: FlexDirection.Column, alignItems: ItemAlign.Center, justifyContent: FlexAlign.Center }) {
          Canvas(this.controller)
            .width('30%')
            .height('20%')
            .onReady(() => {
              this.animateItem = lottie.loadAnimation({
                container: this.controller,
                renderer: 'canvas',
                loop: true,
                autoplay: true,
                context: context,
                name: this.animateName,
                animationData: jsonData,
              })
            })
        }

      } else if (this.loadingStatus === LoadingStatus.SUCCESS) {
        List({ space: CommonConstants.SPACE_16 }) {
          ListItem() {
            Banner({
              swiperData: arr,
              handleClick: (item: number) => {
                hilog.info(0x0001, "testTag", "---->" + item);
              }
            })
          }

          ListItem() {
            Notice()
          }

          ListItem() {
            SearchHelper({
              handleClick: async () => {
                this.selectImage()
              }
            })
          }

          ListItem() {
            UseHelper()
          }

          ListItem() {
            OnlineExercise()
          }

          //测试显示ocr的文本
          ListItem() {
            Text(this.dataValues)
              .fontSize($r('app.float.font_size_10fp'))
              .fontColor($r('app.color.c_black'))
          }
        }
        .scrollBar(BarState.Off)
      } else if (this.loadingStatus === LoadingStatus.FAILED) {
        Text('数据插入失败').fontSize(18)
      }
    }
    .height(CommonConstants.FULL_PERCENT)
    .width(CommonConstants.FULL_PERCENT)
    .padding({
      left: $r('app.float.float_15vp'), right: $r('app.float.float_15vp')
    })
  }

  async loadResources(): Promise<void> {
    this.loadingStatus = LoadingStatus.LOADING
    let queryFinish = await this.homeModel.queryFirstData()
    if (queryFinish) {
      this.loadingStatus = LoadingStatus.SUCCESS
    } else {
      this.loadingStatus = LoadingStatus.FAILED
    }
  }

  //跳转到搜索结果页
  private jumpToSearchResult(ocrTxt: string) {
    router.pushNamedRoute({
      name: HomeConstants.ROUTER_SEARCH_RESULT, params: {
        ocrTxt: ocrTxt
      }
    })
  }

  private async ocrToText() {
    if (!this.chooseImage) {
      return
    }
    // 调用文本识别接口
    let visionInfo: textRecognition.VisionInfo = {
      pixelMap: this.chooseImage
    };
    let textConfiguration: textRecognition.TextRecognitionConfiguration = {
      isDirectionDetectionSupported: false
    };
    textRecognition.recognizeText(visionInfo, textConfiguration,
      (error: BusinessError, data: textRecognition.TextRecognitionResult) => {
        // 识别成功，获取对应的结果
        if (error.code == 0) {
          let recognitionString = data.toString()
          hilog.info(0x0000, 'OCRDemo', `Succeeded in recognizing text：${recognitionString}`)
          // 将结果更新到Text中显示
          this.dataValues = data.value
          this.jumpToSearchResult(data.value)
        }
        if (this.chooseImage && this.imageSource) {
          this.chooseImage.release()
          this.imageSource.release()
        }
      })
  }

  private async selectImage() {
    let uri = await this.openPhoto()
    if (uri === undefined) {
      hilog.error(0x0000, 'OCRDemo', "Failed to get uri.")
      return
    }
    this.loadImage(uri)
  }

  private openPhoto(): Promise<string> {
    return new Promise<string>((resolve, reject) => {
      let photoPicker = new picker.PhotoViewPicker()
      photoPicker.select({
        MIMEType: picker.PhotoViewMIMETypes.IMAGE_TYPE, maxSelectNumber: 1
      }).then((res: picker.PhotoSelectResult) => {
        resolve(res.photoUris[0])
      }).catch((err: BusinessError) => {

        hilog.error(0x0000, 'OCRDemo', `Failed to get photo image uri. code：${err.code}，message：${err.message}`)
        resolve('')
      })
    })
  }

  private loadImage(name: string) {
    setTimeout(async () => {
      let fileSource = await fileIo.open(name, fileIo.OpenMode.READ_ONLY)
      this.imageSource = image.createImageSource(fileSource.fd)
      this.chooseImage = await this.imageSource.createPixelMap()
      this.ocrToText()
    }, 100)
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

//使用帮助
@Component
struct UseHelper {
  @State isShow: boolean = false

  @Builder
  payViewBuilder() {
    Column() {
      PayView()
    }
  }

  build() {
    Column() {
      TitleText({
        leftImage: $r('app.media.ic_home_help'),
        text: $r('app.string.use_helper')
      }).margin({ top: $r('app.float.float_15vp') })
      Flex({
        direction: FlexDirection.Row,
        wrap: FlexWrap.NoWrap,
        justifyContent: FlexAlign.SpaceAround,
        alignItems: ItemAlign.Center,
      }) {
        HelperBtText({ title: $r('app.string.pay_times'), content: $r('app.string.reside_times') })
          .onClick(() => {
            //TODO 充值次数弹窗
            this.isShow = true
          })
          .bindSheet($$this.isShow, this.payViewBuilder(), {
            height: SheetSize.FIT_CONTENT,
            blurStyle: BlurStyle.Thick,
            showClose: false,
            preferType: SheetType.BOTTOM,
            shouldDismiss: ((sheetDismiss: SheetDismiss) => {
              sheetDismiss.dismiss()
            })
          })

        HelperBtText({ title: $r('app.string.search_teach') }).onClick(() => {
          this.jumpToWeb()
        })
      }
    }.alignItems(HorizontalAlign.Start)
  }

  //跳转到H5页面
  private jumpToWeb() {
    router.pushNamedRoute({
      name: HomeConstants.ROUTER_WEB, params: {
        url: HomeConstants.USE_TEACH_URL,
        title: '使用教程'
      }
    })
  }
}

//在线练习
@Component
struct OnlineExercise {
  build() {
    Column() {
      Row() {
        TitleText({
          leftImage: $r('app.media.ic_home_exercise'),
          text: $r('app.string.online_exercise')
        })
        TitleText({
          text: $r('app.string.type_car'),
          textSize: $r('app.float.font_size_12fp'),
          textColor: $r('app.color.c_1f59a8'),
          leftImage: $r('app.media.ic_car'),
          leftImageSize: $r('app.float.float_18vp'),
          leftVisible: Visibility.Visible,
          rightVisible: Visibility.Visible
        })
          .backgroundColor($r('app.color.c_f2f7ff'))
          .borderRadius(CommonConstants.RADIUS_8)
          .padding(CommonConstants.PADDING_8)
      }
      .width(CommonConstants.FULL_PERCENT)
      .justifyContent(FlexAlign.SpaceBetween)
      .margin({ top: $r('app.float.float_15vp') })

      Flex({
        direction: FlexDirection.Row,
        wrap: FlexWrap.NoWrap,
        justifyContent: FlexAlign.SpaceAround,
        alignItems: ItemAlign.Center,
      }) {
        PicTopText({ text: $r('app.string.order_exercise'), img: $r('app.media.ic_in_order_exercise') })
        PicTopText({ text: $r('app.string.mock_exam'), img: $r('app.media.ic_exam') })
        PicTopText({ text: $r('app.string.wrong_review'), img: $r('app.media.ic_show_error') })
        PicTopText({ text: $r('app.string.collection_exercise'), img: $r('app.media.ic_collect_exercise') })
      }.margin({ top: $r('app.float.float_15vp') })
    }
  }
}

//搜题助手
@Component
struct SearchHelper {
  @State isShow: boolean = false
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
      Row() {
        TitleText({
          leftImage: $r('app.media.ic_home_search'),
          text: $r('app.string.search_helper')
        })
        TitleText({
          text: $r('app.string.pay_times'),
          textSize: $r('app.float.font_size_12fp'),
          textColor: $r('app.color.c_1f59a8'),
          leftVisible: Visibility.None,
          rightVisible: Visibility.Visible
        }).onClick(() => {
          //TODO 充值次数弹窗
          this.isShow = true
        })
          .bindSheet($$this.isShow, this.payViewBuilder(), {
            height: SheetSize.FIT_CONTENT,
            blurStyle: BlurStyle.Thick,
            showClose: false,
            preferType: SheetType.BOTTOM,
            shouldDismiss: ((sheetDismiss: SheetDismiss) => {
              sheetDismiss.dismiss()
            })
          })
      }
      .width(CommonConstants.FULL_PERCENT)
      .justifyContent(FlexAlign.SpaceBetween)
      .margin({ top: $r('app.float.float_15vp') })

      Stack({ alignContent: Alignment.TopStart }) {
        Image($r('app.media.ic_search_by_take_pic'))
          .objectFit(ImageFit.Contain)
          .size({ width: 200, height: 60 })
        Image($r('app.media.ic_times_bg'))
          .objectFit(ImageFit.Contain)
          .size({ width: 60, height: 40 })
          .margin({ left: 20, top: -12 })
        Text($r('app.string.reside_times'))
          .fontSize($r('app.float.font_size_10fp'))
          .fontColor($r('app.color.c_white'))
          .margin({ left: 25, top: 2 })
      }.margin({ top: $r('app.float.float_10vp') }).onClick(() => this.handleClick())
    }
  }
}

//公告
@Component
struct Notice {
  build() {
    Flex({ alignItems: ItemAlign.Center }) {
      Row() {
        Image($r('app.media.ic_laba'))
          .objectFit(ImageFit.Contain)
          .size({ width: 15, height: 15 })
        Text($r('app.string.notice_tip'))
          .fontSize($r('app.float.font_size_14fp'))
          .fontColor($r('app.color.c_ce4949'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.MARQUEE })
      }.justifyContent(FlexAlign.Center)
    }
    .width(CommonConstants.FULL_PERCENT)
    .height(CommonConstants.HEIGHT_30)
    .backgroundColor($r('app.color.c_f2f7ff'))
    .padding({ left: $r('app.float.float_10vp'), right: $r('app.float.float_10vp') })
    .borderRadius(CommonConstants.RADIUS_10)
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
          Image($r('app.media.startIcon'))
            .width(CommonConstants.FULL_PERCENT)
            .height(CommonConstants.FULL_PERCENT)
            .borderRadius($r('app.float.float_16vp'))
            .onClick(() => this.handleClick(item))
        }
        .width(CommonConstants.FULL_PERCENT)
        .aspectRatio(SWIPER_ASPECT_RATIO)
        .padding({ right: $r('app.float.float_12vp') })
      }, (item: number) => item + "")
    }
    .width(CommonConstants.FULL_PERCENT)
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

//自定义view,左图中字右图
@Component
struct TitleText {
  @Prop text: Resource
  @Prop textSize: Resource = $r('app.float.font_size_18fp')
  @Prop textColor: Resource = $r('app.color.c_black')
  @Prop textMarginLeft: Resource = $r('app.float.float_10vp')
  @Prop textMarginRight: Resource = $r('app.float.float_5vp')
  @Prop leftImage: Resource
  @Prop leftImageSize: Resource = $r('app.float.float_24vp')
  @Prop rightImageSize: Resource = $r('app.float.float_16vp')
  @Prop rightImage: Resource = $r('app.media.ic_home_gps')
  @Prop leftVisible: Visibility = Visibility.Visible
  @Prop rightVisible: Visibility = Visibility.None

  build() {
    Row() {
      Image(this.leftImage)
        .objectFit(ImageFit.Contain)
        .size({
          width: this.leftImageSize,
          height: this.leftImageSize
        })
        .visibility(this.leftVisible)
      Text(this.text)
        .fontSize(this.textSize)
        .margin({ left: this.textMarginLeft, right: this.textMarginRight })
        .fontColor(this.textColor)
      Image(this.rightImage)
        .objectFit(ImageFit.Contain)
        .size({
          width: this.rightImageSize,
          height: this.rightImageSize
        })
        .visibility(this.rightVisible)
    }
  }
}


//自定义view，帮助的按钮
@Component
struct HelperBtText {
  @Prop title: Resource
  @Prop content: Resource

  build() {
    Stack({ alignContent: Alignment.Center }) {
      Column() {
        Text(this.title)
          .fontSize($r('app.float.font_size_16fp'))
          .fontColor($r('app.color.c_177DF9'))
        Text(this.content)
          .fontSize($r('app.float.font_size_12fp'))
          .margin({ top: $r('app.float.float_5vp') })
          .fontColor($r('app.color.c_bbbbbb'))
      }
    }
    .backgroundColor($r('app.color.c_daebff'))
    .width(CommonConstants.FORTY_FIVE_PERCENT)
    .height(CommonConstants.HEIGHT_56)
    .borderRadius(CommonConstants.RADIUS_10)
    .margin({ top: $r('app.float.float_10vp') })
  }
}

//自定义view，上图下字
@Component
struct PicTopText {
  @Prop text: Resource
  @Prop img: Resource

  build() {
    Column() {
      Image(this.img)
        .objectFit(ImageFit.Contain)
        .size({
          width: CommonConstants.HEIGHT_60,
          height: CommonConstants.HEIGHT_60
        })
      Text(this.text)
        .fontSize($r('app.float.font_size_14fp'))
        .margin({ top: $r('app.float.float_10vp') })
        .fontColor($r('app.color.c_606060'))
    }
  }
}