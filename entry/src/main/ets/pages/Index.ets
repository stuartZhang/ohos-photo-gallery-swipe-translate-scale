import axios, { AxiosResponse } from '@ohos/axios';
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
  zero(): Vector {
    this.x = this.y = 0;
    return this;
  }
}
// ----------------------------------------------------------------------
interface PictureInitData {
  pixelMap: PixelMap;
  info: image.ImageInfo;
}
@Component
struct Picture {
  @State private newScale: number = 1;
  @State private oldScale: number = 1;
  @State private scaleOrigin: Vector = new Vector();
  @State private oldPan: Vector = new Vector();
  @State private newPan: Vector = new Vector();
  @State private thumbnailPixelMap: Ref<PixelMap> = new Ref();
  @State private thumbnailImgInfo: Ref<image.ImageInfo> = new Ref();
  private initDefer: Deferred<PictureInitData, Error> = new Deferred();
  private initPromise: Promise<PictureInitData> = this.initDefer.promise;

  @Prop currentIndex: number;
  @Prop isOnSwiperAnimation: boolean;
  myIndex: number = 0;
  thumbnailUrl: string = '';

  aboutToAppear(): void {
    this.newScale = this.oldScale = 1;
    this.scaleOrigin.zero();
    this.oldPan.zero();
    this.newPan.zero();
    axios.get<ArrayBuffer>(this.thumbnailUrl).then((response: AxiosResponse<ArrayBuffer>): Promise<PixelMap> => {
      return image.createImageSource(response.data).createPixelMap();
    }).then((thumbnailPixelMap: PixelMap) => {
      this.thumbnailPixelMap.value = thumbnailPixelMap;
      return thumbnailPixelMap.getImageInfo();
    }).then((thumbnailImgInfo: image.ImageInfo) => {
      this.thumbnailImgInfo = thumbnailImgInfo;
    }).then(() => {
      if (this.thumbnailPixelMap.value && this.thumbnailImgInfo.value) {
        this.initDefer.resolve({
          pixelMap: this.thumbnailPixelMap.value,
          info: this.thumbnailImgInfo.value
        });
      } else {
        this.initDefer.reject(new Error('初始化未完成'));
      }
    }, (err: Error) => {
      this.initDefer.reject(err);
    });
  }
  build() {
    if (this.thumbnailPixelMap.value) {
      Image(this.thumbnailPixelMap.value)
        .border({ width: 1, color: Color.Black, style: BorderStyle.Solid })
        .padding(0)
        .margin(0)
        .width('100%')
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
        .parallelGesture(GestureGroup(
          GestureMode.Parallel,
          PinchGesture().onActionUpdate((event: GestureEvent) => {
            if (!event.repeat && !this.isOnSwiperAnimation) {
              this.newScale = this.oldScale * event.scale;
              this.scaleOrigin.set(event.pinchCenterX, event.pinchCenterY);
            }
          }).onActionEnd(() => {
            this.oldScale = this.newScale;
          }),
          PanGesture().onActionUpdate((event: GestureEvent) => {
            if (!event.repeat && !this.isOnSwiperAnimation) {
              this.newPan.copyFrom(this.oldPan.add(new Vector(event.offsetX, event.offsetY)));
            }
          }).onActionEnd(() => {
            if (!this.isOnSwiperAnimation) {
              this.oldPan.copyFrom(this.newPan);
            }
          })
        ))
    }
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
