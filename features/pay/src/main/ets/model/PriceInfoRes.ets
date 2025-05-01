export class PriceInfoRes {
  id: string = ""
  name: string = ""
  showtext: string = ""
  days: number = 1
  price: number = 1
  amount: number = 1

  get priceTr() {
    return this.amount * 1.0 / 100
  }

  get priceOrigin() {
    return this.price * 1.0 / 100
  }
}