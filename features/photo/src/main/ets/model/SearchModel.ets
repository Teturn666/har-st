import { SearchEngine } from '@ohos/search/Index'
import { Logger } from '@ohos/utils/Index'
import { QuestionRes } from '@ohos/db/Index'

@Observed
export class SearchModel {
  private static instance: SearchModel

  public static getInstance(): SearchModel {
    if (!SearchModel.instance) {
      SearchModel.instance = new SearchModel()
    }
    return SearchModel.instance
  }

  //获取搜索后得到的数据
  async searchResultList(searchTxt: string): Promise<Array<QuestionRes>> {
    let list = await SearchEngine.getInstance().queryQuestionsWithText(searchTxt)
    Logger.debug(list)
    return list
  }
}