import { vec2 } from '../libs/glMatrix/index';
import image from '@ohos.multimedia.image';
// ----------------------------------------------------------------------
type PromiseState = 'resolved' | 'rejected' | 'pending';
class Deferred<T, E> {
  reject: (error: E) => void = (_: E) => {};
  resolve: (data: T) => void = (_: T) => {};
  state: PromiseState;
  readonly promise: Promise<T>;
  constructor() {
    this.state = 'pending';
    this.promise = new Promise((resolve, reject) => {
      this.resolve = (data: T) => {
        this.state = 'resolved';
        resolve(data);
      };
      this.reject = (error: E) => {
        this.state = 'rejected';
        reject(error);
      };
    });
  }
}
// ----------------------------------------------------------------------
@Observed
class Ref<T> {
  public value?: T;
  constructor(value?: T) {
    this.value = value;
  }
  toString(): string {
    if (typeof this.value == 'object') {
      try {
        return JSON.stringify(this.value);
      } catch (err) {}
    }
    return String(this.value);
  }
}
// ----------------------------------------------------------------------
interface PictureInitData {
  pixelMap: PixelMap;
  info: image.ImageInfo;
}
interface ImageCompleteEvent {
  width: number;
  height: number;
  componentWidth: number;
  componentHeight: number;
  loadingStatus: number;
  contentWidth: number;
  contentHeight: number;
  contentOffsetX: number;
  contentOffsetY: number;
}
type Vec2 = [number, number];
@Component
struct Picture {
  @State private newScale: number = 1;
  @State private oldScale: number = 1;
  @State private scaleOrigin: Vec2 = vec2.create();
  @State private oldPan: Vec2 = vec2.create();
  @State private newPan: Vec2 = vec2.create();

  @Prop currentIndex: number;
  @Prop isOnSwiperAnimation: boolean;
  myIndex: number = 0;
  thumbnailUrl: string = '';

  async init(event: ImageCompleteEvent) {
    console.info('[Picture][init]', JSON.stringify(event));
  }
  aboutToAppear(): void {
    this.newScale = this.oldScale = 1;
    this.scaleOrigin = vec2.zero(this.scaleOrigin);
    this.oldPan = vec2.zero(this.oldPan);
    this.newPan = vec2.zero(this.newPan);
  }
  build() {
    Image(this.thumbnailUrl)
      // .border({ width: 1, color: Color.Black, style: BorderStyle.Solid })
      .padding(0)
      .margin(0)
      .width('100%')
      .objectFit(ImageFit.Contain)
      .backgroundColor(Color.Transparent)
      .fitOriginalSize(true)
      .scale({
        x: this.newScale,
        y: this.newScale,
        centerX: this.scaleOrigin[0],
        centerY: this.scaleOrigin[1]
      })
      .translate({
        x: this.newPan[0],
        y: this.newPan[1]
      })
      .parallelGesture(GestureGroup(
        GestureMode.Parallel,
        PinchGesture().onActionUpdate((event: GestureEvent) => {
          if (!event.repeat && !this.isOnSwiperAnimation) {
            this.newScale = this.oldScale * event.scale;
            this.scaleOrigin = vec2.set(this.scaleOrigin, event.pinchCenterX, event.pinchCenterY);
          }
        }).onActionEnd(() => {
          this.oldScale = this.newScale;
        }),
        PanGesture().onActionUpdate((event: GestureEvent) => {
          if (!event.repeat && !this.isOnSwiperAnimation) {
            this.newPan = vec2.add(this.newPan, this.oldPan, vec2.fromValues(event.offsetX, event.offsetY));
          }
        }).onActionEnd(() => {
          if (!this.isOnSwiperAnimation) {
            this.oldPan = vec2.copy(this.oldPan, this.newPan);
          }
        })
      ))
      .onComplete((event: ImageCompleteEvent) => {
        if (event.loadingStatus == 1) {
          this.init(event);
        }
      })
  }
}
@Entry
@Component
struct Gallery {
  @State private selectedIndex: number = 0;
  @State private isOnSwiperAnimation: boolean = false;
  private swiperController = new SwiperController();
  private thumbnailUrls: string[] = [
    'https://seopic.699pic.com/photo/50034/0209.jpg_wh1200.jpg',
    'https://seopic.699pic.com/photo/50130/3754.jpg_wh1200.jpg',
    'https://seopic.699pic.com/photo/40165/5225.jpg_wh1200.jpg'
  ];
  build() {
    Column() {
      Swiper(this.swiperController) {
        ForEach(this.thumbnailUrls, (thumbnailUrl: string, index: number) => {
          Column() {
            Text() {
              Span(`isOnSwiperAnimation=${this.isOnSwiperAnimation}`)
            }
            Picture({
              thumbnailUrl,
              isOnSwiperAnimation: this.isOnSwiperAnimation,
              myIndex: index,
              currentIndex: this.selectedIndex
            })
          }
          .border({ width: 1, color: Color.Red, style: BorderStyle.Solid })
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
          .padding(0)
          .margin(0)
        }, (_thumbnailUrl: string, index: number) => String(index))
      }
      .cachedCount(2)
      .index(this.selectedIndex)
      .flexGrow(1)
      .width('100%')
      .onChange((index: number) => {
        this.selectedIndex = index;
      })
      .onGestureSwipe((index: number, extraInfo: SwiperAnimationEvent) => {
        if (!this.isOnSwiperAnimation) {
          this.isOnSwiperAnimation = true;
        }
      })
      .onAnimationStart((_index: number, _targetIndex: number, _extraInfo: SwiperAnimationEvent) => {
        this.isOnSwiperAnimation = true;
      })
      .onAnimationEnd((index: number, extraInfo: SwiperAnimationEvent) => {
        this.isOnSwiperAnimation = false;
      })
    }
    .width('100%')
    .height('100%')
  }
}
