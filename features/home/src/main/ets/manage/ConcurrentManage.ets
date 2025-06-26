import { common } from "@kit.AbilityKit";
import { QuestionRes } from "db";
import { SearchEngine } from "search";
import { PreferencesConstants, preferencesUtils } from "utils";
import { MatchResult, QuestionUtil } from "../utils/QuestionUtil";
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
  const settingData = preferencesUtils.getString(PreferencesConstants.SCREEN_READ_SETTING, '', context)
  let resultSearchRes: QuestionRes | null = null

  // 设置了区域识别，不走匹配算法
  if (settingData) {
    resultSearchRes =
      await SearchEngine.getInstance().searchTextWithIndex(ocrText, context, mDataText);
  } else {
    let filterData = QuestionUtil.analyzeTextMatch(ocrText, pipAnswer, 0.3);
    console.debug('ConcurrentManage', "ocrText = " + ocrText)
    console.debug('ConcurrentManage', "pipAnswer = " + pipAnswer)
    console.debug('ConcurrentManage', "data.remainingText = " + filterData.remainingText)
    // console.debug('mDataText', "mDataText = " + mDataText.byteLength)
    resultSearchRes =
      await SearchEngine.getInstance().searchTextWithIndex(filterData.remainingText, context, mDataText);
  }

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