import { preferences } from '@kit.ArkData'
import { ConfigRes } from '../model/ConfigRes'

class PreferencesUtils {
  context: Context | undefined
  private options: preferences.Options = {
    name: 'myStore'
  }
  private dataPreferences: preferences.Preferences | null = null

  setContext(context: Context) {
    this.context = context
  }

  private getPreferences(ctx?: Context) {
    try {
      this.dataPreferences = preferences.getPreferencesSync(ctx || this.context, this.options)
      // console.info('success getPreferences' + this.dataPreferences)
    } catch (error) {
      // console.error('error getPreferences')
    }
  }

  //存string数据
  putString(key: string, value: string, ctx?: Context) {
    //判断preference对象是否存在
    // if (!this.dataPreferences) {
    this.getPreferences(ctx)
    // }
    try {
      this.dataPreferences?.putSync(key, value);
      //持久化存储
      this.dataPreferences?.flushSync()
    } catch (error) {
      console.error(error)
    }
  }

  //number
  putNumber(key: string, value: number, ctx?: Context) {
    //判断preference对象是否存在
    if (!this.dataPreferences) {
      this.getPreferences(ctx)
    }
    try {
      this.dataPreferences?.putSync(key, value);
      //持久化存储
      this.dataPreferences?.flushSync()
    } catch (error) {
      console.error(error)
    }
  }

  //存boolean数据
  putBoolean(key: string, value: boolean, ctx?: Context) {
    //判断preference对象是否存在
    if (!this.dataPreferences) {
      this.getPreferences(ctx)
    }
    try {
      this.dataPreferences?.putSync(key, value);
      //持久化存储
      this.dataPreferences?.flushSync()
    } catch (error) {
      console.error(error)
    }
  }

  putGenerics(key: string, value: ConfigRes, ctx?: Context) {
    //判断preference对象是否存在
    if (!this.dataPreferences) {
      this.getPreferences(ctx)
    }
    try {
      this.dataPreferences?.putSync(key, value);
      //持久化存储
      this.dataPreferences?.flushSync()
    } catch (error) {
      console.error(error)
    }
  }

  //获取string数据
  // ctx 上下文，多线程使用该方法时，需要传入上下文
  getString(key: string, defValue: string = '', ctx?: Context): string {
    //判断preference对象是否存在
    if (!this.dataPreferences) {
      this.getPreferences(ctx)
    }

    let value = this.dataPreferences?.getSync(key, defValue)
    return value as string
  }

  //获取number数据
  getNumber(key: string, defValue: number = 0, ctx?: Context): number {
    //判断preference对象是否存在
    if (!this.dataPreferences) {
      this.getPreferences(ctx)
    }

    let value = this.dataPreferences?.getSync(key, defValue)
    return value as number
  }

  //获取boolean数据
  getBoolean(key: string, defValue?: boolean, ctx?: Context): boolean {
    //判断preference对象是否存在
    if (!this.dataPreferences) {
      this.getPreferences(ctx)
    }

    let value = this.dataPreferences?.getSync(key, defValue)
    return value as boolean
  }

  getGenerics(key: string, defValue?: ConfigRes, ctx?: Context): ConfigRes {
    //判断preference对象是否存在
    if (!this.dataPreferences) {
      this.getPreferences(ctx)
    }
    let value = this.dataPreferences?.getSync(key, defValue)
    return value as ConfigRes
  }

  //删除数据
  deleteData(key: string, ctx?: Context) {
    //判断preference对象是否存在
    if (!this.dataPreferences) {
      this.getPreferences(ctx)
    }
    this.dataPreferences?.deleteSync(key)
    //持久化存储
    this.dataPreferences?.flushSync()
  }

  // 可选：添加清理方法
  dispose() {
    this.dataPreferences = null
    this.context = undefined
  }
}


export const preferencesUtils = new PreferencesUtils()