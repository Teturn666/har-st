//题库表
@Observed
export class BankListRes {
  //数据库主键，自增
  id: number = -1
  qid: number = 0
  name: string = ''
  desc: string = ''
  time: string = ''
  url: string = ''
  num: string = ''
  version: string = ''
  position: number = 0 //
  //1=已下载，2=未下载
  downloadedState: number = 2
  //题库类型：0=题库广场，2=自定义导入
  bankType: number = 0
  //NEW题库
  NewFlag:boolean = false
}