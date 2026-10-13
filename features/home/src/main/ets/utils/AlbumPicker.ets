import { photoAccessHelper } from "@kit.MediaLibraryKit"
import { fileIo } from "@kit.CoreFileKit";
import { image } from "@kit.ImageKit";
import { dataSharePredicates } from "@kit.ArkData";
import { cameraAppStorage } from "../Constants/CameraAppStorage";


export class AlbumPicker {
  ctx?: Context
  photoPicker: photoAccessHelper.PhotoViewPicker | null = null
  private ima: image.ImageSource | null = null

  async SelectImg(callback:(img:image.ImageSource)=>void) {

    this.photoPicker = new photoAccessHelper.PhotoViewPicker()
    AppStorage.setOrCreate(cameraAppStorage.CAMERA_RESTART_CAMERA,true )
    let PhotoResult = await this.photoPicker.select({
      isOriginalSupported: true,
      maxSelectNumber: 1,
    })
    if (PhotoResult?.photoUris?.length != 0) {
      let uri = PhotoResult.photoUris[0]
      let file = fileIo.openSync(uri, fileIo.OpenMode.READ_ONLY);
      let buffer = new ArrayBuffer(4096);
      let readLen = fileIo.readSync(file.fd, buffer);
      this.ima = image.createImageSource(file.fd);
      callback(this.ima)
      fileIo.closeSync(file.fd)
      this.ima= null
    }


  }
 async getThumbnail() {
    let predicates: dataSharePredicates.DataSharePredicates = new dataSharePredicates.DataSharePredicates();
    predicates.orderByDesc(photoAccessHelper.PhotoKeys.DATE_ADDED); // 按拍摄时间降序排列
    let fetchOptions: photoAccessHelper.FetchOptions = {
      fetchColumns: [],
      predicates: predicates
    };
    let photoHelper = photoAccessHelper.getPhotoAccessHelper(this.ctx);
    let fetchResult: photoAccessHelper.FetchResult<photoAccessHelper.PhotoAsset> =
      await photoHelper.getAssets(fetchOptions);
    if (fetchResult !== undefined) {
      let photoAsset: photoAccessHelper.PhotoAsset = await fetchResult.getFirstObject();
      let photoUri = await photoAsset.getThumbnail();
      if (photoUri) {
        AppStorage.setOrCreate(cameraAppStorage.CAMERA_THUMBNAIL, photoUri);
      }
    }
  }
}

export const albumPicker = new AlbumPicker()