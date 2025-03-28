//题库表
@Observed
export class BankListRes {
  id: number = 0
  qid: string = ''
  name: string = ''
  desc: string = ''
  time: string = ''
  url: string = ''
  num: string = ''
  version: number = 0
  position: number = 0
  //1=已下载，2=未下载
  downloadedState: number = 2
}