
import { image } from "@kit.ImageKit"
import { ocrToText } from "./OcrToText"
import { camera } from "@kit.CameraKit"
import { BusinessError } from "@kit.BasicServicesKit"



export class CameraManager {
  private cameraManager: camera.CameraManager | null = null
  private cameraDevice: camera.CameraDevice | null = null
  private cameraInput: camera.CameraInput | null = null // 相机输入流
  private cameraOutput: camera.CameraOutput | null = null
  private imageOutput: camera.CameraOutput | null = null
  private cameraProfile: camera.Profile | null = null
  private session: camera.Session | null = null
  private imageReceiver: image.ImageReceiver | null = null
  private imgSurfaceId: string = ""
  private imgWidth: number = 1920
  private imgHeight: number = 1080
  context?: Context
  async initImageReceiver() {
    try {
      this.imageReceiver =
        image.createImageReceiver({ width: this.imgWidth, height: this.imgHeight }, image.ImageFormat.JPEG, 8)
      this.imgSurfaceId = await this.imageReceiver.getReceivingSurfaceId()
      this.onImageArrival(this.imageReceiver);
    } catch (error) {
    }

  }
  onImageArrival(receiver: image.ImageReceiver): void {
    receiver.on('imageArrival', () => {
      receiver.readNextImage((err: BusinessError, nextImage: image.Image) => {
        if (err || nextImage === undefined) {
          return;
        }
        nextImage.getComponent(image.ComponentType.JPEG, async (err: BusinessError, imgComponent: image.Component) => {
          if (err || imgComponent === undefined) {
          }
          if (imgComponent.byteBuffer) {
            let width = nextImage.size.width;
            let height = nextImage.size.height;
            let stride = imgComponent.rowStride;

            if (stride == width) {
              let pixelMap = await image.createPixelMap(imgComponent.byteBuffer, {
                size: { height: height, width: width },
                srcPixelFormat: 8,
              })
              if (pixelMap){ ocrToText.loadImage(pixelMap)}
            } else {
              const dstBufferSize = width * height * 1.5
              const dstArr = new Uint8Array(dstBufferSize)
              for (let j = 0; j < height * 1.5; j++) {
                const srcBuf = new Uint8Array(imgComponent.byteBuffer, j * stride, width)
                dstArr.set(srcBuf, j * width)
              }
              let pixelMap = await image.createPixelMap(dstArr.buffer, {
                size: { height: height, width: width },
                srcPixelFormat: 8,
              })
              if (pixelMap){ ocrToText.loadImage(pixelMap)}
            }
          } else {
            console.error('byteBuffer is null');
          }
          nextImage.release();

        })
      })
    })
  }

  async initCamera(surfaceId: string,) {

    try {

      this.cameraManager = camera.getCameraManager(this.context)
      const cameraList = this.cameraManager.getSupportedCameras()
      if (cameraList.length >= 1) {
        this.cameraDevice = cameraList[0]
        this.cameraInput = this.cameraManager.createCameraInput(this.cameraDevice)

        await this.cameraInput.open()


        const cameraCapability =
          this.cameraManager.getSupportedOutputCapability(this.cameraDevice, camera.SceneMode.NORMAL_PHOTO)

        this.cameraProfile = cameraCapability.previewProfiles.find(item => item.size.width === this.imgWidth &&
          item.size.height === this.imgHeight) as camera.Profile

        this.cameraOutput = this.cameraManager.createPreviewOutput(this.cameraProfile, surfaceId)

        await this.initImageReceiver()

        this.imageOutput = this.cameraManager.createPreviewOutput(this.cameraProfile, this.imgSurfaceId)

        this.session = this.cameraManager.createSession(camera.SceneMode.NORMAL_PHOTO)as camera.VideoSession;
        this.session.beginConfig()
        this.session.addInput(this.cameraInput)
        this.session.addOutput(this.cameraOutput)
        this.session.addOutput(this.imageOutput)
        this.session.commitConfig()
        await this.session.start()

      } else {
        throw new Error("未读取到摄像头")
      }
    } catch (error) {

    }

  }

  // 释放
  releaseCamera() {
    this.session?.stop()
    this.cameraInput?.close()
    this.cameraOutput?.release()
    this.imageOutput?.release()
    this.session?.release()
    this.cameraManager = null
    this.cameraDevice = null
    this.cameraInput = null // 相机输入流
    this.cameraOutput = null
    this.imageOutput = null
    this.cameraProfile = null
    this.session = null
    this.imageReceiver = null
    this.imgSurfaceId = ""
  }
}

export const cameraManager = new CameraManager()
