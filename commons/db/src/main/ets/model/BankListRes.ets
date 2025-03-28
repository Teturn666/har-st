//题库表
export class BankListRes {
  qid: string = ''
  name: string = ''
  desc: string = ''
  time: string = ''
  url: string = ''
  version: number = 0
  position: number = 0
  //1=已下载，2=未下载
  downloadedState: number = 1
}