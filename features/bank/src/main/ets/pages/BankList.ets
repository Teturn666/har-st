///题库列表
import { BankModel } from '../model/BankModel'
import BankRes from '../model/BankRes'
import { EmitterConstants, Logger, PreferencesConstants, preferencesUtils, } from 'utils';
import { BankListRes, QuestionRes } from 'db'
import { ComponentContent, promptAction, } from '@kit.ArkUI';
import { LoadingDialog } from './LoadingDialog';
import { FinishDialog } from './FinishDialog';
import lottie from '@ohos/lottie';
import { common } from '@kit.AbilityKit';
import { util } from '@kit.ArkTS'
import { onEventObject } from '@umeng/analytics';
import BankMobClickConstants from '../Constants/BankMobClickConstants';
import { DotLoading } from '../components/DotLoading';
import { emitter } from '@kit.BasicServicesKit';
import BankConstants from '../Constants/BankConstants';
import { generatedType, Params } from '../model/BankCategory';
import { NewFlagManager } from '../model/NewFlagManager'
import { cSJLoadFeedAD } from '../utils/loadFeedAd';
import { CSJFeedAd } from '@csj/openadsdk';
import { buildAdLayout } from '../components/buildAdLayout';
import { HybridType } from '../model/SearchQuestionRes';


const TAG = '[BankList]'
let jsonData = null
const context = (getContext(this) as common.UIAbilityContext)


@Builder
function buildText(params: Params) {
  Column() {
    Blank()
    Column() {
      Row() {
        Image($r(params.imgRes)).width('90%').margin({ top: 15 })
      }

      Text("题库下载中").fontSize(12)
        .fontColor($r("app.color.c_9d9d9d"))
        .textAlign(TextAlign.Center).margin({ top: 18 })

      DotLoading({ animating: true })

      Canvas(params.controller)
        .width('30%')
        .height('20%')
        .onReady(() => {
          lottie.loadAnimation({
            container: params.controller,
            renderer: 'canvas',
            loop: true,
            autoplay: true,
            context: context,
            name: params.animateName,
            animationData: jsonData,
          })
        })
        .height(30)
        .margin({ bottom: 16, top: 8 })
    }.width('90%').backgroundColor($r('app.color.start_window_background')).borderRadius(10)

    Blank()
  }.width('100%').height('100%').alignItems(HorizontalAlign.Center)
}

@CustomDialog
struct DownloadOverDialog {
  success: boolean = false
  isUpdate: boolean = false
  controller: CustomDialogController
  bank: BankListRes = {} as BankListRes

  constructor(controller: CustomDialogController, bank: BankListRes) {
    super();
    this.controller = controller;
    this.bank = bank;
  }

  build() {
    Column() {
      Blank()
      Text(this.success ?
        (this.isUpdate ? `更新成功：导入数据${this.bank.num}条`
          : `导入成功：导入数据${this.bank.num}条`)
        : "导入失败：文件不存在或者内容格式异常").fontSize(18)
        .fontColor($r("app.color.c_9d9d9d"))
        .textAlign(TextAlign.Center).margin({ top: 20 })
      Text("确定")
        .width(80)
        .height(30)
        .borderRadius(5)
        .backgroundColor($r('app.color.c_fce8e8'))
        .onClick(() => {
          this.controller.close()
        })
        .textAlign(TextAlign.Center)
        .margin({ top: 25, bottom: 15 })
      Blank()
    }.width('100%').backgroundColor($r('app.color.start_window_background')).borderRadius(10)
  }
}

@Builder
function buildFinishText() {

}

@CustomDialog
struct DeleteDialog {
  confirm?: (item: BankListRes) => void
  controller: CustomDialogController;
  bank: BankListRes = {} as BankListRes;

  constructor(controller: CustomDialogController, bank: BankListRes) {
    super();
    this.controller = controller;
    this.bank = bank;
  }

  build() {
    Column() {
      Blank()
      Text("提示").fontSize(18)
        .fontColor($r("app.color.c_9d9d9d"))
        .textAlign(TextAlign.Center).margin({ top: 20 })
      Text('确定删除 "' + this.bank?.name + '" 这个题库吗？').fontSize(18)
        .fontColor($r("app.color.c_9d9d9d"))
        .textAlign(TextAlign.Start).margin({ top: 20, left: 20, right: 20 })
      Row() {
        Text("确定")
          .width(80)
          .height(30)
          .borderRadius(5)
          .fontColor($r('app.color.c_2a5089'))
          .backgroundColor($r('app.color.c_f4f3fb'))
          .onClick(() => {

            //删除确定
            if (this.confirm) {
              this.confirm(this.bank)

            }
            this.controller.close()
          })
          .textAlign(TextAlign.Center)
          .margin({ top: 25, bottom: 15 })
        Text("取消")
          .width(80)
          .height(30)
          .borderRadius(5)
          .fontColor($r('app.color.c_f75a23'))
          .backgroundColor($r('app.color.c_fce8e8'))
          .onClick(() => {
            //删除取消
            this.controller.close()
          })
          .textAlign(TextAlign.Center)
          .margin({ top: 25, bottom: 15 })
      }
      .justifyContent(FlexAlign.SpaceAround)
      .width('100%')

      Blank()
    }.width('100%').backgroundColor($r('app.color.start_window_background')).borderRadius(10)
  }
}

@Component
export struct BankList {
  @State bankRes: BankRes = new BankRes();
  @State bankModel: BankModel = BankModel.getInstance()
  aid: string = "" //目前题库广场需要传这个参数
  @State searchText: string = ""
  @State fromType: number = 0 //0=题库广场，1=热门搜索，2=我的下载
  @State pageNum: number = 1
  @State loadMore: boolean = false
  @Consume appPathStack: NavPathStack
  private ctx: UIContext = this.getUIContext();
  private mainRenderingSettings: RenderingContextSettings = new RenderingContextSettings(true)
  private controller: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.mainRenderingSettings)
  private animateName = "loading"
  private contentNodeDownload: ComponentContent<Object> =
    new ComponentContent(this.ctx, wrapBuilder(buildText),
      new Params(this.controller, this.animateName, 'app.media.loading_default'));
  private contentNodeUpdate: ComponentContent<Object> =
    new ComponentContent(this.ctx, wrapBuilder(buildText),
      new Params(this.controller, this.animateName, 'app.media.loading_update'));
  private contentNode1: ComponentContent<Object> =
    new ComponentContent(this.ctx, wrapBuilder(buildFinishText));
  private resStr = util.TextDecoder.create('utf-8', { ignoreBOM: true })
  @State hasLoadData: boolean = false
  @State mCurBank: BankListRes = {} as BankListRes
  dialogDeleteController?: CustomDialogController
  dialogDownloadController?: CustomDialogController
  @State updateStatusMap: Map<number, boolean> = new Map();
  @State isUpDate: boolean = false
  @State management: boolean = false;
  @State selectedItems: Set<number> = new Set(); // 存储选中的题库ID
  @State selectAll: boolean = false; // 全选状态
  @State isLoading: boolean = false;
  @State HybridList: HybridType[] = []
  @State private dislikeStatus: boolean = false;
  @State hotList: BankListRes[] = [] //触底请求到的新数据
  @State adIndex: number = 0 //广告数组key
  @State adsList: CSJFeedAd[] = []
  @State firstLength: number = 0
  @State deleteIndex: number = 0
  @State OneAd: boolean = true
  @State HybridIndex: number = 0 //渲染数组的索引
  @Prop myDown: string = '' //判断跳转逻辑参数
  @Prop @Watch("ChangeAd") TabIndex: number = 0
  @State listMap: Map<number, HybridType[]> = new Map();
  @State adMap: Map<number, CSJFeedAd[]> = new Map();
  //NEW标识状态管理
  private newFlagManager: NewFlagManager = NewFlagManager.getInstance();
  @State newFlagStatusMap: Map<number, boolean> = new Map(); // 存储每个题库的NEW显示状态
  @State timer: number = 0

  ChangeAd() {
    cSJLoadFeedAD.AdIndex = this.TabIndex
    let resList = this.listMap.get(this.TabIndex)
    if (resList) {
      this.HybridList = resList
    }
    let resAd = this.adMap.get(this.TabIndex)
    if (resAd) {
      this.adsList = resAd
    }
  }

  aboutToAppear(): void {
    cSJLoadFeedAD.UiContext = this.getUIContext()
    cSJLoadFeedAD.AdIndex = this.TabIndex
    this.timer = setTimeout(() => {
      if (this.getAdIndex()) {
        cSJLoadFeedAD.loadFeedAd((adArray: CSJFeedAd[]) => {
          this.adMap.set(this.TabIndex, adArray)
          let res = this.adMap.get(this.TabIndex)
          if (res) {
            this.adsList = res
          }
          this.hybridData()
        })
      }

    }, 200)


    this.bankRes.newsData = []

    this.loadFeedData().then(() => {
      this.firstLength = this.bankRes.newsData.length
    })
    this.initNewFlagManager()
    this.initDialog()
    emitter.on(EmitterConstants.Delete_ADS, () => {
      this.closeAds()
    })
  }

  closeAds() {
    let res = this.listMap.get(this.TabIndex)
    if (res) {
      this.HybridList = res
      this.HybridList.splice(this.deleteIndex, 1)
      this.listMap.set(this.deleteIndex, this.HybridList)
      let result = this.listMap.get(this.deleteIndex)
      if (result) {
        this.HybridList = result
      }
    }
    if (this.deleteIndex === 2) {
      this.deleteAds(0)
    }
    if (this.deleteIndex === (this.firstLength / 2) + 1) {
      this.deleteAds(1)
    }
    if (this.deleteIndex === (this.firstLength / 2)) {
      this.deleteAds(0)
    }
  }

  deleteAds(Position: number) {
    let res = this.adMap.get(this.TabIndex)
    if (res) {
      this.adsList = res
      this.adsList[Position].destroy()
      this.adsList.splice(Position, 1)
      if (Position!==1){
        this.OneAd = false
      }
      this.adMap.set(this.TabIndex, this.adsList)
    }
  }

  hybridData() {
    const newList: HybridType[] = [];
    this.bankRes.newsData.forEach((item, index) => {
      newList.push({
        type: 'normal', data: item
      });
      if (this.adMap.get(this.TabIndex)?.length && this.adIndex < 2) {
        if (index === 1 && this.OneAd) {
          newList.push({
            type: 'ad', data: this.adsList[this.adIndex]
          });
          this.adIndex++;
        }
        if (index === (this.firstLength / 2 - 1)) {
          newList.push({
            type: 'ad', data: this.adsList[this.adIndex]
          });
          this.adIndex = 0
        }
      }
    });
    this.HybridList = newList;
    this.listMap.set(this.TabIndex, this.HybridList)
  }

  getAdIndex() {
    const res = preferencesUtils.getGenerics(PreferencesConstants.CSJ_AD_PARAMS)
    switch (this.TabIndex) {
      case 0:
        if (res?.hmAd?.informationHot?.switchOff) {
          cSJLoadFeedAD.codeId = res?.hmAd?.informationHot?.csj
          return res?.hmAd?.informationHot?.switchOff
        } else {
          return false
        }
      case 1:
        if (res?.hmAd?.informationOffice?.switchOff) {
          cSJLoadFeedAD.codeId = res?.hmAd?.informationOffice?.csj
          return res?.hmAd?.informationOffice?.switchOff
        } else {
          return false
        }
      case 2:
        if (res?.hmAd?.informationFire?.switchOff) {
          cSJLoadFeedAD.codeId = res?.hmAd?.informationFire?.csj

          return res?.hmAd?.informationFire?.switchOff
        } else {
          return false
        }
      case 3:
        if (res?.hmAd?.informationCoalMine?.switchOff) {
          cSJLoadFeedAD.codeId = res?.hmAd?.informationCoalMine?.csj

          return res?.hmAd?.informationCoalMine?.switchOff
        } else {
          return false
        }
      case 4:
        if (res?.hmAd?.informationNetwork?.switchOff) {
          cSJLoadFeedAD.codeId = res?.hmAd?.informationNetwork?.csj

          return res?.hmAd?.informationNetwork?.switchOff
        } else {
          return false
        }
      case 5:
        if (res?.hmAd?.informationDoctor?.switchOff) {
          cSJLoadFeedAD.codeId = res?.hmAd?.informationDoctor?.csj

          return res?.hmAd?.informationDoctor?.switchOff
        } else {
          return false
        }
      case 6:
        if (res?.hmAd?.informationTraffic?.switchOff) {
          cSJLoadFeedAD.codeId = res?.hmAd?.informationTraffic?.csj

          return res?.hmAd?.informationTraffic?.switchOff
        } else {
          return false
        }
      default:
        return false

    }
  }

  aboutToDisappear(): void {
    clearTimeout(this.timer)
  }

  @Builder
  BankListView(item: BankListRes, index: number) {

    Column() {
      Flex({
        direction: FlexDirection.Row,
        justifyContent: FlexAlign.SpaceAround,
        alignItems: ItemAlign.Center
      }) {
        if (this.management) {
          Image(this.selectedItems.has(item.qid) ? $r('app.media.ic_check_box_selected') :
          $r('app.media.ic_check_box'))
            .objectFit(ImageFit.Contain)
            .size({ width: 32, height: 32 })
            .margin({ left: 15 })
            .onClick(() => {
              this.toggleItemSelection(item.qid);
            });
        }
        Column() {
          Row() {
            Image($r('app.media.ic_feed'))
              .objectFit(ImageFit.Contain)
              .size({ width: $r('app.float.float_16vp'), height: $r('app.float.float_16vp') })
            Text(item.name)
              .fontColor($r('app.color.c_3e3e3e'))
              .fontSize($r('app.float.font_size_16fp'))
              .fontWeight(FontWeight.Bold)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .width('85%')
              .margin({
                left: $r('app.float.float_5vp'),
              })
            // 改进的NEW标识显示逻辑：基于原有NewFlag + 用户查看状态
            if (this.newFlagStatusMap.get(item.qid) === true) {
              Image($r('app.media.ic_NEW'))
                .objectFit(ImageFit.Contain)
                .size({ width: $r('app.float.float_20vp'), height: $r('app.float.float_12vp') })
                .align(Alignment.TopStart)
            }
          }

          Text(item.desc)
            .fontColor($r('app.color.c_3e3e3e'))
            .fontSize($r('app.float.font_size_12fp'))
            .margin({ top: $r('app.float.float_10vp'), bottom: $r('app.float.float_10vp') })

          Row() {
            Text("题库状态：")
              .fontColor($r('app.color.c_9d9d9d'))
              .fontSize($r('app.float.font_size_10fp'))
            if (item.downloadedState === 1) {
              Text("已下载")
                .fontColor(Color.Blue)
                .fontSize($r('app.float.font_size_10fp'))
                .margin({ right: $r('app.float.float_30vp') })
            } else {
              Text("未下载")
                .fontColor(Color.Blue)
                .fontSize($r('app.float.font_size_10fp'))
                .margin({ right: $r('app.float.float_30vp') })
            }
            Text("题库更新时间：" + item.time)
              .fontColor($r('app.color.c_9d9d9d'))
              .fontSize($r('app.float.font_size_10fp'))
          }
        }
        .width('85%')
        .alignItems(HorizontalAlign.Start)
        .justifyContent(FlexAlign.SpaceBetween)
        .margin({
          left: $r('app.float.float_20vp'),
          top: $r('app.float.float_20vp'),
          right: $r('app.float.float_20vp'),
        })


        if (this.fromType !== 2)
        Column() {
          if (item.downloadedState === 1) {
            Image(this.updateStatusMap.get(item.qid) ?? false ?
            $r('app.media.ic_update') :
            $r('app.media.ic_download_pre'))
              .objectFit(ImageFit.Contain)
              .size({ width: $r('app.float.float_60vp'), height: $r('app.float.float_60vp') })

          } else {
            Image($r('app.media.ic_download'))
              .objectFit(ImageFit.Contain)
              .size({ width: $r("app.float.float_60vp"), height: $r("app.float.float_60vp") })
          }
        }
        .margin({
          right: $r('app.float.float_20vp'),
        })
        .onClick(

          async () => {

            this.mCurBank = item
            const needUpdate = this.updateStatusMap.get(item.qid) ?? false;
            this.isUpDate = needUpdate;

            if (item.downloadedState === 1) {
              if (this.fromType === 2) {
                this.showDeleteDialog()
              }

              //更新
              if (needUpdate) {
                LoadingDialog.setContentNode(this.contentNodeUpdate);
                LoadingDialog.openDialog()
                try {
                  const success = await this.bankModel.refreshBank(item)
                  if (success) {
                    item.downloadedState = 1
                    this.updateStatusMap.set(item.qid, false);
                    // 更新成功后标记为已查看
                    await this.markBankAsViewed(item.qid, item.version || '1');
                    this.bankRes.newsData = [...this.bankRes.newsData]
                    LoadingDialog.closeDialog()
                    this.showDownloadOverDialog(true, true)
                    onEventObject(BankMobClickConstants.QUESTION_BANK_CLICK_DOWNLOAD_SUCCESS, {
                      "question_bank_id": item.qid
                    })
                  } else {
                    LoadingDialog.closeDialog()
                    this.showDownloadOverDialog(false, true)
                    onEventObject(BankMobClickConstants.QUESTION_BANK_CLICK_DOWNLOAD_FAIL, {
                      "question_bank_id": item.qid
                    })
                  }
                } catch (error) {
                  LoadingDialog.closeDialog()
                  this.showDownloadOverDialog(false, true)
                  onEventObject(BankMobClickConstants.QUESTION_BANK_CLICK_DOWNLOAD_FAIL, {
                    "question_bank_id": item.qid
                  })
                }
              }
            } else {
              Logger.info(TAG, '题库内容--------' + item)
              LoadingDialog.openDialog()
              try {
                const success = await this.bankModel.downLoadBank(item);
                if (success) {
                  Logger.info(TAG, '下载成功' + item)
                  //更新状态为已下载
                  item.downloadedState = 1
                  let resList = this.listMap.get(this.TabIndex)
                  if (resList) {
                    this.HybridList = [...resList]
                  }

                  this.updateStatusMap.set(item.qid, false);
                  // 下载成功后标记为已查看
                  await this.markBankAsViewed(item.qid, item.version || '1');
                  this.bankRes.newsData = [...this.bankRes.newsData]
                  LoadingDialog.closeDialog()
                  this.showDownloadOverDialog(true, false)

                  onEventObject(BankMobClickConstants.QUESTION_BANK_CLICK_DOWNLOAD_SUCCESS, {
                    "question_bank_id": item.qid
                  })

                } else {
                  Logger.info(TAG, '下载失败' + item)
                  LoadingDialog.closeDialog()
                  this.showDownloadOverDialog(false, false)
                  onEventObject(BankMobClickConstants.QUESTION_BANK_CLICK_DOWNLOAD_FAIL, {
                    "question_bank_id": item.qid
                  })
                }
              } catch (error) {
                Logger.info(TAG, '下载过程中发生错误' + item)
                LoadingDialog.closeDialog()
                this.showDownloadOverDialog(false, false)
                onEventObject(BankMobClickConstants.QUESTION_BANK_CLICK_DOWNLOAD_FAIL, {
                  "question_bank_id": item.qid
                })
              }
            }
          }

        )
      }

      Divider()
        .strokeWidth(0.5)
        .color($r('app.color.c_ebebeb'))
        .margin({
          left: $r('app.float.float_20vp'),
          top: $r('app.float.float_10vp'),
          right: $r('app.float.float_20vp'),
        })
      // if (index === this.bankRes.newsData.length - 1) {
      //   Text("没有更多数据了")
      //     .fontSize(14)
      //     .fontColor($r('app.color.c_9d9d9d'))
      //     .margin({ top: 15, bottom: 15 })
      // }
    }
  }

  // 初始化NEW标识管理器
  private async initNewFlagManager(): Promise<void> {
    await this.newFlagManager.init();
  }

  // 更新NEW标识状态
  private async updateNewFlagStatus(items: BankListRes[]): Promise<void> {
    for (const item of items) {
      const shouldShow = await this.newFlagManager.shouldShowNew(item.qid, item.version || '1', item.NewFlag || false);
      this.newFlagStatusMap.set(item.qid, shouldShow);
    }
    // 触发UI更新
    this.newFlagStatusMap = new Map(this.newFlagStatusMap);
  }

  // 标记题库为已查看（下载或跳转详情时调用）
  private async markBankAsViewed(qid: number, version: string): Promise<void> {
    await this.newFlagManager.markAsViewed(qid, version);
    this.newFlagStatusMap.set(qid, false);
    // 触发UI更新
    this.newFlagStatusMap = new Map(this.newFlagStatusMap);
  }

  //删除弹窗
  showDeleteDialog() {
    this.dialogDeleteController = new CustomDialogController({
      builder: DeleteDialog({
        bank: this.mCurBank,
        confirm: async (item) => {
          // 1. 先关闭对话框
          this.dialogDeleteController?.close()
          item.downloadedState = 2
          this.updateStatusMap.delete(item.qid);
          this.bankRes.newsData = [...this.bankRes.newsData]
          // 4. 执行删除操作
          this.bankModel.deleteTable(item.qid)
        }
      })
    });
    this.dialogDeleteController.open();
    emitter.emit(EmitterConstants.EM_REFRESH_HOME)
  }

  showDownloadOverDialog(success: boolean, isUpdate: boolean) {
    this.dialogDownloadController = new CustomDialogController({

      builder: DownloadOverDialog({

        bank: this.mCurBank, success: success, isUpdate: isUpdate
      })
    });
    this.dialogDownloadController.open();

  }

  async jumpToBankDetail(item: BankListRes, isUpDate: boolean) {
    // 跳转详情时标记为已查看
    await this.markBankAsViewed(item.qid, item.version || '1');

    if (item.downloadedState === 1) {
      //已下载
      const bankQuestionList = await this.bankModel.getBankQuestionList(item.qid)
      //只截取前10道题目
      let questionList = bankQuestionList.slice(0, 10)
      this.appPathStack.pushPathByName(BankConstants.ROUTER_BANK_DETAILS, {
        isUpDate: this.isUpDate,
        downloadedState: 0,
        bankDetails: item,
        questionList: questionList,
        page: this.myDown
      } as generatedType)
    } else {
      //未下载
      let bankDesc = await this.bankModel.getBankDesc(item.qid, item.url)
      console.log("返回的：" + JSON.stringify(bankDesc))
      this.appPathStack.pushPathByName(BankConstants.ROUTER_BANK_DETAILS, {
        downloadedState: 1,
        bankDetails: item,
        questionListtwo: bankDesc,
        page: this.myDown
      } as generatedType)
    }

  }

  private initDialog() {
    LoadingDialog.setContext(this.ctx);
    LoadingDialog.setContentNode(this.contentNodeDownload);
    LoadingDialog.setOptions({
      alignment: DialogAlignment.Center, onWillDismiss: (dismissDialogAction: DismissDialogAction) => {
        if (dismissDialogAction.reason == DismissReason.PRESS_BACK) {
          // dismissDialogAction.dismiss()
        }
        if (dismissDialogAction.reason == DismissReason.TOUCH_OUTSIDE) {
          // dismissDialogAction.dismiss()
        }
      }
    });

    FinishDialog.setContext(this.ctx);
    FinishDialog.setContentNode(this.contentNode1);
    FinishDialog.setOptions({
      alignment: DialogAlignment.Center
    });
  }

  // private initLottie() {
  //   // loading.json需要放到lottie包下的rawfile中
  //   context.resourceManager.getRawFileContent('loading.json', async (err: Error, data: Uint8Array) => {
  //     if (data === null || data === undefined || data.buffer === undefined) {
  //       return;
  //     }
  //     let lottieStr = await this.resStr.decodeWithStream(new Uint8Array(data.buffer))
  //     jsonData = JSON.parse(lottieStr);
  //     this.hasLoadData = true
  //   })
  // }

  private async isNeedUpdate(item: BankListRes): Promise<boolean> {
    // 已下载的题库才需要检查更新
    if (item.downloadedState !== 1) {
      return false;
    }

    try {
      // 假设 BankModel 有一个方法 getLocalBankVersion 返回本地版本号
      const localVersion = await this.bankModel.getLocalVersion(item.qid);

      // 如果本地版本号不存在或为空，或者线上版本号大于本地版本号，返回 true
      return !localVersion || localVersion === '' || Number(item.version) > Number(localVersion);
    } catch (error) {
      Logger.error(TAG, `获取本地版本号失败，qid: ${item.qid}，错误: ${error}`);
      // 如果获取本地版本号失败，假设需要更新
      return true;
    }
  }

  // 删除
  async handleBatchDelete() {
    if (this.selectedItems.size === 0) {
      promptAction.showToast({ message: '请选择后再进行删除', duration: 2000 });
      return;
    }

    if (this.isLoading) {
      return;
    }

    try {
      await new Promise<void>((resolve, reject) => {
        promptAction.showDialog({
          title: '提示',
          message: `确定删除这${this.selectedItems.size}个题库吗？`,
          buttons: [
            { text: '取消', color: '#666666' },
            { text: '确定', color: '#F75A23' }
          ]
        }).then((data) => {
          if (data.index === 1) {
            resolve();
          } else {
            reject();
          }
        });
      });

      this.isLoading = true;

      // 批量删除 - 逐个删除而不是使用Promise.all
      for (const qid of this.selectedItems) {
        try {
          await this.bankModel.deleteTable(qid);
          console.log(`Deleted qid: ${qid}`);
        } catch (deleteError) {
          console.error(`Failed to delete qid ${qid}:`, deleteError);
        }
      }

      // 从列表中移除已删除的项目
      this.bankRes.newsData = this.bankRes.newsData.filter(bank => !this.selectedItems.has(bank.qid));

      // 清空选择状态
      this.selectedItems.clear();
      this.selectAll = false;
      emitter.emit(EmitterConstants.EM_REFRESH_HOME);
    } catch (error) {
      if (error !== undefined) { // 不是用户取消
        console.error(`Batch delete failed: ${error}`);
        promptAction.showToast({ message: '批量删除失败', duration: 2000 });
      }
    } finally {
      this.isLoading = false;
    }
  }

  // 切换单项选择
  toggleItemSelection(qid: number) {
    if (this.selectedItems.has(qid)) {
      this.selectedItems.delete(qid);
    } else {
      this.selectedItems.add(qid);
    }

    // 更新全选状态
    this.selectAll = this.selectedItems.size === this.bankRes.newsData.length && this.bankRes.newsData.length > 0;
  }

  // 切换全选
  toggleSelectAll() {
    if (this.selectAll) {
      // 取消全选
      this.selectedItems.clear();
      this.selectAll = false;
    } else {
      // 全选
      this.selectedItems.clear();
      this.bankRes.newsData.forEach(bank => {
        this.selectedItems.add(bank.qid);
      });
      this.selectAll = true;
    }
  }

  // 退出管理模式
  exitManagement() {
    this.management = false;
    this.selectedItems.clear();
    this.selectAll = false;
  }

  build() {
    Column() {
      if (this.fromType === 2) {
        Row() {
          Image($r('app.media.ic_back'))
            .objectFit(ImageFit.Contain)
            .size({ width: $r('app.float.float_32vp'), height: $r('app.float.float_32vp') })
            .margin({ left: 15, right: 15 })
            .onClick(() => {
              this.appPathStack.pop()
            })
          Text("我的下载")
            .fontSize($r('app.float.font_size_18fp'))
            .fontColor($r('app.color.c_black'))

          if (this.bankRes.newsData.length > 0) {
            Text(this.management ? "退出管理" : "管理")
              .fontSize($r('app.float.font_size_12fp'))
              .fontColor('#060606')
              .margin({ right: 15 })
              .onClick(() => {
                this.management = !this.management;
              })
          } else {
            Blank()
              .width('20%')
          }

        }
        .margin({ top: 15 })
        .justifyContent(FlexAlign.SpaceBetween)
        .width('100%')
      }

      if (this.bankRes.newsData.length > 0) {
        List() {
          ForEach(this.HybridList, (item: HybridType, index: number) => {
            ListItem() {
              if (item.type === 'normal') {
                this.BankListView(item.data as BankListRes, index)
              } else {
                if (item.data as CSJFeedAd) {
                  if ((item.data as CSJFeedAd).isExpressAd()) {
                    NodeContainer((item.data as CSJFeedAd).getAdComponent())
                  } else {
                    buildAdLayout({
                      ad: item.data as CSJFeedAd, index, delete: (index: number) => {
                        this.deleteIndex = index
                      }
                    })
                  }
                }
              }
            }
            .onClick(() => {
              if (item.type === 'normal') {
                this.jumpToBankDetail(item.data as BankListRes, this.isUpDate)
              }
            })
          }, (item: HybridType, index: number) => {
            this.HybridIndex = index
            return util.generateRandomUUID()
          })
          ListItem() {
            if (this.HybridIndex === this.HybridList?.length - 1) {
              Column() {
                Text("没有更多数据了")
                  .fontSize(14)
                  .fontColor($r('app.color.c_9d9d9d'))
                  .margin({ top: 15, bottom: 15 })
              }
              .width('100%')
              .justifyContent(FlexAlign.Center)
            }
          }

        }.onReachEnd(() => {
          if (this.loadMore) {
            this.loadFeedData()
          }
        })
        .layoutWeight(1)

        if (this.management && this.fromType === 2) {
          Row() {
            Image(this.selectAll ? $r('app.media.ic_check_box_selected') : $r('app.media.ic_check_box'))
              .objectFit(ImageFit.Contain)
              .size({ width: 32, height: 32 })
              .onClick(() => {
                this.toggleSelectAll();
              });


            Text("全选")
              .fontColor($r('app.color.c_99000000'))
              .fontSize($r('app.float.font_size_14fp'))
              .margin({ left: 10, })
              .onClick(() => {
                this.toggleSelectAll();
              });


            Text(`（已选${this.selectedItems.size}项）`)
              .fontColor($r('app.color.c_99000000'))
              .fontSize($r('app.float.font_size_14fp'))

            Blank()

            Image($r('app.media.ic_d'))
              .objectFit(ImageFit.Contain)
              .size({ width: 60, height: 22 })
              .onClick(() => {
                this.handleBatchDelete();
              });
          }
          .padding({ left: 10, right: 10 })
          .width('100%')
          .height(72)
          .backgroundColor('#fffaee')
        }

      } else {
        Blank()
          .height("40%")
        Column() {
          Image($r('app.media.hotsearch'))
            .objectFit(ImageFit.Contain)
            .size({ width: 117, height: 100 })

          Text(this.fromType === 1 ? '暂无搜索结果\n换个关键词试试吧' : '暂无下载题库，您可以去题库广场下载')
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

  async loadFeedData(): Promise<void> {
    let newData: BankListRes[] = [];

    switch (this.fromType) {
      case 1:
        let hotList = await this.bankModel.getSearchBankList(this.searchText, this.pageNum);
        if (hotList === null || hotList.length < 10) {
          this.loadMore = false;
        } else {
          this.pageNum++;
          this.loadMore = true;
        }
        for (let item of hotList) {
          this.updateStatusMap.set(item.qid, await this.isNeedUpdate(item));
        }
        newData = hotList;
        this.bankRes.newsData = this.bankRes.newsData.concat(hotList);
        break;
      case 2:
        let downloadList = await this.bankModel.getDownloadBankList();
        for (let item of downloadList) {
          this.updateStatusMap.set(item.qid, await this.isNeedUpdate(item));
        }
        newData = downloadList.filter(bank => bank.bankType === 0);
        this.bankRes.newsData = newData;
        break;
      default:
        let list = await this.bankModel.getBankList(this.aid.toString(), this.pageNum);
        if (list === null || list.length < 10) {
          this.loadMore = false;
        } else {
          this.pageNum++;
          this.loadMore = true;
        }
        for (let item of list) {
          this.updateStatusMap.set(item.qid, await this.isNeedUpdate(item));
        }
        newData = list;
        this.bankRes.newsData = this.bankRes.newsData.concat(list);
        break;
    }

    // 更新NEW标识状态
    if (newData.length > 0) {
      await this.updateNewFlagStatus(newData);
    }
    if (this.bankRes.newsData) {
      this.hybridData()
    }
  }
}