import { questionBankTable, questionTable, questionWrongTable, questionCollectionTable } from 'db'
import { SearchEngine } from 'search/Index';
import { Logger } from 'utils';

export class MainModel {
  private static instance: MainModel

  private constructor() {
  }

  public static getInstance(): MainModel {
    if (!MainModel.instance) {
      MainModel.instance = new MainModel()
    }
    return MainModel.instance
  }

  public initDb() {
    questionBankTable.getRdbStore(() => {
    })
    questionTable.getRdbStore(async () => {
      // await this.initSearchEngin()

    })
    questionWrongTable.getRdbStore(() => {
    })
    questionCollectionTable.getRdbStore(() => {
    })
  }

  //初始化搜索引擎
  public async initSearchEngin() {
    let result = await SearchEngine.getInstance().initWithThreadTask()
    Logger.debug('result---' + result)
  }
}