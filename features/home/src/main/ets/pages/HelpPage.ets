import { TitleBar } from 'widget'
import { common, Want } from '@kit.AbilityKit';
import { EmitterConstants, ToastUtils } from 'utils';
import { BusinessError } from '@kit.BasicServicesKit';


@Component
struct HelpPage {
  @Consume appPathStack: NavPathStack
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
  aboutToAppear(): void {
    console.log('心事帮助页面加载成功');
  }

  build() {
    NavDestination() {
      Column() {
        TitleBar({
          title: '题库导入帮助',
          backClick: () => {
            this.appPathStack.pop()
          },
        }).width('100%')
        Flex({ direction: FlexDirection.Column, justifyContent: FlexAlign.Start }) {
          // 标题
          Text("符合以下格式的TXT和Excel文件题库可直接导入，否则，需要将题库在电脑上修改为以下格式。")
            .fontSize(14)
            .fontWeight(500)
            .margin({ top: 10 })

          // 第一部分：基础说明
          Text("TXT格式说明")
            .fontSize(14)
            .fontWeight(600)
            .margin({ top: 10 })
          Text("第一种，答案在题干的括号里；")
            .fontSize(14)
            .fontWeight(400)
            .margin({ top: 10 })

          Text("第二种：单独一行标注答案，必须含“答案”这个关键词，例如以“正确答案”/“参考答案”/“答案”开头。\n以上两种都要求：")
            .fontSize(14)
            .fontWeight(400)
            .margin({ top: 10 })
          Text("1.每道题目开头必须带有数字题号，例如1、2、3、，数字不能带括号；且题干只能一行写完，不允许分行；")
            .fontSize(14)
            .fontWeight(400)
            .margin({ top: 10 })
          Text("2.每个选项前面必须带ABCD标识，不支持带括号的（A）、（B）这种；同一个选项必须同一行写完，不允许分行；不同选项可以同一行，不强制要求分行。")
            .fontSize(14)
            .fontWeight(400)
            .margin({ top: 10 })
          Text("3.题干和选项不允许同一行")
            .fontSize(14)
            .fontWeight(400)
            .margin({ top: 10 })
          Text("4.判断题支持的答案格式：√/×；正确/错误；Y/N；对/错")
            .fontSize(14)
            .fontWeight(400)
            .margin({ top: 10 })

          Text("Excel格式说明")
            .fontSize(14)
            .fontWeight(600)
            .margin({ top: 10 })

          Text("文件格式：可以是xls和xlsx；")
            .fontSize(14)
            .fontWeight(400)
            .margin({ top: 10 })

          Text("内容格式：第一列：题干，第二列：答案，第三列及后面列都是选项，第二行开始按照题干-答案-选项A-选项B-…-选项G的顺序填写。")
            .fontSize(14)
            .fontWeight(400)
            .margin({ top: 10 })

          Text("注：导入文件支持txt、excel格式，word格式请转为txt再导入")
            .fontSize(14)
            .fontWeight(600)
            .margin({ top: 10 })

          Text("个人制作以及添加题库遇到问题，请联系客服\n QQ:1729868682")
            .fontSize(14)
            .fontWeight(400)
            .margin({ top: 10 })
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
        }
        .padding({ left: 18, right: 18 })

      }
      .width('100%')

    }
    .hideTitleBar( true)
  }
}
@Builder
function HelpPageBuilder() {
  HelpPage()
}



