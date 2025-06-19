import { TitleBar } from 'widget';
import { router } from '@kit.ArkUI';
import HomeConstants from '../Constants/HomeConstants';
import { WebParseExcel } from '../components/WebParseExcel';
import { HomeModel } from '../model/HomeModel';
import { BankListRes } from 'db';
import promptAction from '@ohos.promptAction';
import { BusinessError, emitter } from '@kit.BasicServicesKit';
import { common, Want } from '@kit.AbilityKit';
import { ToastUtils, EmitterConstants, } from 'utils/Index'

import('./HelpPage');
import('./CustomizedBankPage');


const TAG = 'CustomQuestionPage';

@Entry({ routeName: "customQuestionPage" })
@Component
struct CustomQuestionPage {
  @State homeModel: HomeModel = HomeModel.getInstance();
  @State questionBanks: BankListRes[] = [];
  @State isLoading: boolean = false;

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

  onPageShow(): void {
    this.getimportList();
  }

  aboutToAppear(): void {
    this.getimportList();
  }

  @Builder
  rightBuilder() {
    Text('帮助')
      .fontColor($r('app.color.c_F75A23'))
      .onClick(() => {
        router.pushNamedRoute({
          name: HomeConstants.ROUTER_HELP_PAGE,
        });
      });
  }

  async handleDelete(qid: number) {
    if (this.isLoading) {
      return;
    } // 防止重复操作
    this.isLoading = true;
    try {
      await this.homeModel.deleteTable(qid);
      console.log(`Deleted qid: ${qid}`);
      // 按索引删除特定项目，而不是清空整个数组
      const index = this.questionBanks.findIndex(bank => bank.qid === qid);
      if (index !== -1) {
        this.questionBanks.splice(index, 1);
      }
      promptAction.showToast({ message: '删除成功', duration: 2000 });
      emitter.emit(EmitterConstants.EM_REFRESH_HOME)
    } catch (error) {
      console.error(`Delete failed: ${error}`);
      promptAction.showToast({ message: '删除失败', duration: 2000 });
    } finally {
      this.isLoading = false;
    }
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

  build() {
    Column() {
      TitleBar({
        title: '自定义题库',
        backClick: () => {
          router.back();
        },
        rightBuilderParam: this.rightBuilder,
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
            router.pushNamedRoute({
              name: HomeConstants.ROUTER_CUSTOMIZED_BANK_PAGE,
            });
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
      Row() {
        Image($r('app.media.ic_import'))
          .width(85);
      }
      .width('90%')
      .margin({ top: 10, left: 10 })
      .alignItems(VerticalAlign.Top)
      .justifyContent(FlexAlign.Start);

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
                    Image($r('app.media.ic_remove'))
                      .objectFit(ImageFit.Contain)
                      .size({ width: $r('app.float.float_50vp'), height: $r('app.float.float_50vp') })
                      .onClick(() => this.handleDelete(item.qid));
                  }
                  .margin({ right: $r('app.float.float_20vp') });
                }
              }
            }
          });
        }
        .layoutWeight(1)
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
        }
        .margin({ top: 50 })
        .width('100%')
        .height('auto');
      }

      WebParseExcel();
    }
  }
}