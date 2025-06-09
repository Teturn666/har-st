import { Logger } from 'utils/Index';
import DbConstants from './constants/DbConstants';
import { relationalStore } from '@kit.ArkData';

export default class ChRdb {
  private rdbStore: relationalStore.RdbStore | null = null;
  private tableName: string;
  private sqlCreateTable: string;
  private columns: Array<string>;

  constructor(tableName: string, sqlCreateTable: string, columns: Array<string>) {
    this.tableName = tableName;
    this.sqlCreateTable = sqlCreateTable;
    this.columns = columns;
  }

  async getRdbStore(callback: Function = () => {
  }) {
    if (!callback || typeof callback === 'undefined' || callback === undefined) {
      Logger.info('getRdbStore() has no callback!');
      return;
    }
    if (this.rdbStore !== null) {
      Logger.info('The rdbStore exists.');
      callback();
      return
    }
    let context: Context = getContext(this) as Context;
    try {
      this.rdbStore = await relationalStore.getRdbStore(context, DbConstants.STORE_CONFIG)

      if (this.rdbStore.version === 0) {
        await this.rdbStore.executeSql(this.sqlCreateTable)
        this.rdbStore.version = 1
      }

      if (this.rdbStore.version === 1) {
        if (DbConstants.QUESTION_BANK_TABLE.tableName === this.tableName) {
          let predicates = new relationalStore.RdbPredicates(DbConstants.QUESTION_BANK_TABLE.tableName);
          this.rdbStore.query(predicates)

          await this.rdbStore.executeSql('ALTER TABLE questionBank ADD COLUMN num TEXT')
          await this.rdbStore.executeSql('ALTER TABLE questionBank ADD COLUMN bankType INTEGER')
          // console.info(`Success to executeSql.`);

          this.rdbStore.version = 2
        }
        if (DbConstants.QUESTION_TABLE.tableName === this.tableName) {
          await this.rdbStore.executeSql('ALTER TABLE question ADD COLUMN qName TEXT')
          // console.info(`Success to executeSql.`);
        }
      }
      // Logger.info('getRdbStore() finished.');
      callback();
    } catch (e) {
      Logger.info('--->' + e);
    }
  }

  insertData(data: relationalStore.ValuesBucket, callback: Function = () => {
  }) {
    if (!callback || typeof callback === 'undefined' || callback === undefined) {
      Logger.info('insertData() has no callback!');
      return;
    }
    let resFlag: boolean = false;
    const valueBucket: relationalStore.ValuesBucket = data;
    if (this.rdbStore) {
      this.rdbStore.insert(this.tableName, valueBucket, (err, ret) => {
        if (err) {
          Logger.error(`insertData() failed, err: ${err}`);
          callback(resFlag);
          return;
        }
        Logger.info(`insertData() finished: ${ret}`);
        callback(ret);
      });
    }
  }

  /**
   * 异步插入方法
   */
  async insertDataAwait(data: relationalStore.ValuesBucket): Promise<number> {
    const valueBucket: relationalStore.ValuesBucket = data;
    if (this.rdbStore) {
      try {
        let ret = await this.rdbStore.insert(this.tableName, valueBucket);
        Logger.info(`insertData() finished: ${ret}`);
        return ret
      } catch (e) {
        Logger.error(`insertData() failed, err: ${e}`);
      }
    }
    return 0
  }

  deleteData(predicates: relationalStore.RdbPredicates, callback: Function = () => {
  }) {
    if (!callback || typeof callback === 'undefined' || callback === undefined) {
      Logger.info('deleteData() has no callback!');
      return;
    }
    let resFlag: boolean = false;
    if (this.rdbStore) {
      this.rdbStore.delete(predicates, (err, ret) => {
        if (err) {
          Logger.error(`deleteData() failed, err: ${err}`);
          callback(resFlag);
          return;
        }
        Logger.info(`deleteData() finished: ${ret}`);
        callback(!resFlag);
      });
    }
  }

  async deleteDataTask(rdbStore: relationalStore.RdbStore,
    predicates: relationalStore.RdbPredicates): Promise<boolean> {
    try {
      const result = await rdbStore.delete(predicates);
      Logger.info(`deleteData() finished: ${result}`);
      return true;
    } catch (err) {
      Logger.error(`deleteData() failed, err: ${err}`);
      return false;
    }
  }

  async deleteDataAwait(predicates: relationalStore.RdbPredicates): Promise<number> {
    if (this.rdbStore) {
      try {
        let ret = await this.rdbStore.delete(predicates);
        Logger.info(`deleteDataAwait() finished: ${ret} rows affected`);
        return ret;
      } catch (e) {
        Logger.error(`deleteDataAwait() failed, err: ${e}`);
      }
    }
    Logger.error(`deleteDataAwait() failed, rdbStore is null`);
    return 0;
  }

  updateData(predicates: relationalStore.RdbPredicates, data: relationalStore.ValuesBucket, callback: Function = () => {
  }) {
    if (!callback || typeof callback === 'undefined' || callback === undefined) {
      Logger.info('updateDate() has no callback!');
      return;
    }
    let resFlag: boolean = false;
    const valueBucket: relationalStore.ValuesBucket = data;
    if (this.rdbStore) {
      this.rdbStore.update(valueBucket, predicates, (err, ret) => {
        if (err) {
          Logger.error(`updateData() failed, err: ${err}`);
          callback(resFlag);
          return;
        }
        Logger.info(`updateData() finished: ${ret}`);
        callback(!resFlag);
      });
    }
  }

  query(predicates: relationalStore.RdbPredicates, callback: Function = () => {
  }) {
    if (!callback || typeof callback === 'undefined' || callback === undefined) {
      Logger.info('query() has no callback!');
      return;
    }
    if (this.rdbStore) {
      this.rdbStore.query(predicates, this.columns, (err, resultSet) => {
        if (err) {
          Logger.error(`query() failed, err:  ${err}`);
          return;
        }
        Logger.info('query() finished.');
        callback(resultSet);
        resultSet.close();
      });
    }
  }

  /**
   * 返回Promise的查询方法
   * @returns ResultSet
   */
  async querySync(rdbStore: relationalStore.RdbStore,
    predicates: relationalStore.RdbPredicates): Promise<relationalStore.ResultSet | null> {
    if (rdbStore) {
      try {
        let resultSet = await rdbStore.query(predicates, this.columns)
        Logger.info('query() finished.')
        return resultSet
        // resultSet.close()
      } catch (e) {
        Logger.error(`query() failed, err:  ${e}`)
        return null
      }
    } else {
      Logger.error(`query() failed, this.rdbStore is null`)
      return null
    }
  }
}