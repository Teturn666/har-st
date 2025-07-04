import { BankListRes, QuestionRes } from "db"

export interface BankCategory{
  name: string
  aid: string
  url: string
}
export  class Params {
  controller: CanvasRenderingContext2D
  animateName: string
  imgRes: string

  constructor(controller: CanvasRenderingContext2D, animateName: string, imgRes: string) {
    this.controller = controller;
    this.animateName = animateName;
    this.imgRes = imgRes;
  }
}
// 第二种数据格式
export  interface QuestionItem {
  qId: string
  q: string
  a: string[]
  ans: string
}

export  interface generatedType {
  isUpDate: boolean
  bankDetails: BankListRes;
  downloadedState: number;
  questionList: Array<QuestionRes>
  questionListtwo: Array<QuestionItem>
  page?:string
}

export  interface NavQid{
  practiceMode?: number;
  qid?: number;
  backIndex?: number;
  bankPage?:string
}