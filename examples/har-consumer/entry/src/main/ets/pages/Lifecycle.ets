import { ComponentActive, ComponentInactive } from '@kit.ArkUI';
import { Available, deviceInfo } from '@kit.BasicServicesKit';
import { RiveAnimationView, RiveArtboardRenderer, RendererType, RiveFileControllerListener, PlayableInstance, Loop } from '@ohos/rive';
import { RiveFileController } from '@ohos/rive/src/main/ets/runtime/controllers/RiveFileController';

// Host integration example: all lifecycle policy stays outside the frozen HAR API.
const cells: Set<CellPolicy> = new Set();
let nextInstance: number = 0;
let manualPause: boolean = false;
let pageActive: boolean = true;

class CellPolicy implements RiveFileControllerListener {
  instance: number = ++nextInstance;
  item: number = 0;
  active: boolean = true;
  visible: boolean = false;
  frames: number = 0;
  view: RiveAnimationView | null = null;
  controller: RiveFileController = new RiveFileController();

  attach(view: RiveAnimationView): void {
    if (!view.getFile() || !view.controller?.activeArtboard || !view.getRenderer() || this.view === view) { return; }
    this.view = view;
    cells.add(this);
    view.registerListener(this);
    console.info(`RiveLifecycle READY instance=${this.instance} item=${this.item}`);
    this.apply();
  }

  setActive(active: boolean, reason: string): void {
    this.active = active;
    console.info(`RiveLifecycle ACTIVE instance=${this.instance} item=${this.item} value=${active} reason=${reason}`);
    this.apply();
  }

  setVisible(visible: boolean): void {
    this.visible = visible;
    this.apply();
  }

  shouldRun(): boolean {
    return this.active && this.visible && pageActive && AppStorage.get<boolean>('abilityActive') !== false &&
      !manualPause && (this.view?.controller?.isAdvancing ?? false);
  }

  apply(): void {
    if (AppStorage.get<string>('lifecycleGate') === 'false') { return; }
    const renderer = this.view?.getRenderer();
    if (!renderer) { return; }
    if (this.shouldRun()) {
      renderer.start();
    } else {
      renderer.stop();
    }
  }

  detach(): void {
    if (this.view) {
      this.view.unregisterListener(this);
    }
    cells.delete(this);
    console.info(`RiveLifecycle DISPOSE instance=${this.instance} item=${this.item} frames=${this.frames}`);
    this.view = null;
  }

  notifyAdvance(elapsed: number): void { this.frames++; }
  notifyPlay(animation: PlayableInstance): void {}
  notifyPause(animation: PlayableInstance): void {}
  notifyStop(animation: PlayableInstance): void {}
  notifyLoop(animation: PlayableInstance): void {}
  notifyStateChanged(machine: string, state: string): void {
    console.info(`RiveLifecycle STATE instance=${this.instance} ${machine}=${state}`);
  }
}

// Use the existing renderer factory extension. ArkTS disallows method reassignment.
// Override start once so SurfaceChanged and state-machine inputs share the gate.
class ActivityRenderer extends RiveArtboardRenderer {
  private policy: CellPolicy;
  constructor(uiContext: UIContext, policy: CellPolicy) {
    super(uiContext, policy.controller, true,
      AppStorage.get<string>('renderer') === 'canvas' ? RendererType.Canvas : RendererType.Rive);
    this.policy = policy;
  }
  override start(): void {
    if (AppStorage.get<string>('lifecycleGate') === 'false' || this.policy.shouldRun()) { super.start(); }
  }
}

@Builder
function CellContent(policy: CellPolicy, uiContext: UIContext) {
    RiveAnimationView({
      riveResource: 'vehicles.riv', riveArtboard: 'Truck', riveStateMachine: 'bumpy',
      controller: policy.controller,
      creatRendererFun: async () => new ActivityRenderer(uiContext, policy),
      shouldLoadCDNAssets: false, riveTraceAnimations: true,
      rendererType: AppStorage.get<string>('renderer') === 'canvas' ? RendererType.Canvas : RendererType.Rive,
      onReady: (view: RiveAnimationView) => policy.attach(view)
    }).height(180).width('100%')
  .onVisibleAreaChange([0.0], (visible: boolean, ratio: number) => policy.setVisible(visible && ratio > 0))
}

@Available({ minApiVersion: '26.0.0' })
@Reusable
@Component
struct ActiveCell26 {
  @Prop itemId: number = 0;
  private policy: CellPolicy = new CellPolicy();
  aboutToAppear(): void { this.policy.item = this.itemId; }
  aboutToReuse(params: Record<string, Object>): void {
    this.itemId = params['itemId'] as number;
    this.policy.item = this.itemId;
    console.info(`RiveLifecycle REUSE26 instance=${this.policy.instance} item=${this.itemId}`);
  }
  @ComponentActive
  activated(): void { this.policy.setActive(true, 'ComponentActive26'); }
  @ComponentInactive
  inactivated(): void { this.policy.setActive(false, 'ComponentInactive26'); }
  aboutToDisappear(): void { this.policy.detach(); }
  build() {
    Column() {
      Text(`Rive ${this.itemId} · instance ${this.policy.instance}`).fontSize(12)
      CellContent(this.policy, this.getUIContext())
    }.width('100%').height(208)
  }
}

@Reusable
@Component
struct ActiveCell12 {
  @Prop itemId: number = 0;
  private policy: CellPolicy = new CellPolicy();
  aboutToAppear(): void { this.policy.item = this.itemId; }
  aboutToRecycle(): void { this.policy.setActive(false, 'aboutToRecycle10'); }
  aboutToReuse(params: Record<string, Object>): void {
    this.itemId = params['itemId'] as number;
    this.policy.item = this.itemId;
    this.policy.setActive(true, 'aboutToReuse10');
  }
  aboutToDisappear(): void { this.policy.detach(); }
  build() {
    Column() {
      Text(`Rive ${this.itemId} · instance ${this.policy.instance}`).fontSize(12)
      CellContent(this.policy, this.getUIContext())
    }.width('100%').height(208)
  }
}

class ListData implements IDataSource {
  totalCount(): number { return 24; }
  getData(index: number): number { return index; }
  registerDataChangeListener(listener: DataChangeListener): void {}
  unregisterDataChangeListener(listener: DataChangeListener): void {}
}

@Entry
@Component
struct Lifecycle {
  @StorageLink('abilityActive') @Watch('abilityChanged') private abilityActive: boolean = true;
  private data: ListData = new ListData();
  private use26: boolean = deviceInfo.sdkApiVersion >= 26 && AppStorage.get<string>('legacyHooks') !== 'true';
  private listMode: boolean = AppStorage.get<string>('lifecycleMode') === 'list';
  @State private mounted: boolean = true;
  @State private status: string = '';

  onPageShow(): void { pageActive = true; cells.forEach((cell: CellPolicy) => cell.apply()); }
  onPageHide(): void { pageActive = false; cells.forEach((cell: CellPolicy) => cell.apply()); }
  private abilityChanged(): void {
    console.info(`RiveLifecycle ABILITY active=${this.abilityActive}`);
    cells.forEach((cell: CellPolicy) => cell.apply());
  }

  private report(): void {
    cells.forEach((cell: CellPolicy) => {
      console.info(`RiveLifecycle METRIC instance=${cell.instance} item=${cell.item} active=${cell.active} visible=${cell.visible} playing=${cell.view?.isPlaying()} frames=${cell.frames}`);
    });
    this.status = `实例 ${cells.size} · 手动暂停 ${manualPause}`;
  }

  private setManualPause(value: boolean): void {
    manualPause = value;
    cells.forEach((cell: CellPolicy) => {
      if (value) { cell.view?.pause(); }
      else { cell.view?.play('bumpy', Loop.AUTO, undefined, true); }
      cell.apply();
    });
    this.report();
  }

  private cycle(): void {
    // Exercise rapid stop/start within one vsync as well as normal user controls.
    cells.forEach((cell: CellPolicy) => {
      for (let i = 0; i < 100; i++) {
        cell.view?.getRenderer()?.stop();
        cell.apply();
      }
    });
    console.info('RiveLifecycle CYCLE100_DONE');
    this.report();
  }

  @Builder
  private cell(item: number) {
    // Keep apiAvailable as a literal, standalone guard for the SDK checker.
    // sdkApiVersion protects the apiAvailable call itself on pre-26 systems.
    if (deviceInfo.sdkApiVersion >= 26) {
      if (deviceInfo.apiAvailable('26.0.0')) {
        if (this.use26) { ActiveCell26({ itemId: item }) }
        else { ActiveCell12({ itemId: item }) }
      } else { ActiveCell12({ itemId: item }) }
    } else { ActiveCell12({ itemId: item }) }
  }

  build() {
    Column({ space: 8 }) {
      Text(`Rive API26 · ${this.use26 ? 'Active26' : 'Legacy12'} · ${this.listMode ? '列表' : '复用池'}`).fontSize(18)
      Text(this.status).fontSize(12)
      Row({ space: 8 }) {
        Button('暂停').id('life-pause').onClick(() => this.setManualPause(true))
        Button('恢复').id('life-resume').onClick(() => this.setManualPause(false))
        Button('计数').id('life-report').onClick(() => this.report())
      }
      Row({ space: 8 }) {
        Button('回收/复用').id('life-toggle').onClick(() => { this.mounted = !this.mounted; })
        Button('100次启停').id('life-cycle').onClick(() => this.cycle())
        Button('退出').id('life-exit').onClick(() => {
          this.getUIContext().getRouter().replaceUrl({ url: 'pages/Blank' });
        })
      }
      if (this.mounted) {
        if (this.listMode) {
          List() {
            LazyForEach(this.data, (item: number) => {
              ListItem() {
                this.cell(item)
              }
            }, (item: number) => `${item}`)
          }.layoutWeight(1).cachedCount(1).id('life-list')
        } else {
          this.cell(0)
        }
      } else {
        Text('已进入复用池').height(208)
      }
    }.height('100%').width('100%').padding(16).backgroundColor('#E5E7EB')
  }
}
