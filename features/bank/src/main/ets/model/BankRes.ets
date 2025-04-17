import { BankListRes } from 'db';

@Observed
export default class BankRes {
  newsData: Array<BankListRes> = [];
  currentPage: number = 1;
  pageSize: number = 10;
  isVisiblePullDown: boolean = false;
  isVisiblePullUpLoad: boolean = false;
  offsetY: number = 0;
  hasMore: boolean = true;
  startIndex = 0;
  endIndex = 0;
  downY = 0;
  lastMoveY = 0;
  isRefreshing: boolean = false;
  isCanRefresh = false;
  isPullRefreshOperation = false;
  isLoading: boolean = false;
  isCanLoadMore: boolean = false;
}