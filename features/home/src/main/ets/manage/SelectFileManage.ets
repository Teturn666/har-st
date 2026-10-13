import picker from '@ohos.file.picker';
import fs from '@ohos.file.fs';
import { util } from '@kit.ArkTS';

const TAG = 'SelectFileManage'

// 1. 选择文件
export async function selectFile(): Promise<string[]> {
  const documentPicker = new picker.DocumentViewPicker();
  const result = await documentPicker.select({
    fileSuffixFilters: ['.xlsx', '.xls', '.txt']
  });
  let file = fs.openSync(result[0], fs.OpenMode.READ_ONLY);
  const stat = fs.statSync(file.fd);
  let buffer = new ArrayBuffer(stat.size);
  fs.readSync(file.fd, buffer);

  // 转成base64编码的字符串
  const helper = new util.Base64Helper()
  const Base64Str = helper.encodeToStringSync(new Uint8Array(buffer))

  // 获取文件扩展名
  const fileTypeName = getFileExtension(file.name)
  fs.closeSync(file.fd)
  return [file.name, Base64Str, fileTypeName];
}


/**
 * 解析文件名的文件类型（扩展名）
 * @param {string} fileName - 完整文件名（如 "副本demo.xlsx"）
 * @returns {string} 扩展名（小写，无点；若无扩展名返回空字符串）
 */
export function getFileExtension(fileName: string) {
  if (typeof fileName !== 'string' || fileName.trim() === '') {
    return '';
  }
  const lastDotIndex = fileName.lastIndexOf('.');
  if (lastDotIndex === -1 || lastDotIndex === 0) {
    return '';
  }
  const extension = fileName.slice(lastDotIndex + 1).toLowerCase();
  return extension;
}

export function getPrefix(fileName: string) {
  const dotIndex = fileName.lastIndexOf('.');
  return dotIndex === -1 ? fileName : fileName.substring(0, dotIndex);
}
