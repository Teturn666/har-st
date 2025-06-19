import { common } from "@kit.AbilityKit";
import { SearchEngine } from "search";
import { QuestionUtil } from "../utils/QuestionUtil";
import { Params, PipManager } from "./PipManage";

const TAG = 'ConcurrentManage'

export interface ReadSearchResult {
  answer: string;
  question: string;
  pipAnswer: string
}

/**
 * 返回一个最匹配的结果
 * @returns ReadSearchResult 返回结果
 */
@Concurrent
export async function readSearchCurrent(context: common.Context, ocrText: string, pipAnswer: string,
  mDataText: SharedArrayBuffer): Promise<ReadSearchResult> {
  // 进行搜索，然后返回给画中画
  // 过滤掉画中画的text
  const filterData = QuestionUtil.analyzeTextMatch(ocrText, pipAnswer, 0.5);
  // console.log(TAG, "ocrText = " + ocrText)
  // console.log(TAG, "answerAndQuestion = " + answerAndQuestion)
  console.debug('ConcurrentManage', "data.remainingText = " + filterData.remainingText)
  // console.debug('mDataText', "mDataText = " + mDataText.byteLength)

  const resultSearchRes =
    await SearchEngine.getInstance().searchTextWithIndex(filterData.remainingText, context, mDataText);

  if (resultSearchRes?.answer && resultSearchRes?.question) {
    // 过滤选项
    let answer = QuestionUtil.filterOptionsByAnswer(resultSearchRes)
    const pipAnswer = answer + resultSearchRes.question
    return {
      answer,
      question: resultSearchRes?.question,
      pipAnswer
    }
  }

  return {
    answer: '',
    question: '',
    pipAnswer: ''
  }
}