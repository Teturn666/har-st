import fs from '@ohos.file.fs';
import { TitleBar } from 'widget'
import { promptAction, router } from '@kit.ArkUI'
import { getFileExtension, getPrefix } from '../manage/SelectFileManage';
import { WebClass, WebParseExcel } from '../components/WebParseExcel';
import { questionBankTable, QuestionTable } from 'db';
import picker from '@ohos.file.picker';
import { util } from '@kit.ArkTS';
import { ExcelDataObj, QuestionError } from '../model/CustomizedBankModel';
import { ImportWithLog, ParseTxtManage } from '../manage/ParseTxtManage';
import { QuestionModel } from '../manage/ParseTxtManage';
import { BankListRes, QuestionRes } from 'db';
import { BusinessError, emitter } from '@kit.BasicServicesKit';
import { EmitterConstants, PreferencesConstants, preferencesUtils, TimeUtils } from 'utils';
import SearchConstants from 'search/src/main/ets/constants/SearchConstants';
import { SearchEngine } from 'search';
import { fileIo } from '@kit.CoreFileKit';

const TAG = 'CustomizedBankPage'

@Entry({ routeName: "customizedBankPage" })
@Component
export struct CustomizedBankPage {
  @State questionErrorList: QuestionError[] = []
  private dialogController: CustomDialogController | null = null;
  private resultDialogController: CustomDialogController | null = null;
  @State message: string = '等待解析文件...';
  private parser: ParseTxtManage = new ParseTxtManage();
  @State importStatus: string = '未完成'; //'成功'、'失败'、'未完成'
  @State isLoading: boolean = false; // 添加loading状态
  @State loadingMessage: string = '正在导入...'; // loading提示信息
  // 新增：支持外部文件URI
  @State externalFileUri: string = '';
  @State externalFileName: string = '';

  // 将QuestionModel列表转换为QuestionRes列表
  private toQuestionResList(importResult: ImportWithLog): QuestionRes[] {
    const questionResList: QuestionRes[] = new Array(importResult.items.length);
    for (let i = 0; i < importResult.items.length; i++) {
      const item = importResult.items[i];
      const questionRes = new QuestionRes();
      questionRes.question = item.q;
      questionRes.option = item.a;
      questionRes.answer = item.ans;
      questionRes.questionID = item.questionID;
      questionRes.qId = item.qid;
      questionRes.wrongAnswer = "";
      questionResList[i] = questionRes;
    }
    console.log("查看questionResList：" + JSON.stringify(questionResList));
    return questionResList;
  }


  // 自定义题库导入逻辑
  async questionImport() {
    let fileUri: string = '';
    let fileName: string = '';

    // 首先检查是否有外部传入的文件
    const shouldOpenFile = AppStorage.get<boolean>('shouldOpenFile');
    if (shouldOpenFile) {
      fileUri = AppStorage.get<string>('fileUri') || '';
      fileName = AppStorage.get<string>('fileName') || '';

      // 清除AppStorage中的标志，避免重复处理
      AppStorage.setOrCreate('shouldOpenFile', false);

      if (fileUri && fileName) {
        this.externalFileUri = fileUri;
        this.externalFileName = fileName;
        this.message = `准备导入文件: ${fileName}`;

        // 直接处理外部文件
        await this.processExternalFile(fileUri, fileName);
        return;
      }
    }


    // 如果没有外部文件，则使用文件选择器
    const documentPicker = new picker.DocumentViewPicker();
    const result = await documentPicker.select({
      fileSuffixFilters: ['.xlsx', '.xls', '.txt'],
      maxSelectNumber: 1
    });

    if (result.length === 0) {
      promptAction.showToast({ message: '未选择文件', duration: 2000 });
      router.back();
      return;
    }

    // 处理选择的文件
    await this.processSelectedFile(result[0]);
  }

  // 处理选择文件的方法（原有逻辑）
  private async processSelectedFile(filePath: string) {
    let file = fs.openSync(filePath, fs.OpenMode.READ_ONLY);
    const fileTypeName = getFileExtension(file.name);
    const filePreName = getPrefix(file.name);

    this.isLoading = true;
    this.loadingMessage = '正在解析文件...';

    try {
      let bankListRes: BankListRes | undefined;
      if (fileTypeName === 'xlsx' || fileTypeName === 'xls') {
        bankListRes = await this.parseExcel(file, filePreName);
      } else if (fileTypeName === 'txt') {
        bankListRes = await this.parseTxt(file, filePreName);
      } else {
        promptAction.showToast({ message: '不支持的文件格式', duration: 2000 });
        this.isLoading = false;
        return;
      }

      if (bankListRes) {
        this.loadingMessage = '正在初始化搜索...';
        let oldMdataSize = preferencesUtils.getNumber(PreferencesConstants.SEARCH_DATASIZE_ALL, 0)
        preferencesUtils.putNumber(PreferencesConstants.SEARCH_DATASIZE_ALL, oldMdataSize + Number(bankListRes.num))
        await SearchEngine.getInstance().initWithThread(getContext(this), bankListRes.qid, 1)
      }
    } catch (error) {
      console.error('文件处理失败:', error);
      this.importStatus = '失败';
      this.message = '文件处理失败';
      promptAction.showToast({ message: '文件处理失败', duration: 2000 });
    } finally {
      this.isLoading = false;
    }
  }

  // 处理外部文件的方法
  private async processExternalFile(fileUri: string, fileName: string) {
    this.isLoading = true;
    this.loadingMessage = '正在解析文件...';

    try {
      let file = fs.openSync(fileUri, fs.OpenMode.READ_ONLY);
      const fileTypeName = getFileExtension(fileName);
      const filePreName = getPrefix(fileName);

      let bankListRes: BankListRes | undefined;
      if (fileTypeName === 'xlsx' || fileTypeName === 'xls') {
        bankListRes = await this.parseExcel(file, filePreName);
      } else if (fileTypeName === 'txt') {
        bankListRes = await this.parseTxt(file, filePreName);
      } else {
        promptAction.showToast({ message: '不支持的文件格式', duration: 2000 });
        this.isLoading = false;
        return;
      }

      // 进行搜索初始化逻辑
      if (bankListRes) {
        this.loadingMessage = '正在初始化搜索...';
        let oldMdataSize = preferencesUtils.getNumber(PreferencesConstants.SEARCH_DATASIZE_ALL, 0)
        preferencesUtils.putNumber(PreferencesConstants.SEARCH_DATASIZE_ALL, oldMdataSize + Number(bankListRes.num))
        await SearchEngine.getInstance().initWithThread(getContext(this), bankListRes.qid, 1)
      }
    } catch (error) {
      console.error('外部文件处理失败:', error);
      this.importStatus = '失败';
      this.message = '文件处理失败';
      promptAction.showToast({ message: '文件处理失败', duration: 2000 });
    } finally {
      this.isLoading = false;
    }
  }

  private async parseTxt(file: fs.File, filePreName: string): Promise<BankListRes | undefined> {
    try {
      this.loadingMessage = '正在解析TXT文件...';
      const result = await this.parser.parseTxtFile(file)
      this.message = `开始处理TXT文件：${file.path}`;
      if (!result) {
        this.message = '解析失败';
        promptAction.showToast({ message: '解析失败', duration: 2000 });
        return;
      }

      // 获取题库名称
      let bankName: string;
      try {
        bankName = await this.getInputDialogName(filePreName);
      } catch (error) {
        console.info('parseTxt: 用户取消导入操作', error.message);
        this.message = '您已取消导入';
        this.importStatus = '未完成';
        return;
      }

      this.loadingMessage = '正在创建题库...';

      // 创建题库对象
      const bank: BankListRes = {
        id: -1,
        qid: result.items[0]?.qid || 0,
        name: bankName,
        desc: bankName,
        time: TimeUtils.getFormattedTime(),
        url: '',
        num: result.items.length.toString(),
        version: '1.0',
        position: 0,
        downloadedState: 1,
        bankType: 2,
        NewFlag: false
      };

      // 插入题库
      try {
        await questionBankTable.insertDataAwait(bank);
      } catch (error) {
        const err: BusinessError = error as BusinessError;
        this.importStatus = '失败';
        this.message = `插入题库失败: ${err.message}`;
        promptAction.showToast({ message: '插入题库失败', duration: 2000 });
        return
      }

      this.loadingMessage = '正在导入题目...';

      const questionResList: QuestionRes[] = this.toQuestionResList(result);
      let successCount = 0;

      // 批量插入题目
      try {
        const insertPromises = questionResList.map(async (item): Promise<number> => {
          item.qName = bank.name;
          return QuestionTable.getInstance().insertDataAwait(item);
        });
        const insertResults = await Promise.all(insertPromises);
        successCount = insertResults.reduce((sum, result) => sum + (result > 0 ? 1 : 0), 0);

        // 处理插入失败的题目
        insertResults.forEach((results, index) => {
          if (results <= 0) {
            const item = questionResList[index];
            result.logs.push(`插入题目失败: questionID=${item.questionID}, 错误: 插入未成功`);
          }
        });
      } catch (error) {
        const err: BusinessError = error as BusinessError;
        console.error(`批量插入题目失败: ${err.message}`);
        result.logs.push(`批量插入题目失败: 错误: ${err.message}`);
        this.importStatus = '失败';
        this.message = `批量插入题目失败: ${err.message}`;
        promptAction.showToast({ message: '批量插入题目失败', duration: 2000 });
        return;
      }

      // 处理错误日志
      this.questionErrorList = result.logs.map((log: string): QuestionError => {
        const match = log.match(/第(\d+)行:(.*)/s);
        return {
          sheetName: '',
          row: match ? parseInt(match[1]) : 0,
          error: match ? match[2].trim() : log
        };
      });

      // 设置最终状态
      if (successCount > 0) {
        this.importStatus = '成功';
        const toastMessage = this.questionErrorList.length > 0
          ? `成功导入 ${successCount} 道题目，存在 ${this.questionErrorList.length} 个错误`
          : `成功导入 ${successCount} 道题目`;
        // promptAction.showToast({ message: toastMessage, duration: 2000 });
        emitter.emit(EmitterConstants.EM_REFRESH_HOME)

        // 在loading结束后显示成功弹窗
        setTimeout(() => {
          this.importSuccess(successCount);
        }, 100);

        return bank;
      } else {
        this.importStatus = '失败';
        // promptAction.showToast({ message: '导入失败', duration: 2000 });
        return
      }

    } catch (error) {
      const err: BusinessError = error as BusinessError;
      console.error(`读取文件失败: code=${err.code}, message=${err.message}`);
      this.message = `文件读取失败: ${err.message} (错误码: ${err.code})`;
      this.importStatus = '失败';
      // promptAction.showToast({ message: '文件读取失败', duration: 2000 });
      return
    }
  }

  private async parseExcel(file: fs.File, filePreName: string): Promise<BankListRes | undefined> {
    try {
      this.loadingMessage = '正在读取Excel文件...';
      const stat = fs.statSync(file.fd);
      let buffer = new ArrayBuffer(stat.size);
      fs.readSync(file.fd, buffer);
      fs.closeSync(file.fd);

      // 转成base64编码的字符串
      const helper = new util.Base64Helper();
      const excelBase64Str = helper.encodeToStringSync(new Uint8Array(buffer));

      this.loadingMessage = '正在解析Excel数据...';
      // Promise化Excel解析过程
      const excelDataObj = await new Promise<ExcelDataObj>((resolve, reject) => {
        WebClass.webviewController.runJavaScript(
          `parseExcelQuizBank(${JSON.stringify(file.name)},${JSON.stringify(excelBase64Str)})`,
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

      this.message = `开始处理Excel文件: ${file.path}`;

      // 获取题库名称
      let bankName: string;
      try {
        bankName = await this.getInputDialogName(filePreName);
      } catch (error) {
        console.info('parseExcel: 用户取消导入操作', error.message);
        this.message = '您已取消导入';
        this.importStatus = '未完成';
        return;
      }

      this.loadingMessage = '正在保存题库数据...';

      // 设置题库信息
      excelDataObj.quizBank.name = bankName;
      excelDataObj.quizBank.desc = bankName;

      // 插入题库
      await questionBankTable.insertDataAwait(excelDataObj.quizBank);

      // 批量插入题目
      const insertPromises = excelDataObj.questions.map(async (item): Promise<number> => {
        item.qName = bankName;
        return QuestionTable.getInstance().insertDataAwait(item);
      });
      await Promise.all(insertPromises);

      // 设置导入结果
      this.questionErrorList = excelDataObj.questionErrorList || [];
      this.importStatus = '成功';

      const toastMessage = this.questionErrorList.length > 0
        ? `成功导入 ${excelDataObj.quizBank.num} 道题目，存在 ${this.questionErrorList.length} 个错误`
        : `成功导入 ${excelDataObj.quizBank.num} 道题目`;
      // promptAction.showToast({ message: toastMessage, duration: 2000 });
      emitter.emit(EmitterConstants.EM_REFRESH_HOME)

      // 在loading结束后显示成功弹窗
      setTimeout(() => {
        this.importSuccess(Number(excelDataObj.quizBank.num));
      }, 100);

      return excelDataObj.quizBank
    } catch (error) {
      console.error(TAG, 'Excel处理失败:', error);
      this.importStatus = '失败';
      this.message = '导入失败';
      // promptAction.showToast({ message: error.message || '文件解析失败', duration: 2000 });
      return
    }
  }

  async getInputDialogName(defaultName: string): Promise<string> {
    let bankName: string = defaultName;
    let isConfirmed: boolean = false;
    await new Promise<void>((resolve, reject) => {
      this.dialogController = new CustomDialogController({
        builder: InputDialog({
          initialText: defaultName,
          confirm: (value: string) => {
            if (!value.trim()) {
              promptAction.showToast({
                message: "请输入题库名称",
                duration: 2000
              });
              return;
            }
            bankName = value.trim();
            isConfirmed = true;
            resolve();
            this.dialogController?.close();
          },
          cancel: () => {
            console.info('取消输入');
            reject(new Error('用户取消导入'));
          },
        })
      });
      this.dialogController?.open();
    });

    if (!isConfirmed) {
      this.message = '取消导入';
      this.importStatus = '失败';
      // promptAction.showToast({ message: '取消导入', duration: 2000 });
      throw new Error('用户取消导入');
    }
    return bankName;
  }

  async importSuccess(count: number) {
    // 显示成功提示
    await new Promise<void>((resolve) => {
      this.resultDialogController = new CustomDialogController({
        builder: ResultDialog({
          message: `成功导入 ${count} 道题目`,
          confirm: () => {
            console.info('确认成功提示');
            resolve();
          }
        })
      });
      this.resultDialogController?.open();
    });
  }

   aboutToAppear() {
    setTimeout(() => {
      this.questionImport()
    }, 500)
  }

  aboutToDisappear() {
    this.dialogController = null;
    this.resultDialogController = null;
  }

  build() {
    Column() {
      WebParseExcel()
      TitleBar({
        title: '自定义题库',
        backClick: () => {
          router.back()
        },
      }).width('100%')

      Column() {
        Text("个人制作和导入题库遇到问题\n请联系QQ：1729868682")
          .fontSize($r('app.float.float_12vp'))
          .fontColor($r('app.color.c_f2f7ff'))
      }
      .justifyContent(FlexAlign.Center)
      .width('100%')
      .height($r('app.float.float_50vp'))
      .backgroundColor($r('app.color.c_F75A23'))

      // Loading状态显示
      if (this.isLoading) {
        Column() {
          LoadingProgress()
            .width(40)
            .height(40)
            .margin({ bottom: 10 })
            .color($r('app.color.c_F75A23'))

          Text(this.loadingMessage)
            .fontSize(14)
            .fontColor($r('app.color.c_9d9d9d'))
        }
        .justifyContent(FlexAlign.Center)
        .width('100%')
        .height(200)
      } else {
        // 文件路径信息
        Text(this.message)
          .fontSize(12)
          .fontColor($r('app.color.c_9d9d9d'))
          .margin({
            top: 10,
            bottom: 10,
            left: 20,
            right: 20
          })
          .textAlign(TextAlign.Start)

        List({ space: 5 }) {
          ForEach(
            this.questionErrorList,
            (item: QuestionError) => {
              ListItem() {
                Text(`${item.sheetName} 第${item.row}行, ${item.error}`)
                  .fontSize(12)
                  .fontColor($r('app.color.c_9d9d9d'))
                  .margin({ bottom: 10, left: 20, right: 20 })
                  .textAlign(TextAlign.Start)
              }
            },
          )
          ListItem() {
            // 动态显示导入结果
            if (this.importStatus === '成功') {
              Text('导入完成')
                .fontSize(12)
                .fontColor($r('app.color.c_9d9d9d'))
                .margin({ bottom: 10, left: 20, right: 20 })
                .textAlign(TextAlign.Start)
            } else if (this.importStatus === '失败') {
              Text('导入失败')
                .fontSize(12)
                .fontColor($r('app.color.c_9d9d9d'))
                .margin({ bottom: 10, left: 20, right: 20 })
                .textAlign(TextAlign.Start)
            }
          }
        }
        // .height("auto")
        .layoutWeight(1)
        .width("100%")

      }

    }
    .alignItems(HorizontalAlign.Start)
  }
}

@CustomDialog
struct InputDialog {
  @State inputText: string = '';
  controller?: CustomDialogController;
  @Prop initialText: string; // 接收默认文件名
  confirm: (value: string) => void = () => {
  };
  cancel: () => void = () => {
  };

  aboutToAppear() {
    this.inputText = this.initialText; // 在对话框出现时设置默认值
  }

  build() {
    Column({ space: 20 }) {
      Row() {
        Text('备注导入的题库名称')
          .fontSize(18)
          .fontColor('#9d9d9d')
        Image($r('app.media.ic_cha'))
          .width(16)
          .height(16)
          .onClick(() => {
            console.info('InputDialog: Cancel clicked');
            this.cancel();
            this.controller?.close();
          })
      }
      .padding({ left: 18, top: 8, right: 18 })
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)

      TextInput({ placeholder: '请输入题库名称', text: this.inputText })
        .height(50)
        .fontSize(14)
        .placeholderColor('#cbcac6')
        .backgroundColor('#f3f3f3')
        .borderRadius(10)
        .margin({ left: 25, right: 25 })
        .onChange((value: string) => {
          console.info(`InputDialog: Text changed to ${value}`);
          this.inputText = value;
        })

      Blank()

      Flex({ justifyContent: FlexAlign.Center }) {
        Image($r('app.media.ic_confirm'))
          .size({ width: $r('app.float.float_106vp'), height: $r('app.float.float_40vp') })
          .onClick(() => {
            console.info(`InputDialog: Confirm clicked, input: ${this.inputText}`);
            this.confirm(this.inputText);
          })
      }

      Blank()
    }
    .width('90%')
    .height(250)
    .padding({ top: 20, bottom: 20 })
    .borderRadius(12)
  }
}

@CustomDialog
struct ResultDialog {
  @Prop message: string;
  controller?: CustomDialogController;
  confirm: () => void = () => {
  };

  build() {
    Column({ space: 20 }) {
      Row() {
        Text('导入结果')
          .fontSize(18)
          .fontColor('#9d9d9d')
      }
      .padding({ left: 18, top: 8, right: 18 })
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)

      Text(this.message)
        .fontSize(18)
        .fontColor('black')
        .width('90%')
        .align(Alignment.Start)
        .padding({ left: 25, right: 25 })

      Blank()

      Flex({ justifyContent: FlexAlign.Center }) {
        Image($r('app.media.ic_confirm'))
          .width(106)
          .height(40)
          .onClick(() => {
            console.info('ResultDialog: Confirm clicked');
            this.confirm();
            this.controller?.close();
          })
      }

      Blank()
    }
    .width('90%')
    .height(250)
    .padding({ top: 20, bottom: 20 })
    .borderRadius(12)
  }
}