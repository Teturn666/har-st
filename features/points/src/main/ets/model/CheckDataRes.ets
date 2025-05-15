@Observed
export default class CheckDataRes {
  days: number = 0;
  point: number = 0;
}

@Observed
export class showSingle {
  days: string = '';
  point: string = '';
  type: number = 0; //  1，以领取。 2. 点击领取。 3. 未领取
  constructor(days: number, point: number, type: number) {
    this.days = String(days)
    this.point = String(point)
    this.type = type
  }
}