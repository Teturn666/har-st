import { TitleBar } from 'widget';
import { uniformTypeDescriptor as utd } from '@kit.ArkData';
import HomeConstants from '../Constants/HomeConstants';
import { HomeModel } from '../model/HomeModel';
import { BankListRes, QuestionRes } from 'db';
import promptAction from '@ohos.promptAction';
import { EmitterConstants, ToastUtils } from 'utils';
import { BusinessError, emitter } from '@kit.BasicServicesKit';
import { common, Want } from '@kit.AbilityKit';
import fs from '@ohos.file.fs';
import { systemShare } from '@kit.ShareKit';
import { fileUri } from '@kit.CoreFileKit';
import { Customized } from '../model/NavGenericType';

const TAG = 'CustomQuestionPage';

@Component
struct CustomQuestionPage {
  @State homeModel: HomeModel = HomeModel.getInstance();
  @State questionBanks: BankListRes[] = [];
  @State isLoading: boolean = false;
  @State management: boolean = false;
  @State selectedItems: Set<number> = new Set(); // 存储选中的题库ID
  @State selectAll: boolean = false; // 全选状态
  @Consume appPathStack: NavPathStack

  async getimportList() {
    this.isLoading = true;
    try {
      const banks = await this.homeModel.getBankList();
      this.questionBanks = (banks || []).filter(bank => bank.bankType === 2);
      console.log(`Updated questionBanks: ${JSON.stringify(this.questionBanks)}`);
    } catch (error) {
      console.error(`getimportList error: ${error}`);
      this.questionBanks = [];
      promptAction.showToast({ message: '加载题库失败', duration: 2000 });
    } finally {
      this.isLoading = false;
    }
  }

  aboutToAppear(): void {
    this.getimportList();
  }

  @Builder
  rightBuilder() {
    Text('帮助')
      .fontColor($r('app.color.c_F75A23'))
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
          await this.homeModel.deleteTable(qid);
          console.log(`Deleted qid: ${qid}`);
        } catch (deleteError) {
          console.error(`Failed to delete qid ${qid}:`, deleteError);
        }
      }

      // 从列表中移除已删除的项目
      this.questionBanks = this.questionBanks.filter(bank => !this.selectedItems.has(bank.qid));

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
    this.selectAll = this.selectedItems.size === this.questionBanks.length && this.questionBanks.length > 0;
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
      this.questionBanks.forEach(bank => {
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

  // 跳转QQ
  private jumpToQQ() {
    let want: Want = {
      bundleName: 'com.tencent.mqq',
      abilityName: 'EntryAbility'
    }
    try {
      (getContext(this) as common.UIAbilityContext).startAbility(want, (err: BusinessError) => {
        if (err.code) {
          // 处理业务逻辑错误
          ToastUtils.showToast('应用程序未安装')
          return
        }
      });
    } catch (err) {
      // 唤起失败
      ToastUtils.showToast('应用程序未安装')
    }
  }

  // 跳转wx
  private async jumpToWX() {
    let want: Want = {
      bundleName: 'com.tencent.wechat',
      abilityName: 'EntryAbility'
    }
    try {
      (getContext(this) as common.UIAbilityContext).startAbility(want, (err: BusinessError) => {
        if (err.code) {
          // 处理业务逻辑错误
          ToastUtils.showToast('应用程序未安装')
          return
        }
      });
    } catch (err) {
      // 唤起失败
      ToastUtils.showToast('应用程序未安装')
    }
  }

  // 分享题库功能
  async handleShare(bank: BankListRes): Promise<void> {
    if (this.isLoading) {
      return;
    }

    this.isLoading = true;
    try {
      // 获取题库的具体题目数据
      const questionData = await this.homeModel.getBankQuestionList(bank.qid);

      if (!questionData || questionData.length === 0) {
        promptAction.showToast({ message: '该题库暂无题目数据', duration: 2000 });
        return;
      }

      // 将题目数据转换为JSON格式
      const jsonContent: string = questionData.map((item: QuestionRes) => {
        return JSON.stringify({
          q: item.question, // 题目内容
          a: item.option || [], // 选项数组
          ans: item.answer || '' // 正确答案
        });
      }).join('\n');

      // 创建临时文件
      const context = getContext(this) as common.UIAbilityContext;
      const cacheDir: string = context.cacheDir;
      const fileName: string = `${bank.name}_题库_${new Date().getTime()}.txt`;
      const filePath: string = `${cacheDir}/${fileName}`;

      // 写入文件
      const file = fs.openSync(filePath, fs.OpenMode.CREATE | fs.OpenMode.WRITE_ONLY);
      fs.writeSync(file.fd, jsonContent);
      fs.closeSync(file.fd);

      let uri = fileUri.getUriFromPath(filePath)

      // 使用官方系统分享API
      let shareData: systemShare.SharedData = new systemShare.SharedData({
        utd: utd.UniformDataType.COMPOSITE_OBJECT,
        uri: uri,
        title: `${bank.name}.txt`,
      });

      let controller: systemShare.ShareController = new systemShare.ShareController(shareData);
      controller.show(context, {
        selectionMode: systemShare.SelectionMode.SINGLE,
        previewMode: systemShare.SharePreviewMode.DEFAULT,
      }).then(() => {
        promptAction.showToast({ message: '分享成功', duration: 2000 });
        console.log('Share success');
      }).catch((error: BusinessError) => {
        console.error(`Share failed: ${error.message}`);
        promptAction.showToast({ message: '分享失败', duration: 2000 });
      });

    } catch (error) {
      console.error(`Share error: ${error}`);
      promptAction.showToast({ message: '分享失败，请重试', duration: 2000 });
    } finally {
      this.isLoading = false;
    }
  }

  build() {
    NavDestination() {
      Column() {
        TitleBar({
          title: '自定义题库',
          backClick: () => {
            this.appPathStack.pop()
          },
          rightBuilderParam: this.rightBuilder,
          rightBuilderClick: () => {
            this.appPathStack.pushPathByName(HomeConstants.ROUTER_HELP_PAGE, null)
          }
        }).width('100%');

        // 题库制作助手
        Row() {
          Row({ space: 10 }) {
            Row() {
              Image($r('app.media.ic_likes'))
                .size({ width: 70, height: 70 });
            }

            Column({ space: 5 }) {
              Text('题库导入')
                .fontSize(16);
            }
            .justifyContent(FlexAlign.Center)
            .alignItems(HorizontalAlign.Start);
          }

          Button('去导入', { type: ButtonType.Normal })
            .backgroundColor('#F75A23')
            .borderRadius(6)
            .width(70)
            .height(25)
            .onClick(() => {
              this.appPathStack.pushPathByName(HomeConstants.ROUTER_CUSTOMIZED_BANK_PAGE,
                { isShow: true } as Customized)
            });
        }
        .width('90%')
        .height(90)
        .justifyContent(FlexAlign.SpaceBetween)
        .padding(10)
        .backgroundColor(0xf5f5f5)
        .borderRadius(10)
        .margin({ top: 10 });

        // 我的导入
        if (this.questionBanks.length > 0) {
          Row() {
            Image($r('app.media.ic_import'))
              .width(85);
            Blank()
            Text(this.management ? "退出管理" : "管理")
              .fontSize($r('app.float.font_size_12fp'))
              .fontColor('#060606')
              .onClick(() => {
                this.management = !this.management;
              });
          }
          .width('90%')
          .margin({ top: 10, left: 10, right: 10 })
          .alignItems(VerticalAlign.Top)
          .justifyContent(FlexAlign.Start);
        }

        if (this.questionBanks.length > 0) {
          List() {
            ForEach(this.questionBanks, (item: BankListRes, index) => {
              ListItem() {
                Column() {
                  Flex({
                    direction: FlexDirection.Row,
                    justifyContent: FlexAlign.SpaceAround,
                    alignItems: ItemAlign.Center,
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
                        Image($r('app.media.ic_question_bank'))
                          .size({ width: $r('app.float.float_16vp'), height: $r('app.float.font_size_16fp') });
                        Text(item.name)
                          .fontColor($r('app.color.c_3e3e3e'))
                          .fontSize($r('app.float.font_size_16fp'))
                          .fontWeight(400)
                          .margin({ left: 8 });
                      }

                      Row() {
                        if (parseInt(item.num) > 0) {
                          Text(`题目数量：${item.num}`)
                            .fontColor($r('app.color.c_9d9d9d'))
                            .fontSize($r('app.float.font_size_10fp'))
                            .margin({ top: $r('app.float.float_10vp'), bottom: $r('app.float.float_10vp') });
                        } else {
                          Blank()
                        }
                        Text(`导入时间：${item.time}`)
                          .fontColor($r('app.color.c_9d9d9d'))
                          .fontSize($r('app.float.font_size_10fp'))
                          .margin({ top: $r('app.float.float_10vp'), bottom: $r('app.float.float_10vp') });
                      }
                      .width('85%')
                      .justifyContent(FlexAlign.SpaceBetween);
                    }
                    .width('85%')
                    .alignItems(HorizontalAlign.Start)
                    .margin({
                      left: $r('app.float.float_20vp'),
                      top: $r('app.float.float_20vp'),
                      right: $r('app.float.float_20vp'),
                    });

                    Column() {
                      Image($r('app.media.ic_share'))
                        .objectFit(ImageFit.Contain)
                        .size({ width: $r('app.float.float_24vp'), height: $r('app.float.float_24vp') })
                        .onClick(() => {
                          this.handleShare(item)
                        })
                    }
                    .margin({ right: $r('app.float.float_20vp') });
                  }
                }
              }
            });
          }
          .layoutWeight(1)

          if (this.management) {
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
          Column() {
            Image($r('app.media.hotsearch'))
              .objectFit(ImageFit.Contain)
              .size({ width: 117, height: 100 });

            Text('暂无导入题库')
              .fontColor('#9D9D9D')
              .fontSize(14)
              .margin({ top: 28 })
              .textAlign(TextAlign.Center);

            Row() {
              Stack() {
                Image($r('app.media.ic_qqbg'))
                  .objectFit(ImageFit.Contain)
                  .size({ width: 139, height: 40 });

                Row() {
                  Image($r('app.media.ic_qq'))
                    .objectFit(ImageFit.Contain)
                    .size({ width: 22, height: 22 })
                  Text("从QQ导入")
                    .fontSize(14)
                }
                .width('60%')
                .justifyContent(FlexAlign.SpaceBetween)
              }
              .width('50%')
              .onClick(() => {
                this.jumpToQQ()
              })

              Stack() {
                Image($r('app.media.ic_wechatbg'))
                  .objectFit(ImageFit.Contain)
                  .size({ width: 139, height: 40 });

                Row() {
                  Image($r('app.media.ic_wechat'))
                    .objectFit(ImageFit.Contain)
                    .size({ width: 22, height: 22 })
                  Text("从微信导入")
                    .fontSize(14)

                }
                .width('60%')
                .justifyContent(FlexAlign.SpaceBetween)
              }
              .width('50%')
              .onClick(() => {
                this.jumpToWX()
              })
            }
            .width('100%')
            .margin({ top: 20 })

            Text("导入方式：将题库发送至QQ/微信--打开题库--点击右上角--选择其它应用打开--选择【快搜搜题】\n\n" +
              "注：导入文件支持txt、excel格式，word格式请转为txt再导入\n\n" +
              "个人制作以及添加题库遇到问题，请联系客服QQ：1729868682")
              .fontColor('#9D9D9D')
              .fontSize(14)
              .margin({ top: 18 })
              .textAlign(TextAlign.Start)
              .width('90%')

          }
          .margin({ top: 50 })
          .width('100%')
          .height('auto');
        }

        WebParseExcel();
      }
    }
    .hideTitleBar(true)
    .onShown(() => {
      this.getimportList();
    })
  }
}

@Builder
function CustomQuestionPageBuilder() {
  CustomQuestionPage()
}