import { hilog } from "@kit.PerformanceAnalysisKit"
import { systemShare } from '@kit.ShareKit';
import { uniformTypeDescriptor as utd } from '@kit.ArkData';
import { common ,Want } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { ComponentContent } from '@kit.ArkUI';
import { OfficialDialog } from './OfficialDialog';
import router from '@ohos.router'
import MainConstants from "../Constants/MineConstants";
import { faceDetector } from "@kit.CoreVisionKit";
import MineMobClickConstants from "../Constants/MineMobClickConstants";
import { onEventObject } from "@umeng/analytics";
import { productViewManager } from "@kit.StoreKit";
import { audio } from "@kit.AudioKit";


const context = (getContext(this) as common.UIAbilityContext)


@Builder
function buildsupportText() {
  Column() {
    Text('支持我们')
      .fontSize(18)
      .textAlign(TextAlign.Start)
      .fontColor(0xFF3E3E3E)
      .margin({ top: 10, left: 16 })
      .width('100%');
    // 定义渐变颜色数组
    // const gradientColors = ['#9A7013', '#D6B677', '#9E730F', '#FFE083', '#C39118', '#E2B85C'];
    //
    // // 使用 map 方法动态生成星星
    // Row({ space: 10 }) {
    //   gradientColors.map((color, index) => {
    //     Text() {
    //       SymbolSpan($r('sys.symbol.ohos_star'))
    //     }
    //     .fontSize(32)
    //     .textAlign(TextAlign.Start)
    //     .fontColor(color); // 设置渐变颜色
    //   });
    // }

    Text('如果你喜欢我们的应用，请给我们一个五星好评，帮助我们做得更好！')
      .fontSize(16)
      .textAlign(TextAlign.Start)
      .fontColor($r('app.color.c_282828'))
      .padding({ top: 16, left: 16, right: 16 })
      .width('100%');

    Button($r('app.string.i_know'))
      .onClick(() => {
        const request: Want = {
          parameters: {
            bundleName: 'com.chznai.ikst',
          }
        };
        productViewManager.loadProduct(context, request, {
          onError: (error: BusinessError) => {
            hilog.info(0, 'Support', `loadProduct onError. code is ${error.code}, message is ${error.message}`);
          }
        });
        OfficialDialog.closeDialog();
      })
      .margin({ top: 32, bottom: 32 });
  }
  .width('90%')
  .backgroundColor($r('app.color.start_window_background'))
  .borderRadius(10);
}

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
export  struct MinePage {
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
    }, router.RouterMode.Single)
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
        .width('60%') // 限制左侧部分宽度

        Column() {
          Text("签到+2积分")
            .fontSize(12)
            .lineHeight(22)
            .fontColor($r("app.color.c_F75A23"))
            .textAlign(TextAlign.Start)
            .width('100%')
        }
        .width('30%')
        .margin({right:8})
      }
      .alignItems(VerticalAlign.Top)
      .margin({ left: 28, top: 40 ,bottom: 20})
      .visibility(Visibility.Visible)


      // 会员
      Row() {
        Stack({ alignContent: Alignment.TopStart }) {
          Image($r('app.media.rectangle_icon'))
            .objectFit(ImageFit.Cover)
            .width('auto')
            .height(98)

          Button('去充值')
            .fontSize(10)
            .fontColor(Color.Black)
            .backgroundColor('#D4AF37')
            .borderRadius(50)
            .width('auto')
            .height(20)
            .position({ x: 250, y: 6 })
          Stack({ alignContent: Alignment.Center }) {
            Image($r('app.media.subtract_icon'))
              .objectFit(ImageFit.Cover)
              .width(146)
              .height(26)
            Text('VIP会员中心')
              .fontSize(12)
              .fontColor(Color.White)
              .textAlign(TextAlign.Center)
              .width(146)
          }
          .margin({ top: -8, left: 1 })

          Row({ space: 18 }) {
            Column() {
              Image($r('app.media.group_icon'))
                .objectFit(ImageFit.Cover)
                .width(28)
              Text("免广告搜题")
                .fontSize(10)
                .fontColor(Color.White)
                .textAlign(TextAlign.Center)
                .margin({ top: 10 })
            }
            .width('auto')
            .padding(8)
            Column() {
              Image($r('app.media.group_icon'))
                .objectFit(ImageFit.Cover)
                .width(28)
              Text("隐藏悬浮窗")
                .fontSize(10)
                .fontColor(Color.White)
                .textAlign(TextAlign.Center)
                .margin({ top: 10 })
            }
            .width('auto')
            .padding(8)
            Column() {
              Image($r('app.media.group_icon'))
                .objectFit(ImageFit.Cover)
                .width(28)
              Text("指定搜索题库")
                .fontSize(10)
                .fontColor(Color.White)
                .textAlign(TextAlign.Center)
                .margin({ top: 10 })
            }
            .width('auto')
            .padding(8)
            Column() {
              Image($r('app.media.group_icon'))
                .objectFit(ImageFit.Cover)
                .width(28)
              Text("积分会员")
                .fontSize(10)
                .fontColor(Color.White)
                .textAlign(TextAlign.Center)
                .margin({ top: 10 })
            }
            .width('auto')
            .padding(8)
          }
          .width('90%')
          .justifyContent(FlexAlign.SpaceAround)
          .margin({ top: 25,left:10 })
        }
        .width('90%')
        .height('auto')
      }
      .width('100%')
      .justifyContent(FlexAlign.Center)

      List() {
        ListItem() {
          UserListItem({
            name: $r('app.string.my_points'),
            isShow: true,
            value:"15",
            click: () => {
            }
          })
        }
        ListItem() {
          UserListItem({
            name: $r('app.string.operation_settings'),
            isShow: true,
            click: () => {
            }
          })
        }
        ListItem() {
          UserListItem({
            name: $r('app.string.support_us'),
            isShow: true,
            click: () => {
              // 设置为支持我们内容节点
              // OfficialDialog.setContentNode(this.supportContentNode);
              // OfficialDialog.setOptions({ alignment: DialogAlignment.Center, isModal: true });
              // OfficialDialog.openDialog();
              // onEventObject(MineMobClickConstants.MENU_SUPPORT_US);
            }
          })
        }
        ListItem() {
          UserListItem({
            name: $r('app.string.share_friend'),
            isShow: true,
            click: () => {
              this.share()
              // hilog.info(0x001, "text", "分享好友")
            }
          })
        }
        ListItem() {
          UserListItem({
            name: $r('app.string.follow_official_account'),
            isShow: true,
            click: () => {
              // 设置为关注公众号内容节点
              OfficialDialog.setContentNode(this.contentNode);
              OfficialDialog.openDialog();
              onEventObject(MineMobClickConstants.MENU_MY_CODE)
            }
          })
        }

        ListItem() {
          UserListItem({
            name: $r('app.string.help_center'),
            isShow: true,
            click: () => {
              this.jumpToHelpCenter()
            }
          })
        }


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
              // hilog.info(0x0001, "text", "关于我们")
              onEventObject(MineMobClickConstants.MENU_ABOUT)
            }
          })
        }
      }.margin({ top: 40 })
      .alignListItem(ListItemAlign.Center)
    }
    .alignItems(HorizontalAlign.Start)
    .height('100%')
    .width('100%')
  }
}
@Component
struct UserListItem {
  @Prop name: Resource
  isShow: boolean = true
  @Prop value?: string
  click: () => void = () => {

  }

  build() {
    Column() {

      Row({space:10}){
        Text(this.name)
          .fontSize(16)
          .fontColor($r("app.color.c_3e3e3e"))
          .textAlign(TextAlign.Start)
          .padding({ left: 32 })
          .width('auto')
          .height(54)


        if(this.value){
          Text(this.value)
            .fontSize(12)
            .fontColor($r("app.color.c_3e3e3e"))
            .textAlign(TextAlign.Start)
            .padding({ right: 32 })
            .width('auto')
            .height(54)
        }
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)
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