export class MDataTextManage {
  private static instance: MDataTextManage | null = null
  private mDataText: SharedArrayBuffer | null = null

  // 私有构造函数，防止外部直接实例化
  private constructor() {
  }

  // 获取单例实例的静态方法
  public static getInstance(): MDataTextManage {
    if (MDataTextManage.instance === null) {
      MDataTextManage.instance = new MDataTextManage()
    }
    return MDataTextManage.instance
  }

  saveDataText(data: SharedArrayBuffer | null) {
    if (data) {
      this.mDataText = data
    }
  }

  getDataText(): SharedArrayBuffer | null {
    return this.mDataText
  }
}