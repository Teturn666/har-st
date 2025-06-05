import { camera } from "@kit.CameraKit"
import { image } from "@kit.ImageKit"
import json from "@ohos.util.json"

import { ocrToText } from "./OcrToText"


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
  // map: image.PixelMap | null = null   //emit 传递存在问题
  private imgWidth: number = 1920
  private imgHeight: number = 1080

  // callback:(imp:image.PixelMap)=>void=()=>{}


  async initImageReceiver() {
    try {
      this.imageReceiver =
        image.createImageReceiver({ width: this.imgWidth, height: this.imgHeight }, image.ImageFormat.JPEG, 8)
      this.imgSurfaceId = await this.imageReceiver.getReceivingSurfaceId()
      this.imageReceiver.on("imageArrival", async () => {
        try {
          const img = await this.imageReceiver?.readNextImage()
          if (!img) {
            return
          }
          const com = await img?.getComponent(image.ComponentType.JPEG)
          if (!com) {
            return
          }
          if (!com.byteBuffer) {
            return
          }
          // changeMap.Map(com.byteBuffer)
          // emitter.emit("upPix", { data: { "map": com?.byteBuffer } })

          image.createPixelMap(com?.byteBuffer, {
            size: {
              width: this.imgWidth,
              height: this.imgHeight
            },
            srcPixelFormat: 8,
          }, async (err, pixelMap) => {
            pixelMap.rotateSync(180)
            // emitter.emit("upPix", { data: { "map": pixelMap } })
            ocrToText.loadImage(pixelMap)
            // this.map=pixelMap
            // this.callback(pixelMap)
          })
        } catch (error) {
          AlertDialog.show({ message: JSON.stringify(error) })
        }
      })
    } catch (error) {
      AlertDialog.show({ message: JSON.stringify(error) })
    }

  }


  async initCamera(surfaceId: string,) {

    try {

      this.cameraManager = camera.getCameraManager(getContext())
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

        this.session = this.cameraManager.createSession(camera.SceneMode.NORMAL_PHOTO)
        this.session.beginConfig()
        this.session.addInput(this.cameraInput)
        this.session.addOutput(this.cameraOutput)
        this.session.addOutput(this.imageOutput)
        this.session.commitConfig()
        await this.session.start()

        console.log(json.stringify(cameraCapability.previewProfiles))

      } else {
        throw new Error("未读取到摄像头")
      }
    } catch (error) {
      AlertDialog.show({ message: error.message })
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