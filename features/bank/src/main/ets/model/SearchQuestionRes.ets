import { CSJFeedAd } from "@csj/openadsdk"
import { BankListRes } from "db"

@Observed
export class SearchQuestionRes {
  Name: string = ''
  Qnum: number = 0
  id: string = ''
  aid: string = ''
  qid: string = ''
  q: string = ''
  a: string = ''
  ans: string = ''
  father: number = 0
  ASlice: string[] = []
  //1=已下载，2=未下载
  downloadedState: number = 2
}
//广告的混合类型
@Observed
export class HybridType {
  @Track
  type: "normal" | "ad" = "normal"
  @Track
  data: BankListRes | CSJFeedAd = {} as BankListRes
}