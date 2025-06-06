import { CreatePayInfoRes } from "./CreatePayInfoRes"

export class CreatePayRes {
  errno: number = 1
  msg: string = ""
  data: CreatePayInfoRes = new CreatePayInfoRes()
}