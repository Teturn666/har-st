import { BankModel } from '../model/BankModel'
import { BankCategory } from '../model/BankCategory';
import { BankList } from './BankList';
import { EmitterConstants, LoadingStatus, Logger } from 'utils';
import lottie, { AnimationItem } from '@ohos/lottie';
import { common } from '@kit.AbilityKit';
import { util } from '@kit.ArkTS'
import BankConstants from '../Constants/BankConstants';
import { emitter } from '@kit.BasicServicesKit';

const context = (getContext(this) as common.UIAbilityContext)
let jsonData = null

@Component
export struct BankPage {
  @State categoryList: Array<BankCategory> = [];
  @State bankModel: BankModel = BankModel.getInstance()
  @State selectedCategoryId: string = "hot"
  private listScroller: Scroller = new Scroller();
  @State focusIndex: number = 0;
  @State loadingStatus: LoadingStatus = LoadingStatus.OFF
  private subController: TabsController = new TabsController();
  @State hasLoadData: boolean = false
  @State ShowText: boolean = true
  @Consume appPathStack: NavPathStack
  private mainRenderingSettings: RenderingContextSettings = new RenderingContextSettings(true)
  private controller: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.mainRenderingSettings)
  private animateItem: AnimationItem | null = null
  private animateName = "loading"
  private resStr = util.TextDecoder.create('utf-8', { ignoreBOM: true })

  aboutToAppear(): void {
    this.initLottie()
    this.loadResources()
    emitter.on(EmitterConstants.EM_REFRESH_BANK, () => {
      this.loadResources()
    })
  }

  aboutToDisappear(): void {
    lottie.destroy()
  }

  private jumpTohotBankpage() {
    this.appPathStack.pushPathByName(BankConstants.ROUTER_HOT_Search, null)
  }

  @Builder
  subTabBuilder(tab: BankCategory, tabIndex: number) {
    Row() {
      Text(tab.name)
        .fontSize(16)
        .fontColor(this.selectedCategoryId === tab.aid ? '#F75A23' : '#9D9D9D')
        .decoration({
          type: TextDecorationType.None
        })
        .border({
          width: this.selectedCategoryId === tab.aid ? { bottom: 3 } : 0, // 下划线粗细为 3 像素
          color: this.selectedCategoryId === tab.aid ? '#F75A23' : Color.Transparent, // 下划线颜色
          style: BorderStyle.Solid
        })
        .padding({ bottom: 4 })
        .id(tabIndex.toString())
    }
    .justifyContent(FlexAlign.Center)
    .padding({ left: 12, right: 12 })
    .height('auto')
    .onClick(() => {
      this.selectedCategoryId = tab.aid
      this.subController.changeIndex(tabIndex);
      this.focusIndex = tabIndex;
    })
  }

  build() {
    Column() {
      Stack() {
        Image($r('app.media.search_bg'))
          .objectFit(ImageFit.Cover)
          .width('auto')
        Stack({ alignContent: Alignment.Start }) {
          Image($r('app.media.search'))
            .objectFit(ImageFit.Cover)
            .width(340)
            .height(36)
          Row() {
            Image($r('app.media.ic_search'))
              .objectFit(ImageFit.Cover)
              .width(24)
              .height(24)
              .margin({ left: 10, right: 10 })

            Text("请输入题库名称或关键词")
              .fontSize(14)
              .fontColor(0XFF9D9D9D)
          }
        }
      }
      .width(380)
      .height(130)
      .onClick(() => {
        this.jumpTohotBankpage()
      })

      // 数据栏
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
        Row() {
          List({ initialIndex: 0, scroller: this.listScroller, space: 20 }) {
            ForEach(this.categoryList, (item: BankCategory, index: number) => {
              this.subTabBuilder(item, index)
            }, (item: BankCategory, index: number) => JSON.stringify(item) + index)
          }
          .listDirection(Axis.Horizontal)
          .height(30)
          .scrollBar(BarState.Off)
          .width('100%')
          .friction(0.6)
        }

        if (this.ShowText) {
          Row() {
            Text("搜题前请先下载对应题库")
              .fontSize(14)
              .fontColor(Color.White)
              .textAlign(TextAlign.Center)
              .layoutWeight(1)
              .margin({
                left: 20
              })
            Row() {
              Image($r("sys.media.ohos_ic_public_cancel"))
                .fillColor(Color.White)
                .width(15)
                .aspectRatio(1)
            }
            .onClick(() => {
              this.ShowText = false
            })
            .width(40)
          }
          .height(30)
          .width('100%')
          .backgroundColor('#F2B772')
        }

        Tabs({ barPosition: BarPosition.Start, controller: this.subController }) {
          ForEach(this.categoryList, (item: BankCategory, index: number) => {
            TabContent() {
              BankList({
                aid: item.aid,
                TabIndex: this.focusIndex,
              })
            }
            .backgroundColor(Color.White)
            .margin({ bottom: 30 })
          }, (item: BankCategory, index: number) => JSON.stringify(item) + index)
        }
        .barHeight(0)
        .animationDuration(300)
        .onAnimationStart((index: number, targetIndex: number) => {
          this.selectedCategoryId = this.categoryList[targetIndex].aid
          this.focusIndex = targetIndex;
          this.listScroller.scrollToIndex(targetIndex, true, ScrollAlign.CENTER);
        })

      } else if (this.loadingStatus === LoadingStatus.FAILED) {
        Text('数据请求失败').fontSize(18)
      }
    }
    .height('100%')
    .width('100%')
  }

  async loadResources(): Promise<void> {
    this.loadingStatus = LoadingStatus.LOADING
    let list = await this.bankModel.getBankTypeList()

    if (list.length > 0) {
      this.loadingStatus = LoadingStatus.SUCCESS
      // 保存当前选中的categoryId
      const currentSelectedId = this.selectedCategoryId
      // 更新categoryList
      this.categoryList = list
      // 重新同步状态
      this.syncTabState(currentSelectedId)
    } else {
      this.loadingStatus = LoadingStatus.FAILED
    }
  }

  //同步Tab状态
  private syncTabState(previousSelectedId: string) {
    let newSelectedIndex = this.categoryList.findIndex(item => item.aid === previousSelectedId)
    if (newSelectedIndex === -1) {
      if (this.categoryList.length > 0) {
        const hotIndex = this.categoryList.findIndex(item => item.aid === "hot")
        if (hotIndex !== -1) {
          newSelectedIndex = hotIndex
          this.selectedCategoryId = "hot"
        } else {
          newSelectedIndex = 0
          this.selectedCategoryId = this.categoryList[0].aid
        }
      } else {
        newSelectedIndex = 0
        this.selectedCategoryId = "hot"
      }
    } else {
      this.selectedCategoryId = this.categoryList[newSelectedIndex].aid
    }
    this.focusIndex = newSelectedIndex
    setTimeout(() => {
      if (this.subController && newSelectedIndex >= 0) {
        this.subController.changeIndex(newSelectedIndex)
      }

      if (this.listScroller && newSelectedIndex >= 0) {
        this.listScroller.scrollToIndex(newSelectedIndex, true, ScrollAlign.CENTER)
      }
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

@Builder
function BankPageBuilder() {
  BankPage()
}

@Component
struct CategoryTabContent {
  private category: BankCategory = { name: '', aid: '', url: '' };
  @State private isSelected: boolean = false

  build() {
    TabContent() {
      Text(this.category.name)
        .fontSize(30).fontColor(this.isSelected ? '#F75A23' : '#6665DD');
    }
    .tabBar(this.tabBuilder(this.category.name));
  }

  @Builder
  tabBuilder(title: string) {
    Column() {
      Text(title)
        .fontColor(this.isSelected ? '#B86E00' : '#7B7B7B')
    }
    .width('100%')
    .height(50)
    .justifyContent(FlexAlign.Center)
  }
}