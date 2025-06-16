export class ArrayUtil {
  static isEmpty<T>(array?: T[]): boolean {
    if (!array) {
      return true
    }
    return array.length === 0
  }

  static createArrayWithLength<T>(length: number, initialValue?: () => T) {
    return new Array(length).fill(initialValue ? initialValue!() : 0);
  }

  static isOneDimensionalArray<T>(arr: T[][] | T[]): arr is T[] {
    return !Array.isArray(arr[0]);
  }

  static isTwoDimensionalArray<T>(arr: T[][] | T[]): arr is T[][] {
    return Array.isArray(arr[0]);
  }
}