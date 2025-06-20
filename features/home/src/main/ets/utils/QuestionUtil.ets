import { QuestionRes } from 'db';

/**
 * 匹配结果接口
 */
interface MatchResult {
  accuracy: number;
  isAccurate: boolean;
  remainingText: string;
  matchedText: string;
  matchStartIndex: number;
  matchEndIndex: number;
}

/**
 * 最佳匹配信息接口
 */
interface BestMatch {
  startIndex: number;
  endIndex: number;
  matchLength: number;
  accuracy: number;
  matchedText: string;
}

export class QuestionUtil {
  /**
   * 根据答案筛选选项并返回格式化字符串
   * @param questionData 题目数据对象
   * @returns 格式化的答案字符串
   */
  static filterOptionsByAnswer(questionData: QuestionRes): string {
    const answer = questionData.answer;
    const option = questionData.option;

    // 如果答案为空，返回空字符串
    if (!answer) {
      return '';
    }

    // 将答案字符串转换为字符数组，如 "ABD" -> ['A', 'B', 'D']
    const answerChars = answer.split('');

    // 存储筛选出的选项
    const selectedOptions: string[] = [];

    // 遍历答案中的每个字符
    answerChars.forEach(char => {
      // 将字母转换为对应的数组索引 (A=0, B=1, C=2, D=3, ...)
      const index = char.charCodeAt(0) - 'A'.charCodeAt(0);

      // 检查索引是否有效且对应的选项存在
      if (index >= 0 && index < option.length) {
        selectedOptions.push(` ${char} ${option[index]}`);
      }
    });

    // 构建返回字符串
    let result = `[${answer}]`;

    // 添加每个选项到结果中
    selectedOptions.forEach(optionText => {
      result += `${optionText}`;
    });

    return result;
  }

  /**
   * 文字匹配精准率分析函数
   * @param sourceText 源文字（第一段文字）
   * @param targetText 目标文字（第二段文字）
   * @param threshold 精准率阈值（默认0.5，即50%）
   * @returns 返回分析结果对象
   */
  static analyzeTextMatch(sourceText: string, targetText: string, threshold: number = 0.5): MatchResult {
    // 预处理文字，去除多余空格和换行
    const cleanSource = sourceText.replace(/\s+/g, ' ').trim();
    const cleanTarget = targetText.replace(/\s+/g, ' ').trim();

    // 寻找最佳匹配
    let bestMatch: BestMatch = {
      startIndex: -1,
      endIndex: -1,
      matchLength: 0,
      accuracy: 0,
      matchedText: ''
    };

    // 策略1: 寻找目标文字的最长连续子串在源文字中的匹配
    const minMatchLength = Math.max(10, Math.floor(cleanTarget.length * 0.2)); // 最小匹配长度

    // 从最长子串开始尝试匹配
    for (let len = cleanTarget.length; len >= minMatchLength; len--) {
      for (let start = 0; start <= cleanTarget.length - len; start++) {
        const targetSubstring = cleanTarget.substring(start, start + len);

        // 在源文字中查找这个子串
        const sourceIndex = cleanSource.indexOf(targetSubstring);

        if (sourceIndex !== -1) {
          const accuracy = len / cleanTarget.length;
          if (accuracy > bestMatch.accuracy) {
            bestMatch = {
              startIndex: sourceIndex,
              endIndex: sourceIndex + len,
              matchLength: len,
              accuracy: accuracy,
              matchedText: targetSubstring
            };
          }
        }
      }

      // 如果找到了足够好的匹配，就不需要继续尝试更短的子串
      if (bestMatch.accuracy >= threshold) {
        break;
      }
    }

    // 策略2: 如果策略1没有找到好的匹配，尝试模糊匹配
    if (bestMatch.accuracy < threshold) {
      bestMatch = QuestionUtil.findFuzzyMatch(cleanSource, cleanTarget, threshold);
    }

    // 策略3: 如果还是没有找到，尝试关键词匹配
    if (bestMatch.accuracy < threshold) {
      bestMatch = QuestionUtil.findKeywordMatch(cleanSource, cleanTarget);
    }

    // 判断是否达标
    const isAccurate = bestMatch.accuracy >= threshold;

    // 计算剩余文字
    let remainingText = cleanSource;
    if (isAccurate && bestMatch.startIndex !== -1) {
      // 移除匹配的部分
      remainingText = cleanSource.substring(0, bestMatch.startIndex) +
      cleanSource.substring(bestMatch.endIndex);
      remainingText = remainingText.replace(/\s+/g, ' ').trim();
    }

    return {
      accuracy: Math.round(bestMatch.accuracy * 10000) / 100,
      isAccurate: isAccurate,
      remainingText: remainingText,
      matchedText: bestMatch.matchedText,
      matchStartIndex: bestMatch.startIndex,
      matchEndIndex: bestMatch.endIndex
    };
  }

  /**
   * 模糊匹配策略 - 使用编辑距离在源文字中寻找最相似的片段
   */
  private static findFuzzyMatch(sourceText: string, targetText: string, threshold: number): BestMatch {
    let bestMatch: BestMatch = {
      startIndex: -1,
      endIndex: -1,
      matchLength: 0,
      accuracy: 0,
      matchedText: ''
    };

    const targetLength = targetText.length;
    const windowSize = Math.max(targetLength, Math.floor(targetLength * 1.2));

    // 滑动窗口在源文字中寻找最相似的片段
    for (let i = 0; i <= sourceText.length - Math.floor(targetLength * 0.5); i++) {
      const endPos = Math.min(i + windowSize, sourceText.length);
      const sourceSubstring = sourceText.substring(i, endPos);

      const similarity = QuestionUtil.calculateSimilarity(sourceSubstring, targetText);

      if (similarity > bestMatch.accuracy) {
        bestMatch = {
          startIndex: i,
          endIndex: endPos,
          matchLength: endPos - i,
          accuracy: similarity,
          matchedText: sourceSubstring
        };
      }
    }

    return bestMatch;
  }

  /**
   * 关键词匹配策略 - 提取目标文字中的关键词，在源文字中寻找包含这些关键词的片段
   */
  private static findKeywordMatch(sourceText: string, targetText: string): BestMatch {
    // 提取关键词（长度大于2的连续字符）
    const keywords = QuestionUtil.extractKeywords(targetText);

    let bestMatch: BestMatch = {
      startIndex: -1,
      endIndex: -1,
      matchLength: 0,
      accuracy: 0,
      matchedText: ''
    };

    // 寻找包含最多关键词的源文字片段
    for (let i = 0; i < sourceText.length; i++) {
      for (let j = i + 10; j <= sourceText.length; j++) {
        const sourceSubstring = sourceText.substring(i, j);
        const matchCount = keywords.filter(keyword => sourceSubstring.includes(keyword)).length;
        const accuracy = matchCount / keywords.length;

        if (accuracy > bestMatch.accuracy) {
          bestMatch = {
            startIndex: i,
            endIndex: j,
            matchLength: j - i,
            accuracy: accuracy,
            matchedText: sourceSubstring
          };
        }
      }
    }

    return bestMatch;
  }

  /**
   * 提取关键词
   */
  private static extractKeywords(text: string): string[] {
    const keywords: string[] = [];

    // 提取长度>=3的连续中文字符或单词
    const matches = text.match(/[\u4e00-\u9fa5]{3,}|[a-zA-Z]{3,}/g);
    if (matches) {
      keywords.push(...matches);
    }

    // 提取特殊符号组合（如法律条文编号等）
    const specialMatches = text.match(/第[一二三四五六七八九十百千万\d]+条|[a-zA-Z]+\d+|\d+[a-zA-Z]+/g);
    if (specialMatches) {
      keywords.push(...specialMatches);
    }

    // 修复ArkTS兼容性：使用Array.from()代替展开运算符
    return Array.from(new Set(keywords)); // 去重
  }

  /**
   * 计算两个字符串的相似度（优化版）
   */
  static calculateSimilarity(str1: string, str2: string): number {
    const len1 = str1.length;
    const len2 = str2.length;

    if (len1 === 0 && len2 === 0) {
      return 1;
    }
    if (len1 === 0 || len2 === 0) {
      return 0;
    }
    if (str1 === str2) {
      return 1;
    }

    // 对于长文本，使用采样计算来提高性能
    if (len1 > 1000 || len2 > 1000) {
      return QuestionUtil.calculateSimilarityFast(str1, str2);
    }

    // 使用编辑距离算法计算相似度
    const matrix: number[][] = Array(len1 + 1).fill(null).map(() => Array(len2 + 1).fill(0));

    // 初始化矩阵
    for (let i = 0; i <= len1; i++) {
      matrix[i][0] = i;
    }
    for (let j = 0; j <= len2; j++) {
      matrix[0][j] = j;
    }

    // 填充矩阵
    for (let i = 1; i <= len1; i++) {
      for (let j = 1; j <= len2; j++) {
        const cost = str1[i - 1] === str2[j - 1] ? 0 : 1;
        matrix[i][j] = Math.min(
          matrix[i - 1][j] + 1, // 删除
          matrix[i][j - 1] + 1, // 插入
          matrix[i - 1][j - 1] + cost // 替换
        );
      }
    }

    const editDistance = matrix[len1][len2];
    const maxLength = Math.max(len1, len2);

    return (maxLength - editDistance) / maxLength;
  }

  /**
   * 快速相似度计算（用于长文本）
   */
  private static calculateSimilarityFast(str1: string, str2: string): number {
    // 使用n-gram方法计算相似度
    const n = 3;
    const ngrams1 = QuestionUtil.generateNGrams(str1, n);
    const ngrams2 = QuestionUtil.generateNGrams(str2, n);

    const set1 = new Set(ngrams1);
    const set2 = new Set(ngrams2);

    const intersection = new Set(Array.from(set1).filter(x => set2.has(x)));
    // 修复ArkTS兼容性：使用Array.from()和concat()代替展开运算符
    const union = new Set(Array.from(set1).concat(Array.from(set2)));

    return union.size === 0 ? 0 : intersection.size / union.size;
  }

  /**
   * 生成n-gram
   */
  private static generateNGrams(text: string, n: number): string[] {
    const ngrams: string[] = [];
    for (let i = 0; i <= text.length - n; i++) {
      ngrams.push(text.substring(i, i + n));
    }
    return ngrams;
  }
}

// // 使用示例
// const sourceText = "01:1711:29答题背题模拟考试1/1428重置进度判断题收藏依据配电安规,低[电]压:用于配电的交流系统中1000v以下的电压等级。A正确B错误下一题[ABCD] A含有严重超出标准限量的致病性微生物、农药残留、兽药残留、重金厲、污染物质..《关于办理危害食品安全刑事案件适用法律若干问题的解释》规定,生产、销售不符合食品认定为刑法第一百四十三条规定的"足以造成严重食物中毒事故或者其他严重食源性疾病"。";
//
// const targetText = "[ABCD] A 含有严重超出标准限量的致病性微生物、农药残留、兽药残留、重金属、污染物质以及其他危害人体健康的物质的 B 属于病死、死因不明或者检验检疫不合格的畜、禽、兽、水产动物及其肉类、肉类制品的 C 属于国家为防控疾病等特殊需要明令禁止生产、销售的 D 婴幼儿食品中生长发育所需营养成分严重不符合食品安全标准的《关于办理危害食品安全刑事案件适用法律若干问题的解释》规定，生产、销售不符合食品安全标准的食品，具有下列（）情形的，应当认定为刑法第一百四十三条规定的"足以造成严重食物中毒事故或者其他严重食源性疾病"。";
//
// const result = QuestionUtil.analyzeTextMatch(sourceText, targetText, 0.3);
// console.log('匹配结果:', result);