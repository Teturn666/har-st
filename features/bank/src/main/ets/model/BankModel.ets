import {
  questionBankTable,
  QuestionTable,
  BankListRes,
  QuestionRes,
  questionCollectionTable,
  questionWrongTable,
} from 'db'
import { SearchDecryptUtils, SearchEngine } from 'search'
import { Logger, StringUtils } from 'utils'
import { plainToClass } from 'class-transformer'
import { BankNet } from '../service/BankNet'
import { BankCategory } from './BankCategory'
import { BankQuestionRes } from './BankQuestionRes'
import { SearchQuestionRes } from './SearchQuestionRes'
import preferences from '@ohos.data.preferences'
import SearchConstants from 'search/src/main/ets/constants/SearchConstants'

const TAG = '[BankModel]'


@Observed
export class BankModel {
  private bankNet: BankNet
  private static instance: BankModel

  private constructor() {
    this.bankNet = new BankNet()
  }

  public static getInstance(): BankModel {
    if (!BankModel.instance) {
      BankModel.instance = new BankModel()
    }
    return BankModel.instance
  }

  //删除数据库
  async deleteTable(qid: number) {
    //删除相应的题库表
    let bankResultList = await questionBankTable.querySync(qid, false) ?? [];
    if (bankResultList.length > 0) {
      let bankRes = bankResultList[0]
      questionBankTable.deleteData(bankRes, (resFlag: boolean) => {
        Logger.info(TAG, '题库deleteData--------' + resFlag)
      })
    }
    //删除相应的题目表
    let bankQaResultList = await QuestionTable.getInstance().querySync(qid, false, false) ?? [];
    if (bankQaResultList.length > 0) {
      bankQaResultList.forEach((item) => {
        QuestionTable.getInstance().deleteData(item, (resFlag: boolean) => {
          Logger.info(TAG, '题目deleteData--------' + resFlag)
        })
      })
    }
    //删除相应的收藏表
    let collectionResultList = await questionCollectionTable.querySync(qid, false) ?? [];
    if (collectionResultList.length > 0) {
      collectionResultList.forEach((item) => {
        questionCollectionTable.deleteData(item, (resFlag: boolean) => {
          Logger.info(TAG, '收藏题目deleteData--------' + resFlag)
        })
      })
    }
    //删除相应的错题表
    let wrongResultList = await questionWrongTable.querySync(qid, false) ?? [];
    if (wrongResultList.length > 0) {
      wrongResultList.forEach((item) => {
        questionWrongTable.deleteData(item, (resFlag: boolean) => {
          Logger.info(TAG, '错题题目deleteData--------' + resFlag)
        })
      })
    }
  }

  //更新题库
  async refreshBank(bank: BankListRes): Promise<boolean> {
    await this.deleteTable(bank.qid)
    const okdata = await this.downLoadBank(bank)
    return okdata
  }

  //获取数据库题库版本
  async getLocalVersion(qid: number): Promise<string | null> {
    try {
      const dbResult = await questionBankTable.querySync(qid, false) ?? [];
      if (dbResult.length > 0) {
        return dbResult[0].version; // Return the version of the first item
      }
      return null;
    } catch (error) {
      Logger.error(TAG, `Error querying local version for qid ${qid}: ${error}`);
      return null;
    }
  }

  //获取热门搜索列表
  public async getHotSearchList(): Promise<string[]> {
    try {
      let data = await this.bankNet.getHotSearchList()
      // Logger.info(TAG, '返回数据--------' + data)
      return data
    } catch (e) {
      Logger.info(TAG, 'err--------' + e)
      return []
    }
  }


  //获取题库tab类型目录列表
  public async getBankTypeList(): Promise<BankCategory[]> {
    try {
      let data = await this.bankNet.getBankTypeList()
      return data
    } catch (e) {
      Logger.info(TAG, 'err--------' + e)
      return []
    }
  }

  //获取数据库已经下载的题库
  public async getDownloadBankList():
    Promise<BankListRes[]> {
    let bankResultList = await questionBankTable.querySync(0) ?? [];

    Logger.info(TAG, '下载的题库--------' + bankResultList.length)
    return bankResultList
  }

  //获取题库列表
  public async getBankList(aid: string, pageNo: number): Promise<BankListRes[]> {
    let bankList: BankListRes[] = []
    try {
      let data = await this.bankNet.getBankList(aid, pageNo)
      for (let item of data) {
        let result = await questionBankTable.querySync(item.qid, false) ?? []
        Logger.info(TAG, 'result--------' + result)
        if (result.length > 0) {
          bankList.push(result[0])
        } else {
          bankList.push(item)
          // Logger.info(TAG, `Search bank result22: ${JSON.stringify(data)}`)
        }
      }
      return bankList
    } catch (e) {
      return []
    }
  }

  //搜索题库列表
  public async getSearchBankList(content: string, pageNo: number): Promise<BankListRes[]> {
    let bankList: BankListRes[] = []
    try {
      let data = await this.bankNet.getSearchBankList(content, pageNo)
      Logger.info(TAG, `Search bank result: ${JSON.stringify(data)}`)
      for (let item of data) {
        let result = await questionBankTable.querySync(item.qid, false) ?? []
        Logger.info(TAG, 'result--------' + result)
        if (result.length > 0) {
          bankList.push(result[0])
        } else {
          bankList.push(item)
          // Logger.info(TAG, `Search bank result22: ${JSON.stringify(data)}`)
        }
      }
      return bankList
    } catch (e) {
      // Logger.error(TAG, `Error in getSearchBankList: ${e}`);
      return []
    }
  }

  //搜索题目列表
  public async getSearchQuestionList(content: string, pageNo: number): Promise<SearchQuestionRes[]> {
    let questionList: SearchQuestionRes[] = []
    try {
      let data = await this.bankNet.getSearchQuestionList(content, pageNo.toString());
      Logger.info(TAG, `Search bank result: ${JSON.stringify(data)}`);
      for (let item of data) {
        let result = await questionBankTable.querySync(Number(item.qid), false) ?? []
        Logger.info(TAG, 'result--------' + result)

        if (result.length > 0) {
          item.downloadedState = 1
        } else {
          item.downloadedState = 2
        }
        questionList.push(item)
      }
      return questionList
    } catch (e) {
      Logger.error(TAG, `Error in getSearchBankList: ${e}`);
      return [];
    }
  }

  //单个题目详情
  public async getBankDetail(id: string): Promise<BankListRes> {
    try {
      let data = await this.bankNet.getBankDetail(id);
      Logger.info(TAG, `Search bank result: ${JSON.stringify(data)}`);
      return data;
    } catch (e) {
      Logger.error(TAG, `Error in getSearchBankList: ${e}`);
      return new BankListRes();
    }
  }

  //点击题库下载的操作
  public async downLoadBank(bankListRes: BankListRes): Promise<boolean> {
    try {
      let qid = bankListRes.qid
      let url = bankListRes.url
      let subTxtName = StringUtils.subUrl(url)
      // Logger.info(TAG, 'subTxtName--------' + subTxtName)
      let suffix = StringUtils.subLastIndex(subTxtName, '.')
      // Logger.info(TAG, 'suffix--------' + suffix)

      let str = await this.bankNet.getDownloadQuestionBank(url)
      // Logger.info(TAG, 'trStr--------' + str)

      let trStr = await SearchDecryptUtils.getTrText(suffix, str, subTxtName)
      Logger.info(TAG, 'trStr--------' + trStr)
      //转换成 题目的对象
      let lines = trStr.split('\n')
      let qaNum = 0
      for (let i = 0; i < lines.length; i++) {
        let line = lines[i]

        if (line !== '') {
          const questionRes = plainToClass(BankQuestionRes, JSON.parse(line))
          console.info('instance:', JSON.stringify(questionRes))
          //题目数据插入存储
          let questionDb = new QuestionRes()
          questionDb.qId = qid
          questionDb.qName = bankListRes.name
          questionDb.question = questionRes.q
          questionDb.answer = questionRes.ans
          questionDb.option = questionRes.a
          questionDb.questionID = qid + i + 1
          let ret = await QuestionTable.getInstance().insertDataAwait(questionDb)
          Logger.info(TAG, 'ret--------' + ret)
          qaNum++
        }
      }
      //插入题库表,下载成功后的状态
      bankListRes.downloadedState = 1
      bankListRes.position = 0
      bankListRes.bankType = 1
      let ret = await questionBankTable.insertDataAwait(bankListRes)
      this.initSearchEngin(bankListRes.qid, qaNum, 1)

      Logger.info(TAG, 'ret22--------' + ret)
      return true
    } catch (e) {
      Logger.info(TAG, "----->" + e)
      return false
    }
  }

  //初始化搜索引擎,更新查询数据
  public async initSearchEngin(qid: number, qaNum: number, type: number) {
    let sp = preferences.getPreferencesSync(getContext(this), SearchConstants.SEARCH_OPTIONS)
    //删除
    if (type === 2) {
      qaNum = 0
    } else {
      let oldNum = sp.getSync(SearchConstants.SEARCH_DATASIZE, 0)
      if (typeof oldNum === 'number') {
        qaNum = oldNum + qaNum
      }
    }
    sp.putSync(SearchConstants.SEARCH_DATASIZE, qaNum)
    sp.flushSync()
    let result = await SearchEngine.getInstance().initWithThreadTask(qid, type)
    Logger.debug('result---' + result)
  }
}
