import ChRdb from '../ChRdb';
import DbConstants from '../constants/DbConstants';
import { relationalStore } from '@kit.ArkData';
import { QuestionRes } from '../model/QuestionRes';
import { Logger } from 'utils';

// 题目表（单例模式）
export class QuestionTable {
  private static _instance: QuestionTable;
  private accountTable: ChRdb;

  // 私有构造函数防止外部实例化
  private constructor() {
    this.accountTable = new ChRdb(
      DbConstants.QUESTION_TABLE.tableName,
      DbConstants.QUESTION_TABLE.sqlCreate,
      DbConstants.QUESTION_TABLE.columns
    );
  }

  // 获取单例实例
  public static getInstance(): QuestionTable {
    if (!QuestionTable._instance) {
      QuestionTable._instance = new QuestionTable();
    }
    return QuestionTable._instance;
  }

  getRdbStore(callback: Function = () => {
  }) {
    this.accountTable.getRdbStore(callback);
  }

  insertData(account: QuestionRes, callback: Function) {
    const valueBucket: relationalStore.ValuesBucket = this.generateBucket(account);
    this.accountTable.insertData(valueBucket, callback);
  }

  async insertDataAwait(account: QuestionRes) {
    const valueBucket: relationalStore.ValuesBucket = this.generateBucket(account);
    return await this.accountTable.insertDataAwait(valueBucket);
  }

  async deleteData(account: QuestionRes, callback: Function, rdb?: relationalStore.RdbStore) {
    let predicates = new relationalStore.RdbPredicates(DbConstants.QUESTION_TABLE.tableName);
    predicates.equalTo('qId', account.qId);
    if (rdb) {
      await this.accountTable.deleteDataTask(rdb, predicates);
    } else {
      this.accountTable.deleteData(predicates, callback);
    }
  }

  updateData(account: QuestionRes, callback: Function) {
    const valueBucket: relationalStore.ValuesBucket = this.generateBucket(account);
    let predicates = new relationalStore.RdbPredicates(DbConstants.QUESTION_TABLE.tableName);
    predicates.equalTo('questionID', account.questionID);
    this.accountTable.updateData(predicates, valueBucket, callback);
  }

  // 抽取的公共查询函数
  private async executeQuestionQuery(rdbStore: relationalStore.RdbStore, id: number, searchCount: boolean = false,
    isSearch: boolean = false, isAll: boolean = true): Promise<Array<QuestionRes>> {
    const predicates = new relationalStore.RdbPredicates(DbConstants.QUESTION_TABLE.tableName);

    if (!isAll) {
      //搜索走的是找id的位置；题库练习走的是根据题库qId找关联的题目
      predicates.equalTo(isSearch ? 'id' : 'qId', id);
    }

    const resultSet = rdbStore.querySync(predicates);
    if (!resultSet) {
      return [];
    }

    try {
      let count: number = resultSet.rowCount;
      if (count === 0 || typeof count === 'string') {
        console.log(`${DbConstants.TABLE_TAG} Query no results!`);
        return [];
      }

      //指定搜索的长度
      if (searchCount) {
        if (count > 10) {
          count = 10
        }
      }

      resultSet.goToFirstRow();
      const result: QuestionRes[] = [];
      for (let i = 0; i < count; i++) {
        const tmp: QuestionRes = {
          id: -1,
          qId: 0,
          qName: '',
          question: '',
          answer: '',
          option: [],
          wrongAnswer: '',
          questionID: 0
        };
        tmp.id = resultSet.getDouble(resultSet.getColumnIndex('id'));
        tmp.qId = resultSet.getDouble(resultSet.getColumnIndex('qId'));
        //这个升级后插入的列
        tmp.qName = resultSet.getString(resultSet.getColumnIndex('qName'));
        tmp.question = resultSet.getString(resultSet.getColumnIndex('question'));
        tmp.answer = resultSet.getString(resultSet.getColumnIndex('answer'));
        tmp.option = resultSet.getString(resultSet.getColumnIndex('option')).split(DbConstants.SEPARATOR);
        tmp.wrongAnswer = resultSet.getString(resultSet.getColumnIndex('wrongAnswer'));
        tmp.questionID = resultSet.getDouble(resultSet.getColumnIndex('questionID'));
        result[i] = tmp;
        resultSet.goToNextRow();
      }
      return result;
    } catch (e) {
      Logger.error(e);
      return [];
    }
  }

  //不走多线程,题库详情搜索前10题
  async queryCountSync(id: number, searchCount: boolean = true, isSearch: boolean = false,
    isAll: boolean = false): Promise<Array<QuestionRes>> {
    let rdb = await relationalStore.getRdbStore(getContext(), DbConstants.STORE_CONFIG)
    return this.executeQuestionQuery(rdb, id, searchCount, isSearch, isAll);
  }

  //不走多线程
  async querySync(id: number, isSearch: boolean = false,
    isAll: boolean = true): Promise<Array<QuestionRes>> {
    let rdb = await relationalStore.getRdbStore(getContext(), DbConstants.STORE_CONFIG)
    return this.executeQuestionQuery(rdb, id, false, isSearch, isAll);
  }

  //多线程
  async querySyncTaskPool(rdbStore: relationalStore.RdbStore, id: number,
    isSearch: boolean = false,
    isAll: boolean = true): Promise<Array<QuestionRes>> {
    return this.executeQuestionQuery(rdbStore, id, false, isSearch, isAll);
  }

  /**
   * 生成ValuesBucket
   * @param account
   * @returns
   */
  private generateBucket(account: QuestionRes): relationalStore.ValuesBucket {
    return {
      qId: account.qId,
      qName: account.qName,
      question: account.question,
      answer: account.answer,
      option: (account.option ?? []).join(DbConstants.SEPARATOR),
      wrongAnswer: account.wrongAnswer,
      questionID: account.questionID
    };
  }
}
