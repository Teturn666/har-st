//题目表
export interface QuestionRes {
  id: number
  questionId: number
  pid: number
  question: string
  option: string[]
  answer: string
  questionCase: string
  img: string
}