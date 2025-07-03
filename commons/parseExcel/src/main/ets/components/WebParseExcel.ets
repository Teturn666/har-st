import { webview } from '@kit.ArkWeb';
import { ExcelDataObj } from '../model/ExcelDataModel';

const TAG = 'WebParseExcel';

export class WebClass {
  static webviewController: webview.WebviewController = new webview.WebviewController();

  static async webParseExcel(fileName: string, excelBase64Str: string): Promise<ExcelDataObj> {
    return new Promise<ExcelDataObj>((resolve, reject) => {
      if (!fileName) {
        reject(new Error(`Excel解析失败: 文件名称为空`));
        return
      }

      if (!excelBase64Str) {
        reject(new Error(`Excel解析失败: 文件内容为空`));
        return
      }

      WebClass.webviewController.runJavaScript(
        `parseExcelQuizBank(${JSON.stringify(fileName)},${JSON.stringify(excelBase64Str)})`,
        async (error, excelData) => {
          if (error) {
            console.error(TAG, `run Excel error, ErrorCode: ${error.code}`);
            reject(new Error(`Excel解析失败: ${error.code}`));
            return;
          }

          if (!excelData || excelData === 'null') {
            reject(new Error('Excel符合格式的数据为空'));
            return;
          }

          try {
            resolve(JSON.parse(excelData) as ExcelDataObj);
          } catch (parseError) {
            reject(new Error(`Excel数据解析失败: ${parseError}`));
          }
        }
      );
    });
  }

  constructor() {
  }
}

@Component
export struct WebParseExcel {
  @State webClassObj: WebClass = new WebClass();

  build() {
    Column() {
      Web({ src: $rawfile('webParseExcel.html'), controller: WebClass.webviewController })
        .height(1)
        .visibility(Visibility.Hidden)
    }
  }
}


