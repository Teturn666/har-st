import { curves, router } from '@kit.ArkUI';
import { camera } from '@kit.CameraKit';
import { image } from '@kit.ImageKit';
import { albumPicker } from '../utils/AlbumPicker';
import { createAtManager } from '../utils/CreateAtManager';
import HomeConstants from '../Constants/HomeConstants';
import { cameraAppStorage } from '../Constants/CameraAppStorage';

import('./CropImagePage')


@Entry({ routeName: 'photoSearchPage' })
@Component
struct PhotoSearchPage {
  @State isSwitchFlash: boolean = false;
  @State surfaceId: string = ''; //相机id
  @State context: Context = this.getUIContext().getHostContext()!;
  @StorageLink(cameraAppStorage.CAMERA_THUMBNAIL) photoUri: image.PixelMap | null = null;
  mXComponentController: XComponentController = new XComponentController;

  aboutToAppear(): void {
    AppStorage.setOrCreate(cameraAppStorage.CAMERA_RESTART_CAMERA, true)
  }

  aboutToDisappear(): void {
    AppStorage.setOrCreate(cameraAppStorage.CAMERA_RESTART_CAMERA, false)
    createAtManager.releaseCamera()
  }


  SelectImg() {
    albumPicker.SelectImg((img: image.ImageSource) => {
      if (img) {
        AppStorage.setOrCreate(cameraAppStorage.CAMERA_CAMERA_URI, img);
        router.pushNamedRoute({
          name: HomeConstants.ROUTER_CROP_IMAGE,
        })
      }
    })
  }

  build() {
    RelativeContainer() {
      Column() {
        XComponent({
          type: XComponentType.SURFACE,
          controller: this.mXComponentController
        })
          .onLoad(async () => {
            this.surfaceId = this.mXComponentController.getXComponentSurfaceId();
            createAtManager.surfaceId = this.surfaceId
            createAtManager.cameraShooting()
          })
      }
      .height('100%')
      .width('100%')

      Row() {
        Row() {
          Image($r('app.media.flashlight'))
            .width(30)
            .aspectRatio(1)
            .fillColor(Color.White)
            .onClick(() => {
              this.isSwitchFlash = !this.isSwitchFlash
              if (this.isSwitchFlash) {
                createAtManager.setPhotoFlashMode(camera.FlashMode.FLASH_MODE_ALWAYS_OPEN)
              } else {
                createAtManager.setPhotoFlashMode(camera.FlashMode.FLASH_MODE_CLOSE)
              }
            })
        }
        .width(40)
        .justifyContent(FlexAlign.Center)
        .aspectRatio(1)
        .backgroundColor('#ff4e4d4d')
        .borderRadius('50%')

        Row() {
          Column({ space: 8 }) {
            Image($r('app.media.camera'))
              .width(28)
              .height(23)

              .fillColor(Color.White)
            Text('拍照')
              .fontColor(Color.White)
              .fontSize(14)
          }
          .justifyContent(FlexAlign.Center)
          .width(70)
          .aspectRatio(1)
          .borderRadius(35)
          .backgroundColor('#ffea8c3c')
          .onClick(() => {
            createAtManager.capture().then(() => {
              router.pushNamedRoute({
                name: HomeConstants.ROUTER_CROP_IMAGE,
              })
            })

          })
        }

        Row() {
          if (this.photoUri) {
            Column({ space: 5 }) {
              Image(this.photoUri)
                .borderWidth(this.photoUri === null ? 0 : 1)
                .borderColor(Color.White)
                .width(50)
                .height(60)
                .borderRadius(5)
                .animation({ curve: curves.springMotion() })
                .onClick(() => {
                  this.SelectImg()
                })
              Text('相册')
                .fontSize(14)
                .fontColor(Color.White)
            }
          } else {
            Column({ space: 8 }) {
              Image($r('app.media.album'))
                .fillColor(Color.White)
                .width(40)
                .aspectRatio(1)
              Text('相册')
                .fontColor(Color.White)
            }
            .onClick(() => {

              this.SelectImg()
            })
            .margin({ top: 5 })
          }
        }
      }
      .margin({
        bottom: 30
      })
      .padding(30)
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)
      .alignRules({
        bottom: { anchor: '__container__', align: VerticalAlign.Bottom },
      })

      Row() {
        Image($r('sys.media.ohos_ic_public_arrow_left'))
          .width(30)
          .aspectRatio(1)
          .backgroundColor('#ff4e4d4d')
          .borderRadius('50%')
          .fillColor(Color.White)

      }
      .onClick(() => {
        createAtManager.releaseCamera()
        router.replaceUrl({
          url: HomeConstants.ROUTER_MAIN_PAGE,
        })
      })
      .margin({ top: 20, left: 20 })
      .backgroundColor('#ff4e4d4d')
      .alignRules({
        top: { anchor: '__container__', align: VerticalAlign.Top },
      })
      .justifyContent(FlexAlign.Center)
      .width(30)
      .aspectRatio(1)
      .borderRadius('50%')
    }
    .height('100%')
    .width('100%')
  }
}