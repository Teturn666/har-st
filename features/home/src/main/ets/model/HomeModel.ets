import {
  BankListRes,
  questionBankTable,
  questionWrongTable,
  questionCollectionTable,
  QuestionTable,
  QuestionRes
} from 'db'
import { LoadingStatus, Logger } from 'utils/Index'
import { taskpool } from '@kit.ArkTS'
import { deleteTableTask } from 'bank/src/main/ets/manage/ConcurrentManage'

const TAG = '[HomeModel]'

@Observed
export class HomeModel {
  private static instance: HomeModel
  loadingStatus: LoadingStatus = LoadingStatus.OFF

  private constructor() {
  }

  public static getInstance(): HomeModel {
    if (!HomeModel.instance) {
      HomeModel.instance = new HomeModel()
    }
    return HomeModel.instance
  }

  //删除数据库
  deleteTable(qid: number) {
    try {
      // 创建任务并在 TaskPool 中执行
      const task: taskpool.Task = new taskpool.Task(deleteTableTask, getContext(this), qid);
      taskpool.execute(task);
    } catch (error) {
      Logger.error(`TaskPool 执行失败: ${error}`);
    }
  }

  //获取数据库下载的题库
  public async getBankList(): Promise<BankListRes[]> {
    let bankResultList = await questionBankTable.querySync(0) ?? [];

    Logger.info(TAG, '下载的题库--------' + bankResultList.length)
    return bankResultList
  }

  //获取题库中的题目
  public async getBankQuestionList(qid: number): Promise<QuestionRes[]> {
    let resultList = await QuestionTable.getInstance().querySync(qid, false, false) ?? [];

    Logger.info(TAG, '题库的题目--------' + JSON.stringify(resultList))
    return resultList
  }

  //获取数据库错题的题库
  public async getWrongBankList(): Promise<BankListRes[]> {
    const bankList: BankListRes[] = []
    let wrongResultList = await questionWrongTable.querySync(0) ?? [];
    if (wrongResultList.length > 0) {
      for (const item of wrongResultList) {
        let bankResultList = await questionBankTable.querySync(item.qId, false) ?? [];
        if (bankResultList.length > 0) {
          bankList.push(bankResultList[0])
        }
      }
    }
    Logger.info(TAG, '错题的题库--------' + bankList.length)
    return bankList
  }

  //获取数据库错题的题目
  public async getWrongQuestionList(qId: number): Promise<QuestionRes[]> {
    let wrongResultList = await questionWrongTable.querySync(qId, false) ?? [];
    return wrongResultList
  }

  //获取数据库收藏的题库
  public async getCollectionBankList(): Promise<BankListRes[]> {
    const bankList: BankListRes[] = []
    let collectionResultList = await questionCollectionTable.querySync(0) ?? [];
    if (collectionResultList.length > 0) {
      for (const item of collectionResultList) {
        let bankResultList = await questionBankTable.querySync(item.qId, false) ?? [];
        if (bankResultList.length > 0) {
          bankList.push(bankResultList[0])
        }
      }
    }
    Logger.info(TAG, '收藏的题库--------' + bankList.length)
    return bankList
  }

  //获取数据库收藏的题目
  public async getCollectionQuestionList(qId: number): Promise<QuestionRes[]> {
    let collectionResultList = await questionCollectionTable.querySync(qId, false) ?? [];
    return collectionResultList
  }

  //删除数据库收藏的题目
  public async deleteDataByQuestionID(questionID: number): Promise<void> {
    let dataByQuestionID = await questionCollectionTable.deleteDataByQuestionID(questionID);
    return dataByQuestionID
  }

  //插入数据库收藏的题目
  public async collectInserDataAwait(questionDb: QuestionRes): Promise<void> {
    await questionCollectionTable.insertDataAwait(questionDb);
  }

  //插入数据库错题的题目
  public async WrongInserDataAwait(questionDb: QuestionRes): Promise<void> {
    await questionWrongTable.insertDataAwait(questionDb);
  }

  //查询题库信息
  public async queryQuestionBankList(qId: number): Promise<BankListRes[]> {
    let QuestionBankList = await questionBankTable.querySync(qId, false) ?? [];
    return QuestionBankList
  }

  /**
   * 根据 qid 获取题库信息
   */
  async getBankListById(qid: number): Promise<BankListRes[]> {
    return await questionBankTable.querySync(qid, false);
  }

  /**
   * 更新题库进度位置
   */
  async updateBankPosition(bankInfo: BankListRes): Promise<void> {
    return new Promise((resolve, reject) => {
      questionBankTable.updateData(bankInfo, (ret: boolean) => {
        if (ret) {
          console.log('题库进度更新成功');
          resolve();
        } else {
          console.error('题库进度更新失败');
          reject(new Error('更新失败'));
        }
      });
    });
  }

  //更新题目
  async updateQuestion(questionDb: QuestionRes): Promise<void> {
    return new Promise((resolve, reject) => {
      QuestionTable.getInstance().updateData(questionDb, (ret: boolean) => {
        if (ret) {
          console.log('题目更新成功');
          resolve();
        } else {
          console.error('题目更新失败');
          reject(new Error('更新失败'));
        }
      });
    });
  }

}