import { ImageCropper } from '@candies/image_cropper';
import * as image_cropper from "@candies/image_cropper";

import { image } from '@kit.ImageKit';
import { router } from '@kit.ArkUI';
import { ocrToText } from '../utils/OcrToText';
import { createAtManager } from '../utils/CreateAtManager';
import { CropperConfig } from '../model/CropperConfig';
import { cameraAppStorage } from '../Constants/CameraAppStorage';

@Entry({ routeName: 'cropImagePage' })
@Component
struct CropImagePage {
  @StorageLink(cameraAppStorage.CAMERA_CAMERA_URI) CameraUri: image.ImageSource | null = null;
  @State image: image.ImageSource | undefined = undefined;
  controller: image_cropper.ImageCropperController = new image_cropper.ImageCropperController();
  @State _config: image_cropper.ImageCropperConfig = new CropperConfig({ controller: this.controller })
  aboutToAppear(): void {
  }

  aboutToDisappear(): void {
    this.controller.reset();
    this.CameraUri = null;
  }
onPageHide(): void {
  this.controller.reset();
  this.CameraUri = null;
}
  build() {
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
            .fontSize(14)
            .textAlign(TextAlign.Center)
        }
        .onClick(() => {
          router.back()
        })
        .justifyContent(FlexAlign.Center)
        .backgroundColor('#ccc')
        .width(50)
        .height(50)
        .borderRadius(25)

        Row() {
          Image($r("app.media.confirm"))
            .width(30)
            .aspectRatio(1)
            .fillColor("#000")
        }
        .onClick(() => {
          createAtManager.releaseCamera()
          this.controller.getCroppedImage().then((pixelMap) => {
            if (pixelMap){
              ocrToText.loadImage(pixelMap,true)
            }
          })

        })
        .justifyContent(FlexAlign.Center)
        .backgroundColor('#ccc')
        .width(50)
        .height(50)
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
    }
    .backgroundColor('#000000')
    .height('100%')
    .width('100%')
  }
}