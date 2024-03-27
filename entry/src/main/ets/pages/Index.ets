@Entry
@Component
struct Index {
  @State private selectedIndex: number = 0;
  private swiperController = new SwiperController();
  private thumbnailUrls: string[] = [
    'https://seopic.699pic.com/photo/50034/0209.jpg_wh1200.jpg',
    'https://seopic.699pic.com/photo/50130/3754.jpg_wh1200.jpg',
    'https://seopic.699pic.com/photo/40165/5225.jpg_wh1200.jpg'
  ];
  build() {
    Column() {
      Swiper(this.swiperController) {
        ForEach(this.thumbnailUrls, (thumbnailUrl: string) => {
          Image(thumbnailUrl)
            .objectFit(ImageFit.Contain)
            .backgroundColor(Color.Transparent)
            .fitOriginalSize(true)
        }, (_thumbnailUrl: string, index: number) => String(index))
      }
      .cachedCount(2)
      .index(this.selectedIndex)
      .flexGrow(1)
      .width('100%')
      .onChange((index: number) => {
        this.selectedIndex = index;
      })
    }
    .width('100%')
    .height('100%')
  }
}
