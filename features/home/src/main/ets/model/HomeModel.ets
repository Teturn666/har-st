import { LoadingStatus, Logger } from '@ohos/utils/Index'
import { HomeNet } from '../service/HomeNet'
import { HomeBankListRes } from './HomeBankListRes'
import { List } from '@kit.ArkTS'
import { UpdateRes } from './UpdateRes'
import { QuestionBankTable, QuestionTable, QuestionRes } from '@ohos/db/Index'
import { SearchEngine } from '@ohos/search/Index'
import { preferences } from '@kit.ArkData'
import { Context } from '@kit.AbilityKit'
import HomeConstants from '../Constants/HomeConstants'

const TAG = '[HomeModel]'

@Observed
export class HomeModel {
  private funNetwork: HomeNet
  private static instance: HomeModel
  loadingStatus: LoadingStatus = LoadingStatus.OFF
  private questionBankTable = new QuestionBankTable()
  private questionTable = new QuestionTable()
  private sp: preferences.Preferences | null = null

  private constructor() {
    this.funNetwork = new HomeNet()
  }

  public static getInstance(): HomeModel {
    if (!HomeModel.instance) {
      HomeModel.instance = new HomeModel()
    }
    return HomeModel.instance
  }

  //创建sp的实例
  createSp(context: Context) {
    this.sp = preferences.getPreferencesSync(context, HomeConstants.SP_OPTIONS)
  }

  //创建数据库
  createTable() {
    this.questionBankTable.getRdbStore()
    this.questionTable.getRdbStore()
  }

  //是否需要请求第一次的接口
  async queryFirstData(): Promise<boolean> {
    if (this.sp != null) {
      let hasData = this.sp.getSync(HomeConstants.HAS_DATA, false)
      if (!hasData) {
        return await this.getBankList()
      } else {
        return await this.setQuestionTable()
      }
    } else {
      return await this.getBankList()
    }
  }

  //获取题库列表
  private async getBankList(): Promise<boolean> {
    try {
      let data = await this.funNetwork.getHomeBankListRes()
      Logger.info(TAG, 'getHomeBankListResources success--------' + JSON.stringify(data))

      await this.insertQuestionBank(data)
      return await this.setQuestionTable()
    } catch (e) {
      Logger.info(TAG, 'err--------' + e)
      return false
    }
  }

  //存储题库表的数据
  private async insertQuestionBank(data: List<HomeBankListRes>) {
    for (let i = 0; i < data.length; i++) {
      let resItem: HomeBankListRes = data[i]
      let ret = await this.questionBankTable.insertDataAwait(data[i])
      Logger.info("insert ret " + ret)
      await this.getBankChapter(resItem.id)
    }
    Logger.info("====存储的数据完成==")
    if (this.sp != null) {
      this.sp.putSync(HomeConstants.HAS_DATA, true)
      this.sp.flush()
    }
  }

  //获取章节信息
  private async getBankChapter(bankId: number): Promise<void> {
    try {
      let data = await this.funNetwork.getHomeBankChapterRes(bankId)
      Logger.info(TAG, 'getHomeBankListResources success--------' + JSON.stringify(data));
      // resolve()
      for (let item of data.chapterList) {
        await this.getQuestionList(item.id)
      }
    } catch (err) {
      Logger.info(TAG, 'err--------' + err);
    }
  }

  //根据题库Id获取更新信息
  getBankBaseInfo(): Promise<void> {
    return new Promise((resolve: (value: void) => void,
      reject: (reason?: Object) => void) => {
      this.funNetwork.getHomeBankBaseInfoRes().then((data: void | HomeBankListRes) => {
        Logger.info(TAG, 'getHomeBankListResources success--------' + JSON.stringify(data));
        resolve()
      }).catch((err: Error) => {
        Logger.info(TAG, 'err--------' + err);
        reject(err)
      })
    })
  }

  //获取版本更新信息
  getUpdate(): Promise<void> {
    return new Promise((resolve: (value: void) => void,
      reject: (reason?: Object) => void) => {
      this.funNetwork.getUpdateVersionRes().then((data: void | UpdateRes) => {
        Logger.info(TAG, 'getHomeBankListResources success--------' + JSON.stringify(data));
        resolve()
      }).catch((err: Error) => {
        Logger.info(TAG, 'err--------' + err);
        reject(err)
      })
    })
  }

  //获取配置列表的数据
  getConfigList(): Promise<void> {
    return new Promise((resolve: (value: void) => void,
      reject: (reason?: Object) => void) => {
      this.funNetwork.getConfigRes().then((data: void | string) => {
        Logger.info(TAG, 'getHomeBankListResources success--------' + data);
        resolve()
      }).catch((err: Error) => {
        Logger.info(TAG, 'err--------' + err);
        reject(err)
      })
    })
  }

  //获取题库信息
  private async getQuestionList(chapterId: number): Promise<void> {
    try {
      let data = await this.funNetwork.getQuestionListRes(chapterId)
      Logger.info(TAG, 'getHomeBankListResources success--------' + data);
      await this.insertQuestion(data)
    } catch (e) {
      Logger.info(TAG, 'err--------' + e);
    }
  }

  //存储题目表的数据，直接存储解密后的数据
  private async insertQuestion(data: List<QuestionRes>) {
    Logger.info("====ll==" + data.length)
    for (let i = 0; i < data.length; i++) {
      const quesInfo: QuestionRes = data[i]
      // let quesId = quesInfo.id

      //解密题目
      // quesInfo.question = await SearchDecryptUtils.getQuestionText(quesInfo.question, quesId)
      // //解密获取图片
      // // quesInfo.img = await SearchDecryptUtils.getQuestionImages(quesInfo.question, quesId)
      // //解密选项
      // quesInfo.option = await SearchDecryptUtils.getOptions(quesInfo.option, quesId)
      // //解密答案
      // quesInfo.answer = await SearchDecryptUtils.getQuestionAnswer(quesInfo.answer, quesId)

      const id = await this.questionTable.insertDataAwait(quesInfo)
      Logger.info("====id==" + id)
    }
  }

  //把题目表传到检索页去
  async setQuestionTable(): Promise<boolean> {
    SearchEngine.getInstance().setQuestionTable(this.questionTable)

    // TODO 不设置延迟会因为 rDB == null 不能完成初始化完成,这块还需优化，需要提前创建数据库
    setTimeout(async () => {
      return await SearchEngine.getInstance().initWithThreadTask()
    }, 2000)

    return true
  }
}