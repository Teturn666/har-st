import fs from '@ohos.file.fs';
import { BusinessError } from '@kit.BasicServicesKit';
import { common } from '@kit.AbilityKit';
import { util } from '@kit.ArkTS';
import SearchConstants from '../constants/SearchConstants';

// 定义可序列化的数据格式
type SerializableTreeMapData = Record<string, number[]>;

export type TreeDataObject = Record<string, number[]>;

export class SearchMapManage {
  // 新增单例实例存储
  private static instance: SearchMapManage;

  // 私有构造函数防止外部实例化
  private constructor() {
  }

  // 新增单例获取方法
  static getInstance(): SearchMapManage {
    if (!SearchMapManage.instance) {
      SearchMapManage.instance = new SearchMapManage();
    }
    return SearchMapManage.instance;
  }

  // 保存数据到文件
  async saveMapToFile(ctx: common.Context, data: Map<string, Set<number>>): Promise<void> {
    try {
      const serializableData: SerializableTreeMapData = {};
      const entries = data.entries();
      let entry = entries.next();
      while (!entry.done) {
        const key = entry.value[0];
        const setValues = entry.value[1];
        serializableData[key] = Array.from<number>(setValues).sort((a, b) => a - b);
        entry = entries.next();
      }
      const jsonData = JSON.stringify(serializableData, null, 2);
      const file =
        await fs.open(ctx.filesDir + SearchConstants.SEARCH_FILE_NAME, fs.OpenMode.CREATE | fs.OpenMode.WRITE_ONLY);
      await fs.write(file.fd, jsonData);
      await fs.close(file.fd);
      console.info('map data saved successfully');
    } catch (error) {
      const err = error as BusinessError;
      console.error('Failed to save map data:', err);
    }
  }

  // 从文件中加载数据,返回map数据类型
  async loadMapFromFile(ctx: common.Context): Promise<Map<string, Set<number>> | null> {
    try {
      const stat = await fs.stat(ctx.filesDir + SearchConstants.SEARCH_FILE_NAME);
      if (!stat.isFile()) {
        throw new Error('文件不存在');
      }
      const file = await fs.open(ctx.filesDir + SearchConstants.SEARCH_FILE_NAME, fs.OpenMode.READ_ONLY);
      const buffer = new ArrayBuffer(stat.size);
      await fs.read(file.fd, buffer);
      await fs.close(file.fd);
      const textDecoder = util.TextDecoder.create('utf-8');
      const jsonData = textDecoder.decodeToString(new Uint8Array(buffer));
      const serializableData: SerializableTreeMapData = JSON.parse(jsonData);
      const restoredMap = new Map<string, Set<number>>();
      const keys = Object.keys(serializableData);
      for (let i = 0; i < keys.length; i++) {
        const key = keys[i];
        restoredMap.set(key, new Set(serializableData[key]));
      }
      return restoredMap;
    } catch (error) {
      const err = error as BusinessError;
      console.error('Failed to load map data:', err);
      return new Map<string, Set<number>>();
    }
  }

  /**
   * 从文件中加载数据,返回数组对象数据类型
   * @param ctx
   * @returns
   */
  // 从文件中加载数据,返回对象数据类型
  async loadObjectFromFile(ctx: common.Context): Promise<TreeDataObject | null> {
    try {
      const stat = await fs.stat(ctx.filesDir + SearchConstants.SEARCH_FILE_NAME);
      if (!stat.isFile()) {
        throw new Error('文件不存在');
      }

      const file = await fs.open(ctx.filesDir + SearchConstants.SEARCH_FILE_NAME, fs.OpenMode.READ_ONLY);
      const buffer = new ArrayBuffer(stat.size);
      await fs.read(file.fd, buffer);
      await fs.close(file.fd);

      const textDecoder = util.TextDecoder.create('utf-8');
      const jsonData = textDecoder.decodeToString(new Uint8Array(buffer));
      const serializableData: SerializableTreeMapData = JSON.parse(jsonData);

      // 创建对象而不是Map
      const restoredObject: TreeDataObject = {};
      const keys = Object.keys(serializableData);

      for (let i = 0; i < keys.length; i++) {
        const key = keys[i];
        restoredObject[key] = serializableData[key];
      }

      return restoredObject;
    } catch (error) {
      const err = error as BusinessError;
      console.error('Failed to load TreeObject data:', err);
      return {};
    }
  }

  /**
   * 从文件中加载数据,返回SharedArrayBuffer对象数据类型
   * @param ctx
   * @returns SharedArrayBuffer | null
   */
  async loadSharedArrayBufferFromFile(ctx: common.Context): Promise<SharedArrayBuffer | null> {
    try {
      const stat = await fs.stat(ctx.filesDir + SearchConstants.SEARCH_FILE_NAME);
      if (!stat.isFile()) {
        throw new Error('文件不存在');
      }

      const file = await fs.open(ctx.filesDir + SearchConstants.SEARCH_FILE_NAME, fs.OpenMode.READ_ONLY);
      const buffer = new ArrayBuffer(stat.size);
      await fs.read(file.fd, buffer);
      await fs.close(file.fd);

      // 创建SharedArrayBuffer,大小与读取的文件大小一致
      const sharedBuffer = new SharedArrayBuffer(stat.size);

      // 创建视图来操作SharedArrayBuffer
      const sharedView = new Uint8Array(sharedBuffer);
      const sourceView = new Uint8Array(buffer);

      // 将ArrayBuffer的数据复制到SharedArrayBuffer中
      sharedView.set(sourceView);

      return sharedBuffer;
    } catch (error) {
      const err = error as BusinessError;
      console.error('Failed to load SharedArrayBuffer data:', err);
      return null;
    }
  }

  /**
   * 从SharedArrayBuffer中解析JSON数据（辅助函数）
   * @param sharedBuffer
   * @returns 解析后的对象数据
   */
  parseDataFromSharedBuffer(sharedBuffer: SharedArrayBuffer): TreeDataObject {
    try {
      const textDecoder = util.TextDecoder.create('utf-8');
      const jsonData = textDecoder.decodeToString(new Uint8Array(sharedBuffer));
      const serializableData: SerializableTreeMapData = JSON.parse(jsonData);

      // 创建对象而不是Map
      const restoredObject: TreeDataObject = {};
      const keys = Object.keys(serializableData);

      for (let i = 0; i < keys.length; i++) {
        const key = keys[i];
        restoredObject[key] = serializableData[key];
      }

      return restoredObject;
    } catch (error) {
      console.error('Failed to parse data from SharedArrayBuffer:', error);
      return {};
    }
  }

  // 清空沙箱文件内容：删除文件
  async clearTreeMapFile(ctx: common.Context): Promise<boolean> {
    try {
      const filePath = ctx.filesDir + SearchConstants.SEARCH_FILE_NAME;

      // 先检查文件是否存在
      try {
        await fs.stat(filePath);
      } catch (error) {
        console.info('map file does not exist, no need to clear');
        return true;
      }

      // 删除文件
      await fs.unlink(filePath);
      console.info('map file cleared successfully (deleted)');
      return true;
    } catch (error) {
      const err = error as BusinessError;
      console.error('Failed to clear map file:', err);
      return false;
    }
  }

  // 清空沙箱文件内容 - 方式2：清空文件内容但保留文件
  async clearTreeMapFileContent(ctx: common.Context): Promise<boolean> {
    try {
      const filePath = ctx.filesDir + SearchConstants.SEARCH_FILE_NAME;

      // 先检查文件是否存在
      try {
        await fs.stat(filePath);
      } catch (error) {
        console.info('map file does not exist, creating empty file');
      }

      // 写入空的JSON对象到文件
      const emptyData = JSON.stringify({}, null, 2);
      const file = await fs.open(filePath, fs.OpenMode.CREATE | fs.OpenMode.WRITE_ONLY | fs.OpenMode.TRUNC);
      await fs.write(file.fd, emptyData);
      await fs.close(file.fd);
      console.info('map file content cleared successfully');
      return true;
    } catch (error) {
      const err = error as BusinessError;
      console.error('Failed to clear map file content:', err);
      return false;
    }
  }
}
