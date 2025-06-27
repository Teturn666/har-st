import { CSJFeedAd } from "@csj/openadsdk"
import { BankListRes } from "db"

export interface BankCategory{
  name: string
  aid: string
  url: string
}
@Observed
export class DateItem {
  @Track
  type: "normal" | "ad" = "normal"
  @Track
  data: BankListRes | CSJFeedAd = {} as BankListRes
}