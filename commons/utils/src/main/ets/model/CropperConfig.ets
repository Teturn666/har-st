import * as image_cropper from "@candies/image_cropper";
import { ImageCropperLayerPainter } from "@candies/image_cropper";
import { cropLayerPainter } from "./ImageCroplayerPainter";


interface GeneratedTypeLiteralInterface_1 {
  controller: image_cropper.ImageCropperController;
  cropLayerPainter?: ImageCropperLayerPainter;
  cropRectPadding?: image_cropper.geometry.EdgeInsets;
  initCropRectType?: image_cropper.InitCropRectType;
  cornerColor?: string | number;
  lineHeight?: number;
  initialCropAspectRatio?: number;
}

export class CropperConfig extends image_cropper.ImageCropperConfig {
  constructor(params: GeneratedTypeLiteralInterface_1) {
    super({
      cropRectPadding: image_cropper.geometry.EdgeInsets.all(0),
      controller: params.controller,
      initCropRectType: image_cropper.InitCropRectType.imageRect,
      cornerColor: '#FA5722',
      lineHeight: 0.3,
      initialCropAspectRatio: 5 / 3,
      cropLayerPainter: cropLayerPainter,
    });
  }
}
