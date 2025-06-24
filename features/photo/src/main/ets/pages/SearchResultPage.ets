import { TitleBar } from 'widget/Index'
import { router } from '@kit.ArkUI'
import { routerHome } from '../constants/RouterHome'
import { SearchTypeView } from '../components/SearchTypeView'

@Entry({ routeName: 'searchResultPage' })
@Component
export struct SearchResultPage {
  build() {
    Flex({ direction: FlexDirection.Column }) {
      TitleBar({
        title: '搜索结果',
        backClick: () => {
          router.replaceUrl({
            url: routerHome.ROUTER_CROPIMAGE_Page
          })
        }
      })
      SearchTypeView()
    }
  }
}

