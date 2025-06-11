import fs from '@ohos.file.fs';
import { TitleBar } from 'widget'
import { promptAction, router } from '@kit.ArkUI'
import { getFileExtension, getPrefix } from '../manage/SelectFileManage';
import { WebClass } from '../components/WebParseExcel';
import { questionBankTable, QuestionTable } from 'db';
import picker from '@ohos.file.picker';
import { util } from '@kit.ArkTS';
import { ExcelDataObj, QuestionError } from '../model/CustomizedBankModel';
import { ImportWithLog, ParseTxtManage } from '../manage/ParseTxtManage';
import { QuestionModel } from '../manage/ParseTxtManage';
import { BankListRes, QuestionRes } from 'db';
import { BusinessError, emitter } from '@kit.BasicServicesKit';
import { EmitterConstants, TimeUtils } from 'utils';
import { preferences } from '@kit.ArkData';
import SearchConstants from 'search/src/main/ets/constants/SearchConstants';
import { SearchEngine } from 'search';

const TAG = 'CustomizedBankPage'

@Entry({ routeName: "customizedBankPage" })
@Component
struct CustomizedBankPage {
  @State questionErrorList: QuestionError[] = []
  private dialogController: CustomDialogController | null = null;
  private resultDialogController: CustomDialogController | null = null;
  @State message: string = '等待解析文件...';
  private parser: ParseTxtManage = new ParseTxtManage();
  @State importStatus: string = '未完成'; //'成功'、'失败'、'未完成'

  // 将QuestionModel列表转换为QuestionRes列表
  private toQuestionResList(importResult: ImportWithLog): QuestionRes[] {
    const questionResList: QuestionRes[] = [];
    importResult.items.forEach((item: QuestionModel, index: number) => {
      const questionRes = new QuestionRes();
      questionRes.question = item.q;
      questionRes.option = item.a;
      questionRes.answer = item.ans;
      questionRes.questionID = item.questionID;
      questionRes.qId = item.qid;
      questionRes.wrongAnswer = "";
      questionResList.push(questionRes);
      console.log("查看questionResList：" + JSON.stringify(questionResList));
    });
    return questionResList;
  }

  // 自定义题库导入逻辑
  async questionImport() {
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

    let file = fs.openSync(result[0], fs.OpenMode.READ_ONLY);
    const fileTypeName = getFileExtension(file.name);
    const filePreName = getPrefix(file.name);

    try {
      let bankListRes: BankListRes | undefined;
      if (fileTypeName === 'xlsx' || fileTypeName === 'xls') {
        bankListRes = await this.parseExcel(file, filePreName);
      } else if (fileTypeName === 'txt') {
        bankListRes = await this.parseTxt(file, filePreName);
      } else {
        promptAction.showToast({ message: '不支持的文件格式', duration: 2000 });
      }
      // 进行搜索初始化逻辑
      if (bankListRes) {
        //更新mdataSize
        let sp = preferences.getPreferencesSync(getContext(this), SearchConstants.SEARCH_OPTIONS)
        sp.putSync(SearchConstants.SEARCH_DATASIZE_ALL,
          sp.getSync(SearchConstants.SEARCH_DATASIZE_ALL, 0) as number + Number(bankListRes.num))
        sp.flushSync()

        // 更新mdataText分词
        await SearchEngine.getInstance().initWithThread(getContext(this), bankListRes.qid, 1)
      }
    } catch (error) {
      console.error('文件处理失败:', error);
      this.importStatus = '失败';
      this.message = '文件处理失败';
      promptAction.showToast({ message: '文件处理失败', duration: 2000 });
    }
  }

  private async parseTxt(file: fs.File, filePreName: string): Promise<BankListRes | undefined> {
    try {
      const result = await this.parser.parseTxtFile(file.path)
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

      // 批量插入题目
      const questionResList: QuestionRes[] = this.toQuestionResList(result);
      let successCount = 0;

      for (let item of questionResList) {
        try {
          item.qName = bank.name;
          await QuestionTable.getInstance().insertDataAwait(item);
          successCount++;
        } catch (error) {
          const err: BusinessError = error as BusinessError;
          console.error(`插入题目失败: questionID=${item.questionID}, error=${err.message}`);
          result.logs.push(`插入题目失败: questionID=${item.questionID}, 错误: ${err.message}`);
          return
        }
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

      await this.importSuccess(successCount);

      // 设置最终状态
      if (successCount > 0) {
        this.importStatus = '成功';
        const toastMessage = this.questionErrorList.length > 0
          ? `成功导入 ${successCount} 道题目，存在 ${this.questionErrorList.length} 个错误`
          : `成功导入 ${successCount} 道题目`;
        promptAction.showToast({ message: toastMessage, duration: 2000 });
        emitter.emit(EmitterConstants.EM_REFRESH_HOME)
        return bank;
      } else {
        this.importStatus = '失败';
        promptAction.showToast({ message: '导入失败', duration: 2000 });
        return
      }

    } catch (error) {
      const err: BusinessError = error as BusinessError;
      console.error(`读取文件失败: code=${err.code}, message=${err.message}`);
      this.message = `文件读取失败: ${err.message} (错误码: ${err.code})`;
      this.importStatus = '失败';
      promptAction.showToast({ message: '文件读取失败', duration: 2000 });
      return
    }
  }

  private async parseExcel(file: fs.File, filePreName: string): Promise<BankListRes | undefined> {
    try {
      const stat = fs.statSync(file.fd);
      let buffer = new ArrayBuffer(stat.size);
      fs.readSync(file.fd, buffer);
      fs.closeSync(file.fd);

      // 转成base64编码的字符串
      const helper = new util.Base64Helper();
      const excelBase64Str = helper.encodeToStringSync(new Uint8Array(buffer));

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

      await this.importSuccess(Number(excelDataObj.quizBank.num));

      // 设置导入结果
      this.questionErrorList = excelDataObj.questionErrorList || [];
      this.importStatus = '成功';

      const toastMessage = this.questionErrorList.length > 0
        ? `成功导入 ${excelDataObj.quizBank.num} 道题目，存在 ${this.questionErrorList.length} 个错误`
        : `成功导入 ${excelDataObj.quizBank.num} 道题目`;
      promptAction.showToast({ message: toastMessage, duration: 2000 });
      emitter.emit(EmitterConstants.EM_REFRESH_HOME)
      return excelDataObj.quizBank
    } catch (error) {
      console.error(TAG, 'Excel处理失败:', error);
      this.importStatus = '失败';
      this.message = '导入失败';
      promptAction.showToast({ message: error.message || '文件解析失败', duration: 2000 });
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
      promptAction.showToast({ message: '取消导入', duration: 2000 });
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

  async aboutToAppear() {
    this.questionImport()
  }

  aboutToDisappear() {
    this.dialogController = null;
    this.resultDialogController = null;
  }

  build() {
    Column() {
      TitleBar({
        title: '自定义题库',
        backClick: () => {
          router.back()
        },
      }).width('100%')

      Column() {
        Text("个人制作和导入题库遇到问题\n请联系QQ：2885403085")
          .fontSize($r('app.float.float_12vp'))
          .fontColor($r('app.color.c_f2f7ff'))
      }
      .justifyContent(FlexAlign.Center)
      .width('100%')
      .height($r('app.float.float_50vp'))
      .backgroundColor($r('app.color.c_F75A23'))

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
      }
      .height("auto")
      .width("100%")

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
