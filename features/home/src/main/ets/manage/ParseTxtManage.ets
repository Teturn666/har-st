import { util } from '@kit.ArkTS';
import fs from '@ohos.file.fs';
import promptAction from '@ohos.promptAction';
import { BusinessError } from '@ohos.base';

export interface QuestionModel {
  q: string;
  a: string[];
  ans: string;
  type: 'single' | 'multiple' | 'truefalse';
  qid: number;
  questionID: number;
}

export interface ImportWithLog {
  items: QuestionModel[];
  logs: string[];
}

export class ParseTxtManage {
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

  // 预处理
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

  // 解析题干
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
            q.q =
              this.join('（', arr, i === arr.length - 1 && tarr.length === 2 && !tarr[1].trim() ? arr.length - 1 : -1);
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

  // 格式化题目
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

  // 判断是否为题目行
  private isQuestionLine(s: string): boolean {
    return /^\d+[.、]/.test(s) || (s.includes('（') && s.includes('）'));
  }

  // 提取题干内容
  private extractQuestion(s: string): string {
    return this.removeQid(s);
  }

  // 处理答案行
  private processAnswer(question: QuestionModel | null, line: string): void {
    if (!question) {
      return;
    }

    let ans = '';
    line = line.replace('正确答案', '').replace('参考答案', '').replace('答案', '');
    for (let i = 0; i < line.length; i++) {
      let t = line[i].toUpperCase();
      if (this.labels.includes(t)) {
        ans += t;
      }
    }

    if (this.isAnswer(ans)) {
      question.ans = ans;
      this.formatQuestionType(question);
    }
  }

  // 格式化题目类型
  private formatQuestionType(q: QuestionModel): void {
    const isTrueFalse = ['×', 'X', 'N', '错误', '错', '√', '✔', 'Y', '正确', '对'].some(s => q.ans.includes(s));
    if (isTrueFalse && q.a.length === 0) {
      q.a = ['正确', '错误'];
      q.ans = q.ans.includes('×') || q.ans.includes('X') || q.ans.includes('N') ||
      q.ans.includes('错误') || q.ans.includes('错') ? 'B' : 'A';
      q.type = 'truefalse';
    } else {
      q.type = q.ans.length > 1 ? 'multiple' : 'single';
    }
  }

  // 刷新当前题目
  private flushCurrentQuestion(res: ImportWithLog, question: QuestionModel | null): void {
    if (question) {
      const formatted = this.formatQuestion(question);
      if (formatted) {
        res.items.push(formatted);
      }
    }
  }

  // 验证题目有效性
  private validateQuestion(q: QuestionModel): QuestionModel | null {
    if (!q.q || !q.ans || (q.type !== 'truefalse' && q.a.length === 0)) {
      return null;
    }
    q.ans = q.ans.split('').filter(c => this.ANSWERLABEL.includes(c)).join('');
    return q.ans ? q : null;
  }

  // 生成题目ID
  private generateQuestionIDs(result: ImportWithLog): void {
    const ts = Math.floor(Date.now() / 1000);
    const baseQid = ts * 10000 + Math.floor(Math.random() * 10000);
    result.items.forEach((item, index) => {
      item.qid = baseQid;
      item.questionID = baseQid + index + 1;
    });
  }

  // 字符串拼接
  private join(delimiter: string, list: string[], endpos: number): string {
    if (!list || list.length === 0) {
      return '';
    }
    let resstr = list[0];
    for (let i = 1; i < list.length && (endpos === -1 || i < endpos); i++) {
      resstr += delimiter + list[i];
    }
    return resstr;
  }

  // 核心解析函数
  private parse(data: string[]): ImportWithLog | null {
    if (!data || data.length === 0) {
      console.error('输入数据为空或无效');
      return null;
    }
    let res: ImportWithLog = { items: [], logs: [] };
    let cur: QuestionModel | null = null;
    console.info(`开始解析 ${data.length} 行数据`);

    for (let lineid = 0; lineid < data.length; lineid++) {
      let s = data[lineid];
      if (!s || !s.trim()) {
        console.info(`第${lineid + 1}行: 空行，跳过`);
        continue;
      }
      let ss = this.preProcess(s);
      console.info(`第${lineid + 1}行: 预处理后: ${ss}`);
      if (!ss || !ss.trim()) {
        console.info(`第${lineid + 1}行: 预处理后为空，跳过`);
        continue;
      }
      if (/\d/.test(ss[0])) {
        if (cur) {
          cur = this.formatQuestion(cur);
          if (cur) {
            res.items.push(cur);
            console.info(`第${lineid + 1}行: 完成题目: ${JSON.stringify(cur)}`);
          } else {
            console.info(`第${lineid + 1}行: formatQuestion 返回 null`);
            res.logs.push(`第${lineid + 1}行: 题目格式化失败`);
          }
          cur = null;
        }
        ss = this.removeQid(ss);
        console.info(`第${lineid + 1}行: 移除题号后: ${ss}`);
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
          console.info(`第${lineid + 1}行: parseQuestion 返回 null，初始化默认题目`);
        } else {
          console.info(`第${lineid + 1}行: parseQuestion: ${JSON.stringify(cur)}`);
        }
      } else if (this.ANSWERLABEL.includes(ss[0])) {
        let pa = this.parseAnswers(ss);
        if (cur) {
          cur.a.push(...pa);
          console.info(`第${lineid + 1}行: 解析选项: ${JSON.stringify(pa)}`);
        } else {
          console.info(`第${lineid + 1}行: 无当前题目，选项行被忽略: ${ss}`);
          res.logs.push(`第${lineid + 1}行: 无题目上下文，选项行被忽略: ${ss}`);
        }
      } else if (ss.startsWith('答案') || ss.startsWith('正确答案') || ss.startsWith('参考答案')) {
        if (!cur) {
          console.info(`第${lineid + 1}行: 无当前题目，答案行被忽略: ${ss}`);
          res.logs.push(`第${lineid + 1}行: 没识别到题干答案。即将跳过这道题: ${s}`);
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
        console.info(`第${lineid + 1}行: 解析答案: ${ans}`);
        if (this.isAnswer(ans)) {
          cur.ans = ans;
          cur = this.formatQuestion(cur);
          if (cur) {
            res.items.push(cur);
            console.info(`第${lineid + 1}行: 完成题目: ${JSON.stringify(cur)}`);
          } else {
            console.info(`第${lineid + 1}行: formatQuestion 返回 null`);
            res.logs.push(`第${lineid + 1}行: 答案格式化失败: ${s}`);
          }
          cur = null;
        } else {
          console.info(`第${lineid + 1}行: 无效答案: ${ans}`);
          res.logs.push(`第${lineid + 1}行: 没解析到有效答案。即将跳过这道题: ${s}`);
        }
      } else {
        console.info(`第${lineid + 1}行: 不符合题目/选项/答案格式: ${ss}`);
        res.logs.push(`第${lineid +
          1}行: ${s}\n该行不是以题目数字开头，也不是以ABCD选项开头，也不是标记答案行。即将跳过该行。`);
      }
    }
    if (cur) {
      cur = this.formatQuestion(cur);
      if (cur) {
        res.items.push(cur);
        console.info(`最后题目: 完成: ${JSON.stringify(cur)}`);
      } else {
        console.info(`最后题目: formatQuestion 返回 null`);
        res.logs.push(`最后题目: 题目格式化失败`);
      }
    }
    console.info(`解析完成: items=${res.items.length}, logs=${res.logs.length}`);
    return res;
  }

  // 解析TXT文件
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

        try {
          const firstLine = lines.find(line => line.length > 0);
          if (firstLine) {
            JSON.parse(firstLine);
            console.info('检测到JSON格式内容，调用parseJsonFile');
            return await this.parseJsonFile(filePath);
          }
        } catch (e) {
          // Not JSON, proceed with regular text parsing
          console.info('非JSON格式内容，继续按普通文本解析');
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

  // 解析JSON格式的TXT文件
  async parseJsonFile(filePath: string): Promise<ImportWithLog | null> {
    if (!filePath || typeof filePath !== 'string') {
      console.error('文件路径无效');
      promptAction.showToast({ message: '文件路径无效', duration: 2000 });
      return null;
    }

    let file: fs.File | null = null;
    try {
      file = fs.openSync(filePath, fs.OpenMode.READ_ONLY);
      console.info(`成功打开JSON文件: ${filePath}`);
      try {
        let stat = fs.statSync(file.path);
        console.info(`JSON文件状态: size=${stat.size}, mtime=${stat.mtime}`);

        let buffer = new ArrayBuffer(stat.size);
        let bytesRead = fs.readSync(file.fd, buffer);

        let decoder = util.TextDecoder.create('utf-8', { ignoreBOM: true });
        let text = decoder.decodeWithStream(new Uint8Array(buffer).slice(0, bytesRead));
        let lines = text.split('\n').map(line => line.trim()).filter(line => line.length > 0);

        if (lines.length === 0) {
          console.error('JSON文件为空或无有效内容');
          promptAction.showToast({ message: 'JSON文件中没有有效内容', duration: 2000 });
          return null;
        }

        let res: ImportWithLog = { items: [], logs: [] };
        for (let lineid = 0; lineid < lines.length; lineid++) {
          let s = lines[lineid];
          if (!s || !s.trim()) {
            console.info(`第${lineid + 1}行: 空行，跳过`);
            continue;
          }
          try {
            let model: QuestionModel = JSON.parse(s.trim());
            if (model && model.q && model.ans) {
              // Validate and format the question
              let formatted = this.formatQuestion(model);
              if (formatted) {
                res.items.push(formatted);
                console.info(`第${lineid + 1}行: 成功解析JSON题目: ${JSON.stringify(formatted)}`);
              } else {
                res.logs.push(`第${lineid + 1}行: 题目格式化失败: ${s}`);
                console.info(`第${lineid + 1}行: formatQuestion 返回 null`);
              }
            } else {
              res.logs.push(`第${lineid + 1}行: JSON题目缺少必要字段: ${s}`);
              console.info(`第${lineid + 1}行: JSON题目无效`);
            }
          } catch (e) {
            let err = e as BusinessError;
            res.logs.push(`第${lineid + 1}行: ${s}\nJSON格式异常: ${err.message}`);
            console.error(`第${lineid + 1}行: JSON解析失败: ${err.message}`);
          }
        }

        if (res.items.length === 0) {
          console.error('没有解析到有效JSON题目');
          promptAction.showToast({ message: 'JSON文件中没有有效题目', duration: 2000 });
          return null;
        }

        // Generate question IDs
        this.generateQuestionIDs(res);
        console.info(`JSON解析完成: items=${res.items.length}, logs=${res.logs.length}`);
        return res;
      } catch (statError) {
        let err = statError as BusinessError;
        console.error(`获取JSON文件状态失败: filePath=${filePath}, code=${err.code}, message=${err.message}`);
        let message = '获取JSON文件状态失败';
        if (err.code === 13900002) {
          message = `JSON文件不存在或路径错误: ${filePath}`;
        } else if (err.code === 13900004) {
          message = `无权限访问JSON文件: ${filePath}`;
        }
        promptAction.showToast({ message, duration: 2000 });
        return null;
      }
    } catch (error) {
      let err = error as BusinessError;
      let message = '解析JSON文件失败';
      if (err.code === 13900002) {
        message = `JSON文件不存在或路径错误: ${filePath}`;
      } else if (err.code === 13900004) {
        message = `无权限访问JSON文件: ${filePath}`;
      } else {
        message = `解析JSON文件失败: ${filePath} (错误: ${err.message})`;
      }
      console.error(`解析JSON文件失败: code=${err.code}, message=${err.message}, filePath=${filePath}`);
      promptAction.showToast({ message, duration: 2000 });
      return null;
    } finally {
      if (file) {
        try {
          fs.closeSync(file);
          console.info(`成功关闭JSON文件: ${filePath}`);
        } catch (closeError) {
          console.error(`关闭JSON文件失败: ${(closeError as BusinessError).message}`);
        }
      }
    }
  }
}