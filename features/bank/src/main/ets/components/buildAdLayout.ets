import { CSJArrayList, CSJConstant, CSJFeedAd, CSJImage, FilterWord } from "@csj/openadsdk";
import { ArrayList, util } from "@kit.ArkTS";
import { customDislikeComponent } from "./CustomDislikeComponent";


@Component
export struct buildAdLayout {
  ad: CSJFeedAd | null = null
  clickViewIds: CSJArrayList<string> = new CSJArrayList()
  creativeViewIds: CSJArrayList<string> = new CSJArrayList()
  rootComponentId: string = util.generateRandomUUID()
  isNeedDislikeDialog: boolean = true
  index: number = 0
  delete: (index: number) => void = () => {
  }

  build() {
    Column() {
      Row() {
        Row() {
          Image(this.ad?.getIcon()?.getImageUrl())
            .height(32)
            .width(32)
            .borderRadius(5)
            .margin({ right: 5 })
            .id(this.clickViewIds.addAdId(util.generateRandomUUID()))

          //描述内容
          Text(this.ad?.getDescription())
            .fontSize(12)
            .textAlign(TextAlign.Start)
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .id(this.clickViewIds.addAdId(util.generateRandomUUID()))
        }
        .height(35)
        .width("85%")
        .justifyContent(FlexAlign.Start);

        Row() {

          Image($r("app.media.tt_dislike")).onClick(() => {
            if (this.isNeedDislikeDialog) { //是否需要走定义Dislike弹窗
              let customDislikeBuilder: WrappedBuilder<[fwList: Array<FilterWord>,
                onSelected: (filterPosition: number, filterName: string) => void,
                onOtherSuggestComment: (suggestionValue: string) => void,
                onUserSuggestDialogCancel: (commentValue: string) => void,
              ]> = wrapBuilder(customDislikeComponent);
              this.ad?.getDislikeDialog()?.setCustomDislikeComponent(customDislikeBuilder)
            }
            this.ad?.getDislikeDialog()?.showDislikeDialog(this)
            this.delete(this.index)
          })
            .height(16)
            .width(16)
            .borderRadius(8)
        }.height(35)
        .width("10%")
        .justifyContent(FlexAlign.End);
      }
      .justifyContent(FlexAlign.SpaceBetween)
      .height(35)
      .width("100%")
      .padding({ left: 10, right: 10, bottom: 4 })

      //视频|图片区域
      Stack({ alignContent: Alignment.BottomStart }) {
        if (this.ad?.getImageMode() == CSJConstant.IMAGE_MODE_VIDEO ||
          this.ad?.getImageMode() == CSJConstant.IMAGE_MODE_VIDEO_VERTICAL) {
          NodeContainer(this.ad?.getAdComponent())
        } else if (this.ad?.getImageList()) {
          Text('图片')
          this.buildImageLayout(this.ad, this.creativeViewIds)
        }

        Flex({ direction: FlexDirection.Column, justifyContent: FlexAlign.End }) {
          if (typeof this.ad?.getAdLogo() === "string") {
            Text(this.ad?.getAdLogo())
              .fontSize(6)
              .height(18)
              .width(30)
              .fontColor(Color.White)
              .backgroundColor("#40ffffff")
              .align(Alignment.Center)
              .padding({ left: 2 })
          } else {
            Image(this.ad?.getAdLogo()).height(20).width(30).objectFit(ImageFit.Auto).onClick((event: ClickEvent) => {
              this.ad?.onAdClick(CSJConstant.TYPE_CLICK_LOGO, event);
            })
          }
        }.width("100%")
        .height(20)
      }.height(200)

      Row() {
        Text(this.ad?.getTitle())
          .fontSize(12)
          .textAlign(TextAlign.Center)
          .id(this.creativeViewIds.addAdId(util.generateRandomUUID())) //设置组件Id，涉及计费;
        Button(this.ad?.getButtonText(), { type: ButtonType.Normal })
          .fontSize(12)
          .borderRadius(5)
          .id(this.creativeViewIds.addAdId(util.generateRandomUUID())) //设置组件Id，涉及计费;
      }
      .justifyContent(FlexAlign.SpaceBetween)
      .height(35)
      .width("100%")
      .padding({
        top: 5,
        bottom: 5,
        left: 10,
        right: 10
      })
    }
    .backgroundColor("#08000000")
    .id(this.rootComponentId) //设置广告容器组件rootId
    .onAppear(() => {
      //注册计费事件
      this.ad?.registerViewForInteraction(this.rootComponentId, this.getUIContext(), this.clickViewIds,
        this.creativeViewIds)
    })
  }

  @Builder
  buildImageLayout(ad: CSJFeedAd, creativeViewIds: CSJArrayList<string>) {
    if (ad.getImageMode() == CSJConstant.IMAGE_MODE_LARGE_IMG) {
      Image(this.getImageUrl(ad))
        .objectFit(ImageFit.Cover)
        .id(creativeViewIds.addAdId(util.generateRandomUUID())) //设置组件Id，涉及计费;
    } else if (ad.getImageMode() == CSJConstant.IMAGE_MODE_SMALL_IMG) {
      Image(this.getImageUrl(ad))
        .objectFit(ImageFit.Cover)
        .id(creativeViewIds.addAdId(util.generateRandomUUID())) //设置组件Id，涉及计费;
    } else if (ad.getImageMode() == CSJConstant.IMAGE_MODE_VERTICAL_IMG) {
      Image(this.getImageUrl(ad))
        .objectFit(ImageFit.Cover)
        .id(creativeViewIds.addAdId(util.generateRandomUUID())) //设置组件Id，涉及计费;
    } else if (ad.getImageMode() == CSJConstant.IMAGE_MODE_GROUP_IMG) {
      Row({ space: 10 }) {
        ForEach((ad.getImageList() ?? new ArrayList<CSJImage>()).convertToArray(), (image: CSJImage) => {
          Image(image.getImageUrl())
            .objectFit(ImageFit.Cover)
            .width(((100 / (ad.getImageList()?.length ?? 0) - 1) + "%"))
            .height("100%")
            .id(creativeViewIds.addAdId(util.generateRandomUUID())) //设置组件Id，涉及计费;
        })
      }.justifyContent(FlexAlign.SpaceBetween).width("100%").alignItems(VerticalAlign.Center).height("100%")
    }
  }

  private getImageUrl(ad: CSJFeedAd): string {
    let imageList = ad.getImageList();
    if (imageList && imageList.length > 0) {
      return imageList[0].getImageUrl()
    }
    return ""
  }
}
