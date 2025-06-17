// 停止原因枚举
export enum StopReason {
  MANUAL_STOP = 0,           // 主动调用停止
  STOPPED_BY_USER = 1,       // 用户主动停止（系统级）
  CANCELED = 2,              // 用户取消
  STOPPED_BY_CALL = 3,       // 来电停止
  INTERRUPTED_BY_OTHER = 4,  // 被其他应用中断
  // 负数表示错误停止，值为负的错误码
}

// 停止回调类型
export type StopCallback = (stopReason: number) => void;

// 数据回调类型
export type DataCallback = (fileNum: number) => void;

// 导出函数类型
export const startScreenCapture: (
  intervalTime: number,
  dataCallback: DataCallback,
  stopCallback?: StopCallback  // 可选的停止回调
) => number;

export const stopScreenCapture: () => number;