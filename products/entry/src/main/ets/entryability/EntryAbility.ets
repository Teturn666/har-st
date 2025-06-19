import { AbilityConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';
import { PreferencesConstants, preferencesUtils, WXApi, WXEventHandler } from 'utils/Index';
import { DemoConstants } from 'utils';
import { cSJAdSdkAd } from '../utils/CSJAdSdk';
import { MainModel } from '../model/MainModel';
import { BusinessError } from '@kit.BasicServicesKit';
import fs from '@ohos.file.fs';
import { router } from '@kit.ArkUI';
import EntryConstants from '../components/EntryConstants';


export default class EntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onCreate');
    this.handleWeChatCallIfNeed(want)
    cSJAdSdkAd.ctx = this.context
    preferencesUtils.context = this.context
    // 处理文件打开请求
    this.handleFileOpen(want);
  }

  private handleFileOpen(want: Want): void {
    // 获取文件URI
    const uri = want.uri;
    const action = want.action;
    const type = want.type;

    hilog.info(0x0000, 'testTag', 'Received URI: %{public}s', uri || 'null');
    hilog.info(0x0000, 'testTag', 'Received Action: %{public}s', action || 'null');
    hilog.info(0x0000, 'testTag', 'Received Type: %{public}s', type || 'null');

    // 检查parameters中的关键信息
    if (want.parameters) {
      const mimeType = want.parameters['mime-type'] as string;
      const isSelector = want.parameters['isSelector'] as boolean;
      hilog.info(0x0000, 'testTag', 'MIME Type: %{public}s', mimeType || 'null');
      hilog.info(0x0000, 'testTag', 'Is Selector: %{public}s', isSelector?.toString() || 'null');
    }

    // 打印完整的want信息以便调试
    hilog.info(0x0000, 'testTag', 'Full want: %{public}s', JSON.stringify(want));

    // 修改判断条件：检查URI是否存在且为文件URI，或者检查是否为支持的文件类型
    const isFileUri = uri && uri.startsWith('file://');

    // 支持的文件类型
    const supportedTypes = [
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet', // .xlsx
      'application/vnd.ms-excel', // .xls
      'text/plain', // .txt
      'text/csv' // .csv (通常也被当作Excel文件处理)
    ];

    const isExcelFile = type === 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet' ||
      type === 'application/vnd.ms-excel';
    const isTxtFile = type === 'text/plain';
    const isSupportedFile = supportedTypes.includes(type || '');

    const mimeTypeFromParams = want.parameters?.['mime-type'] as string;
    const hasSupportedMimeType = supportedTypes.includes(mimeTypeFromParams || '');

    if (isFileUri || isSupportedFile || hasSupportedMimeType) {
      hilog.info(0x0000, 'testTag', 'Processing file URI: %{public}s', uri);
      hilog.info(0x0000, 'testTag', 'Match reason - isFileUri: %{public}s, isSupportedFile: %{public}s, hasSupportedMimeType: %{public}s',
        isFileUri?.toString(), isSupportedFile?.toString(), hasSupportedMimeType?.toString());
      hilog.info(0x0000, 'testTag', 'File type details - Excel: %{public}s, TXT: %{public}s, Type: %{public}s',
        isExcelFile?.toString(), isTxtFile?.toString(), type || 'null');

      if (!uri) {
        hilog.error(0x0000, 'testTag', 'URI is null but other conditions matched');
        return;
      }

      try {
        // 验证文件是否可访问
        let file = fs.openSync(uri, fs.OpenMode.READ_ONLY);
        hilog.info(0x0000, 'testTag', 'File opened successfully');
        fs.closeSync(file);

        // 解析并解码文件名
        let fileName = '';
        try {
          // 从URI中提取文件名部分
          const uriParts = uri.split('/');
          const encodedFileName = uriParts[uriParts.length - 1];

          // URL解码文件名
          fileName = decodeURIComponent(encodedFileName);
          hilog.info(0x0000, 'testTag', 'Original encoded filename: %{public}s', encodedFileName);
          hilog.info(0x0000, 'testTag', 'Decoded filename: %{public}s', fileName);
        } catch (decodeError) {
          hilog.error(0x0000, 'testTag', 'Failed to decode filename: %{public}s', (decodeError as Error).message);
          // 如果解码失败，使用原始文件名
          const uriParts = uri.split('/');
          fileName = uriParts[uriParts.length - 1];
          hilog.info(0x0000, 'testTag', 'Using original filename: %{public}s', fileName);
        }

        // 获取文件扩展名以进一步确定文件类型
        const fileExtension = fileName.toLowerCase().split('.').pop() || '';
        let detectedFileType = type || 'unknown';

        // 根据扩展名推断文件类型（如果type为空或不准确）
        if (!type || type === 'application/octet-stream') {
          switch (fileExtension) {
            case 'xlsx':
              detectedFileType = 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
              break;
            case 'xls':
              detectedFileType = 'application/vnd.ms-excel';
              break;
            case 'txt':
              detectedFileType = 'text/plain';
              break;
            case 'csv':
              detectedFileType = 'text/csv';
              break;
            default:
              detectedFileType = type || 'unknown';
          }
        }

        // 将文件信息传递给页面
        AppStorage.setOrCreate('fileUri', uri);
        AppStorage.setOrCreate('fileName', fileName);
        AppStorage.setOrCreate('fileType', detectedFileType);
        AppStorage.setOrCreate('fileExtension', fileExtension);
        AppStorage.setOrCreate('shouldOpenFile', true);

        hilog.info(0x0000, 'testTag', 'File info stored - Name: %{public}s, Type: %{public}s, Extension: %{public}s',
          fileName, detectedFileType, fileExtension);

        //导航到自定义题库页面
        this.navigateToCustomizedBankPageWithRouter();

      } catch (err) {
        let error: BusinessError = err as BusinessError;
        hilog.error(0x0000, 'testTag', 'Failed to open file: %{public}s', error.message);
      }
    } else {
      hilog.info(0x0000, 'testTag', 'No matching conditions for file opening');
      hilog.info(0x0000, 'testTag', 'Conditions checked - URI exists: %{public}s, is file URI: %{public}s, is supported file: %{public}s',
        (uri ? 'true' : 'false'), (isFileUri ? 'true' : 'false'), (isSupportedFile ? 'true' : 'false'));
      hilog.info(0x0000, 'testTag', 'File type received: %{public}s, MIME from params: %{public}s',
        type || 'null', mimeTypeFromParams || 'null');
    }
  }

  //导航到自定义题库页面的方法
  private navigateToCustomizedBankPageWithRouter(): void {
    try {
      // 延迟执行，确保应用完全启动
      setTimeout(() => {
        router.pushNamedRoute({
          name: EntryConstants.ROUTER_CUSTOMIZED_BANK_PAGE,
          params: {
            fileUri: AppStorage.get<string>('fileUri'),
            fileName: AppStorage.get<string>('fileName'),
          },
        },router.RouterMode.Single).then(() => {
          hilog.info(0x0000, 'testTag', 'Successfully navigated to CustomizedBankPage with router');
        }).catch((error:Error) => {
          hilog.error(0x0000, 'testTag', 'Router navigation failed: %{public}s', error.message);
        });
      }, 500); // 延迟500ms确保应用启动完成
    } catch (error) {
      hilog.error(0x0000, 'testTag', 'Router navigation error: %{public}s', error.message);
    }
  }

  onDestroy(): void {
    hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onDestroy');
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    // Main window is created, set main page for this ability
    hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onWindowStageCreate');

    windowStage.loadContent('pages/MainPage', (err) => {
      if (err.code) {
        hilog.error(0x0000, 'testTag', 'Failed to load the content. Cause: %{public}s', JSON.stringify(err) ?? '');
        return;
      }
      hilog.info(0x0000, 'testTag', 'Succeeded in loading the content.');

    });
    DemoConstants.windowStage = windowStage

    let res = preferencesUtils.getGenerics(PreferencesConstants.CSJ_AD_PARAMS)
    if (res?.hmAd?.adconfig?.csjAppId) {
      cSJAdSdkAd.ConfigSDK()
      }

  }

  onWindowStageDestroy(): void {
    // Main window is destroyed, release UI related resources
    hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onWindowStageDestroy');
  }

  onForeground(): void {
    // Ability has brought to foreground
    hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onForeground');
  }

  onBackground(): void {
    // Ability has back to background
    hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onBackground');
  }

  onNewWant(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    this.handleWeChatCallIfNeed(want)

    // 应用已启动时接收新的文件打开请求
    this.handleFileOpen(want);
  }

  private handleWeChatCallIfNeed(want: Want) {
    WXApi.handleWant(want, WXEventHandler)
  }
}
