import { camera } from "@kit.CameraKit";
import { display } from "@kit.ArkUI";
import { photoAccessHelper } from "@kit.MediaLibraryKit";
import { BusinessError } from "@kit.BasicServicesKit";
import { colorSpaceManager } from "@kit.ArkGraphics2D";
import { getGravity } from "../utils/GravityUtil";
import { fileIo } from "@kit.CoreFileKit";
import { image } from "@kit.ImageKit";
import { cameraAppStorage } from "../Constants/CameraAppStorage";

export class CreateAtManager {
  ctx?: Context
  surfaceId: string = ''
  private cameraManager: camera.CameraManager | null = null
  private cameraArray: camera.CameraDevice[] = []
  private cameraInput: camera.CameraInput | null = null
  private cameraOutputCap: camera.CameraOutputCapability | null = null
  private previewProfilesArray: camera.Profile[] = []
  private photoProfilesArray: camera.Profile[] = []
  private previewProfile: camera.Profile | undefined = undefined
  private photoProfile: undefined | camera.Profile = undefined
  private previewOutput: camera.PreviewOutput | null = null
  private photoOutPut: camera.PhotoOutput | null = null
  private photoSession: camera.PhotoSession | null = null

  async cameraShooting() {
    this.releaseCamera();
    this.cameraManager = camera.getCameraManager(getContext() || this.ctx);
    this.cameraArray = this.cameraManager.getSupportedCameras();
    this.cameraInput = this.cameraManager.createCameraInput(this.cameraArray[0]);
    await this.cameraInput.open();
    this.cameraOutputCap =
      this.cameraManager.getSupportedOutputCapability(this.cameraArray[0], camera.SceneMode.NORMAL_PHOTO);
    if (this.cameraOutputCap) {
      this.previewProfilesArray = this.cameraOutputCap.previewProfiles
      this.photoProfilesArray = this.cameraOutputCap.photoProfiles;
    }
    this.previewProfile = this.previewProfilesArray.find((profile: camera.Profile) => {
      let screen = display.getDefaultDisplaySync();
      if (screen.width <= 1080) {
        return profile.size.height === 1080 && profile.size.width === 1440;
      } else if (screen.width <= 1440 && screen.width > 1080) {
        return profile.size.height === 1080 && profile.size.width === 1920;
      }
      return undefined
    })
    this.photoProfile = this.photoProfilesArray.find((profile: camera.Profile) => {
      if (this.previewProfile) {
        return profile.size.width <= 4096 && profile.size.width >= 2448 &&
          profile.size.height ===
            ((this.previewProfile.size.height / this.previewProfile.size.width)) * profile.size.width;
      }
      return undefined;
    });
    this.previewOutput = this.cameraManager.createPreviewOutput(this.previewProfile, this.surfaceId);
    this.photoOutPut = this.cameraManager.createPhotoOutput(this.photoProfile);
    this.setPhotoOutputCb();
    this.photoSession = this.cameraManager.createSession(camera.SceneMode.NORMAL_PHOTO) as camera.PhotoSession;
    this.photoSession.beginConfig();
    this.photoSession.addInput(this.cameraInput);
    this.photoSession.addOutput(this.previewOutput);
    this.photoSession.addOutput(this.photoOutPut);
    this.photoSession.setColorSpace(colorSpaceManager.ColorSpace.DISPLAY_P3);
    await this.photoSession.commitConfig();
    await this.photoSession.start();
    let flashStatus: boolean = this.photoSession.hasFlash();
    if (flashStatus) {
      this.photoSession.setFlashMode(camera.FlashMode.FLASH_MODE_CLOSE);
    }
  }

  async capture() {
    const curRotation = await getGravity()
    let settings: camera.PhotoCaptureSetting = {
      quality: camera.QualityLevel.QUALITY_LEVEL_HIGH,
      rotation: curRotation ? this.getPhotoRotation(this.photoOutPut!, curRotation) : camera.ImageRotation.ROTATION_0,
      mirror: false
    };
    this.photoOutPut?.capture(settings)
  }

  setPhotoFlashMode(flashMode: number) {
    this.photoSession?.setFlashMode(flashMode);
  }

  private getPhotoRotation(photoOutput: camera.PhotoOutput, deviceDegree: number): camera.ImageRotation {
    let photoRotation: camera.ImageRotation = camera.ImageRotation.ROTATION_0;

    try {
      photoRotation = photoOutput.getPhotoRotation(deviceDegree);
    } catch (error) {
      let err = error as BusinessError;
      console.error(`The photoOutput.getPhotoRotation call failed. error code: ${err.code}`);
    }

    return photoRotation;
  }

  private setPhotoOutputCb() {
    this.photoOutPut?.on('photoAssetAvailable', (_err: BusinessError, photoAsset: photoAccessHelper.PhotoAsset) => {
      let file = fileIo.openSync(photoAsset.uri, fileIo.OpenMode.READ_ONLY);
      let buffer = new ArrayBuffer(4096);
      let readLen = fileIo.readSync(file.fd, buffer);
      let img = image.createImageSource(file.fd);
      AppStorage.setOrCreate(cameraAppStorage.CAMERA_CAMERA_URI, img);
      fileIo.close(file.fd)
    })
  }

  closeCamera() {
    if (this.cameraInput) {
      this.cameraInput.close();
    }
  }

  releaseCamera() {

    if (this.photoSession) {
      this.photoSession.stop();
    }
    if (this.cameraInput) {
      this.cameraInput.close();
    }
    if (this.previewOutput) {
      this.previewOutput.release();
    }
    if (this.photoSession) {
      this.photoSession.release();
    }
    if (this.photoOutPut) {
      this.photoOutPut.release();
    }
  }
}

export const createAtManager = new CreateAtManager()