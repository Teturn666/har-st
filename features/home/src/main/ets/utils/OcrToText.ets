import { fileIo, picker } from "@kit.CoreFileKit"
import { hilog } from "@kit.PerformanceAnalysisKit"
import { BusinessError, emitter } from "@kit.BasicServicesKit"
import { image } from "@kit.ImageKit"
import { textRecognition } from "@kit.CoreVisionKit"
import { router } from "@kit.ArkUI"
import { onEventObject } from "@umeng/analytics"
import HomeMobClickConstants from "../Constants/HomeMobClickConstants"
import HomeConstants from "../Constants/HomeConstants"


export  class  OcrToText {
  private imageSource?: image.ImageSource
  chooseImage?: PixelMap
  dataValues:string=""


  // private openPhoto(): Promise<string> {
  //   return new Promise<string>((resolve, reject) => {
  //     let photoPicker = new picker.PhotoViewPicker()
  //     photoPicker.select({
  //       MIMEType: picker.PhotoViewMIMETypes.IMAGE_TYPE, maxSelectNumber: 1
  //     }).then((res: picker.PhotoSelectResult) => {
  //       resolve(res.photoUris[0])
  //     }).catch((err: BusinessError) => {
  //
  //       hilog.error(0x0000, 'OCRDemo', `Failed to get photo image uri. code：${err.code}，message：${err.message}`)
  //       resolve('')
  //     })
  //   })
  // }

   loadImage(map:image.PixelMap,search?:boolean) {

      // let fileSource = await fileIo.open(name, fileIo.OpenMode.READ_ONLY)
      // this.imageSource = image.createImageSource(fileSource.fd)
      // this.chooseImage = await this.imageSource.createPixelMap()
        this.ocrToText(map,search)

  }
  private async ocrToText(map:image.PixelMap,search?:boolean) {
    // emitter.on("upPix", (event) => {
    //   this.chooseImage = event.data!["map"]
    // })
    if (!map) {
      return
    }
    // 调用文本识别接口
    let visionInfo: textRecognition.VisionInfo = {
      pixelMap:map
    };
    let textConfiguration: textRecognition.TextRecognitionConfiguration = {
      isDirectionDetectionSupported: false
    };
    textRecognition.recognizeText(visionInfo, textConfiguration,
      (error: BusinessError, data: textRecognition.TextRecognitionResult) => {
        // 识别成功，获取对应的结果
        if (error.code == 0) {
          let recognitionString = data.toString()
          hilog.info(0x0000, 'OCRDemo', `Succeeded in recognizing text：${recognitionString}`)
          // 将结果更新到Text中显示
          // this.dataValues = data.value
          emitter.emit("dataText", { data: { "text": data.value } })
          if (search){
            this.jumpToSearchResult()
          }

        }
        if (this.chooseImage && this.imageSource) {
          this.chooseImage.release()
          this.imageSource.release()
        }
      })
  }
  //跳转到搜索结果页
  private jumpToSearchResult() {

    router.pushNamedRoute({
      name: HomeConstants.ROUTER_SEARCH_RESULT
    })
    onEventObject(HomeMobClickConstants.E_CLICK_EXPORT_ALLROUNDSEARCH)
  }
}
export  const ocrToText = new OcrToText ()