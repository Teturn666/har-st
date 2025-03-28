import { relationalStore } from '@kit.ArkData';
import { DbTableBean } from '../model/DbTableBean';

export default class DbConstants {
  /**
   * Rdb database config.
   */
  static readonly STORE_CONFIG: relationalStore.StoreConfig = {
    name: 'question.db',
    securityLevel: relationalStore.SecurityLevel.S1
  };
  /**
   * Account table config.
   */
  //题库表
  static readonly QUESTION_BANK_TABLE: DbTableBean = {
    tableName: 'questionBank',
    sqlCreate: 'CREATE TABLE IF NOT EXISTS questionBank(id INTEGER PRIMARY KEY AUTOINCREMENT, qId TEXT, ' +
      'name TEXT,desc TEXT,time TEXT, url TEXT,version INTEGER,position INTEGER，downloadedState INTEGER)',
    columns: ['id', 'qId', 'name', 'desc', 'time', 'url', 'version', 'position', 'downloadedState ']
  };
  //题目表
  static readonly QUESTION_TABLE: DbTableBean = {
    tableName: 'question',
    sqlCreate: 'CREATE TABLE IF NOT EXISTS question(id INTEGER PRIMARY KEY AUTOINCREMENT, qId INTEGER, ' +
      'question TEXT, option TEXT, answer TEXT)',
    columns: ['id', 'qId', 'question', 'option', 'answer']
  };
  /**
   * Log tag.
   */
  static readonly RDB_TAG = '[Debug.ChRdb]';
  static readonly TABLE_TAG = '[Debug.AccountTable]';
  //选项拼接的间隔符
  static readonly SEPARATOR: string = "~~~"
}
