import { ArrayList, LinkedList, List, TreeMap, TreeSet } from '@kit.ArkTS'
import { QuestionRes, QuestionTable } from 'db/Index'
import { GetAllSelectedUtil, Logger, PreferencesConstants, preferencesUtils, StringUtils } from 'utils/Index'
import { SegmentEngine } from './SegmentEngine'

import { StringFilter } from './StringFilter'
import { QuestionBean } from '../model/QuestionBean';
import systemDateTime from '@ohos.systemDateTime';
import SearchConstants from '../constants/SearchConstants'
import { taskpool } from '@kit.ArkTS';
import { searchInitCurrent, searchTask } from '../manage/ConcurrentManage'
import { common } from '@kit.AbilityKit'
import { preferences, relationalStore } from '@kit.ArkData'
import DbConstants from 'db/src/main/ets/constants/DbConstants'
import { SearchMapManage } from '../manage/SearchMapManage'

const TAG = 'SearchEngine'

export class SearchEngine {
  private static delegate = new SearchEngine()
  mIsInitFinish = false
  private mStopWords = "\t1234567890【】，。,.、  ？?_;；：:…'\"\nABCD"
  private static MIN_SCORE = 0.001

  private constructor() {
  }

  public static getInstance(): SearchEngine {
    return SearchEngine.delegate
  }

  /**
   * 查找题目表数据库所有的数据
   *
   * @param context - 应用上下文对象，用于获取数据库连接
   * @returns 返回包含所有题目数据的列表
   */
  private async findAllQuestionDataSync(context: Context, qid: number, type: number) {
    let rdbStore = await relationalStore.getRdbStore(context, DbConstants.STORE_CONFIG);
    // let questions = await QuestionTable.getInstance()?.querySync(0)  // 旧
    // 题库所对应的题库
    let questions: QuestionRes[] = []
    // 如果是删除逻辑
    if (type === 2) {
      questions = await QuestionTable.getInstance()?.querySyncTaskPool(rdbStore, 0)
      preferencesUtils.putNumber(PreferencesConstants.SEARCH_DATASIZE_ALL, questions.length, context)
      // 清空文件内容
      await SearchMapManage.getInstance().clearTreeMapFileContent(context, SearchConstants.SEARCH_FILE_ALL)
    } else {
      // 添加逻辑
      questions = await QuestionTable.getInstance()?.querySyncTaskPool(rdbStore, qid, false, false)
      const oldMdataSize = preferencesUtils.getNumber(PreferencesConstants.SEARCH_DATASIZE_ALL, 0, context)
      preferencesUtils.putNumber(PreferencesConstants.SEARCH_DATASIZE_ALL, oldMdataSize + questions.length, context)
    }
    let questionList: ArrayList<QuestionRes> = new ArrayList<QuestionRes>()

    questions.forEach((resultElement) => {
      questionList.add(resultElement)
    })
    return questionList
  }

  /**
   * 根据qidArr找到数据库里的数据进行搜索初始化(vip)
   *
   * @param context - 应用上下文对象，用于获取数据库连接
   * @param qidArr - 题库ID数组
   * @returns 返回包含所有题目数据的列表
   */
  async findQuestionInitEngine(context: Context, qidArr: number[]) {
    let rdbStore = await relationalStore.getRdbStore(context, DbConstants.STORE_CONFIG);
    // 题库所对应的题库
    let questions: QuestionRes[] = []
    for (const qid of qidArr) {
      let data = await QuestionTable.getInstance()?.querySyncTaskPool(rdbStore, qid, false, false)
      questions = questions.concat(data)
    }
    let questionList: ArrayList<QuestionRes> = new ArrayList<QuestionRes>()

    // 重置mDataSize的大小
    preferencesUtils.putNumber(PreferencesConstants.SEARCH_DATASIZE_SOME, questions?.length, context)
    questions.forEach((resultElement) => {
      questionList.add(resultElement)
    })

    if (questionList && questionList.length > 0) {
      let startTime = systemDateTime.getTime();
      Logger.debug(TAG, "开始初始化引擎：" + startTime)
      await this.initEngineTaskPool(context, questionList, SearchConstants.SEARCH_FILE_SOME)
    }
    console.log(TAG, "findQuestionInitEngine 初始化搜索引擎完成")
  }


  /**
   * 从数据库初始化数据并判断是否需要初始化搜索引擎
   */
  public async indexFromDatabase(context: common.Context, qid: number, type: number): Promise<void> {
    let questionList = await this.findAllQuestionDataSync(context, qid, type)
    if (questionList && questionList.length > 0) {
      let startTime = systemDateTime.getTime();
      Logger.debug(TAG, "开始初始化引擎：" + startTime)
      await this.initEngineTaskPool(context, questionList, SearchConstants.SEARCH_FILE_ALL)
    }
  }

  private async initEngineTaskPool(context: Context, questionList: ArrayList<QuestionRes>,
    fileName: string): Promise<void> {
    // 此处需要从沙箱文件里取出变量
    const mDataTexts =
      await SearchMapManage.getInstance().loadMapFromFile(context, fileName) || new Map<string, Set<number>>();
    const mStopWords = "\t1234567890【】，。,.、  ？?_;；：:…'\"\nABCD";
    questionList.forEach((item) => {
      // 处理题干分词
      const questionStr = item.question;
      if (!StringUtils.isNullOrEmpty(questionStr)) {
        const wordList = SegmentEngine.getInstance().cut(questionStr); // 明确变量名
        wordList.forEach((key: string) => {
          if (mStopWords.includes(key)) {
            return;
          }

          // 获取或初始化Set
          const existingSet = mDataTexts.get(key) ?? new Set<number>();
          existingSet.add(item.id);
          mDataTexts.set(key, existingSet);
        });
      }

      // 处理选项分词
      const optionStr = item.option.join();
      if (!StringUtils.isNullOrEmpty(optionStr)) {
        const wordList = SegmentEngine.getInstance().cut(optionStr);
        wordList.forEach((key: string) => {
          if (mStopWords.includes(key)) {
            return;
          }

          const existingSet = mDataTexts.get(key) ?? new Set<number>();
          existingSet.add(item.id);
          mDataTexts.set(key, existingSet);
        });
      }
    });

    // 存储进入沙箱文件
    await SearchMapManage.getInstance().saveMapToFile(context, mDataTexts, fileName)
    console.debug(TAG, "保存成功")
  }

  // TODO 这个方法还得完善，差单线程
  // async initIfNotInit() {
  //   // 在多线程中执行初始化
  //   if (!this.mIsInitFinish) {
  //     await this.initWithThreadTask();
  //   }
  // }


  /**
   * 初始化搜索引擎
   * @param context
   */
  // async initWithThread(context: common.Context): Promise<boolean> {
  //   this.mIsInitFinish = false
  //   let isFinish = await this.indexFromDatabase(context)
  //   this.mIsInitFinish = true
  //   return isFinish
  // }


  /**
   * 初始化搜索引擎
   *
   * @param context
   * @param type 1添加题库 2删除题库
   */
  async initWithThread(ctx: common.Context, qid: number, type: number) {
    SearchEngine.getInstance().indexFromDatabase(ctx, qid, type)
  }


  /**
   * 初始化搜索引擎
   * @param context
   */
  async initWithThreadTask(qid: number, type: number) {
    try {
      // 创建任务并在 TaskPool 中执行
      const task: taskpool.Task = new taskpool.Task(searchInitCurrent, getContext(this), qid, type);
      await taskpool.execute(task) as number;
      SearchEngine.getInstance().mIsInitFinish = true
    } catch (error) {
      SearchEngine.getInstance().mIsInitFinish = false
      Logger.error(`TaskPool 执行失败: ${error}`);
    }
  }

  /**
   * 返回一个最匹配的结果
   * @param qStr 搜索内容
   * @returns 返回结果
   */
  public async queryTextWithIndexInThread(qStr: string, mDataText: SharedArrayBuffer): Promise<QuestionRes | null> {
    try {
      // 在这里读取内容
      // 创建任务并在 TaskPool 中执行
      const task: taskpool.Task = new taskpool.Task(searchTask, getContext(this), qStr, mDataText);
      const res = await taskpool.execute(task) as QuestionRes;
      return res
    } catch (error) {
      Logger.error(`TaskPool 执行失败: ${error}`);
      return null
    }
  }

  // /**
  //  * 返回一个最匹配的结果
  //  * @param qStr 搜索内容
  //  * @returns 返回结果
  //  */
  // public async queryTextWithIndexInThread(qStr: string): Promise<QuestionRes | null> {
  //   // if (!this.mIsInitFinish) {
  //   //   Logger.error("搜索引擎初还未初始化完成")
  //   //   return null
  //   // }
  //   try {
  //     let id = await SearchEngine.getInstance().searchTextWithIndex(qStr)
  //     if (id === -1) {
  //       return null
  //     } else {
  //       let result = await QuestionTable.getInstance()?.querySync(id, true, false) ?? []
  //       Logger.info('题目表获取到的数据====>' + result.length)
  //       if (result.length > 0) {
  //         return result[0]
  //       }
  //     }
  //   } catch (e) {
  //     return null
  //   }
  //   return null
  // }

  async searchTextWithIndex(q: string, context: common.Context,
    mDataText: SharedArrayBuffer): Promise<QuestionRes | null> {
    let mMatchScores = new TreeMap<number, number>()

    let mDataSize: number = 0
    let isAllSelect = GetAllSelectedUtil.isUserBankAllSelected()
    if (isAllSelect) {
      mDataSize = preferencesUtils.getNumber(PreferencesConstants.SEARCH_DATASIZE_ALL, 0, context)
    } else {
      mDataSize = preferencesUtils.getNumber(PreferencesConstants.SEARCH_DATASIZE_SOME, 0, context)
    }

    if (mDataSize === 0) {
      // 查询数据库，获取题目数量
      let rdbStore = await relationalStore.getRdbStore(context, DbConstants.STORE_CONFIG);
      const questions = await QuestionTable.getInstance()?.querySyncTaskPool(rdbStore, 0)
      if (isAllSelect) {
        preferencesUtils.putNumber(PreferencesConstants.SEARCH_DATASIZE_ALL, questions?.length, context)
      } else {
        preferencesUtils.putNumber(PreferencesConstants.SEARCH_DATASIZE_SOME, questions?.length, context)
      }
      mDataSize = questions?.length
    }

    let mDataTextData = SearchMapManage.getInstance().parseDataFromSharedBuffer(mDataText)
    // 取出数据
    if (!StringUtils.isNullOrEmpty(q)) {
      let list = SegmentEngine.getInstance().cut(q)
      for (const key of list) {
        if (this.mStopWords.search(key) !== -1) {
          continue;
        }
        // 等待查询结果
        const ids = mDataTextData?.[key];
        if (ids?.length === 0) {
          continue; // 无有效 id 时跳过
        }
        // 更新匹配分数
        ids && ids.forEach((id: number) => {
          const currentScore = mMatchScores.get(id) ?? 0;
          const newScore = currentScore + Math.log10(mDataSize / ids.length);
          mMatchScores.set(id, newScore);
        });
      }
    }

    //获取 top5
    let topN = 5
    let topList = new LinkedList<TopItem>()
    mMatchScores.forEach((value: number, key: number): void => {
      if (topList.length === 0) {
        let item = new TopItem()
        item.id = key
        item.score = value
        topList.add(item)
      } else {
        let isAdd = false
        for (let i = 0; i < topList.length; i++) {
          if (value > topList[i].score) {
            let item = new TopItem()
            item.id = key
            item.score = value
            topList.set(i, item)
            isAdd = true
            return
          }
        }
        if (!isAdd && value > SearchEngine.MIN_SCORE) {
          let item = new TopItem()
          item.id = key
          item.score = value
          topList.add(item)
        }
        while (topList.length > topN) {
          topList.removeLast()
        }
      }
    })

    //处理 top5
    let maxVal = -1
    let bestQuestion: QuestionRes | null = null
    let maxLcs = -1

    // 只获取一次数据库连接
    let rdbStore = await relationalStore.getRdbStore(context, DbConstants.STORE_CONFIG);

    // topList 一直为空
    for (let topListElement of topList) {
      Logger.info(TAG, "resultSet topList");
      let result = await QuestionTable.getInstance()?.querySyncTaskPool(rdbStore, topListElement.id, true, false) ?? [];
      Logger.info(TAG, '题目表获取到的数据====>' + result.length)

      let qs: QuestionRes | null = null;
      if (result.length > 0) {
        qs = result[0]
      }

      let ss = ""
      if (qs != null) {
        ss = qs.question + qs.answer
      }

      let lcsVal = this.lcs(q, ss)
      if (maxLcs < lcsVal) {
        maxLcs = lcsVal
      }

      let score = topListElement.score * lcsVal * 1.0 / ss.length
      if (score > maxVal) {
        bestQuestion = qs
        maxVal = score
      } else if (score == maxVal && topListElement.id > (bestQuestion?.id || -1)) {
        bestQuestion = qs
        maxVal = score
      }
    }

    // TODO 这个系数需要根据情况调整
    if (maxVal <= 0.1) {
      return null
    }
    return bestQuestion
  }

  /**
   * 获取题目拼接的数据，读屏搜题会用到
   * @param q 检索字符串
   * @returns 结果
   */
  private async fetchTop1Question(q: string): Promise<Array<QuestionBean> | null> {
    // if (!this.mIsInitFinish) {
    //   Logger.error("搜索引擎初还未初始化完成")
    //   return null;
    // }
    let qStr = StringFilter.formatString(q);
    const mDataText =
      await SearchMapManage.getInstance()
        .loadSharedArrayBufferFromFile(getContext(this), SearchConstants.SEARCH_FILE_ALL)
    if (!mDataText) {
      return null
    }
    let result = await this.searchTextWithIndex(qStr, getContext(this), mDataText);
    let questions = new Array<QuestionBean>()
    // let result = await QuestionTable.getInstance()?.querySync(id, true, false) ?? []
    Logger.info('题目表获取到的数据====>' + result)
    if (result) {
      let record: QuestionRes = result
      const qItem = new QuestionBean()
      qItem.q = "【" + record.answer + "】" + record.question
      let options = record.option
      options.forEach((optionsElement) => {
        qItem.a.add(optionsElement)
      })
      questions.push(qItem)
    }
    return questions
  }

  /**
   * 获取拼接后的题目数据（读屏搜题）
   * @param q
   * @param callback
   */
  async queryTextWithIndexInThreadTwo(q: string): Promise<Array<QuestionBean>> {
    try {
      let questions = await this.fetchTop1Question(q) ?? []
      return questions;
    } catch (e) {
      return []
    }
  }

  /**
   * 异步方法，根据输入内容获取
   * @param q
   * @returns
   */
  public async queryQuestionsWithText(q: string): Promise<Array<QuestionRes>> {
    try {
      let questions = await this.fetchQuestions(q)
      return questions
    } catch (e) {
      return []
    }
  }

  //查找相似题目
  private async fetchQuestions(q: string): Promise<QuestionRes[]> {
    // if (!this.mIsInitFinish) {
    //   Logger.error("搜索引擎初还未初始化完成")
    //   return [];
    // }
    let qStr = StringFilter.formatString(q)
    let ids = await this.searchQuestionsId(qStr)
    let questions = new Array<QuestionRes>()

    for (let idsElement of ids) {
      let result = await QuestionTable.getInstance()?.querySync(idsElement, true, false) ?? []
      Logger.info('题目表获取到的数据====>' + result.length)
      if (result.length > 0) {
        questions.push(result[0])
      }
    }

    return questions
  }

  /**
   * 返回相似的题目ID
   * @param q 查询字符串
   * @returns 检索相似的题目的ID
   */
  private async searchQuestionsId(q: string): Promise<List<number>> {
    let mDataSize: number = 0
    let mMatchScores = new TreeMap<number, number>()
    // 这里判断是否为全部题库
    let mDataText: Map<string, Set<number>>
    let isAllSelect = GetAllSelectedUtil.isUserBankAllSelected()
    if (isAllSelect) {
      mDataSize = preferencesUtils.getNumber(PreferencesConstants.SEARCH_DATASIZE_ALL, 0)
      mDataText =
        await SearchMapManage.getInstance().loadMapFromFile(getContext(this), SearchConstants.SEARCH_FILE_ALL) ||
        new Map<string, Set<number>>()
    } else {
      mDataSize = preferencesUtils.getNumber(PreferencesConstants.SEARCH_DATASIZE_SOME, 0)
      mDataText =
        await SearchMapManage.getInstance().loadMapFromFile(getContext(this), SearchConstants.SEARCH_FILE_SOME) ||
        new Map<string, Set<number>>()
    }

    // 存在老用户的首选项文件为search,此时需要切换到myStore
    if (mDataSize === 0) {
      // 查询数据库，获取题目数量
      let rdbStore = await relationalStore.getRdbStore(getContext(this), DbConstants.STORE_CONFIG);
      const questions = await QuestionTable.getInstance()?.querySyncTaskPool(rdbStore, 0)
      if (isAllSelect) {
        preferencesUtils.putNumber(PreferencesConstants.SEARCH_DATASIZE_ALL, questions?.length)
      } else {
        preferencesUtils.putNumber(PreferencesConstants.SEARCH_DATASIZE_SOME, questions?.length)
      }
      mDataSize = questions?.length
    }

    if (!StringUtils.isNullOrEmpty(q)) {
      //分词
      let list = SegmentEngine.getInstance().cut(q)
      list.forEach((key: string) => {
        if (this.mStopWords.search(key) != -1) {
          return
        }
        let ids = mDataText.get(key)!
        if (ids !== undefined && ids !== null && ids.size > 0) {
          ids.forEach((id: number) => {
            let score = mMatchScores.get(id) == null ? 0.0 : mMatchScores.get(id)
            score += Math.log10(mDataSize / ids.size)
            mMatchScores.set(id, score)
          })
        }
      })
    }

    // TODO 这里需要获取的数量根据情况修改，安卓速度还好，鸿蒙有点慢
    //获取top 100
    let topN = 100
    let topList = new LinkedList<TopItem>()
    mMatchScores.forEach((value: number, key: number): void => {
      if (topList.length === 0) {
        let item = new TopItem()
        item.id = key
        item.score = value
        topList.add(item)
      } else {
        let isAdd = false
        for (let i = 0; i < topList.length; i++) {
          if (value > topList[i].score) {
            let item = new TopItem()
            item.id = key
            item.score = value
            topList.set(i, item)
            isAdd = true
            return
          }
        }
        if (!isAdd && value > SearchEngine.MIN_SCORE) {
          let item = new TopItem()
          item.id = key
          item.score = value
          topList.add(item)
        }
        while (topList.length > topN) {
          topList.removeLast()
        }
      }
    })

    // 处理分数,并且对相同的问题去重
    let resList = new List<TopItem>()
    let qsCache = new TreeSet<string>()
    for (let item of topList) {
      let result = await QuestionTable.getInstance()?.querySync(item.id, true, false) ?? [];
      Logger.info('题目表获取到的数据====>' + result.length)
      if (result.length > 0) {
        let qs: QuestionRes = result[0]
        let cacheStr: string = qs.question + " " + (qs.option).join(SearchConstants.SEPARATOR)
        if (qsCache.has(cacheStr)) {
          continue
        }
        qsCache.add(cacheStr)
        let ss = ""
        if (qs != null) {
          ss = qs.question + qs.answer
        }
        let lcsVal = this.lcs(q, ss)
        let score = item.score * lcsVal * 1.0 / ss.length
        let topItem = new TopItem()
        topItem.id = qs.id
        topItem.score = score
        resList.add(item)
      }
    }

    //将结果按照相似度排序
    let ids = new List<number>()
    resList.sort((o1: TopItem, o2: TopItem) => {
      return o2.score - o1.score < 0 ? -1 : 1
    })

    for (let i = 0; i < (resList.length > 10 ? 10 : resList.length); i++) {
      ids.add(resList.get(i).id)
    }
    return ids
  }

  //计算两个字符串最长公共子序列
  private lcs(s1: string, s2: string): number {
    if (StringUtils.isNullOrEmpty(s1) || StringUtils.isNullOrEmpty(s2)) {
      return 0
    }
    const lenStr1 = s1.length
    const lenStr2 = s2.length
    let r: number[][] = []
    // 初始化数组
    for (let i = 0; i < lenStr1 + 1; i++) {
      let arr = new Array<number>()
      for (let j = 0; j < lenStr2 + 1; j++) {
        arr.push(0)
      }
      r.push(arr)
    }
    for (let i = 0; i < lenStr1; i++) {
      for (let j = 0; j < lenStr2; j++) {
        if ((s1.substring(i, i + 1)) === (s2.substring(j, j + 1))) {
          r[i + 1][j + 1] = r[i][j] + 1
        } else if (r[i + 1][j] > r[i][j + 1]) {
          r[i + 1][j + 1] = r[i + 1][j]
        } else {
          r[i + 1][j + 1] = r[i][j + 1]
        }
      }
    }
    return r[lenStr1][lenStr2]
  }
}

class TopItem {
  id: number = -1
  score: number = 0.0
}
