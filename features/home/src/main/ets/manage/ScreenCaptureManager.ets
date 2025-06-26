import { common } from '@kit.AbilityKit';
import testNapi from 'libscrcap2pixel.so';
import { image } from '@kit.ImageKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { util } from '@kit.ArkTS';
import fs from '@ohos.file.fs';
import { fileUri } from '@kit.CoreFileKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { PipManager } from './PipManage';
import { PreferencesConstants, preferencesUtils } from 'utils';

// 常量定义
const TAG = 'ScreenCapture';
const LOG_DOMAIN = 0x0001;
const IMAGE_QUALITY = 100;

// 录屏状态枚举
export enum RecordingState {
  IDLE = 0,
  RECORDING = 1,
  PROCESSING = 2
}

// 回调接口
export interface ScreenCaptureCallback {
  onStateChanged?: (state: RecordingState) => void;
  onPreviewUpdate?: (previewImagePath: string, fileName: string) => void;
  onError?: (errorMessage: string) => void;
  onLoadingChanged?: (isLoading: boolean) => void;
  onPixelMapReady?: (pixelMap: image.PixelMap) => void;
}

/**
 * 屏幕录制管理器 - 单例模式
 */
export class ScreenCaptureManager {
  // 单例实例
  private static instance: ScreenCaptureManager | null = null;
  // 状态管理
  private recordingState: RecordingState = RecordingState.IDLE;
  private previewImagePath: string = '';
  private currentFileName: string = '';
  private errorMessage: string = '';
  private isLoading: boolean = false;
  // 应用上下文
  private context: common.ApplicationContext | null = null;
  private cacheBasePath: string = '';
  private callback: ScreenCaptureCallback | null = null;

  /**
   * 私有构造函数，防止外部直接实例化
   */
  private constructor() {
    // 私有构造函数
  }

  /**
   * 获取单例实例
   * @param context 应用上下文，只在第一次调用时需要传递
   * @returns ScreenCaptureManager实例
   */
  public static getInstance(context?: common.ApplicationContext): ScreenCaptureManager {
    if (ScreenCaptureManager.instance === null) {
      if (!context) {
        throw new Error('首次获取ScreenCaptureManager实例时必须传递ApplicationContext');
      }
      ScreenCaptureManager.instance = new ScreenCaptureManager();
      ScreenCaptureManager.instance.initialize(context);
    }
    return ScreenCaptureManager.instance;
  }

  /**
   * 初始化管理器
   * @param context 应用上下文
   */
  private initialize(context: common.ApplicationContext): void {
    this.context = context;
    this.cacheBasePath = context.cacheDir;
    this.logInfo(`应用缓存路径: ${this.cacheBasePath}`);
  }

  /**
   * 重置单例实例（用于测试或特殊情况）
   */
  public static resetInstance(): void {
    ScreenCaptureManager.instance = null;
  }

  /**
   * 设置回调
   */
  setCallback(callback: ScreenCaptureCallback): void {
    this.callback = callback;
  }

  /**
   * 获取录屏状态文本
   */
  getRecordingButtonText(): string {
    switch (this.recordingState) {
      case RecordingState.IDLE:
        return '开始录屏';
      case RecordingState.RECORDING:
        return '录屏中...';
      case RecordingState.PROCESSING:
        return '处理中...';
      default:
        return '开始录屏';
    }
  }

  /**
   * 检查录屏状态
   */
  isRecording(): boolean {
    return this.recordingState === RecordingState.RECORDING;
  }

  /**
   * 获取当前状态
   */
  getRecordingState(): RecordingState {
    return this.recordingState;
  }

  /**
   * 获取错误信息
   */
  getErrorMessage(): string {
    return this.errorMessage;
  }

  /**
   * 获取加载状态
   */
  getIsLoading(): boolean {
    return this.isLoading;
  }

  /**
   * 日志记录统一管理
   */
  private logInfo(message: string): void {
    hilog.info(LOG_DOMAIN, TAG, message);
    console.info(`[${TAG}] ${message}`);
  }

  private logError(message: string): void {
    hilog.error(LOG_DOMAIN, TAG, message);
    console.error(`[${TAG}] ${message}`);
  }

  /**
   * 显示错误信息
   */
  private showError(message: string): void {
    this.errorMessage = message;
    this.logError(message);
    this.callback?.onError?.(message);
    // 3秒后清除错误信息
    setTimeout(() => {
      this.errorMessage = '';
    }, 3000);
  }

  /**
   * 异步保存PixelMap到文件
   */
  private async savePixelMapToFile(pixelMap: image.PixelMap): Promise<string> {
    try {
      if (!pixelMap) {
        throw new Error('PixelMap为空');
      }

      const fileName = `capture_${util.generateRandomUUID(true)}.png`;
      const filePath = `${this.cacheBasePath}/${fileName}`;

      this.logInfo(`开始保存图片: ${fileName}`);

      // 创建图片打包器
      const imagePackerApi = image.createImagePacker();
      const packOpts: image.PackingOption = {
        format: 'image/png',
        quality: IMAGE_QUALITY
      };

      // 打开文件
      const file = fs.openSync(filePath, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE);

      try {
        // 异步打包到文件
        await imagePackerApi.packToFile(pixelMap, file.fd, packOpts);
        this.logInfo(`图片保存成功: ${fileName}`);

        // 更新UI状态
        this.previewImagePath = new fileUri.FileUri(filePath).toString();
        this.currentFileName = fileName;
        this.callback?.onPreviewUpdate?.(this.previewImagePath, this.currentFileName);

        return filePath;
      } finally {
        // 确保文件描述符被关闭
        fs.closeSync(file.fd);
      }
    } catch (error) {
      const errorMsg = `保存图片失败: ${error.message || error}`;
      this.showError(errorMsg);
      return '';
    }
  }

  /**
   * 处理屏幕截图
   */
  private async processScreenCapture(filePath: string): Promise<void> {
    try {
      this.recordingState = RecordingState.PROCESSING;
      this.isLoading = true;
      this.callback?.onStateChanged?.(this.recordingState);
      this.callback?.onLoadingChanged?.(this.isLoading);

      this.logInfo(`开始处理截图文件: ${filePath}`);

      // 创建图片源
      const imageSource = image.createImageSource(filePath);
      if (!imageSource) {
        throw new Error('创建ImageSource失败');
      }

      // 创建PixelMap (使用Promise版本)
      const pixelMap = await new Promise<image.PixelMap>((resolve, reject) => {
        imageSource.createPixelMap((err: BusinessError, pm: image.PixelMap) => {
          if (err) {
            reject(new Error(`创建PixelMap失败: code=${err.code}, message=${err.message}`));
          } else {
            resolve(pm);
          }
        });
      });

      const data = preferencesUtils.getString(PreferencesConstants.SCREEN_READ_SETTING, '')
      let region: image.Region
      if (data) {
        region = JSON.parse(data) as image.Region
      } else {
        // 默认值
        region =
          { x: 0, y: 0.0721, size: { width: 0, height: 0.493 } }
      }
      // 同步获取图像信息
      let imageInfo = pixelMap.getImageInfoSync();

      let width = imageInfo.size.width;
      let regionHeight = imageInfo.size.height * region.y;
      let regionSizeHeight = imageInfo.size.height * region.size.height;

      // 对pixelMap进行裁剪处理
      this.cropPixelMap(pixelMap, 0, regionHeight, width, regionSizeHeight)

      // 使用回调，将pixelMap传入回调函数
      this.callback?.onPixelMapReady?.(pixelMap);

      this.logInfo('截图处理完成');
    } catch (error) {
      this.showError(`处理截图失败: ${error.message || error}`);
    } finally {
      this.recordingState = RecordingState.IDLE;
      this.isLoading = false;
      this.callback?.onStateChanged?.(this.recordingState);
      this.callback?.onLoadingChanged?.(this.isLoading);
    }
  }

  private async cropPixelMap(pixelMap: image.PixelMap, x: number, y: number, width: number,
    height: number): Promise<image.PixelMap> {
    // 定义裁剪区域
    let region: image.Region = {
      x: x,
      y: y,
      size: {
        width: width,
        height: height
      }
    };

    // 裁剪PixelMap（注意：这会修改原PixelMap）
    pixelMap.cropSync(region);
    return pixelMap;
  }

  /**
   * 开始录屏
   */
  startScreenCapture(intervalTime: number = 2): void {
    try {
      this.recordingState = RecordingState.RECORDING;
      this.errorMessage = '';
      this.callback?.onStateChanged?.(this.recordingState);

      this.logInfo(`开始屏幕录制，间隔时间: ${intervalTime}秒`);

      let firstTime = true;

      // 数据回调函数
      const dataCallback = async (fileNum: number) => {
        const captureFilePath = `${this.cacheBasePath}/getPngName${fileNum}.png`;
        this.logInfo(`收到截图回调: ${captureFilePath}`);

        // 只用第一次执行
        if (firstTime) {
          // 创建画中画控制器
          await PipManager.getInstance().init(getContext(this));
          PipManager.getInstance().setAutoStart(true);
          PipManager.getInstance().startPip();
          PipManager.getInstance().stopCallBack = () => {
            // 设置回调，关闭画中画时停止读屏幕
            console.log(TAG, '画中画关闭')
            this?.stopScreenCapture();
          };
          firstTime = false
        }

        // 异步处理截图
        await this.processScreenCapture(captureFilePath);
      };

      // 停止回调函数
      const stopCallback = (stopReason: number) => {
        console.log(TAG, `收到停止回调，原因: ${stopReason}`);
        // 关闭画中画
        PipManager.getInstance().stopPip();
      };

      // 调用原生模块开始录屏，传入停止回调
      const result = testNapi.startScreenCapture(intervalTime, dataCallback, stopCallback);

      if (result !== 5) {
        throw new Error(`启动录屏失败，返回码: ${result}`);
      }

      this.logInfo('录屏启动成功');

    } catch (error) {
      this.showError(`启动录屏失败: ${error.message || error}`);
      this.recordingState = RecordingState.IDLE;
      this.callback?.onStateChanged?.(this.recordingState);
    }
  }

  /**
   * 停止录屏
   */
  stopScreenCapture(): void {
    try {
      // if (!this.isRecording()) {
      //   this.showError('当前没有进行录屏');
      //   return;
      // }

      this.logInfo('停止屏幕录制');
      testNapi.stopScreenCapture();
      this.recordingState = RecordingState.IDLE;
      this.callback?.onStateChanged?.(this.recordingState);
    } catch (error) {
      this.showError(`停止录屏失败: ${error.message || error}`);
    }
  }

  /**
   * 清除预览
   */
  clearPreview(): void {
    this.previewImagePath = '';
    this.currentFileName = '';
    this.errorMessage = '';
    this.callback?.onPreviewUpdate?.('', '');
  }
}