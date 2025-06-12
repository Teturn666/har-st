import { SearchEngine } from "../engine/SearchEngine";
import { common } from "@kit.AbilityKit";
import { QuestionRes } from "db";

const TAG = 'ConcurrentManage'

/**
 * 返回一个最匹配的结果
 * @param qStr 搜索内容
 * @returns 返回结果
 */
@Concurrent
export async function searchTask(context: common.Context, qStr: string,
  mDataText: SharedArrayBuffer): Promise<QuestionRes | null> {
  try {
    // 直接返回 QuestionRes 对象
    return await SearchEngine.getInstance().searchTextWithIndex(qStr, context, mDataText);
  } catch (e) {
    return null;
  }
}

/**
 * 多线程执行搜索分词逻辑
 * @param qStr 搜索内容
 * @param type 类型 1添加 2删除
 * @returns 返回结果
 */
@Concurrent
export async function searchInitCurrent(context: common.Context, qid: number, type: number): Promise<void> {
  // 注意：在并发函数中需要重新获取单例实例
  await SearchEngine.getInstance().indexFromDatabase(context, qid, type)
}


