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
  private readonly supportedEncodings = ['UTF-8', 'UTF-16le', 'UTF-16be', 'gb18030', 'gbk', 'gb2312'];

  private detectEncoding(buffer: Uint8Array): string {
    if (buffer.length >= 3 && buffer[0] === 0xEF && buffer[1] === 0xBB && buffer[2] === 0xBF) {
      return 'UTF-8';
    }
    if (buffer.length >= 2 && buffer[0] === 0xFF && buffer[1] === 0xFE) {
      return 'UTF-16le';
    }
    if (buffer.length >= 2 && buffer[0] === 0xFE && buffer[1] === 0xFF) {
      return 'UTF-16be';
    }

    if (this.isASCII(buffer)) {
      return 'UTF-8';
    }

    if (this.isLikelyUTF16(buffer)) {
      return 'UTF-16le';
    }

    if (this.isLikelyGB18030(buffer)) {
      return 'gb18030';
    }

    if (this.isValidUTF8(buffer)) {
      return 'UTF-8';
    }

    if (this.isLikelyGB18030(buffer)) {
      return 'gb18030';
    }

    return 'UTF-8';
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

    return (nullCount / totalBytes) > 0.2;
  }

  private isASCII(buffer: Uint8Array): boolean {
    for (let i = 0; i < Math.min(buffer.length, 1000); i++) {
      if (buffer[i] > 127) {
        return false;
      }
    }
    return true;
  }

  private isLikelyGB18030(buffer: Uint8Array): boolean {
    let validGB18030Pairs = 0;
    let totalPairs = 0;
    let hasGBChars = false;

    for (let i = 0; i < Math.min(buffer.length - 1, 1000); i++) {
      const byte1 = buffer[i];
      const byte2 = buffer[i + 1];

      // 跳过ASCII字符
      if (byte1 <= 0x7F) {
        continue;
      }

      totalPairs++;

      // 检查GB18030/GBK双字节字符范围
      if (byte1 >= 0x81 && byte1 <= 0xFE) {
        if ((byte2 >= 0x40 && byte2 <= 0x7E) || (byte2 >= 0x80 && byte2 <= 0xFE)) {
          if ((byte1 & 0xF0) === 0xE0 && (byte2 & 0xC0) === 0x80) {
            continue;
          }

          validGB18030Pairs++;
          hasGBChars = true;
          i++;
        }
      }
    }

    return hasGBChars && totalPairs > 0 && (validGB18030Pairs / totalPairs) > 0.8;
  }

  private isValidUTF8(buffer: Uint8Array): boolean {
    let i = 0;
    let validSequences = 0;
    let totalChecked = 0;
    let hasMultiByteChars = false;

    while (i < Math.min(buffer.length, 2000)) {
      const byte = buffer[i];
      totalChecked++;

      if (byte <= 0x7F) {
        validSequences++;
        i++;
      } else if ((byte & 0xE0) === 0xC0) {
        if (i + 1 < buffer.length &&
          (buffer[i + 1] & 0xC0) === 0x80 &&
          byte >= 0xC2) {
          validSequences++;
          hasMultiByteChars = true;
          i += 2;
        } else {
          return false;
        }
      } else if ((byte & 0xF0) === 0xE0) {
        if (i + 2 < buffer.length &&
          (buffer[i + 1] & 0xC0) === 0x80 &&
          (buffer[i + 2] & 0xC0) === 0x80) {
          const codepoint = ((byte & 0x0F) << 12) |
            ((buffer[i + 1] & 0x3F) << 6) |
            (buffer[i + 2] & 0x3F);
          if (codepoint >= 0x800) {
            validSequences++;
            hasMultiByteChars = true;
            i += 3;
          } else {
            return false;
          }
        } else {
          return false;
        }
      } else if ((byte & 0xF8) === 0xF0) {
        if (i + 3 < buffer.length &&
          (buffer[i + 1] & 0xC0) === 0x80 &&
          (buffer[i + 2] & 0xC0) === 0x80 &&
          (buffer[i + 3] & 0xC0) === 0x80) {
          const codepoint = ((byte & 0x07) << 18) |
            ((buffer[i + 1] & 0x3F) << 12) |
            ((buffer[i + 2] & 0x3F) << 6) |
            (buffer[i + 3] & 0x3F);
          if (codepoint >= 0x10000 && codepoint <= 0x10FFFF) {
            validSequences++;
            hasMultiByteChars = true;
            i += 4;
          } else {
            return false;
          }
        } else {
          return false;
        }
      } else {

        return false;
      }
    }

    const validRatio = validSequences / totalChecked;
    if (hasMultiByteChars) {
      return validRatio >= 0.98;
    } else {
      return validRatio >= 0.95;
    }
  }


  private tryDecodeTextWithSupportedEncodings(buffer: Uint8Array): GeneratedTypeLiteralInterface | null {
    for (const encoding of this.supportedEncodings) {
      try {
        const decoder = util.TextDecoder.create(encoding, { ignoreBOM: true });
        const text = decoder.decodeToString(buffer);

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

  private isValidDecodedText(text: string): boolean {
    if (!text || text.length === 0) {
      return false;
    }

    const invalidChars = text.match(/[������]/g);
    const invalidRatio = invalidChars ? invalidChars.length / text.length : 0;

    if (invalidRatio > 0.05) {
      return false;
    }

    const controlChars = text.match(/[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]/g);
    const controlRatio = controlChars ? controlChars.length / text.length : 0;

    if (controlRatio > 0.01) {
      return false;
    }

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
      .replace(/\)/g, '）')
      .replace(/[０-９]/g, (c) => String.fromCharCode(c.charCodeAt(0) - 0xFF10)); // 全角数字转半角
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

  // 在parseQuestion函数中添加更严格的验证
  private isValidQuestionFormat(s: string): boolean {
    if (!s || !s.trim()) {
      return false;
    }

    const ss = s.trim();

    // 检查题目长度，太短的可能不是有效题目
    if (ss.length < 10) {
      return false;
    }

    // 检查是否包含过多的乱码字符
    const randomChars = ss.match(/[^\u4e00-\u9fff\w\s()（）、，。.!?；：""''【】\[\]]/g);
    if (randomChars && randomChars.length > ss.length * 0.3) {
      return false;
    }

    // 检查是否有基本的题目结构（问号、冒号等）
    const hasQuestionStructure = /[？?：:]/.test(ss) || ss.includes('选择') || ss.includes('判断') || ss.includes('下列');

    // 如果包含答案括号，但没有明显的题目结构，可能是乱码
    const hasAnswerPattern = /[（(][ABCD对错√×✔XYN正确错误]+[）)]/g.test(ss);
    const answerMatches = ss.match(/[（(][ABCD对错√×✔XYN正确错误]+[）)]/g);

    if (hasAnswerPattern && !hasQuestionStructure) {
      // 如果有多个答案括号但没有题目结构，很可能是乱码
      if (answerMatches && answerMatches.length > 1) {
        return false;
      }
    }

    return true;
  }

  // 解析题干
  private parseQuestion(s: string): QuestionModel | null {
    if (!s) {
      return null;
    }

    // 添加格式验证
    if (!this.isValidQuestionFormat(s)) {
      console.info(`题目格式验证失败，跳过: ${s}`);
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
      if (q.a.length > 0) {
        let lastAns = q.ans[q.ans.length - 1];
        if (this.ANSWERLABEL.includes(lastAns)) {
          let idx = this.ANSWERLABEL.indexOf(lastAns);
          if (idx >= q.a.length) {
            return null;
          }
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

      if (/[\d０-９]/.test(ss[0])) {
        // 处理上一题
        if (cur) {
          let formattedCur = this.formatQuestion(cur);
          if (formattedCur) {
            res.items.push(formattedCur);
            console.info(`第${lineid + 1}行: 完成上一题: ${JSON.stringify(formattedCur)}`);
          } else {
            console.info(`第${lineid + 1}行: 上一题格式化失败，跳过上一题`);
            if (!cur.ans || cur.ans.trim() === '') {
              res.logs.push(`题目缺少答案，已跳过: ${cur.q}`);
            } else {
              res.logs.push(`题目格式化失败，已跳过: ${cur.q}`);
            }
          }
        }

        // 开始处理新题目
        cur = null;
        ss = this.removeQid(ss);
        console.info(`第${lineid + 1}行: 移除题号后: ${ss}`);

        let parsedQuestion = this.parseQuestion(ss);
        if (parsedQuestion && parsedQuestion.q) {
          cur = parsedQuestion;
          console.info(`第${lineid + 1}行: parseQuestion成功: ${JSON.stringify(cur)}`);
        } else {
          cur = {
            q: ss,
            a: [],
            ans: '',
            type: 'single',
            qid: 0,
            questionID: 0
          };
          console.info(`第${lineid + 1}行: parseQuestion失败，创建基础题目结构`);
        }

      } else if (this.ANSWERLABEL.includes(ss[0])) {
        // 处理选项行
        if (cur) {
          let pa = this.parseAnswers(ss);
          cur.a.push(...pa);
          console.info(`第${lineid + 1}行: 解析选项: ${JSON.stringify(pa)}`);
        } else {
          console.info(`第${lineid + 1}行: 无当前题目，选项行被忽略: ${ss}`);
          res.logs.push(`第${lineid + 1}行: 无题目上下文，选项行被忽略: ${ss}`);
        }

      } else if (ss.startsWith('答案') || ss.startsWith('正确答案') || ss.startsWith('参考答案')) {
        // 处理答案行
        if (!cur) {
          console.info(`第${lineid + 1}行: 无当前题目，答案行被忽略: ${ss}`);
          res.logs.push(`第${lineid + 1}行: 没识别到题干答案。即将跳过这道题: ${s}`);
          continue;
        }

        let ans = '';
        let cleanSs = ss.replace('正确答案', '').replace('参考答案', '').replace('答案', '');
        for (let i = 0; i < cleanSs.length; i++) {
          let t = cleanSs[i].toUpperCase();
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

  // 解析TXT文件
  async parseTxtFile(files: fs.File): Promise<ImportWithLog | null> {
    if (!files.path || typeof files.path !== 'string') {
      console.error('文件路径无效');
      promptAction.showToast({ message: '导入失败: 文件不存在或者内容格式异常', duration: 2000 });
      return null;
    }

    let file: fs.File | null = null;
    try {
      let stat: fs.Stat = fs.statSync(files.fd);
      console.info(`文件状态: size=${stat.size}, mtime=${stat.mtime}`);

      if (stat.size === 0) {
        console.error('文件为空');
        promptAction.showToast({ message: '导入失败: 文件不存在或者内容格式异常', duration: 2000 });
        return null;
      }

      let buffer: ArrayBuffer = new ArrayBuffer(stat.size);
      let bytesRead: number = fs.readSync(files.fd, buffer);
      let bufferView = new Uint8Array(buffer).slice(0, bytesRead);

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
          return await this.parseJsonFromBuffer(bufferView);
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
      console.error(`获取文件状态失败: filePath=${files}, code=${err.code}, message=${err.message}`);
      promptAction.showToast({
        message: '导入失败: 文件不存在或者内容格式异常',
        duration: 2000
      });
      return null;
    } finally {
      if (file) {
        try {
          fs.closeSync(file);
          console.info(`成功关闭文件: ${files}`);
        } catch (closeError) {
          console.error(`关闭文件失败: ${(closeError as BusinessError).message}`);
        }
      }
    }
  }


  // 解析JSON格式的TXT文件
  private parseJsonFromBuffer(bufferView: Uint8Array): Promise<ImportWithLog | null> {
    return new Promise((resolve) => {
      try {
        let detectedEncoding = this.detectEncoding(bufferView);
        console.info(`检测到编码: ${detectedEncoding}`);

        // 检查是否为支持的编码
        if (!this.supportedEncodings.includes(detectedEncoding)) {
          console.error(`不支持的编码格式: ${detectedEncoding}`);
          promptAction.showToast({
            message: '导入失败: 文件不存在或者内容格式异常',
            duration: 2000
          });
          resolve(null);
          return;
        }

        let text: string = '';
        let actualEncoding = detectedEncoding;

        try {
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
            resolve(null);
            return;
          }
        }

        // 检查解码后的文本是否有效
        if (!text || text.trim().length === 0) {
          console.error('解码后文本为空');
          promptAction.showToast({
            message: '导入失败: 文件不存在或者内容格式异常',
            duration: 2000
          });
          resolve(null);
          return;
        }

        let lines = text
          .split('\n')
          .map((line: string) => line.trim())
          .filter((line: string) => line.length > 0);

        if (!lines || lines.length === 0) {
          console.error('JSON文件为空或无有效内容');
          promptAction.showToast({ message: 'JSON文件中没有有效内容', duration: 2000 });
          resolve(null);
          return;
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
          resolve(null);
          return;
        }

        this.generateQuestionIDs(res);
        console.info(`JSON解析完成: items=${res.items.length}, logs=${res.logs.length}, encoding=${actualEncoding}`);
        resolve(res);
      } catch (error) {
        let err = error as BusinessError;
        console.error(`解析JSON内容失败: ${err.message}`);
        promptAction.showToast({
          message: '导入失败: 文件不存在或者内容格式异常',
          duration: 2000
        });
        resolve(null);
      }
    });
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
