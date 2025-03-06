export interface TabBarData {
  id: TabBarType;
  title: ResourceStr;
  activeIcon: ResourceStr;
  defaultIcon: ResourceStr;
}

export enum TabBarType {
  HOME = 0,
  MINE
}

export const TabsInfo: TabBarData[] = [
  {
    id: TabBarType.HOME,
    title: $r('app.string.tab_home'),
    activeIcon: $r('app.media.ic_home_pre'),
    defaultIcon: $r('app.media.ic_home')
  },
  {
    id: TabBarType.MINE,
    title: $r('app.string.tab_mine'),
    activeIcon: $r('app.media.ic_mine_pre'),
    defaultIcon: $r('app.media.ic_mine')
  },
]