import { fileIo, picker } from "@kit.CoreFileKit"
import { BusinessError } from "@kit.BasicServicesKit"
import { hilog } from "@kit.PerformanceAnalysisKit"
import { ocrToText } from "./OcrToText"
import { image } from "@kit.ImageKit"
import HomeConstants from "../Constants/HomeConstants"
import { onEventObject } from "@umeng/analytics"
import HomeMobClickConstants from "../Constants/HomeMobClickConstants"

export class SelectImage {
  async selectImg() {
    await this.selectImgTo()
    return false
  }

  async selectImgTo() {
    let uri = await this.openPhoto()
    if (uri === undefined) {
      hilog.error(0x0000, 'OCRDemo', "Failed to get uri.")
      return
    }
    this.loadImage(uri)

  }

  private async loadImage(name: string) {
    let fileSource = fileIo.openSync(name, fileIo.OpenMode.READ_ONLY)
    let imageSource = image.createImageSource(fileSource.fd)
    let chooseImage = await imageSource.createPixelMap()
    ocrToText.loadImage(chooseImage, true)


  }

  private openPhoto() {
    return new Promise<string>((resolve, reject) => {
      let photoPicker = new picker.PhotoViewPicker()
      photoPicker.select({
        MIMEType: picker.PhotoViewMIMETypes.IMAGE_TYPE, maxSelectNumber: 1
      }).then((res: picker.PhotoSelectResult) => {
        resolve(res.photoUris[0])
      }).catch((err: BusinessError) => {

        hilog.error(0x0000, 'OCRDemo', `Failed to get photo image uri. code：${err.code}，message：${err.message}`)
        resolve('')
      })
    })
  }
}

export const selectImage = new SelectImage()