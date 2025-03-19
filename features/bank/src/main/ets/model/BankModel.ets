import { QuestionBankTable, QuestionTable, BankListRes, QuestionRes } from '@ohos/db'
import { SearchDecryptUtils } from '@ohos/search'
import { Logger, StringUtils } from '@ohos/utils'
import { BankNet } from '../service/BankNet'
import { BankCategory } from './BankCategory'

const TAG = '[BankModel]'

@Observed
export class BankModel {
  private bankNet: BankNet
  private static instance: BankModel
  private questionBankTable = new QuestionBankTable()
  private questionTable = new QuestionTable()

  private constructor() {
    this.bankNet = new BankNet()
  }

  public static getInstance(): BankModel {
    if (!BankModel.instance) {
      BankModel.instance = new BankModel()
    }
    return BankModel.instance
  }

  //创建数据库
  createTable() {
    this.questionBankTable.getRdbStore()
    this.questionTable.getRdbStore()
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

  //获取题库列表详情
  public async getBankList(aid: string, pageSize: number, pageNo: number): Promise<BankListRes[]> {
    try {
      let data = await this.bankNet.getBankList(aid, pageSize, pageNo)
      return data
    } catch (e) {
      return []
    }
  }

  //点击题库下载的操作
  public async downLoadBank(bankListRes: BankListRes): Promise<boolean> {
    try {
      //插入题库表
      let ret = await this.questionBankTable.insertDataAwait(bankListRes)
      Logger.info(TAG, 'ret--------' + ret)

      await this.downLoadBankFile(bankListRes.qid, bankListRes.url)
      return true
    } catch (e) {
      return false
    }
  }

  //下载题库文件
  public async downLoadBankFile(qid: string, url: string): Promise<boolean> {
    try {
      let subTxtName = StringUtils.subUrl(url)
      // Logger.info(TAG, 'subTxtName--------' + subTxtName)
      let suffix = StringUtils.subLastIndex(subTxtName, '.')
      // Logger.info(TAG, 'suffix--------' + suffix)

      let str = await this.bankNet.getDownloadQuestionBank(url)
      // Logger.info(TAG, 'trStr--------' + str)

      let trStr = await SearchDecryptUtils.getTrText(suffix, str, subTxtName)
      Logger.info(TAG, 'trStr--------' + trStr)
      //转换成 题目的对象
      let jsonStr = JSON.parse(trStr.replace(/[\r\n\t]/g, '')) as QuestionRes
      let ret = await this.questionTable.insertDataAwait(jsonStr)
      Logger.info(TAG, 'ret--------' + ret)
      return true
    } catch (e) {
      Logger.info(TAG, "----->" + e)
      return false
    }
  }
}