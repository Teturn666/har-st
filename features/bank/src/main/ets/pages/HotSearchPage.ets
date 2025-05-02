import { BankModel } from '../model/BankModel';
import { Logger, LoadingStatus } from 'utils';
import router from '@ohos.router';
import lottie, { AnimationItem } from '@ohos/lottie';
import { common } from '@kit.AbilityKit';
import { util } from '@kit.ArkTS';
import { BankList } from './BankList';
import BankConstants from '../Constants/BankConstants';
import { SearchQuestionRes } from '../model/SearchQuestionRes';
import { BankListRes } from 'db';

const TAG = '[HotSearchPage]';
const context = (getContext(this) as common.UIAbilityContext);
let jsonData = null;



@Entry({ routeName: 'hotSearchPage' })
@Component
export struct HotSearchPage {
  @State searchText: string = '';
  private controller: TextInputController = new TextInputController();
  @State bankModel: BankModel = BankModel.getInstance();
  @State hotSearchItems: string[] = [];
  @State loadingStatus: LoadingStatus = LoadingStatus.OFF;
  @State hasLoadData: boolean = false;
  private mainRenderingSettings: RenderingContextSettings = new RenderingContextSettings(true);
  private controllerCanvas: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.mainRenderingSettings);
  private animateItem: AnimationItem | null = null;
  private animateName = "loading";
  private resStr = util.TextDecoder.create('utf-8', { ignoreBOM: true });
  private listScroller: Scroller = new Scroller();
  @State isHotSearchVisible: boolean = true;
  @State selectedTabIndex: number = 0;
  private tabsController: TabsController = new TabsController();
  @State questionBankList: SearchQuestionRes[] = [];
  @State aid: string = '';

  aboutToAppear(): void {
    this.initLottie();
    this.loadResources();
  }

  aboutToDisappear(): void {
    lottie.destroy();
  }

  private initLottie() {
    context.resourceManager.getRawFileContent('loading.json', async (err: Error, data: Uint8Array) => {
      if (data === null || data === undefined || data.buffer === undefined) {
        Logger.error(TAG, 'Failed to load loading.json');
        return;
      }
      let lottieStr = await this.resStr.decodeWithStream(new Uint8Array(data.buffer));
      jsonData = JSON.parse(lottieStr);
      this.hasLoadData = true;
    });
  }

  async getSearchBankList(): Promise<void> {
    if (!this.searchText.trim()) {
      Logger.info(TAG, 'Search text is empty');
      this.isHotSearchVisible = true;
      this.questionBankList = [];
      this.aid = '';
      return;
    }

    this.loadingStatus = LoadingStatus.LOADING;
    try {
      // const SearchQuestionRes: BankListRes[] = await this.bankModel.getSearchQuestionkList(this.searchText, 1);

      // const result: BankListRes[] = await this.bankModel.getSearchBankList(this.searchText, 1);

      // if (result && result.length > 0) {
      //   this.questionBankList = result;
      //   // 假设所有搜索结果的 aid 相同，取第一个的 aid
      //   console.info("查看数据",this.searchText)
      //
      //   this.aid = result[0].aid || '';
      //   this.isHotSearchVisible = false;
      //   this.selectedTabIndex = 0;
      //   this.tabsController.changeIndex(0);
      //   this.loadingStatus = LoadingStatus.SUCCESS;
      // } else {
      //   this.questionBankList = [];
      //   this.aid = '';
      //   this.isHotSearchVisible = false;
      //   this.loadingStatus = LoadingStatus.SUCCESS;
      // }
    } catch (e) {
      Logger.error(TAG, `Error searching bank list: ${e}`);
      this.questionBankList = [];
      this.aid = '';
      this.isHotSearchVisible = false;
      this.loadingStatus = LoadingStatus.FAILED;
    }
  }

  async loadResources(): Promise<void> {
    this.loadingStatus = LoadingStatus.LOADING;
    try {
      let list = await this.bankModel.getHotSearchList();
      if (list.length > 0) {
        this.hotSearchItems = list;
        this.loadingStatus = LoadingStatus.SUCCESS;
      } else {
        this.loadingStatus = LoadingStatus.FAILED;
      }
    } catch (e) {
      Logger.error(TAG, `Error loading hot search list: ${e}`);
      this.loadingStatus = LoadingStatus.FAILED;
    }
  }

  @Builder
  tabBuilder(tabName: string, index: number) {
    Row() {
      Text(tabName)
        .fontSize(16)
        .fontColor(this.selectedTabIndex === index ? '#F75A23' : '#9D9D9D')
        .decoration({ type: TextDecorationType.None })
        .border({
          width: this.selectedTabIndex === index ? { bottom: 3 } : 0,
          color: this.selectedTabIndex === index ? '#F75A23' : Color.Transparent,
          style: BorderStyle.Solid,
        })
        .padding({ bottom: 4 })
        .id(index.toString())
    }
    .justifyContent(FlexAlign.Center)
    .padding({ left: 12, right: 12 })
    .height('auto')
    .onClick(() => {
      this.selectedTabIndex = index;
      this.tabsController.changeIndex(index);
    });
  }

  build() {
    Column() {
      Row() {
        Image($r('sys.media.ohos_ic_public_arrow_left'))
          .width(24)
          .height(24)
          .fillColor('#666666')
          .margin({ right: 8 })
          .onClick(() => {
            router.back();
          })

        Stack({ alignContent: Alignment.Start }) {
          Image($r('app.media.search'))
            .objectFit(ImageFit.Contain)
            .width(310)
            .height(36)

          Row() {
            Image($r('app.media.ic_search'))
              .objectFit(ImageFit.Cover)
              .width(24)
              .height(24)
              .margin({ left: 10 })

            TextInput({ placeholder: '请输入题库名称或关键词', controller: this.controller })
              .width('65%')
              .height(36)
              .fontSize(14)
              .fontColor(0xFF9D9D9D)
              .backgroundColor('transparent')
              .onChange((value: string) => {
                this.searchText = value;
                if (value.trim()) {
                  this.getSearchBankList();
                } else {
                  this.isHotSearchVisible = true;
                  this.questionBankList = [];
                  this.aid = '';
                }
              })

            Image($r('app.media.ic_del'))
              .width(24)
              .height(24)
              .visibility(this.searchText.length > 0 ? Visibility.Visible : Visibility.Hidden)
              .onClick(() => {
                this.controller.deleteText();
                this.searchText = '';
                this.isHotSearchVisible = true;
                this.selectedTabIndex = 0;
                this.questionBankList = [];
                this.aid = '';
              })
          }
        }
      }
      .height(76)

      if (this.hasLoadData && this.loadingStatus === LoadingStatus.LOADING) {
        Flex({ direction: FlexDirection.Column, alignItems: ItemAlign.Center, justifyContent: FlexAlign.Center }) {
          Canvas(this.controllerCanvas)
            .width('30%')
            .height('20%')
            .onReady(() => {
              this.animateItem = lottie.loadAnimation({
                container: this.controllerCanvas,
                renderer: 'canvas',
                loop: true,
                autoplay: true,
                context: context,
                name: this.animateName,
                animationData: jsonData,
              });
            });
        }
        .height('100%')
      } else if (this.loadingStatus === LoadingStatus.SUCCESS) {
        if (this.isHotSearchVisible) {
          Row() {
            Image($r('app.media.ic_fire'))
              .width(20)
              .height(20)
              .margin({ right: 8 })

            Image($r('app.media.ic_hotsearch'))
              .width(80)
          }
          .width('90%')
          .height('auto')
          .padding({ left: 16, top: 16, bottom: 10 })

          List({ scroller: this.listScroller }) {
            ForEach(this.hotSearchItems, (item: string, index: number) => {
              ListItem() {
                Row() {
                  Text(`${index + 1}`)
                    .fontSize(16)
                    .fontColor(index < 3 ? '#F75A23' : '#9D9D9D')
                    .fontStyle(FontStyle.Italic)
                    .width(30)
                    .textAlign(TextAlign.Start)

                  Text(item)
                    .fontSize(16)
                    .fontColor(index < 3 ? '#3E3E3E' : '#9D9D9D')
                    .textAlign(TextAlign.Start)
                }
                .width('100%')
                .padding({ left: 38, right: 16, top: 15 })
                .onClick(() => {
                  Logger.info(TAG, `Clicked on: ${item}`);
                  this.searchText = item;
                  this.controller.addText(item);
                  this.getSearchBankList();
                });
              }
            }, (item: string, index: number) => index.toString())
          }
          .width('100%')
          .height('auto')
        } else {
          Column() {
            Row() {
              List({ initialIndex: 0, scroller: this.listScroller, space: 8 }) {
                this.tabBuilder('题库', 0);
                this.tabBuilder('题目', 1);
              }
              .listDirection(Axis.Horizontal)
              .height(30)
              .scrollBar(BarState.Off)
              .width('100%')
              .friction(0.6)
            }

            Tabs({ barPosition: BarPosition.Start, controller: this.tabsController }) {
              TabContent() {
                if (this.aid) {
                  BankList({fromType:1}); // 传递 aid
                } else {
                  Column() {
                    Image($r('app.media.hotsearch'))
                      .objectFit(ImageFit.Contain)
                      .size({ width: 117, height: 100 })

                    Text('暂无搜索结果\n换个关键词试试吧')
                      .fontColor('#9D9D9D')
                      .fontSize(14)
                      .margin({ top: 28 })
                      .textAlign(TextAlign.Center)
                  }
                  .width('100%')
                  .height('auto')
                }
              }
              .backgroundColor(Color.White)
              .margin({ bottom: 30 })

              TabContent() {
                if (this.questionBankList.length > 0) {
                  List({ scroller: this.listScroller }) {
                    ForEach(this.questionBankList, (item: SearchQuestionRes, index: number) => {
                      ListItem() {
                        Column() {
                          Text(item.q)
                            .fontSize(16)
                            .fontColor('#3E3E3E')
                            .textAlign(TextAlign.Start)
                            .margin({ top: 10, left: 16, right: 16 })
                          ForEach(item.ASlice, (option: string, optIndex: number) => {
                            Row() {
                              Text(`${String.fromCharCode(65 + optIndex)}. ${option}`)
                                .fontSize(14)
                                .fontColor('#9D9D9D')
                                .textAlign(TextAlign.Start)
                            }
                            .padding({ left: 16, top: 8 })
                            .width('100%')
                          }, (option: string, optIndex: number) => optIndex.toString())
                          Text(`答案: ${item.ans}`)
                            .fontSize(14)
                            .fontColor('#F75A23')
                            .textAlign(TextAlign.Start)
                            .margin({ top: 8, left: 16, bottom: 10 })
                        }
                        .width('100%')
                        .backgroundColor(Color.White)
                      }
                    }, (item: SearchQuestionRes, index: number) => item.id)
                  }
                  .width('100%')
                  .height('auto')
                } else {
                  Column() {
                    Image($r('app.media.hotsearch'))
                      .objectFit(ImageFit.Contain)
                      .size({ width: 117, height: 100 })

                    Text('快搜题库中暂无收录该关键词相关题目\n输入更完整的题干关键词试试吧')
                      .fontColor('#9D9D9D')
                      .fontSize(14)
                      .margin({ top: 28 })
                      .textAlign(TextAlign.Center)
                  }
                  .width('100%')
                  .height('auto')
                }
              }
            }
            .barHeight(0)
            .animationDuration(300)
            .onChange((index: number) => {
              this.selectedTabIndex = index;
              this.listScroller.scrollToIndex(index, true, ScrollAlign.START);
            })
          }
        }
      } else if (this.loadingStatus === LoadingStatus.FAILED) {
        Text('数据请求失败')
          .fontSize(18)
          .fontColor('#9D9D9D')
          .margin({ top: 20 })
      }
    }
    .height('100%')
    .width('100%')
    .backgroundColor(Color.White)
  }
}