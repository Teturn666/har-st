import { util } from '@kit.ArkTS';
import fs from '@ohos.file.fs';
import promptAction from '@ohos.promptAction';
import { BusinessError } from '@ohos.base';
import { picker } from '@kit.CoreFileKit';
import { BankListRes, QuestionRes, questionTable, questionBankTable } from 'db';

interface QuestionModel {
  q: string;
  a: string[];
  ans: string;
  type: 'single' | 'multiple' | 'truefalse';

  // 新增字段
  qid: number;
  questionID: number;
}

interface ImportWithLog {
  items: QuestionModel[];
  logs: string[];
}

@CustomDialog
struct InputDialog {
  @State inputText: string = '';
  controller?: CustomDialogController;
  confirm: (value: string) => void = () => {
  };
  cancel: () => void = () => {
  };

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
            this.controller?.close();
          })
      }

      Blank()
    }
    .width('90%')
    .height(250)
    .padding({ top: 20, bottom: 20 })
    .backgroundColor(Color.White)
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
    .backgroundColor(Color.White)
    .borderRadius(12)
  }
}

@Entry({ routeName: "questionUtils" })
@Component
struct QuestionUtils {
  private dialogController: CustomDialogController | null = null;
  private resultDialogController: CustomDialogController | null = null;
  @State message: string = '等待解析文件...';
  private ANSWERLABEL: string = 'ABCDEFGHI';
  private SKIPSTR: string = ' 、.．，,\t';
  private labels: string = 'ABCDEFGHI对错√×✔X正确错误YN';

  // 规范化字符串
  private format(s: string): string {
    if (!s) {
      return s;
    }
    return s.replace(/Ａ/g, 'A')
      .replace(/Ｂ/g, 'B')
      .replace(/Ｃ/g, 'C')
      .replace(/Ｄ/g, 'D')
      .replace(/．/g, '.')
      .replace(/\(/g, '（')
      .replace(/\)/g, '）');
  }

  // 规范化答案
  private formatAnswer(s: string): string {
    if (!s) {
      return s;
    }
    return s.replace(/Ａ/g, 'A')
      .replace(/Ｂ/g, 'B')
      .replace(/Ｃ/g, 'C')
      .replace(/Ｄ/g, 'D')
      .replace(/\s/g, '')
      .replace(/\./g, '')
      .replace(/、/g, '')
      .replace(/，/g, '')
      .replace(/,/g, '');
  }

  // 检查是否为有效答案
  private isAnswer(s: string): boolean {
    if (!s || !s.trim()) {
      return false;
    }
    for (let i = 0; i < s.length; i++) {
      if (!this.labels.includes(s[i])) {
        return false;
      }
    }
    return true;
  }

  // 解析选项
  private parseAnswers(s: string): string[] {
    let andid = this.ANSWERLABEL.indexOf(s[0]);
    let a: string[] = [];
    let idx = 0;
    let ss = this.format(s);
    while (idx >= 0) {
      ss = ss.substring(idx + 1).trim();
      for (let i = 0; i < ss.length; i++) {
        if (!this.SKIPSTR.includes(ss[i])) {
          ss = ss.substring(i);
          break;
        }
      }
      idx = ss.indexOf(this.ANSWERLABEL[andid + 1]);
      andid += 1;
      if (idx < 0) {
        if (ss) {
          a.push(ss);
        }
        break;
      } else {
        let tmp = ss.substring(0, idx).trim();
        if (tmp) {
          a.push(tmp);
        }
      }
    }
    return a;
  }

  // 移除题号
  private removeQid(s: string): string {
    if (!s || !s.trim()) {
      return s;
    }
    let ss = s.trim();
    let flag = false;
    for (let i = 0; i < ss.length; i++) {
      let isSkip = this.SKIPSTR.includes(ss[i]);
      let isDigit = /\d/.test(ss[i]);
      if (isSkip) {
        flag = true;
      }
      if (flag) {
        if (!isSkip) {
          return ss.substring(i);
        }
      } else {
        if (!isDigit) {
          return ss.substring(i);
        }
      }
    }
    return ss;
  }

  // 预处理（将开头的答案括号移到末尾）
  private preProcess(s: string): string {
    if (!s || !s.trim()) {
      return s;
    }
    let ss = s.trim()
      .replace(/\t/g, '')
      .replace(/\n/g, '')
      .replace(/\(/g, '（')
      .replace(/\)/g, '）')
      .replace(/\uFEFF/g, '');
    if (ss.startsWith('（')) {
      let arr = ss.split('）', 2);
      let ans = arr[0].replace('（', '').trim();
      ans = this.formatAnswer(ans);
      if (this.isAnswer(ans)) {
        return `${arr[1].trim()}（${ans}）`;
      }
    }
    return ss;
  }

  // 解析题干（优先从括号提取答案）
  private parseQuestion(s: string): QuestionModel | null {
    if (!s) {
      return null;
    }
    let ss = this.format(s.trim());
    let q: QuestionModel | null = null;
    if (ss.includes('（') && ss.includes('）')) {
      let arr = ss.split('（');
      for (let i = 0; i < arr.length; i++) {
        arr[i] = arr[i].trim();
        let t = arr[i];
        if (t.includes('）')) {
          let tarr = t.split('）', 2);
          let tans = this.formatAnswer(tarr[0]);
          if (this.isAnswer(tans)) {
            q = {
              q: '',
              a: [],
              ans: tans,
              type: 'single',
              qid: 0,
              questionID: 0
            };
            arr[i] = `）${tarr[1].trim()}`;
            if (i === arr.length - 1 && tarr.length === 2 && !tarr[1].trim()) {
              q.q = this.join('（', arr, arr.length - 1);
            } else {
              q.q = this.join('（', arr, -1);
            }
            return q;
          }
        }
      }
    }
    if (!q) {
      q = {
        q: '',
        a: [],
        ans: '',
        type: 'single',
        qid: 0,
        questionID: 0
      };
      ss = s.trim();
      let size = ss.length;
      for (let i = 0; i < ss.length; i++) {
        let tans = this.formatAnswer(ss.substring(size - 1 - i));
        if (!this.isAnswer(tans)) {
          break;
        }
        q.ans = tans;
        q.q = ss.substring(0, size - 1 - i);
      }
      if (q.q) {
        return q;
      }
    }
    return null;
  }

  // 格式化题目（处理判断题答案，验证答案有效性）
  private formatQuestion(q: QuestionModel | null): QuestionModel | null {
    if (!q || !q.q || !q.ans) {
      return null;
    }
    if (this.isAnswer(q.ans)) {
      if (['×', 'X', 'N', '错误', '错'].some(s => q.ans.includes(s))) {
        q.a = ['正确', '错误'];
        q.ans = 'B';
        q.type = 'truefalse';
      } else if (['√', '✔', 'Y', '正确', '对'].some(s => q.ans.includes(s))) {
        q.a = ['正确', '错误'];
        q.ans = 'A';
        q.type = 'truefalse';
      } else {
        q.type = q.ans.length > 1 ? 'multiple' : 'single';
      }
      let lastAns = q.ans[q.ans.length - 1];
      if (this.ANSWERLABEL.includes(lastAns)) {
        let idx = this.ANSWERLABEL.indexOf(lastAns);
        if (idx >= q.a.length) {
          return null;
        }
      }
      return q;
    }
    return null;
  }

  // 核心解析函数
  private parse(data: string[]): ImportWithLog | null {
    if (!data || data.length === 0) {
      return null;
    }
    let res: ImportWithLog = { items: [], logs: [] };
    let cur: QuestionModel | null = null;
    for (let lineid = 0; lineid < data.length; lineid++) {
      let s = data[lineid];
      if (!s || !s.trim()) {
        continue;
      }
      let ss = this.preProcess(s);
      console.info(`行：${ss}`);
      if (!ss || !ss.trim()) {
        continue;
      }
      if (/\d/.test(ss[0])) {
        if (cur) {
          cur = this.formatQuestion(cur);
          if (cur) {
            res.items.push(cur);
            console.info(`完成：${JSON.stringify(cur)}`);
            cur = null;
          } else {
            console.info('formatQuestion：null');
          }
        }
        ss = this.removeQid(ss);
        console.info(`removeQid：${ss}`);
        cur = this.parseQuestion(ss);
        if (!cur || !cur.q) {
          cur = {
            q: ss,
            a: [],
            ans: '',
            type: 'single',
            qid: 0,
            questionID: 0
          };
          console.info('parseQuestion：null');
        } else {
          console.info(`parseQuestion：${JSON.stringify(cur)}`);
        }
      } else if (this.ANSWERLABEL.includes(ss[0])) {
        let pa = this.parseAnswers(ss);
        if (cur) {
          cur.a.push(...pa);
        }
        console.info(`parseAnswers：${JSON.stringify(pa)}`);
      } else if (ss.startsWith('答案') || ss.startsWith('正确答案') || ss.startsWith('参考答案')) {
        if (!cur) {
          res.logs.push(`第${lineid + 1}行：${s}\n没识别到题干答案。即将跳过这道题`);
          continue;
        }
        let ans = '';
        ss = ss.replace('正确答案', '').replace('参考答案', '').replace('答案', '');
        for (let i = 0; i < ss.length; i++) {
          let t = ss[i].toUpperCase();
          if (this.labels.includes(t)) {
            ans += t;
          }
        }
        console.info(`parse ans：${ans}`);
        if (this.isAnswer(ans)) {
          cur.ans = ans;
          cur = this.formatQuestion(cur);
          if (cur) {
            res.items.push(cur);
            console.info(`完成：${JSON.stringify(cur)}`);
            cur = null;
          }
        } else {
          res.logs.push(`第${lineid + 1}行：${s}\n没解析到答案。即将跳过这道题`);
        }
      } else {
        res.logs.push(`第${lineid +
          1}行：${s}\n该行不是以题目数字开头，也不是以ABCD选项开头，也不是标记答案行。即将跳过该行。`);
      }
    }
    if (cur) {
      cur = this.formatQuestion(cur);
      if (cur) {
        res.items.push(cur);
        console.info(`完成：${JSON.stringify(cur)}`);
      } else {
        console.info('formatQuestion：null');
      }
    }
    return res;
  }

  // 读取并解析TXT文件
  async parseTxtFile(filePath: string): Promise<ImportWithLog | null> {
    if (!filePath || typeof filePath !== 'string') {
      console.error('文件路径无效');
      promptAction.showToast({ message: '文件路径无效', duration: 2000 });
      return null;
    }

    let file: fs.File | null = null;
    try {
      file = fs.openSync(filePath, fs.OpenMode.READ_ONLY);
      console.info(`成功打开文件: ${filePath}`);
      try {
        let stat: fs.Stat;
        console.info(`尝试获取文件状态: ${filePath}`);
        stat = fs.statSync(file.path);
        console.info(`文件状态: size=${stat.size}, mtime=${stat.mtime}`);

        let buffer: ArrayBuffer = new ArrayBuffer(stat.size);
        let bytesRead: number = fs.readSync(file.fd, buffer);

        let decoder = util.TextDecoder.create('utf-8', { ignoreBOM: true });
        let text: string = decoder.decodeWithStream(new Uint8Array(buffer).slice(0, bytesRead));
        let lines: string[] =
          text.split('\n').map((line: string) => line.trim()).filter((line: string) => line.length > 0);


        if (lines.length === 0) {
          console.error('文件为空或无有效内容');
          promptAction.showToast({ message: '文件中没有有效内容', duration: 2000 });
          return null;
        }

        let result: ImportWithLog | null = this.parse(lines);
        if (!result || result.items.length === 0) {
          console.error('没有解析到有效题目');
          promptAction.showToast({ message: '文件中没有有效题目', duration: 2000 });
          return null;
        }

        // 生成数字类型流水号 qid：秒级时间戳 * 10000 + 4 位随机数
        const ts = Math.floor(Date.now() / 1000);
        const rand4 = Math.floor(Math.random() * 10000);
        const qid = ts * 10000 + rand4;
        result.items.forEach((item, idx) => {
          item.qid = qid;
          item.questionID = qid + 1 + idx;
        });
        return result;
      } catch (statError) {
        let err: BusinessError = statError as BusinessError;
        console.error(`获取文件状态失败: filePath=${filePath}, code=${err.code}, message=${err.message}`);
        let message: string = '获取文件状态失败';
        if (err.code === 13900002) {
          message = `文件不存在或路径错误: ${filePath}`;
        } else if (err.code === 13900004) {
          message = `无权限访问文件: ${filePath}`;
        }
        promptAction.showToast({ message: message, duration: 2000 });
        return null; // 提前返回，避免使用未初始化的 stat
      }
    } catch (error) {
      let err: BusinessError = error as BusinessError;
      let message: string = '解析文件失败';
      if (err.code === 13900002) {
        message = `文件不存在或路径错误: ${filePath}`;
      } else if (err.code === 13900004) {
        message = `无权限访问文件: ${filePath}`;
      } else {
        message = `解析文件失败: ${filePath} (错误: ${err.message})`;
      }
      console.error(`解析文件失败: code=${err.code}, message=${err.message}, filePath=${filePath}`);
      promptAction.showToast({ message: message, duration: 2000 });
      return null;
    } finally {
      if (file) {
        try {
          fs.closeSync(file);
          console.info(`成功关闭文件: ${filePath}`);
        } catch (closeError) {
          console.error(`关闭文件失败: ${(closeError as BusinessError).message}`);
        }
      }
    }
  }

  // 字符串拼接
  private join(delimiter: string, list: string[], endpos: number): string {
    if (!list || list.length === 0) {
      return '';
    }
    let resstr = list[0];
    for (let i = 1; i < list.length; i++) {
      if (endpos !== -1 && i === endpos) {
        break;
      }
      resstr += delimiter + list[i];
    }
    return resstr;
  }

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
      // 根据题目类型生成错误答案
      questionRes.wrongAnswer = ""
      questionResList.push(questionRes);
      console.log("查看questionResList：" + JSON.stringify(questionResList))
    });

    return questionResList;
  }

  // 获取当前格式化时间
  private getFormattedTime(): string {
    const now = new Date();
    const year = now.getFullYear();
    const month = String(now.getMonth() + 1).padStart(2, '0');
    const day = String(now.getDate()).padStart(2, '0');
    return `${year}-${month}-${day}`;
  }

  // 在自定义组件即将析构销毁时将dialogController置空
  aboutToDisappear() {
    this.dialogController = null;
    this.resultDialogController = null;
  }

  async aboutToAppear(): Promise<void> {
    try {
      const documentPicker = new picker.DocumentViewPicker();
      const resultPath: string[] = await documentPicker.select({
        fileSuffixFilters: ['.txt', '.xlsx', '.xls']
      });

      if (!resultPath || resultPath.length === 0) {
        console.error('用户未选择文件');
        this.message = '未选择文件，请选择一个有效的 .txt 文件';
        promptAction.showToast({ message: '未选择文件', duration: 2000 });
        return;
      }

      const filePath: string = resultPath[0];
      console.info(`文件路径: ${filePath}`);

      if (!filePath.endsWith('.txt')) {
        console.error(`不支持的文件类型: ${filePath}`);
        this.message = '仅支持 .txt 文件，请选择正确文件类型';
        promptAction.showToast({ message: '仅支持 .txt 文件', duration: 2000 });
        return;
      }

      let result: ImportWithLog | null = await this.parseTxtFile(filePath);
      if (!result) {
        this.message = '解析失败';
        promptAction.showToast({ message: '解析失败', duration: 2000 });
        return;
      }

      // 输入题库名称
      let bankName: string = '自定义题库';
      let isConfirmed: boolean = false;
      await new Promise<void>((resolve) => {
        this.dialogController = new CustomDialogController({
          builder: InputDialog({
            confirm: (value: string) => {
              console.info(`确认输入: ${value}`);
              bankName = value.trim() || '自定义题库';
              isConfirmed = true;
              resolve();
            },
            cancel: () => {
              console.info('取消输入');
              resolve();
            }
          })
        });
        this.dialogController?.open();
      });

      if (!isConfirmed) {
        this.message = '取消导入';
        promptAction.showToast({ message: '取消导入', duration: 2000 });
        return;
      }

      // 创建BankListRes
      const bank: BankListRes = {
        id: -1,
        qid: result.items[0]?.qid || 0,
        name: bankName,
        desc: bankName,
        time: this.getFormattedTime(),
        url: '',
        num: result.items.length.toString(),
        version: '1.0',
        position: 0,
        downloadedState: 1,
        bankType: 2
      };

      let output: string = '';
      let successCount = 0;

      // 插入题库
      try {
        await questionBankTable.insertDataAwait(bank);
        console.info(`成功插入题库: ${JSON.stringify(bank)}`);
        output += `题库名称: ${bank.name}\n题目数量: ${bank.num}\n创建时间: ${bank.time}\n\n`;
      } catch (error) {
        const err: BusinessError = error as BusinessError;
        console.error(`插入题库失败: ${err.message}`);
        result.logs.push(`插入题库失败: ${err.message}`);
        this.message = `插入题库失败: ${err.message}`;
        promptAction.showToast({ message: '插入题库失败', duration: 2000 });
        return;
      }

      // 插入题目
      let questionResList: QuestionRes[] = this.toQuestionResList(result);
      for (let item of questionResList) {
        try {
          item.qName = bank.name
          await questionTable.insertDataAwait(item);
          successCount++;
          output += `[qId=${item.qId}, questionID=${item.questionID}]\n`;
          output += `题干: ${item.question}\n`;
          output += `选项: ${item.option.join('；')}\n`;
          output += `答案: ${item.answer}\n\n`;
        } catch (error) {
          const err: BusinessError = error as BusinessError;
          console.error(`插入题目失败: questionID=${item.questionID}, error=${err.message}`);
          result.logs.push(`插入题目失败: questionID=${item.questionID}, 错误: ${err.message}`);
        }
      }

      // 显示成功提示
      await new Promise<void>((resolve) => {
        this.resultDialogController = new CustomDialogController({
          builder: ResultDialog({
            message: `成功导入 ${successCount} 道题目`,
            confirm: () => {
              console.info('确认成功提示');
              resolve();
            }
          })
        });
        this.resultDialogController?.open();
      });

      result.logs.forEach((log: string) => {
        output += `错误: ${log}\n`;
      });

      this.message = `成功插入题库: ${bank.name}\n成功导入 ${successCount} 道题目\n\n${output}`;
      promptAction.showToast({ message: `成功导入 ${successCount} 道题目`, duration: 2000 });
    } catch (error) {
      const err: BusinessError = error as BusinessError;
      console.error(`读取文件失败: code=${err.code}, message=${err.message}`);
      this.message = `文件读取失败: ${err.message} (错误码: ${err.code})`;
      promptAction.showToast({ message: '文件读取失败', duration: 2000 });
    }
  }

  build() {
    Column() {
      Scroll() {
        Text(this.message)
          .fontSize(16)
          .margin(20)
          .textAlign(TextAlign.Start)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Color.White)
  }
}
