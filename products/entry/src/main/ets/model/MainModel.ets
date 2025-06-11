import { questionBankTable, QuestionTable, questionWrongTable, questionCollectionTable } from 'db'
import { MainNet } from '../service/MainNet';
import { ConfigRes } from 'utils/src/main/ets/model/ConfigRes';
import { ChPackageUtils } from 'utils/Index'

export class MainModel {
  private mainNet: MainNet
  private static instance: MainModel

  private constructor() {
    this.mainNet = new MainNet()
  }

  public static getInstance(): MainModel {
    if (!MainModel.instance) {
      MainModel.instance = new MainModel()
    }
    return MainModel.instance
  }

  public initDb() {
    questionBankTable.getRdbStore()
    QuestionTable.getInstance().getRdbStore()
    questionWrongTable.getRdbStore()
    questionCollectionTable.getRdbStore()
  }

  public initHeadParams() {
    ChPackageUtils.getDeviceId()
    ChPackageUtils.getVersionName()
  }

  public async getConfigList(): Promise<ConfigRes> {
    try {
      return await this.mainNet.getConfigList()
    } catch (e) {
      return new ConfigRes()
    }
  }
}
