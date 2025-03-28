import { hilog } from "@kit.PerformanceAnalysisKit"
import { systemShare } from '@kit.ShareKit';
import { uniformTypeDescriptor as utd } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { ComponentContent } from '@kit.ArkUI';
import { OfficialDialog } from './OfficialDialog';
import router from '@ohos.router'
import MainConstants from "../Constants/MineConstants";
import { faceDetector } from "@kit.CoreVisionKit";

const context = (getContext(this) as common.UIAbilityContext)

@Builder
function buildText() {
  Column() {
    Text("关注题库公众号")
      .fontSize(18)
      .textAlign(TextAlign.Start)
      .fontColor($r('app.color.c_9d9d9d'))
      .margin({ top: 10, left: 16 })
      .width('100%')
    Image('http://xxqg.thootv.com/images/wxgzh1.jpg').padding({ top: 10, left: 16, right: 16 }).width('100%')
    Text("欢迎关注题库公众号，保持题库最新更全，微信公众号搜索“答题大全”添加关注即可")
      .fontSize(16)
      .textAlign(TextAlign.Start)
      .fontColor($r('app.color.c_282828'))
      .padding({ top: 16, left: 16, right: 16 })
      .width('100%')
    Button($r('app.string.i_know'))
      .onClick(() => {
        OfficialDialog.closeDialog()
      })
      .margin({ top: 32, bottom: 32 })
  }.width('90%')
  .backgroundColor($r('app.color.start_window_background'))
  .borderRadius(10)
}

@Entry
@Component
export struct MinePage {
  @State message: string = "hello"
  private ctx: UIContext = this.getUIContext();
  private contentNode: ComponentContent<Object> =
    new ComponentContent(this.ctx, wrapBuilder(buildText));

  aboutToAppear(): void {
    OfficialDialog.setContext(this.ctx);
    OfficialDialog.setContentNode(this.contentNode);
    OfficialDialog.setOptions({ alignment: DialogAlignment.Center, isModal: true });
  }

  private jumpToSearchResult() {
    router.pushNamedRoute({ name: MainConstants.ROUTER_ABOUT_US })
  }

  private jumpToHelpCenter() {
    router.pushNamedRoute({
      name: MainConstants.ROUTER_WEB, params: {
        url: "https://ti.iksdt.com/static/doc/help/help.html",
        title: "帮助中心"
      }
    })
  }

  private async share() {
    let shareData: systemShare.SharedData = new systemShare.SharedData({
      utd: utd.UniformDataType.TEXT,
      content: '我正在使用快搜答题神器，支持各类答题平台，快来一起轻松答题吧！官方下载链接：http://app.iksdt.com',
      title: '快搜搜题',
      description: '我正在使用快搜答题神器，支持各类答题平台，快来一起轻松答题吧！官方下载链接：http://app.iksdt.com',
      thumbnail: new Uint8Array()
    });

    let controller: systemShare.ShareController = new systemShare.ShareController(shareData);
    let context = getContext(this) as common.UIAbilityContext;
    controller.show(context, {
      selectionMode: systemShare.SelectionMode.SINGLE,
      previewMode: systemShare.SharePreviewMode.DEFAULT,
    }).then(() => {

    }).catch((error: BusinessError) => {

    });
  }

  private async goFeedback() {
    context.openLink(MainConstants.FEEDBACK_URL, { appLinkingOnly: false })
      .then(() => {
        console.info('Link opened successfully');
      })
      .catch((error: BusinessError) => {
        console.error('Failed to open link:', error);
      });
  }

  // private async goWeb(){
  //   let shareData: systemShare.SharedData = new systemShare.SharedData({
  //     utd: utd.UniformDataType.HYPERLINK,
  //     content: 'https://crmeb.yweiai.com/chat/pc?noCanClose=1&kefu_id=12&token=075774b0dae195a3b971d8f98388d502&openid=harmony&nickName=harmony', // 仅为示例 使用时请替换为自己的链接
  //     title: '快搜搜题意见反馈',
  //     description: '快搜搜题意见反馈',
  //     // thumbnail: new Uint8Array() // 推荐传入适合的缩略图 不传则显示默认html图标
  //   });
  //   let controller: systemShare.ShareController = new systemShare.ShareController(shareData);
  //   let context = getContext(this) as common.UIAbilityContext;
  //   controller.show(context, {
  //     selectionMode: systemShare.SelectionMode.SINGLE,
  //     previewMode: systemShare.SharePreviewMode.DEFAULT,
  //   }).then(() => {
  //     console.info('ShareController show success.');
  //   }).catch((error: BusinessError) => {
  //     console.error(`ShareController show error. code: ${error.code}, message: ${error.message}`);
  //   });
  // }

  build() {
    Column() {
      Row() {
        Image($r('app.media.user_icon'))
          .objectFit(ImageFit.Contain)
          .width(48)
          .height(48)
        Column() {
          Text("游客")
            .fontSize(14)
            .fontColor($r("app.color.c_3e3e3e"))
            .textAlign(TextAlign.Start)
            .padding({ left: 16 })
            .lineHeight(20)
          Text("欢迎使用快搜搜题")
            .fontSize(12)
            .fontColor($r("app.color.c_9d9d9d"))
            .textAlign(TextAlign.Start)
            .padding({ left: 16 })
            .lineHeight(20)
        }.alignItems(HorizontalAlign.Start)
      }.alignItems(VerticalAlign.Top)
      .margin({ left: 28, top: 40 }).visibility(Visibility.None)

      List() {
        // ListItem() {
        //   UserListItem({
        //     name: $r('app.string.share_friend'),
        //     isShow: true,
        //     click: () => {
        //       this.share()
        //       // hilog.info(0x001, "text", "分享好友")
        //     }
        //   })
        // }

        ListItem() {
          UserListItem({
            name: $r('app.string.follow_official_account'),
            isShow: true,
            click: () => {
              OfficialDialog.openDialog()
            }
          })
        }

        // ListItem() {
        //   UserListItem({
        //     name: $r('app.string.help_center'),
        //     isShow: true,
        //     click: () => {
        //       this.jumpToHelpCenter()
        //     }
        //   })
        // }
        //
        ListItem() {
          UserListItem({
            name: $r('app.string.feedback'),
            isShow: true,
            click: () => {
              this.goFeedback()
              // hilog.info(0x0001, "text", "意见反馈")
            }
          })
        }

        ListItem() {
          UserListItem({
            name: $r('app.string.about_us'),
            isShow: false,
            click: () => {
              this.jumpToSearchResult()
              hilog.info(0x0001, "text", "关于我们")
            }
          })
        }
      }.margin({ top: 40 })
      .alignListItem(ListItemAlign.Center)
    }.alignItems(HorizontalAlign.Start)
    .height('100%')
    .width('100%')

  }
}

@Component
struct UserListItem {
  @Prop name: Resource
  isShow: boolean = true
  click: () => void = () => {

  }

  build() {
    Column() {
      Text(this.name)
        .fontSize(16)
        .fontColor($r("app.color.c_3e3e3e"))
        .textAlign(TextAlign.Start)
        .padding({ left: 32 })
        .width('100%')
        .height(54)
      Row() {

      }
      .width('90%')
      .height(1)
      .backgroundColor($r("app.color.c_ebebeb"))
      .margin({ left: 32, right: 32 })
      // .linearGradient({
      //   angle: 90,
      //   colors: [
      //     [$r("app.color.c_transparent"), 0.0],
      //     [$r("app.color.c_ebebeb"), 1],
      //   ]
      // })
      .visibility(this.isShow ? Visibility.Visible : Visibility.Hidden)
    }.onClick(() => this.click()).width('100%')
  }
}