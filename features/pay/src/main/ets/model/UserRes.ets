import { UserDetailRes } from "./UserDetailRes"

export class UserRes {
  errno: number = 1
  msg: string = ""
  data: UserDetailRes = new UserDetailRes()
}