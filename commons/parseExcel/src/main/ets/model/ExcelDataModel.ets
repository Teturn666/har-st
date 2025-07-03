// 解析excel后传递给鸿蒙侧数据结构
export interface ExcelDataObj {
  quizBank: BankListRes,
  questions: Array<QuestionRes>
  questionErrorList: QuestionError[]
}

// 无法解析的行数据结构
export interface QuestionError {
  sheetName: string,
  row: number, // 表头位于第1行
  error?: string
}

//题目表
export class QuestionRes {
  //数据库主键，自增
  id: number = 0
  //题库ID
  qId: number = 0
  //题库名称
  qName: string = ""
  //问题
  question: string = ""
  //选项数组
  option: string[] = []
  //正确答案
  answer: string = ""
  //错误答案
  wrongAnswer: string = ""
  //题目id
  questionID: number = 0
}

//题库表
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
  NewFlag: boolean = false
}