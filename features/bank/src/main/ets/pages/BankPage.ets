import { BankModel } from '../model/BankModel'
import { BankCategory } from '../model/BankCategory';
import { BankList } from './BankList';
import { LoadingStatus } from '@ohos/utils';
import lottie, { AnimationItem } from '@ohos/lottie';
import { common } from '@kit.AbilityKit';
import { util } from '@kit.ArkTS'

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
  private mainRenderingSettings: RenderingContextSettings = new RenderingContextSettings(true)
  private controller: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.mainRenderingSettings)
  private animateItem: AnimationItem | null = null
  private animateName = "loading"
  private resStr = util.TextDecoder.create('utf-8', { ignoreBOM: true })

  aboutToAppear(): void {
    this.initLottie()
    this.loadResources()
  }

  aboutToDisappear(): void {
    lottie.destroy()
  }

  @Builder
  subTabBuilder(tab: BankCategory, tabIndex: number) {
    Row() {
      Text(tab.name)
        .fontSize(16)
        .fontColor(this.selectedCategoryId === tab.aid ? '#F75A23' : '#9D9D9D')
        .id(tabIndex.toString())
    }
    .justifyContent(FlexAlign.Center)
    .padding({ left: 12, right: 12 })
    .height(30)
    .onClick(() => {
      this.selectedCategoryId = tab.aid
      this.subController.changeIndex(tabIndex);
      this.focusIndex = tabIndex;
    })
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
        Row() {
          List({ initialIndex: 0, scroller: this.listScroller }) {
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

        Tabs({ barPosition: BarPosition.Start, controller: this.subController }) {
          ForEach(this.categoryList, (item: BankCategory) => {
            TabContent() {
              Column() {
                BankList({ aid: item.aid })
                  .align(Alignment.Start)
                  .width('100%')
              }
            }
            .backgroundColor(Color.White)

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
      this.categoryList = list
    } else {
      this.loadingStatus = LoadingStatus.FAILED
    }
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

@Component
struct CategoryTabContent {
  private category: BankCategory = { name: '', aid: '', url: '' };
  @State private isSelected: boolean = false

  build() {
    TabContent() {
      Text(this.category.name)// 显示 Category 的名称
        .fontSize(30).fontColor(this.isSelected ? '#F75A23' : '#6665DD');
    }
    .tabBar(this.tabBuilder(this.category.name)); // 设置 TabBar 的标题为 Category 的名称
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

