@Observed
class Vector {
  x: number = Infinity;
  y: number = Infinity;

  constructor(x?: number, y?: number) {
    this.set(x, y);
  }
  copyFrom(vector: Vector): Vector {
    this.x = vector.x;
    this.y = vector.y;
    return this;
  }
  set(x = 0, y = 0): Vector {
    this.x = x;
    this.y = y;
    return this;
  }
  add(vector: Vector): Vector {
    return new Vector(
      this.x + vector.x,
      this.y + vector.y
    );
  }
}
@Entry
@Component
struct Index {
  @State private selectedIndex: number = 0;
  @State private newScale: number = 1;
  @State private oldScale: number = 1;
  @State private scaleOrigin: Vector = new Vector();
  @State private oldPan: Vector = new Vector();
  @State private newPan: Vector = new Vector();
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
            .scale({
              x: this.newScale,
              y: this.newScale,
              centerX: this.scaleOrigin.x,
              centerY: this.scaleOrigin.y
            })
            .translate({
              x: this.newPan.x,
              y: this.newPan.y
            })
            .parallelGesture(PinchGesture().onActionUpdate((event: GestureEvent) => {
              if (!event.repeat) {
                this.newScale = this.oldScale * event.scale;
                this.scaleOrigin.set(event.pinchCenterX, event.pinchCenterY);
              }
            }).onActionEnd(() => {
              this.oldScale = this.newScale;
            }))
            .parallelGesture(PanGesture().onActionUpdate((event: GestureEvent) => {
              if (!event.repeat) {
                this.newPan.copyFrom(this.oldPan.add(new Vector(event.offsetX, event.offsetY)));
              }
            }).onActionEnd(() => {
              this.oldPan.copyFrom(this.newPan);
            }))
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
