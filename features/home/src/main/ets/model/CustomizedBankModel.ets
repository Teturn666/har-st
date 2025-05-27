import { BankListRes, QuestionRes } from "db"

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