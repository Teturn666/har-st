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

interface GeneratedTypeLiteralInterface {
  text: string;
  encoding: string;
}

export class ParseTxtManage {
  private ANSWERLABEL: string = 'ABCDEFGHI';
  private SKIPSTR: string = ' 、.．，,\t';
  private labels: string = 'ABCDEFGHI对错√×✔X正确错误YN';
  // 支持的编码格式列表
  private readonly supportedEncodings = ['UTF-8', 'UTF-16le', 'UTF-16be', 'gb18030', 'gbk', 'gb2312'];

  // 检测文件编码
  private detectEncoding(buffer: Uint8Array): string {
    // 检查BOM
    if (buffer.length >= 3 && buffer[0] === 0xEF && buffer[1] === 0xBB && buffer[2] === 0xBF) {
      return 'UTF-8';
    }
    if (buffer.length >= 2 && buffer[0] === 0xFF && buffer[1] === 0xFE) {
      return 'UTF-16le';
    }
    if (buffer.length >= 2 && buffer[0] === 0xFE && buffer[1] === 0xFF) {
      return 'UTF-16be';
    }

    // 检测UTF-16（无BOM）
    if (this.isLikelyUTF16(buffer)) {
      // 简单判断字节序，通常小端序更常见
      return 'UTF-16le';
    }

    // 尝试检测GB18030/GBK编码
    if (this.isLikelyGB18030(buffer)) {
      return 'gb18030';
    }

    // 尝试检测UTF-8（无BOM）
    if (this.isValidUTF8(buffer)) {
      return 'UTF-8';
    }

    // 检查是否为ASCII
    if (this.isASCII(buffer)) {
      return 'UTF-8'; // ASCII兼容UTF-8
    }

    // 默认返回GB18030
    return 'gb18030';
  }

  // 检测是否可能是UTF-16编码
  private isLikelyUTF16(buffer: Uint8Array): boolean {
    if (buffer.length < 4) {
      return false;
    }

    let nullCount = 0;
    let totalBytes = Math.min(buffer.length, 100);

    for (let i = 0; i < totalBytes; i++) {
      if (buffer[i] === 0) {
        nullCount++;
      }
    }

    // 如果null字节占比超过20%，可能是UTF-16
    return (nullCount / totalBytes) > 0.2;
  }

  // 检测是否为纯ASCII
  private isASCII(buffer: Uint8Array): boolean {
    for (let i = 0; i < Math.min(buffer.length, 1000); i++) {
      if (buffer[i] > 127) {
        return false;
      }
    }
    return true;
  }

  // 检测是否可能是GB18030编码
  private isLikelyGB18030(buffer: Uint8Array): boolean {
    let gb18030Count = 0;
    let totalBytes = 0;

    for (let i = 0; i < Math.min(buffer.length, 1000); i++) {
      const byte = buffer[i];
      totalBytes++;

      // GB18030/GBK双字节字符范围
      if (byte >= 0x81 && byte <= 0xFE) {
        if (i + 1 < buffer.length) {
          const nextByte = buffer[i + 1];
          // 检查是否符合GBK编码规则
          if ((nextByte >= 0x40 && nextByte <= 0x7E) || (nextByte >= 0x80 && nextByte <= 0xFE)) {
            gb18030Count += 2;
            i++; // 跳过下一个字节
            totalBytes++;
          }
        }
      }
    }

    // 如果GB18030字符占比超过30%，认为是GB18030编码
    return totalBytes > 0 && (gb18030Count / totalBytes) > 0.3;
  }

  // 检测是否是有效的UTF-8编码
  private isValidUTF8(buffer: Uint8Array): boolean {
    let i = 0;
    let validUTF8Count = 0;
    let totalSequences = 0;

    while (i < Math.min(buffer.length, 1000)) {
      const byte = buffer[i];
      totalSequences++;

      if (byte <= 0x7F) {
        // ASCII字符
        validUTF8Count++;
        i++;
      } else if ((byte & 0xE0) === 0xC0) {
        // 2字节UTF-8序列
        if (i + 1 < buffer.length && (buffer[i + 1] & 0xC0) === 0x80) {
          validUTF8Count++;
          i += 2;
        } else {
          i++;
        }
      } else if ((byte & 0xF0) === 0xE0) {
        // 3字节UTF-8序列
        if (i + 2 < buffer.length &&
          (buffer[i + 1] & 0xC0) === 0x80 &&
          (buffer[i + 2] & 0xC0) === 0x80) {
          validUTF8Count++;
          i += 3;
        } else {
          i++;
        }
      } else if ((byte & 0xF8) === 0xF0) {
        // 4字节UTF-8序列
        if (i + 3 < buffer.length &&
          (buffer[i + 1] & 0xC0) === 0x80 &&
          (buffer[i + 2] & 0xC0) === 0x80 &&
          (buffer[i + 3] & 0xC0) === 0x80) {
          validUTF8Count++;
          i += 4;
        } else {
          i++;
        }
      } else {
        i++;
      }
    }

    return totalSequences > 0 && (validUTF8Count / totalSequences) > 0.7;
  }

  // 尝试用支持的编码解码文本
  private tryDecodeTextWithSupportedEncodings(buffer: Uint8Array): GeneratedTypeLiteralInterface | null {
    for (const encoding of this.supportedEncodings) {
      try {
        const decoder = util.TextDecoder.create(encoding, { ignoreBOM: true });
        const text = decoder.decodeToString(buffer);

        // 检查解码结果是否包含有效中文字符或看起来合理
        if (this.isValidDecodedText(text)) {
          console.info(`成功使用编码 ${encoding} 解码文本`);
          return { text, encoding };
        }
      } catch (error) {
        console.warn(`编码 ${encoding} 解码失败: ${error}`);
        continue;
      }
    }

    return null;
  }

  // 更严格的文本有效性检查
  private isValidDecodedText(text: string): boolean {
    if (!text || text.length === 0) {
      return false;
    }

    // 检查是否包含过多的乱码字符
    const invalidChars = text.match(/[������]/g);
    const invalidRatio = invalidChars ? invalidChars.length / text.length : 0;

    // 如果乱码字符超过5%，认为解码失败
    if (invalidRatio > 0.05) {
      return false;
    }

    // 检查是否包含过多控制字符（除了常见的换行、制表符）
    const controlChars = text.match(/[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]/g);
    const controlRatio = controlChars ? controlChars.length / text.length : 0;

    // 如果控制字符超过1%，认为解码失败
    if (controlRatio > 0.01) {
      return false;
    }

    // 检查是否包含常见的中文字符、数字或字母
    const hasValidContent = /[\u4e00-\u9fff\d\w\s]/.test(text);

    return hasValidContent;
  }

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
            res.logs.push(`第${lineid + 1}行: 题目格式化失败: ${s}`);
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
      }
    }
    console.info(`解析完成: items=${res.items.length}, logs=${res.logs.length}`);
    return res;
  }

  // 解析TXT文件 - 支持多种编码格式
  async parseTxtFile(filePath: string): Promise<ImportWithLog | null> {
    if (!filePath || typeof filePath !== 'string') {
      console.error('文件路径无效');
      promptAction.showToast({ message: '导入失败: 文件不存在或者内容格式异常', duration: 2000 });
      return null;
    }

    let file: fs.File | null = null;
    try {
      file = fs.openSync(filePath, fs.OpenMode.READ_ONLY);
      console.info(`成功打开文件: ${filePath}`);

      try {
        let stat: fs.Stat = fs.statSync(file.path);
        console.info(`文件状态: size=${stat.size}, mtime=${stat.mtime}`);

        // 检查文件大小，防止空文件
        if (stat.size === 0) {
          console.error('文件为空');
          promptAction.showToast({ message: '导入失败: 文件不存在或者内容格式异常', duration: 2000 });
          return null;
        }

        let buffer: ArrayBuffer = new ArrayBuffer(stat.size);
        let bytesRead: number = fs.readSync(file.fd, buffer);
        let bufferView = new Uint8Array(buffer).slice(0, bytesRead);

        // 检测文件编码
        let detectedEncoding = this.detectEncoding(bufferView);
        console.info(`检测到编码: ${detectedEncoding}`);

        // 检查是否为支持的编码
        if (!this.supportedEncodings.includes(detectedEncoding)) {
          console.error(`不支持的编码格式: ${detectedEncoding}`);
          promptAction.showToast({
            message: '导入失败: 文件不存在或者内容格式异常',
            duration: 2000
          });
          return null;
        }

        let text: string = '';
        let actualEncoding = detectedEncoding;

        try {
          // 首先尝试检测到的编码
          let decoder = util.TextDecoder.create(detectedEncoding, { ignoreBOM: true });
          text = decoder.decodeToString(bufferView);

          // 验证解码结果
          if (!this.isValidDecodedText(text)) {
            console.warn(`使用 ${detectedEncoding} 编码解码结果不理想，尝试其他编码`);
            throw new Error('解码结果无效');
          }
        } catch (error) {
          console.warn(`使用 ${detectedEncoding} 编码失败，尝试其他编码: ${error}`);

          // 尝试支持的编码解码
          const decodeResult = this.tryDecodeTextWithSupportedEncodings(bufferView);
          if (decodeResult) {
            text = decodeResult.text;
            actualEncoding = decodeResult.encoding;
            console.info(`成功使用 ${actualEncoding} 编码解码文件`);
          } else {
            console.error('所有支持的编码尝试均失败');
            promptAction.showToast({
              message: '导入失败: 文件不存在或者内容格式异常',
              duration: 2000
            });
            return null;
          }
        }

        // 检查解码后的文本是否有效
        if (!text || text.trim().length === 0) {
          console.error('解码后文本为空');
          promptAction.showToast({
            message: '导入失败: 文件不存在或者内容格式异常',
            duration: 2000
          });
          return null;
        }

        let lines: string[] = text
          .split('\n')
          .map((line: string) => line.trim())
          .filter((line: string) => line.length > 0);

        if (lines.length === 0) {
          console.error('文件为空或无有效内容');
          promptAction.showToast({
            message: '导入失败: 文件不存在或者内容格式异常',
            duration: 2000
          });
          return null;
        }

        // 检查是否为JSON格式
        try {
          const firstLine = lines.find(line => line.length > 0);
          if (firstLine && firstLine.startsWith('{')) {
            JSON.parse(firstLine);
            console.info('检测到JSON格式内容，调用parseJsonFile');
            return await this.parseJsonFile(filePath);
          }
        } catch (e) {
          console.info('非JSON格式内容，继续按普通文本解析');
        }

        let result: ImportWithLog | null = this.parse(lines);
        if (!result || result.items.length === 0) {
          console.error('没有解析到有效题目');
          promptAction.showToast({
            message: '导入失败: 文件不存在或者内容格式异常',
            duration: 2000
          });
          return null;
        }

        // 添加编码信息到日志
        // result.logs.unshift(`文件编码: ${actualEncoding}`);

        this.generateQuestionIDs(result);
        console.info(`解析完成: items=${result.items.length}, logs=${result.logs.length}, encoding=${actualEncoding}`);
        return result;

      } catch (statError) {
        let err: BusinessError = statError as BusinessError;
        console.error(`获取文件状态失败: filePath=${filePath}, code=${err.code}, message=${err.message}`);
        promptAction.showToast({
          message: '导入失败: 文件不存在或者内容格式异常',
          duration: 2000
        });
        return null;
      }
    } catch (error) {
      let err: BusinessError = error as BusinessError;
      console.error(`解析文件失败: code=${err.code}, message=${err.message}, filePath=${filePath}`);
      promptAction.showToast({
        message: '导入失败: 文件不存在或者内容格式异常',
        duration: 2000
      });
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

  // 生成题目ID
  private generateQuestionIDs(result: ImportWithLog): void {
    const ts = Math.floor(Date.now() / 1000);
    const baseQid = ts * 10000 + Math.floor(Math.random() * 10000);
    result.items.forEach((item, index) => {
      item.qid = baseQid;
      item.questionID = baseQid + index + 1;
    });
  }
}
