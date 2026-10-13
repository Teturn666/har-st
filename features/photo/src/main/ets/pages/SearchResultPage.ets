import { TitleBar } from 'widget/Index'
import { routerHome } from '../constants/RouterHome'
import { SearchTypeView } from '../components/SearchTypeView'

@Entry({ routeName: 'searchResultPage' })
@Component
export struct SearchResultPage {
  @Consume appPathStack: NavPathStack

  build() {
    Flex({ direction: FlexDirection.Column }) {
      TitleBar({
        title: '搜索结果',
        backClick: () => {
          this.appPathStack.replacePathByName(routerHome.ROUTER_PhotoSearch_Page, null)
        }
      })
      SearchTypeView()
    }
  }
}

