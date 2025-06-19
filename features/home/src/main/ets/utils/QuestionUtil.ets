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
   * @param threshold 精准率阈值（默认0.8，即80%）
   * @returns 返回分析结果对象
   */
  static analyzeTextMatch(sourceText: string, targetText: string, threshold: number = 0.8): MatchResult {
    // 预处理文字，去除多余空格和换行
    const cleanSource = sourceText.replace(/\s+/g, ' ').trim();
    const cleanTarget = targetText.replace(/\s+/g, ' ').trim();

    // 寻找最佳匹配位置
    let bestMatch: BestMatch = {
      startIndex: -1,
      endIndex: -1,
      matchLength: 0,
      accuracy: 0,
      matchedText: ''
    };

    // 使用滑动窗口方式寻找最佳匹配
    const targetLength = cleanTarget.length;

    for (let i = 0; i <= cleanSource.length - targetLength; i++) {
      const substring = cleanSource.substring(i, i + targetLength);
      const accuracy = QuestionUtil.calculateSimilarity(substring, cleanTarget);

      if (accuracy > bestMatch.accuracy) {
        bestMatch = {
          startIndex: i,
          endIndex: i + targetLength,
          matchLength: targetLength,
          accuracy: accuracy,
          matchedText: substring
        } as BestMatch;
      }
    }

    // 如果没有找到足够长的匹配，尝试寻找部分匹配
    if (bestMatch.accuracy < threshold) {
      // 寻找目标文字的连续子串在源文字中的最佳匹配
      for (let len = Math.floor(targetLength * 0.6); len >= Math.floor(targetLength * 0.3); len--) {
        for (let start = 0; start <= targetLength - len; start++) {
          const targetSubstring = cleanTarget.substring(start, start + len);
          const sourceIndex = cleanSource.indexOf(targetSubstring);

          if (sourceIndex !== -1) {
            const accuracy = len / targetLength;
            if (accuracy > bestMatch.accuracy) {
              bestMatch = {
                startIndex: sourceIndex,
                endIndex: sourceIndex + len,
                matchLength: len,
                accuracy: accuracy,
                matchedText: targetSubstring
              } as BestMatch;
            }
          }
        }
      }
    }

    // 判断是否达标
    const isAccurate = bestMatch.accuracy >= threshold;

    // 计算剩余文字
    let remainingText = cleanSource;
    if (isAccurate && bestMatch.startIndex !== -1) {
      remainingText = cleanSource.substring(0, bestMatch.startIndex) +
      cleanSource.substring(bestMatch.endIndex);
      remainingText = remainingText.replace(/\s+/g, ' ').trim();
    }

    return {
      accuracy: Math.round(bestMatch.accuracy * 10000) / 100, // 保留两位小数的百分比
      isAccurate: isAccurate,
      remainingText: remainingText,
      matchedText: bestMatch.matchedText,
      matchStartIndex: bestMatch.startIndex,
      matchEndIndex: bestMatch.endIndex
    } as MatchResult;
  }

  /**
   * 计算两个字符串的相似度
   * @param str1 字符串1
   * @param str2 字符串2
   * @returns 相似度（0-1之间的数值）
   */
  static calculateSimilarity(str1: string, str2: string): number {
    const len1 = str1.length;
    const len2 = str2.length;

    if (len1 === 0 || len2 === 0) {
      return 0;
    }
    if (str1 === str2) {
      return 1;
    }

    // 使用编辑距离算法计算相似度
    const matrix: number[][] = [];

    // 初始化矩阵
    for (let i = 0; i <= len1; i++) {
      matrix[i] = [];
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
}


// // 示例使用
// const text1 = "00:4802:04答题背题模拟考试1/1428重置进度判断题收藏依据配电安规,低[电]压:用于配电的交流系统中1000v以下的电压等级。正确B错误下一题答案:C工作终结依据配电安规报告应简明扼要,主要包括下列内容:工作负责人姓名,某线路(设备)说明起止杆塔号、分支线名称、位置称设备双重名称等)工作已经完工,所修项目、试验结果、设备改动情况和存在问题等作班自行装设的接地线已全部拆除,线路(设上已无本班组工作人员和遗留物";
//
// const text2 = "答案:C工作终结 依据配电安规，（ ）报告应简明扼要,主要包括下列内容:工作负责人姓名,某线路(设备)说明起止杆塔号、分支线名称、位置称设备双重名称等)工作已经完工,所修项目、试验结果、设备改动情况和存在问题等作班自行装设的接地线已全部拆除,线路(设备)上无本班组工作人员和遗留物。";
//
// // 调用函数
// const result = analyzeTextMatch(text1, text2, 0.7);
