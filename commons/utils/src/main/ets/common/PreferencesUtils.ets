import { preferences } from '@kit.ArkData'

let dataPreferences: preferences.Preferences | null = null

class PreferencesUtils {
  private context: Context | undefined
  options: preferences.Options = {
    name: 'myStore'
  }

  setContext(context: Context) {
    this.context = context
  }

  getPreferences() {
    try {
      dataPreferences = preferences.getPreferencesSync(this.context, this.options)
      // console.info('success getPreferences' + dataPreferences)

    } catch (error) {
      // console.error('error  getPreferences')
    }
  }

  //存string数据
  putString(key: string, value: string) {
    //判断preference对象是否存在
    if (!dataPreferences) {
      this.getPreferences()
    }
    try {
      dataPreferences?.putSync(key, value);

      //持久化存储
      dataPreferences?.flushSync()
    } catch (error) {
      console.error(error)
    }
  }

  //number
  putNumber(key: string, value: number) {
    //判断preference对象是否存在
    if (!dataPreferences) {
      this.getPreferences()
    }
    try {
      dataPreferences?.putSync(key, value);

      //持久化存储
      dataPreferences?.flushSync()
    } catch (error) {
      console.error(error)
    }
  }

  //存boolean数据
  putBoolean(key: string, value: boolean) {
    //判断preference对象是否存在
    if (!dataPreferences) {
      this.getPreferences()
    }
    try {
      dataPreferences?.putSync(key, value);

      //持久化存储
      dataPreferences?.flushSync()
    } catch (error) {
      console.error(error)
    }
  }

  //获取string数据
  getString(key: string, defValue: string = ''): string {
    //判断preference对象是否存在
    if (!dataPreferences) {
      this.getPreferences()
    }

    let value = dataPreferences?.getSync(key, defValue)

    return value as string
  }

  //获取number数据
  getNumber(key: string, defValue: number = 0): number {
    //判断preference对象是否存在
    if (!dataPreferences) {
      this.getPreferences()
    }

    let value = dataPreferences?.getSync(key, defValue)

    return value as number
  }

  //获取boolean数据
  getBoolean(key: string, defValue?: boolean): boolean {
    //判断preference对象是否存在
    if (!dataPreferences) {
      this.getPreferences()
    }

    let value = dataPreferences?.getSync(key, defValue)

    return value as boolean
  }

  //删除数据
  deleteData(key: string) {
    //判断preference对象是否存在
    if (!dataPreferences) {
      this.getPreferences()
    }
    dataPreferences?.deleteSync(key)
    //持久化存储
    dataPreferences?.flushSync()
  }
}


export const preferencesUtils = new PreferencesUtils()