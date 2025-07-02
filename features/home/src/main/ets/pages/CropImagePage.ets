import { ImageCropper } from '@candies/image_cropper';
import * as image_cropper from "@candies/image_cropper";
import { image } from '@kit.ImageKit';
import { ocrToText } from '../utils/OcrToText';
import { CropperConfig } from 'utils/src/main/ets/model/CropperConfig';
import { cameraAppStorage } from '../Constants/CameraAppStorage';
import { SearchBindSheet } from '../components/SearchBindSheet';
import { ProgressLoading } from 'utils/src/main/ets/components/ProgressLoading';




@Component
struct CropImagePage {
  @StorageLink(cameraAppStorage.CAMERA_CAMERA_URI) CameraUri: image.ImageSource | null = null;
  @State image: image.ImageSource | undefined = undefined;
  controller: image_cropper.ImageCropperController = new image_cropper.ImageCropperController();
  @State _config: image_cropper.ImageCropperConfig = new CropperConfig({ controller: this.controller })
  @State SearchText: boolean = false
  @State isLoading: boolean = false
  @State backHome: boolean = false
  @Consume appPathStack: NavPathStack
  RichController: RichEditorController = new RichEditorController()

  @Builder
  SearchTextBuilder() {
    SearchBindSheet()
  }

  aboutToAppear(): void {
  }

  aboutToDisappear(): void {
    this.controller.reset();
    this.CameraUri = null;

  }

  build() {
    NavDestination() {
      RelativeContainer() {
        if (this.CameraUri) {
          ImageCropper(
            {
              image: this.CameraUri,
              config: this._config,
            }
          )
            .margin({ top: 20 })
            .width('90%')
            .height('70%')
            .alignRules({
              top: { anchor: '__container__', align: VerticalAlign.Top },
              middle: { anchor: '__container__', align: HorizontalAlign.Center }
            })
        }

        Row() {
          Row() {
            Text("返回")
              .fontSize(12)
              .textAlign(TextAlign.Center)
          }
          .onClick(() => {
            if (this.backHome) {
             this.appPathStack.popToIndex(-1)

            } else {
             this.appPathStack.pop()
            }

          })
          .justifyContent(FlexAlign.Center)
          .backgroundColor('#ccc')
          .width(40)
          .height(40)
          .borderRadius(25)

          Row() {
            Image($r("app.media.confirm"))
              .fillColor(Color.White)
              .width(30)
              .aspectRatio(1)
              .fillColor("#000")

          }
          .backgroundColor("#CA6928")
          .onClick(() => {
            this.backHome = true
            this.isLoading = true
            this.controller.getCroppedImage().then((pixelMap) => {
              if (pixelMap) {
                ocrToText.loadImage(pixelMap).then(() => {
                  this.SearchText = true
                  this.isLoading = false
                })

              }
            })

          })
          .justifyContent(FlexAlign.Center)
          .width(50)
          .height(50)
          .borderRadius(25)

          Row() {
            Image($r("app.media.rotate"))
              .width(20)
              .height(20)
          }
          .onClick(() => {
            this.controller.rotate({ rotateCropRect: false })
          })
          .justifyContent(FlexAlign.Center)
          .backgroundColor('#ccc')
          .width(40)
          .height(40)
          .borderRadius(25)
        }
        .justifyContent(FlexAlign.SpaceAround)
        .width('100%')
        .margin({
          bottom: 30
        })

        .alignRules({
          bottom: { anchor: "__container__", align: VerticalAlign.Bottom },
        })

        if (this.isLoading) {
          ProgressLoading()
        }
      }
      .bindSheet($$this.SearchText, this.SearchTextBuilder, {
        showClose: false,
        height: '90%',
        dragBar: true,
        onWillDismiss: (dismissSheetAction: DismissSheetAction) => {
          if (dismissSheetAction.reason !== DismissReason.SLIDE_DOWN) {
            dismissSheetAction.dismiss()
          }
        }
      })
      .backgroundColor('#000000')
      .height('100%')
      .width('100%')
    }
    .hideTitleBar( true)
    .onBackPressed(()=>{
      if (this.backHome) {
        this.appPathStack.popToIndex(-1)
      }
      return this.backHome
    })
  }
}
@Builder
function CropImagePageBuilder() {
  CropImagePage()
}