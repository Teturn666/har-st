import { onEventObject } from '@umeng/analytics';
import { TitleBar } from 'widget/Index';
import { ComponentContent } from '@kit.ArkUI';
import { BankListRes, QuestionRes } from 'db';
import { EmitterConstants, Logger } from 'utils';
import { LoadingDialog } from './LoadingDialog';
import { BankModel } from '../model/BankModel';
import BankMobClickConstants from '../Constants/BankMobClickConstants';
import { DotLoading } from '../components/DotLoading';
import lottie from '@ohos/lottie';
import { common } from '@kit.AbilityKit';
import { FinishDialog } from './FinishDialog';
import BankConstants from '../Constants/BankConstants';
import { emitter } from '@kit.BasicServicesKit';
import { generatedType, NavQid, Params, QuestionItem } from '../model/BankCategory';


const TAG = '[BankList]'
let jsonData = null
const context = (getContext(this) as common.UIAbilityContext)


@Builder
function buildFinishText() {
}


@Component
struct BankDetailsPage {
  //题库详情
  @State bankDetails: BankListRes = new BankListRes()
  //题目列表
  @State questionList: Array<QuestionRes> = []
  @State questionListtwo: Array<QuestionItem> = []
  @State downloadedState: number = 0 // 已下载 0 未下载 1
  @State bankModel: BankModel = BankModel.getInstance()
  @State updateStatusMap: Map<number, boolean> = new Map();
  @State private refreshTrigger: number = 0;
  dialogDownloadController?: CustomDialogController
  @State mCurBank: BankListRes = {} as BankListRes
  @State bankUpdate: boolean = false
  @State pages: string = ''
  @Consume appPathStack: NavPathStack
  private mainRenderingSettings: RenderingContextSettings = new RenderingContextSettings(true)
  private controller: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.mainRenderingSettings)
  private ctx: UIContext = this.getUIContext();
  private animateName = "loading"
  private contentNodeUpdate: ComponentContent<Object> =
    new ComponentContent(this.ctx, wrapBuilder(buildText),
      new Params(this.controller, this.animateName, 'app.media.loading_update'));
  private contentNodeDownload: ComponentContent<Object> =
    new ComponentContent(this.ctx, wrapBuilder(buildText),
      new Params(this.controller, this.animateName, 'app.media.loading_default'));
  private contentNode1: ComponentContent<Object> =
    new ComponentContent(this.ctx, wrapBuilder(buildFinishText));

  showDownloadOverDialog(success: boolean, isUpdate: boolean, fromPractice: boolean = false,
    practiceType: string = '') {
    this.dialogDownloadController = new CustomDialogController({
      builder: DownloadOverDialog({
        bank: this.mCurBank,
        success: success,
        isUpdate: isUpdate,
        fromPractice: fromPractice,
        practiceType: practiceType,
        onStartPractice: () => {
          // 跳转到练习页面的逻辑
          this.appPathStack.pushPathByName(BankConstants.ROUTER_EXERCISE_LIST, { qid: this.mCurBank.qid } as NavQid)
        }
      })
    });
    this.dialogDownloadController.open();
  }

  aboutToAppear(): void {
    this.initDialog()
    this.loadsourse()
  }

  loadsourse() {
    const res = this.appPathStack.getParamByName(BankConstants.ROUTER_BANK_DETAILS) as generatedType[]
    if (res && res.length) {
      let params = res[0]
      this.bankUpdate = params.isUpDate ?? false;
      this.downloadedState = params.downloadedState ?? 0;
      this.bankDetails = params.bankDetails;
      this.questionList = params.questionList ?? [];
      this.questionListtwo = params.questionListtwo ?? [];
      if (params.page) {
        this.pages = params.page
      }
      console.log("接搜的参数" + this.pages);
    } else {
      Logger.error(TAG, "加载参数异常，params为空");
    }

  }

  formatFirstTypeOption(option: string, optionIndex: number): string {
    if (!option) {
      return '';
    }

    const optionLabels = ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H'];
    const label = optionLabels[optionIndex] || (optionIndex + 1).toString();
    return `${label}. ${option}`;
  }

  // 在 BankDetailsPage 组件中添加此方法
  formatOptionText(option: string, optionIndex: number): string {
    if (!option) {
      return '';
    }

    const trimmedOption = option.trim();
    if (trimmedOption === '') {
      return '';
    }

    // 检查是否以 "A-"、"A."、"A、"、"A "、"A："等开头
    const hasPrefix = /^[A-Z][-.\s、：]/.test(trimmedOption);

    if (hasPrefix) {
      // 如果已经有前缀，直接显示
      return trimmedOption;
    } else {
      // 如果没有前缀，添加对应的字母前缀
      const optionLabels = ['A', 'B', 'C', 'D', 'E', 'F'];
      const label = optionLabels[optionIndex] || (optionIndex + 1).toString();
      return `${label}. ${trimmedOption}`;
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

  build() {
    NavDestination() {
      Column() {
        TitleBar({
          title: "题库详情",
          backClick: () => {
            if (this.pages) {
              this.appPathStack.pop()
            } else {
              this.appPathStack.popToIndex(-1)
            }
          }
        })
          .backgroundColor(Color.White)
          .width('100%');

        if (this.bankDetails || this.questionListtwo) {
          List() {
            ListItem() {
              Column() {
                Row() {
                  Image($r('app.media.ic_feed'))
                    .objectFit(ImageFit.Contain)
                    .size({ width: $r('app.float.float_16vp'), height: $r('app.float.float_16vp') })
                  Text(this.bankDetails?.name)
                    .fontColor($r('app.color.c_3e3e3e'))
                    .fontSize($r('app.float.font_size_16fp'))
                    .margin({
                      left: $r('app.float.float_5vp'),
                    })
                }

                Text(this.bankDetails.desc)
                  .fontColor($r('app.color.c_9d9d9d'))
                  .fontSize($r('app.float.font_size_12fp'))
                  .margin({ top: $r('app.float.float_10vp'), bottom: $r('app.float.float_10vp') })

                Row() {
                  Text("题库状态：")
                    .fontColor($r('app.color.c_9d9d9d'))
                    .fontSize($r('app.float.font_size_10fp'))
                  if (this.downloadedState === 0) {
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
                  Text("题目数：" + this.bankDetails.num)
                    .fontColor($r('app.color.c_9d9d9d'))
                    .fontSize($r('app.float.font_size_10fp'))
                  Blank()
                  Text("题库更新时间：" + this.bankDetails.time)
                    .fontColor($r('app.color.c_9d9d9d'))
                    .fontSize($r('app.float.font_size_10fp'))
                }
                .width('95%')
                .justifyContent(FlexAlign.SpaceBetween)
              }
              .alignItems(HorizontalAlign.Start)
              .backgroundColor(Color.White)
              .borderRadius(5)
              .padding({
                left: $r('app.float.float_10vp'),
                top: $r('app.float.float_10vp'),
                right: $r('app.float.float_10vp'),
                bottom: $r('app.float.float_10vp'),
              })
              .width('100%')
            }

            ListItem() {
              Column() {
                Text("题库练习")
                  .fontColor($r('app.color.c_black'))
                  .fontSize($r('app.float.font_size_14fp'))
                  .fontWeight(600)
                Text("点击顺序练习、模拟考试可下载题库")
                  .fontColor($r('app.color.c_9d9d9d'))
                  .fontSize($r('app.float.font_size_10fp'))
                  .margin({ top: 5 })
                Row() {
                  Image($r('app.media.ic_question_bank_exercise'))
                    .width(60)
                    .height(60)
                    .onClick(async () => {
                      this.mCurBank = this.bankDetails;
                      if (this.downloadedState === 1) {
                        //下载
                        LoadingDialog.openDialog()
                        try {
                          const success = await this.bankModel.downLoadBank(this.bankDetails!);
                          if (success) {
                            //更新状态为已下载
                            this.downloadedState = 0
                            this.bankUpdate = false
                            this.updateStatusMap.set(this.bankDetails!.qid, false);
                            this.refreshTrigger++; // 触发UI更新
                            LoadingDialog.closeDialog()
                            this.showDownloadOverDialog(true, false, true, 'exercise')
                            onEventObject(BankMobClickConstants.QUESTION_BANK_CLICK_DOWNLOAD_SUCCESS, {
                              "question_bank_id": this.bankDetails!.qid
                            })
                            emitter.emit(EmitterConstants.EM_REFRESH_BANK)
                          } else {
                            LoadingDialog.closeDialog()
                            this.showDownloadOverDialog(false, false)
                            onEventObject(BankMobClickConstants.QUESTION_BANK_CLICK_DOWNLOAD_FAIL, {
                              "question_bank_id": this.bankDetails!.qid
                            })
                          }
                        } catch (error) {
                          Logger.info(TAG, '下载过程中发生错误' + JSON.stringify(this.bankDetails))
                          LoadingDialog.closeDialog()
                          this.showDownloadOverDialog(false, false)
                          onEventObject(BankMobClickConstants.QUESTION_BANK_CLICK_DOWNLOAD_FAIL, {
                            "question_bank_id": this.bankDetails!.qid
                          })
                        }
                      } else {
                        // 已下载，直接跳转到练习
                        this.appPathStack.pushPathByName(BankConstants.ROUTER_EXERCISE_LIST,
                          { qid: this.mCurBank.qid, bankPage: BankConstants.ROUTER_BANK_DETAILS } as NavQid)
                      }
                    })
                  Image($r('app.media.ic_practice'))
                    .width(60)
                    .height(60)
                    .margin({ left: 18 })

                    .onClick(async () => {
                      this.mCurBank = this.bankDetails;
                      if (this.downloadedState === 1) {
                        //下载
                        LoadingDialog.openDialog()
                        try {
                          const success = await this.bankModel.downLoadBank(this.bankDetails!);
                          if (success) {
                            //更新状态为已下载
                            this.downloadedState = 0
                            this.bankUpdate = false
                            this.updateStatusMap.set(this.bankDetails!.qid, false);
                            this.refreshTrigger++; // 触发UI更新
                            LoadingDialog.closeDialog()
                            // 修改：传递模拟考试类型参数
                            this.showDownloadOverDialog(true, false, true, 'exam')
                            onEventObject(BankMobClickConstants.QUESTION_BANK_CLICK_DOWNLOAD_SUCCESS, {
                              "question_bank_id": this.bankDetails!.qid
                            })
                            emitter.emit(EmitterConstants.EM_REFRESH_BANK)
                          } else {
                            LoadingDialog.closeDialog()
                            this.showDownloadOverDialog(false, false)
                            onEventObject(BankMobClickConstants.QUESTION_BANK_CLICK_DOWNLOAD_FAIL, {
                              "question_bank_id": this.bankDetails!.qid
                            })
                          }
                        } catch (error) {
                          Logger.info(TAG, '下载过程中发生错误' + JSON.stringify(this.bankDetails))
                          LoadingDialog.closeDialog()
                          this.showDownloadOverDialog(false, false)
                          onEventObject(BankMobClickConstants.QUESTION_BANK_CLICK_DOWNLOAD_FAIL, {
                            "question_bank_id": this.bankDetails!.qid
                          })
                        }
                      } else {
                        // 已下载，直接跳转到模拟考试
                        this.appPathStack.pushPathByName(BankConstants.ROUTER_EXERCISE_COMMON_LIST, {
                          practiceMode: 1,
                          qid: this.mCurBank.qid, bankPage: BankConstants.ROUTER_BANK_DETAILS
                        } as NavQid)

                      }

                    })
                }
                .width('100%')
                .margin({ top: 18 })
              }
              .alignItems(HorizontalAlign.Start)
              .padding({ top: 10, left: 10 })
              .borderRadius(5)
              .margin({ top: 10 })
              .backgroundColor(Color.White)
              .height(135)
              .width('100%')

            }

            //内容
            ListItem() {
              Column() {
                Text("题库预览 （10题）")
                  .fontColor($r('app.color.c_black'))
                  .fontSize($r('app.float.font_size_14fp'))
                  .fontWeight(600)
                  .margin({ bottom: 10 })

                if (this.questionList.length > 0) {
                  Column() {
                    // 遍历显示所有题目
                    ForEach(this.questionList, (item: QuestionRes, index: number) => {
                      Column() {
                        // 题目序号和内容
                        Text() {
                          Span(`${index + 1}.`)
                            .fontSize($r('app.float.font_size_12fp'))
                            .fontColor($r('app.color.c_black'))
                          Span(item.question)
                            .fontSize($r('app.float.font_size_12fp'))
                            .fontColor($r('app.color.c_black'))
                        }
                        .width('100%')
                        .lineHeight(24)
                        .margin({ bottom: 10 })
                        .textAlign(TextAlign.Start)

                        // 选项列表
                        Column() {
                          ForEach(item.option, (option: string, optionIndex: number) => {
                            if (option && option.trim() !== '') {
                              Row() {
                                Text(this.formatFirstTypeOption(option, optionIndex))
                                  .fontSize($r('app.float.font_size_12fp'))
                                  .fontColor($r('app.color.c_black'))
                                  .lineHeight(24)
                              }
                              .width('100%')
                              .alignItems(VerticalAlign.Top)
                            }
                          })
                        }
                        .alignItems(HorizontalAlign.Start)
                        .margin({ bottom: 15 })

                        // 答案
                        Row() {
                          Text() {
                            Span("答案：")
                              .fontSize($r('app.float.font_size_12fp'))
                              .fontColor($r('app.color.c_black'))
                            Span(item.answer)
                              .fontSize($r('app.float.font_size_12fp'))
                              .fontColor($r('app.color.c_black'))
                          }
                        }
                        .width('100%')
                        .margin({ bottom: index === this.questionList.length - 1 ? 5 : 10 })

                        Divider()
                          .strokeWidth(0.5)
                          .color($r('app.color.c_ebebeb'))
                          .margin({
                            left: $r('app.float.float_20vp'),
                            top: $r('app.float.float_10vp'),
                            right: $r('app.float.float_20vp'),
                          })
                      }
                      .width('100%')
                      .alignItems(HorizontalAlign.Start)
                    })
                  }
                  .width('100%')
                  .alignItems(HorizontalAlign.Start)
                } else {
                  Column() {
                    // 遍历显示所有题目
                    ForEach(this.questionListtwo, (item: QuestionItem, index: number) => {
                      Column() {
                        // 题目序号和内容
                        Text() {
                          Span(`${index + 1}.`)
                            .fontSize($r('app.float.font_size_12fp'))
                            .fontColor($r('app.color.c_black'))
                          Span(item.q)
                            .fontSize($r('app.float.font_size_12fp'))
                            .fontColor($r('app.color.c_black'))
                        }
                        .width('100%')
                        .lineHeight(24)
                        .margin({ bottom: 10 })
                        .textAlign(TextAlign.Start)

                        // 选项列表
                        Column() {
                          ForEach(item.a, (option: string, optionIndex: number) => {
                            // 检查选项是否存在且不为空
                            if (option && option.trim() !== '') {
                              Row() {
                                Text(this.formatOptionText(option, optionIndex))
                                  .fontSize($r('app.float.font_size_12fp'))
                                  .fontColor($r('app.color.c_black'))
                                  .lineHeight(24)
                              }
                              .width('100%')
                              .alignItems(VerticalAlign.Top)
                            }
                          })
                        }
                        .alignItems(HorizontalAlign.Start)
                        .margin({ bottom: 15 })


                        // 答案
                        Row() {
                          Text() {
                            Span("答案：")
                              .fontSize($r('app.float.font_size_12fp'))
                              .fontColor($r('app.color.c_black'))
                            Span(item.ans)
                              .fontSize($r('app.float.font_size_12fp'))
                              .fontColor($r('app.color.c_black'))
                          }
                        }
                        .width('100%')
                        .margin({ bottom: index === this.questionList.length - 1 ? 5 : 10 })

                        Divider()
                          .strokeWidth(0.5)
                          .color($r('app.color.c_ebebeb'))
                          .margin({
                            left: $r('app.float.float_20vp'),
                            top: $r('app.float.float_10vp'),
                            right: $r('app.float.float_20vp'),
                          })
                      }
                      .width('100%')
                      .alignItems(HorizontalAlign.Start)
                    })
                  }
                  .width('100%')
                  .alignItems(HorizontalAlign.Start)
                }

              }
              .alignItems(HorizontalAlign.Start)
              .padding({ top: 10, left: 10 })
              .backgroundColor($r('app.color.white'))
              .margin({ top: 10 })
              .width('100%')
            }
          }
          .width('95%')
          .layoutWeight(1)

          Blank()
          Stack() {
            Image(this.downloadedState === 0 ?
              this.bankUpdate ? $r('app.media.ic_bank_detail_bg') :
              $r('app.media.ic_bank_detail_bgs') : $r('app.media.ic_bank_detail_bg'))
              .objectFit(ImageFit.Cover)
              .width(282)
              .onClick(async () => {
                this.mCurBank = this.bankDetails;

                if (this.downloadedState === 1) {
                  Logger.info(TAG, '题库内容--------' + JSON.stringify(this.bankDetails))
                  LoadingDialog.openDialog()
                  try {
                    const success = await this.bankModel.downLoadBank(this.bankDetails!);
                    if (success) {
                      //更新状态为已下载
                      this.downloadedState = 0
                      this.bankUpdate = false
                      this.updateStatusMap.set(this.bankDetails!.qid, false);
                      this.refreshTrigger++; // 触发UI更新
                      LoadingDialog.closeDialog()
                      this.showDownloadOverDialog(true, false)
                      onEventObject(BankMobClickConstants.QUESTION_BANK_CLICK_DOWNLOAD_SUCCESS, {
                        "question_bank_id": this.bankDetails!.qid
                      })
                      emitter.emit(EmitterConstants.EM_REFRESH_BANK)
                    } else {
                      // Logger.info(TAG, '下载失败' + item)
                      LoadingDialog.closeDialog()
                      this.showDownloadOverDialog(false, false)
                      onEventObject(BankMobClickConstants.QUESTION_BANK_CLICK_DOWNLOAD_FAIL, {
                        "question_bank_id": this.bankDetails!.qid
                      })
                    }
                  } catch (error) {
                    Logger.info(TAG, '下载过程中发生错误' + JSON.stringify(this.bankDetails))
                    LoadingDialog.closeDialog()
                    this.showDownloadOverDialog(false, false)
                    onEventObject(BankMobClickConstants.QUESTION_BANK_CLICK_DOWNLOAD_FAIL, {
                      "question_bank_id": this.bankDetails!.qid
                    })
                  }
                } else {
                  if (this.bankUpdate) {
                    LoadingDialog.setContentNode(this.contentNodeUpdate);
                    LoadingDialog.openDialog()
                    try {
                      const success = await this.bankModel.refreshBank(this.bankDetails!)
                      if (success) {
                        this.downloadedState = 0
                        this.bankUpdate = false
                        this.updateStatusMap.set(this.bankDetails!.qid, false); // 更新成功后重置更新状态
                        this.refreshTrigger++; // 触发UI更新
                        LoadingDialog.closeDialog()
                        this.showDownloadOverDialog(true, true)
                        onEventObject(BankMobClickConstants.QUESTION_BANK_CLICK_DOWNLOAD_SUCCESS, {
                          "question_bank_id": this.bankDetails!.qid
                        })
                        emitter.emit(EmitterConstants.EM_REFRESH_BANK)
                      } else {
                        LoadingDialog.closeDialog()
                        this.showDownloadOverDialog(false, true)
                        onEventObject(BankMobClickConstants.QUESTION_BANK_CLICK_DOWNLOAD_FAIL, {
                          "question_bank_id": this.bankDetails!.qid
                        })
                      }
                    } catch (error) {
                      LoadingDialog.closeDialog()
                      this.showDownloadOverDialog(false, true)
                      onEventObject(BankMobClickConstants.QUESTION_BANK_CLICK_DOWNLOAD_FAIL, {
                        "question_bank_id": this.bankDetails!.qid
                      })
                    }
                  }
                }
              })
            Text(this.bankDetails.downloadedState === 1 ? this.bankUpdate ? "更新" : "已最新" : "下载")
              .fontColor($r('app.color.white'))
              .fontSize($r('app.float.font_size_14fp'))
          }
          .backgroundColor($r('app.color.white'))
          .width('100%')
          .height(62)

        } else {

          Text("加载中...")
            .fontColor($r('app.color.c_9d9d9d'))
            .fontSize($r('app.float.font_size_14fp'))
            .margin({ top: $r('app.float.float_50vp') })
        }
      }
      .backgroundColor('#f5fdff')
      .width('100%')
      .height('100%')
    }
    .hideTitleBar(true)
    .onBackPressed(() => {
      if (this.pages) {
        this.appPathStack.pop()
      } else {
        this.appPathStack.popToIndex(-1)
      }

      return true
    })
  }
}


@CustomDialog
struct DownloadOverDialog {
  success: boolean = false
  isUpdate: boolean = false
  fromPractice: boolean = false // 新增：是否来自练习点击
  practiceType: string = '' // 新增：练习类型
  controller: CustomDialogController
  bank: BankListRes = {} as BankListRes
  onStartPractice?: () => void // 新增：开始练习回调

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

      // 修改按钮文字和点击行为
      Text(this.success && this.fromPractice ? "开始练习" : "确定")
        .width(80)
        .height(30)
        .fontSize(14)
        .borderRadius(5)
        .backgroundColor($r('app.color.c_fce8e8'))
        .onClick(() => {
          this.controller.close()
          if (this.success && this.fromPractice && this.onStartPractice) {
            this.onStartPractice();
          }
        })
        .textAlign(TextAlign.Center)
        .margin({ top: 25, bottom: 15 })
      Blank()
    }.width('100%').backgroundColor($r('app.color.start_window_background')).borderRadius(10)
  }
}

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
        })// .width('90%')
        .height(30)
        .margin({ bottom: 16, top: 8 })
    }.width('90%').backgroundColor($r('app.color.start_window_background')).borderRadius(10)

    Blank()
  }.width('100%').height('100%').alignItems(HorizontalAlign.Center)
}

@Builder
function BankDetailsPageBuilder() {
  BankDetailsPage()
}