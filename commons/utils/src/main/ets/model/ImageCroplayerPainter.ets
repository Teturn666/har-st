import * as image_cropper from "@candies/image_cropper";

export class RectangleImageCropperWithTextLayerPainter extends image_cropper.ImageCropperLayerPainter {
  protected paintMask(config: image_cropper.ImageCropperLayerPainterConfig): void {
    const rect = config.layoutRect;
    const cropRect = config.cropRect;
    const canvas = config.canvas;

    canvas.save();
    canvas.fillStyle = 'rgba(0, 0, 0, 0.4)';
    canvas.beginPath();
    canvas.rect(rect.left, rect.top, rect.width, rect.height);
    canvas.rect(cropRect.left, cropRect.top, cropRect.width, cropRect.height);
    canvas.fill('evenodd');
    canvas.closePath();
    canvas.restore();
  }

  protected paintCorners(config: image_cropper.ImageCropperLayerPainterConfig): void {
    const cropRect = config.cropRect;
    const canvas = config.canvas;
    const cornerSize = 20;
    const lineWidth = 4;
    canvas.save();
    canvas.strokeStyle = config.cornerColor;
    canvas.lineWidth = lineWidth;
    canvas.beginPath();
    canvas.moveTo(cropRect.topLeft.dx, cropRect.topLeft.dy + cornerSize);
    canvas.lineTo(cropRect.topLeft.dx, cropRect.topLeft.dy);
    canvas.lineTo(cropRect.topLeft.dx + cornerSize, cropRect.topLeft.dy);
    canvas.stroke();
    canvas.beginPath();
    canvas.moveTo(cropRect.topRight.dx - cornerSize, cropRect.topRight.dy);
    canvas.lineTo(cropRect.topRight.dx, cropRect.topRight.dy);
    canvas.lineTo(cropRect.topRight.dx, cropRect.topRight.dy + cornerSize);
    canvas.stroke();
    canvas.beginPath();
    canvas.moveTo(cropRect.bottomRight.dx, cropRect.bottomRight.dy - cornerSize);
    canvas.lineTo(cropRect.bottomRight.dx, cropRect.bottomRight.dy);
    canvas.lineTo(cropRect.bottomRight.dx - cornerSize, cropRect.bottomRight.dy);
    canvas.stroke();
    canvas.beginPath();
    canvas.moveTo(cropRect.bottomLeft.dx + cornerSize, cropRect.bottomLeft.dy);
    canvas.lineTo(cropRect.bottomLeft.dx, cropRect.bottomLeft.dy);
    canvas.lineTo(cropRect.bottomLeft.dx, cropRect.bottomLeft.dy - cornerSize);
    canvas.stroke();
    canvas.restore();
  }

  protected paintTextHint(config: image_cropper.ImageCropperLayerPainterConfig): void {
    const canvas = config.canvas;
    const cropRect = config.cropRect;
    const text = "只框选题干，不带选项";
    canvas.save();
    canvas.font = "bold 50px sans-serif";
    canvas.textAlign = "center";
    canvas.textBaseline = "middle";
    const textWidth = canvas.measureText(text).width;
    const padding = 20;
    const bgHeight = 30;
    const bgWidth = textWidth + padding * 2;
    const bgX = cropRect.center.dx - bgWidth / 2;
    const bgY = cropRect.top - bgHeight - 10;
    const textX = cropRect.center.dx;
    const textY = bgY + bgHeight / 2;
    canvas.beginPath();
    canvas.moveTo(bgX + 8, bgY);
    canvas.lineTo(bgX + bgWidth - 8, bgY);
    canvas.quadraticCurveTo(bgX + bgWidth, bgY, bgX + bgWidth, bgY + 8);
    canvas.lineTo(bgX + bgWidth, bgY + bgHeight - 8);
    canvas.quadraticCurveTo(bgX + bgWidth, bgY + bgHeight, bgX + bgWidth - 8, bgY + bgHeight);
    canvas.lineTo(bgX + 8, bgY + bgHeight);
    canvas.quadraticCurveTo(bgX, bgY + bgHeight, bgX, bgY + bgHeight - 8);
    canvas.lineTo(bgX, bgY + 8);
    canvas.quadraticCurveTo(bgX, bgY, bgX + 8, bgY);
    canvas.closePath();
    canvas.fillStyle = "#FF4D4D";
    canvas.fill();
    canvas.fillStyle = "#FFFFFF";
    canvas.fillText(text, textX, textY);
    canvas.restore();
  }

  paint(config: image_cropper.ImageCropperLayerPainterConfig): void {
    this.paintMask(config);

    this.paintLines(config);

    this.paintCorners(config);

    this.paintTextHint(config);
  }
}

export const cropLayerPainter = new RectangleImageCropperWithTextLayerPainter();