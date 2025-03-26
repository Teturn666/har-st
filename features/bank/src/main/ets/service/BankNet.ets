import { BankTrigger } from './BankTrigger';
import { BaseResponse, HttpUtils } from '@ohos/network/Index';
import axios, { AxiosResponse, AxiosProgressEvent } from '@ohos/axios';
import { BankCategory } from '../model/BankCategory';
import { BusinessError } from '@kit.BasicServicesKit';
import { BankListRes } from '@ohos/db'
import { Logger } from '@ohos/utils'
import fs, { ReadTextOptions } from '@ohos.file.fs';

const TAG = '[BankNet]'

export class BankNet {
  //获取题库tab类型列表
  public getBankTypeList(): Promise<BankCategory[]> {
    return new Promise((resolve: Function, reject: Function) => {
      HttpUtils.getInstance().get(BankTrigger.HOME_CATEGORY_LIST_URL)
        .then((res: AxiosResponse<BaseResponse<BankCategory[]>>) => {
          let code = res.data.code
          if (code === "0") {
            resolve(res.data.data);
          } else {
            reject("data is null");
          }
        }).catch((error: BusinessError) => {
        reject(error);
      })
    })
  }

  //获取题库列表
  public getBankList(aid: string, pageNo: number): Promise<BankListRes[]> {
    return new Promise((resolve: Function, reject: Function) => {
      HttpUtils.getInstance()
        .get(BankTrigger.HOME_BANK_LIST_URL, { params: { "aid": aid, "pageSize": 10, "pageNo": pageNo } })
        .then((res: AxiosResponse<BaseResponse<BankListRes[]>>) => {
          let code = res.data.code
          if (code === "0") {
            resolve(res.data.data);
          } else {
            reject("data is null");
          }
        })
        .catch((error: BusinessError) => {
          reject(error);
        })
    })
  }

  //获取题库文件内容
  public getDownloadQuestionBank(downloadUrl: string): Promise<string> {

    return new Promise((resolve: Function, reject: Function) => {

      let filePath = getContext(this).cacheDir + '/import.data'
      // Download the file. If the file already exists, delete the existing one first.
      try {
        //检查文件是否存在
        fs.accessSync(filePath);
        //删除文件
        fs.unlinkSync(filePath);
      } catch (err) {
        Logger.info(TAG, 'fs err--------' + err)
      }

      axios({
        url: downloadUrl,
        method: 'get',
        context: getContext(this),
        filePath: filePath,
        onDownloadProgress: (progressEvent: AxiosProgressEvent): void => {
          Logger.info(TAG,
            '下载文件-------' + "progress: " + progressEvent && progressEvent.loaded && progressEvent.total ?
            Math.ceil(progressEvent.loaded / progressEvent.total * 100) : 0)
        }
      }).then((res: AxiosResponse) => {
        console.info("result: " + JSON.stringify(res.data));

        try {
          let readTextOptions: ReadTextOptions = {
            offset: 0,
            length: 0,
            encoding: 'utf-8'
          };
          let stat = fs.statSync(filePath);
          readTextOptions.length = stat.size;
          let str = fs.readTextSync(filePath, readTextOptions)
          // Logger.info(TAG, "读取的长度----" + str)
          resolve(str);
        } catch (e) {
          Logger.info(TAG, "读取文件内容失败----" + e)
        }
      }).catch((error: BusinessError) => {
        console.error("error:" + JSON.stringify(error));
      })
    })
  }
}