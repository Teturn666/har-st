import { QuestionRes } from "db";

export  interface  NavDoubleString{
  title:string
  type:string
}
export  interface NavQid{
  practiceMode?: number;
  qid?: number;
  backIndex?: number;
}
export  interface DetailParams {
  title: string;
  correctCount: number;
  wrongCount: number;
  timeSpent: string;
  questions: QuestionRes[];
  typePage: number;
  backIndex: number;
  isBankData: boolean;
}