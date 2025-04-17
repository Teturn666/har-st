import { LoadingStatus, Logger } from 'utils/Index'

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
}