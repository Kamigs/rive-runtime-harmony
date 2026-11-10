# @ohos/rive 1.0.4 发布包声明清单

以下从发布 HAR 的 `.d.ets` 生成，保留参数、可选性、返回类型和回调签名。默认值和运行行为不能从声明推断，另见 API 兼容记录。

## Index.d.ets

```typescript
export { Loop } from './src/main/ets/runtime/core/Loop';
export { Direction } from './src/main/ets/runtime/core/Direction';
export { Alignment } from './src/main/ets/runtime/core/Alignment';
export { Fit } from './src/main/ets/runtime/core/Fit';
export { AdvanceResult } from './src/main/ets/runtime/core/AdvanceResult';
export { EventType } from './src/main/ets/runtime/core/EventType';
export { RiveAnimationView } from './src/main/ets/runtime/RiveAnimationView';
export { initializeRive } from './src/main/ets/rive/RiveInitializer';
export { RiveFileControllerListener, RiveEventListener, ControllerState, PointerEvents, } from './src/main/ets/runtime/controllers/RiveFileController';
export { FileAsset, AudioAsset, FontAsset, ImageAsset, RiveRenderImage, RiveAudio, RiveFont, } from './src/main/ets/runtime/core/FileAsset';
export { FileAssetLoader, ContextAssetLoader, FallbackAssetLoader, CDNAssetLoader, } from './src/main/ets/runtime/core/FileAssetLoader';
export { File } from './src/main/ets/runtime/core/File';
export { RendererType } from './src/main/ets/runtime/renderers/RendererType';
export { RiveArtboardRenderer } from './src/main/ets/runtime/renderers/RiveArtboardRenderer';
export { RendererAttributes } from './src/main/ets/runtime/renderers/RendererAttributes';
export { Renderer } from './src/main/ets/runtime/renderers/Renderer';
export { RectF } from './src/main/ets/runtime/renderers/RectF';
export { default as LinearAnimationInstance } from './src/main/ets/runtime/core/LinearAnimationInstance';
export { StateMachineInstance } from './src/main/ets/runtime/core/StateMachineInstance';
export { PlayableInstance } from './src/main/ets/runtime/core/PlayableInstance';
export { SMIBoolean } from './src/main/ets/runtime/core/SMIBoolean';
export { SMINumber } from './src/main/ets/runtime/core/SMINumber';
export { SMITrigger } from './src/main/ets/runtime/core/SMITrigger';
export { SMIInput } from './src/main/ets/runtime/core/SMIInput';
export { Artboard } from './src/main/ets/runtime/core/Artboard';
export { BindableArtboard } from './src/main/ets/runtime/core/BindableArtboard';
export { RiveManager } from './src/main/ets/runtime/core/Rive';
export { ViewModel } from './src/main/ets/runtime/core/ViewModel';
export { ViewModelInstance } from './src/main/ets/runtime/core/ViewModelInstance';
export { ViewModelBooleanProperty, ViewModelColorProperty, ViewModelEnumProperty, ViewModelNumberProperty, ViewModelStringProperty, ViewModelTriggerProperty, ViewModelImageProperty, ViewModelListProperty, ViewModelArtboardProperty, } from './src/main/ets/runtime/core/ViewModelInstance';
export { RiveEvent } from './src/main/ets/runtime/core/RiveEvent';
export { RiveGeneralEvent } from './src/main/ets/runtime/core/RiveGeneralEvent';
export { RiveOpenURLEvent } from './src/main/ets/runtime/core/RiveOpenURLEvent';
export { RiveEventReport } from './src/main/ets/runtime/core/RiveEventReport';
export { RiveTextValueRun } from './src/main/ets/runtime/core/RiveTextValueRun';
export { AnimationException } from './src/main/ets/runtime/core/errors/AnimationException';
export { ArtboardException } from './src/main/ets/runtime/core/errors/ArtboardException';
export { MalformedFileException } from './src/main/ets/runtime/core/errors/MalformedFileException';
export { RiveException } from './src/main/ets/runtime/core/errors/RiveException';
export { StateMachineException } from './src/main/ets/runtime/core/errors/StateMachineException';
export { StateMachineInputException } from './src/main/ets/runtime/core/errors/StateMachineInputException';
export { TextValueRunException } from './src/main/ets/runtime/core/errors/TextValueRunException';
export { UnsupportedRuntimeVersionException } from './src/main/ets/runtime/core/errors/UnsupportedRuntimeVersionException';
export { ViewModelException } from './src/main/ets/runtime/core/errors/ViewModelException';
export { FontFallbackStrategy, FontBytes } from './src/main/ets/runtime/fonts/FontFallbackStrategy';
export { FontHelper, FontOpts, NativeFontHelper, FileFont, Font, Weight } from './src/main/ets/runtime/fonts/FontHelpers';
export { Helpers, PointF } from './src/main/ets/runtime/core/Helpers';
export { ImageDecoder } from './src/main/ets/runtime/core/ImageDecoder';
export { test_file_asset_loader } from './src/main/ets/test/test_file_asset_loader';
export { test_file_import, test_ArtboardByName_withValidName, test_ArtboardCount_ValidFile, test_Artboard_ByIndexValid, test_ArtboardName_ValidIndex, test_CreateDefault_BindableArtboard, test_CreateBindableArtboard_ByName, test_ViewModel_Count, test_ViewModel_ByIndex, test_ViewModel_ByName, } from './src/main/ets/test/test_file';
```

## src/main/ets/rive/RiveInitializer.d.ets

```typescript
export declare function initializeRive(): void;
```

## src/main/ets/runtime/RiveAnimationView.d.ets

```typescript
import { File } from './core/File';
import { RiveFileController, RiveFileControllerListener, RiveEventListener } from './controllers/RiveFileController';
import { Loop } from './core/Loop';
import { Alignment } from './core/Alignment';
import { Fit } from './core/Fit';
import { Direction } from './core/Direction';
import { ResourceType } from './renderers/RendererAttributes';
import { RendererType } from './renderers/RendererType';
import { FileAssetLoader } from './core/FileAssetLoader';
import { StateMachineInstance } from './core/StateMachineInstance';
import LinearAnimationInstance from './core/LinearAnimationInstance';
import { Renderer } from './renderers/Renderer';
import { ChangedInput } from './core/ChangedInput';
export declare class RiveAnimationViewBuilder {
    alignment: Alignment | null;
    fit: Fit | null;
    loop: Loop | null;
    rendererType: RendererType | null;
    autoplay: boolean | null;
    autoBind: boolean;
    traceAnimations: boolean | null;
    artboardName: string | null;
    animationName: string | null;
    stateMachineName: string | null;
    assetLoader: FileAssetLoader | null;
    shouldLoadCDNAssets: boolean;
    touchPassThrough: boolean;
    multiTouchEnabled: boolean;
    resource: number | string | Uint8Array | File | null;
    resourceType: ResourceType | null;
    constructor(context: Context);
    setAlignment(value: Alignment): RiveAnimationViewBuilder;
    setFit(value: Fit): RiveAnimationViewBuilder;
    setLoop(value: Loop): RiveAnimationViewBuilder;
    setRendererType(value: RendererType): RiveAnimationViewBuilder;
    setAutoplay(value: boolean): RiveAnimationViewBuilder;
    setAutoBind(value: boolean): RiveAnimationViewBuilder;
    setTraceAnimations(value: boolean): RiveAnimationViewBuilder;
    setArtboardName(value: string): RiveAnimationViewBuilder;
    setAnimationName(value: string): RiveAnimationViewBuilder;
    setStateMachineName(value: string): RiveAnimationViewBuilder;
    setResource(value: number | string | Uint8Array | File): RiveAnimationViewBuilder;
    setAssetLoader(value: FileAssetLoader): RiveAnimationViewBuilder;
    setShouldLoadCDNAssets(value: boolean): RiveAnimationViewBuilder;
    setTouchPassThrough(value: boolean): RiveAnimationViewBuilder;
    setMultiTouchEnabled(value: boolean): RiveAnimationViewBuilder;
    build(): RiveAnimationView;
}
@Component
export declare struct RiveAnimationView {
    onReady?: (view: RiveAnimationView) => void;
    riveResource: string;
    riveUrl: string;
    riveLoop: number;
    riveFit: string;
    shouldLoadCDNAssets: boolean;
    touchPassThrough: boolean;
    multiTouchEnabled: boolean;
    rendererType: RendererType;
    alignmentIndex: number;
    riveArtboard: string;
    riveAnimation: string;
    riveStateMachine: string;
    riveAutoPlay: boolean;
    riveAutoBind: boolean;
    riveTraceAnimations: boolean;
    creatRendererFun: () => Promise<Renderer | null>;
    riveAssetLoaderClass: FileAssetLoader | null;
    controller: RiveFileController | null;
    build(): void;
    aboutToAppear(): Promise<void>;
    applyBuilder(builder: RiveAnimationViewBuilder): void;
    init(): Promise<void>;
    getRenderer(): Renderer | null;
    pause(): void;
    pauseAnimation(animationName: string, isStateMachine?: boolean): void;
    pauseAnimations(animationNames: string[], areStateMachines?: boolean): void;
    stop(): void;
    stopAnimation(animationName: string, isStateMachine?: boolean): void;
    stopMultipleAnimations(animationNames: string[], areStateMachines?: boolean): void;
    play(animationName?: string, loop?: Loop, direction?: Direction, isStateMachine?: boolean, settleInitialState?: boolean): void;
    playAnimations(animationNames: string[], loop?: Loop, direction?: Direction, areStateMachines?: boolean, settleInitialState?: boolean): void;
    reset(): void;
    fireState(stateMachineName: string, inputName: string): void;
    setBooleanState(stateMachineName: string, inputName: string, value: boolean): void;
    setNumberState(stateMachineName: string, inputName: string, value: number): void;
    fireStateAtPath(inputName: string, path: string): void;
    setBooleanStateAtPath(inputName: string, value: boolean, path: string): void;
    setNumberStateAtPath(inputName: string, value: number, path: string): void;
    setMultipleStates(...inputs: ChangedInput[]): void;
    getTextRunValue(textRunName: string, path?: string): string | null;
    setTextRunValue(textRunName: string, textValue: string, path?: string): void;
    getVolume(): number | null;
    setVolume(value: number): void;
    setRiveResource(resId: number | string, artboardName?: string, animationName?: string, stateMachineName?: string, autoplay?: boolean, autoBind?: boolean, fit?: Fit, alignment?: Alignment, loop?: Loop): void;
    setRiveBytes(bytes: ArrayBuffer, artboardName?: string, animationName?: string, stateMachineName?: string, autoplay?: boolean, autoBind?: boolean, fit?: Fit, alignment?: Alignment, loop?: Loop): void;
    setRiveFile(file: File, artboardName?: string, animationName?: string, stateMachineName?: string, autoplay?: boolean, autoBind?: boolean, fit?: Fit, alignment?: Alignment, loop?: Loop): void;
    setAssetLoader(assetLoader: FileAssetLoader | null): void;
    getFile(): File | null;
    getArtboardName(): string | null;
    setArtboardName(name: string | null): void;
    getAutoplay(): boolean;
    setAutoplay(value: boolean): void;
    getFit(): Fit;
    setFit(value: Fit): void;
    getAlignment(): Alignment;
    setAlignment(value: Alignment): void;
    getLayoutScaleFactor(): number | null;
    setLayoutScaleFactor(value: number | null): void;
    getAnimations(): LinearAnimationInstance[];
    getStateMachines(): StateMachineInstance[];
    getPlayingAnimations(): Set<LinearAnimationInstance>;
    getPlayingStateMachines(): Set<StateMachineInstance>;
    isPlaying(): boolean;
    registerListener(listener: RiveFileControllerListener): void;
    unregisterListener(listener: RiveFileControllerListener): void;
    addEventListener(listener: RiveEventListener): void;
    removeEventListener(listener: RiveEventListener): void;
    aboutToDisappear(): void;
    onPageShow(): void;
    onPageHide(): void;
}
```

## src/main/ets/runtime/controllers/RiveFileController.d.ets

```typescript
import { Loop } from '../core/Loop';
import { File } from '../core/File';
import { RendererAttributes } from '../renderers/RendererAttributes';
import { Alignment } from '../core/Alignment';
import { Fit } from '../core/Fit';
import { Direction } from '../core/Direction';
import { StateMachineInstance } from '../core/StateMachineInstance';
import { Artboard } from '../core/Artboard';
import LinearAnimationInstance from '../core/LinearAnimationInstance';
import { PlayableInstance } from '../core/PlayableInstance';
import { RiveEvent } from '../core/RiveEvent';
import { Observable } from '../Observable';
import { ChangedInput } from '../core/ChangedInput';
import { RefCount } from '../core/RefCount';
import { Bounds } from '../core/Helpers';
export interface RiveFileControllerListener {
    notifyPlay(animation: PlayableInstance): void;
    notifyPause(animation: PlayableInstance): void;
    notifyStop(animation: PlayableInstance): void;
    notifyLoop(animation: PlayableInstance): void;
    notifyStateChanged(stateMachineName: string, stateName: string): void;
    notifyAdvance?(elapsed: number): void;
}
export interface RiveEventListener {
    notifyEvent(event: RiveEvent): void;
}
export declare class ControllerState {
    file: File;
    activeArtboard: Artboard;
    animations: LinearAnimationInstance[];
    playingAnimations: Set<LinearAnimationInstance>;
    stateMachines: StateMachineInstance[];
    playingStateMachines: Set<StateMachineInstance>;
    isActive: boolean;
    constructor(file: File, activeArtboard: Artboard, animations: LinearAnimationInstance[], playingAnimations: Set<LinearAnimationInstance>, stateMachines: StateMachineInstance[], playingStateMachines: Set<StateMachineInstance>, isActive: boolean);
    dispose(): void;
}
export declare enum PointerEvents {
    POINTER_DOWN = 0,
    POINTER_UP = 1,
    POINTER_MOVE = 2,
    POINTER_EXIT = 3
}
export type OnStartCallback = () => void;
export declare class RiveFileController extends RefCount implements Observable<RiveFileControllerListener> {
    loop: Loop;
    autoplay: boolean;
    file: File | null;
    isActive: boolean;
    onStart: OnStartCallback | null;
    targetBounds: Bounds | null;
    requireArtboardResize: boolean;
    constructor(loop?: Loop, autoplay?: boolean, file?: File | null, activeArtboard?: Artboard | null, rendererAttributes?: RendererAttributes | null, onStart?: OnStartCallback | null);
    set activeArtboard(value: Artboard | null);
    get activeArtboard(): Artboard | null;
    get layoutScaleFactor(): number | null;
    set layoutScaleFactor(value: number | null);
    get layoutScaleFactorAutomatic(): number;
    set layoutScaleFactorAutomatic(value: number);
    get layoutScaleFactorActive(): number;
    get animations(): LinearAnimationInstance[];
    get stateMachines(): StateMachineInstance[];
    get playingAnimations(): Set<LinearAnimationInstance>;
    get playingStateMachines(): Set<StateMachineInstance>;
    get pausedAnimations(): Set<LinearAnimationInstance>;
    get pausedStateMachines(): Set<StateMachineInstance>;
    get artboardBounds(): Bounds;
    get isAdvancing(): boolean;
    get isAnimating(): boolean;
    get fit(): Fit;
    set fit(value: Fit);
    get alignment(): Alignment;
    set alignment(value: Alignment);
    setRiveFile(file: File, artboardName?: string | null): void;
    selectArtboard(name?: string | null): void;
    setupScene(rendererAttributes: RendererAttributes): void;
    play(animationNameOrNames?: string | string[] | Loop | undefined, loopOrDirection?: Loop | Direction | boolean | undefined, directionOrIsStateMachine?: Direction | boolean | undefined, isStateMachineOrSettleInitialState?: boolean | undefined, settleInitialStateOverride?: boolean): void;
    pauseAllAnimations(): void;
    pauseAnimations(animationName: string, isStateMachine?: boolean): void;
    pauseMultipleAnimations(animationNames: string[], areStateMachines?: boolean): void;
    stopAllAnimations(): void;
    stopAnimations(animationName: string, isStateMachine?: boolean): void;
    stopMultipleAnimations(animationNames: string[], areStateMachines?: boolean): void;
    fireState(stateMachineName: string, inputName: string, path?: string | null): void;
    setBooleanState(stateMachineName: string, inputName: string, value: boolean, path?: string | null): void;
    setNumberState(stateMachineName: string, inputName: string, value: number, path?: string | null): void;
    fireStateAtPath(inputName: string, path: string): void;
    setBooleanStateAtPath(inputName: string, value: boolean, path: string): void;
    setNumberStateAtPath(inputName: string, value: number, path: string): void;
    queueInputs(...inputs: ChangedInput[]): void;
    getArtboard(): Artboard | null;
    getTextRunValue(textRunName: string, path?: string): string | null;
    setTextRunValue(textRunName: string, textValue: string, path?: string): void;
    getVolume(): number | null;
    setVolume(value: number): void;
    pointerEvent(eventType: PointerEvents, pointerID: number, x: number, y: number): void;
    advance(elapsed: number): void;
    getOrCreateStateMachines(animationName: string): StateMachineInstance[];
    reset(): void;
    registerListener(listener: RiveFileControllerListener): void;
    unregisterListener(listener: RiveFileControllerListener): void;
    addEventListener(listener: RiveEventListener): void;
    removeEventListener(listener: RiveEventListener): void;
    saveControllerState(): ControllerState | null;
    restoreControllerState(state: ControllerState): void;
}
```

## src/main/ets/runtime/core/AdvanceResult.d.ets

```typescript
export declare enum AdvanceResult {
    /** The animation advanced but did not loop or finish. */
    ADVANCED = 0,
    /** The animation reached its end in ONESHOT mode and stopped. */
    ONESHOT = 1,
    /** The animation looped back to the beginning in LOOP mode. */
    LOOP = 2,
    /** The animation reached an end and reversed direction in PINGPONG mode. */
    PINGPONG = 3,
    /** The animation was already finished and did not advance effectively. */
    NONE = 4
}
```

## src/main/ets/runtime/core/Alignment.d.ets

```typescript
export declare enum Alignment {
    TOP_LEFT = 0,
    TOP_CENTER = 1,
    TOP_RIGHT = 2,
    CENTER_LEFT = 3,
    CENTER = 4,
    CENTER_RIGHT = 5,
    BOTTOM_LEFT = 6,
    BOTTOM_CENTER = 7,
    BOTTOM_RIGHT = 8
}
export declare namespace Alignment {
    function fromIndex(index: number): Alignment;
}
```

## src/main/ets/runtime/core/Artboard.d.ets

```typescript
import rive from 'libohos_rive.so';
import { File } from './File';
import { NativeObject } from './NativeObject';
import { ViewModelInstance, Transfer } from './ViewModelInstance';
import { StateMachineInstance } from './StateMachineInstance';
import LinearAnimationInstance from './LinearAnimationInstance';
import { SMIInput } from './SMIInput';
import { RiveTextValueRun } from './RiveTextValueRun';
export declare class Artboard extends NativeObject {
    file: File;
    constructor(unsafeCppPointer: BigInt, file: File);
    protected cppDelete(pointer: BigInt): void;
    release(): number;
    /** Get the [name] of the Artboard. */
    get name(): string;
    /**
     * Get the first [animation][LinearAnimationInstance] of the [Artboard].
     *
     * If you use more than one animation, it is preferred to use the [animation] functions.
     *
     * @throws AnimationException if the animation does not exist.
     */
    get firstAnimation(): LinearAnimationInstance;
    /**
     * Get the animation at a given 0-based [index] in the [Artboard].
     *
     * @throws AnimationException If the animation does not exist.
     */
    animationIndex(index: number): LinearAnimationInstance;
    /**
     * Get the animation with a given [name] in the [Artboard].
     *
     * @throws AnimationException If the animation does not exist.
     */
    animation(name: string): LinearAnimationInstance;
    /**
     * Get the first [state machine][StateMachineInstance] of the artboard.
     *
     * If you use more than one animation, it is preferred to use the [stateMachine] functions.
     *
     * @throws StateMachineException If the state machine does not exist.
     */
    get firstStateMachine(): StateMachineInstance;
    /**
     * Get the state machine at a given 0-based [index] in the artboard.
     *
     * @throws StateMachineException If the state machine does not exist.
     */
    stateMachineIndex(index: number): StateMachineInstance;
    /**
     * Get the state machine with a given [name] in the artboard.
     *
     * @throws StateMachineException If the state machine does not exist.
     */
    stateMachine(name: string): StateMachineInstance;
    /**
     * Get the input instance with a given [name] on the nested artboard represented at [path].
     *
     * @throws StateMachineInputException If the input does not exist.
     */
    input(name: string, path: string): SMIInput;
    /**
     * Get a [RiveTextValueRun] with a given [name] in the artboard.
     *
     * @return The text value run.
     * @throws TextValueRunException If the text run does not exist.
     */
    textRunName(name: string): RiveTextValueRun;
    /**
     * Get the text value for a text run named [name].
     *
     * @return The text value of the run, or null if the run is not found.
     */
    getTextRunValueName(name: string): string;
    /**
     * Set the text value for a text run named [name] to [textValue].
     *
     * @throws TextValueRunException If the text run does not exist.
     */
    setTextRunValueName(name: string, textValue: string): void;
    /**
     * Get a [RiveTextValueRun] with a given [name] on the nested artboard represented at [path].
     *
     * @return The text value run.
     * @throws TextValueRunException If the text run does not exist.
     */
    textRunNameAndPath(name: string, path: string): RiveTextValueRun;
    /**
     * Get the text value for a text run named [name] on the nested artboard represented at [path].
     *
     * @return The text value of the run, or null if the run is not found.
     */
    getTextRunValueNameAndPath(name: string, path: string): string;
    /**
     * Set the text value for a text run named [name] to [textValue] on the nested artboard
     * represented at [path].
     *
     * @throws TextValueRunException If the text run does not exist.
     */
    setTextRunValueNameAndPath(name: string, textValue: string, path: string): void;
    /** Get and set the volume of the artboard. */
    get volume(): number;
    set volume(value: number);
    /** @return The number of animations stored inside the artboard. */
    get animationCount(): number;
    /** @return The number of state machines stored inside the artboard. */
    get stateMachineCount(): number;
    /**
     * The [ViewModelInstance] assigned to this artboard. Once assigned, modifications to the
     * properties of the instance will be reflected in the bindings of this artboard.
     *
     * Assigning null will do nothing.
     *
     * You should only use assign this property if your file does not contain a state machine. If it
     * does, prefer [StateMachineInstance.viewModelInstance] instead, as it will set the view model
     * for both the state machine and the artboard.
     */
    get viewModelInstance(): ViewModelInstance | null;
    set viewModelInstance(value: ViewModelInstance | null);
    /**
     * @throws ViewModelException If the instance contained by [transfer] has already been assigned
     *    or disposed.
     */
    receiveViewModelInstance(transfer: Transfer): ViewModelInstance;
    /**
     * Advancing the artboard:
     * - Updates the layout for all dirty components contained in the artboard
     * - Updates the positions
     * - Forces all components in the artboard to be laid out
     *
     * Components are all the shapes, bones and groups of an artboard. Whenever components are added
     * to an artboard, for example when an artboard is first loaded, they are considered dirty.
     * Whenever animations change properties of components, move a shape, or change a color, they
     * are marked as dirty.
     *
     * Before any changes to components will be visible in the next rendered frame, the artboard
     * needs to be [advanced][advance].
     *
     * [elapsedTime] is currently not taken into account.
     */
    advance(elapsedTime: number): boolean;
    /** Draw the the artboard to the [renderer][app.rive.runtime.kotlin.renderers.Renderer].
     *  fileAddress (optional): the owning File's cppPointer. The native layer refs it across the
     *  worker draw so a JS-thread File release can't free the shared Animations/StateMachines the
     *  ArtboardInstance dereferences during draw (use-after-free fix). Pass the File when known. */
    draw(rendererAddress: BigInt, fileAddress?: BigInt): void;
    /**
     * Draw the the artboard to the [renderer][app.rive.runtime.kotlin.renderers.Renderer]. Also
     * align the artboard to the render surface.
     * fileAddress (optional): see draw() — the owning File's cppPointer, ref'd across the worker draw.
     */
    drawFit(rendererAddress: BigInt, fit: rive.Fit, alignment: rive.Alignment, scaleFactor?: number, fileAddress?: BigInt): void;
    /** Reset the artboard size to its defaults. */
    resetArtboardSize(): void;
    /** @return The bounds of artboard as defined in the Rive Editor. */
    get bounds(): rive.Bounds;
    /** The width of the artboard. */
    get width(): number;
    set width(value: number);
    /** The height of the artboard. */
    get height(): number;
    set height(value: number);
    /** @return The names of all animations in the artboard. */
    get animationNames(): string[];
    /** @return The names of all stateMachines in the artboard. */
    get stateMachineNames(): string[];
    convertInput(input: SMIInput): SMIInput;
}
```

## src/main/ets/runtime/core/BindableArtboard.d.ets

```typescript
import { NativeObject } from './NativeObject';
export declare class BindableArtboard extends NativeObject {
    constructor(unsafeCppPointer: BigInt);
    protected cppDelete(pointer: BigInt): void;
    get name(): string;
}
```

## src/main/ets/runtime/core/Direction.d.ets

```typescript
export declare enum Direction {
    BACKWARDS = 0,
    FORWARDS = 1,
    AUTO = 2
}
export declare namespace Direction {
    function getValue(direction: Direction): number;
    function fromInt(value: number): Direction | undefined;
}
```

## src/main/ets/runtime/core/EventType.d.ets

```typescript
/** The type of Rive event. */
export declare enum EventType {
    OpenURLEvent = 131,
    GeneralEvent = 128
}
/**
 * Convert a numeric type code to EventType
 * @param type The numeric type code
 * @returns The corresponding EventType or GeneralEvent if not found
 */
export declare function EventTypeFromInt(type: number): EventType;
```

## src/main/ets/runtime/core/File.d.ets

```typescript
import rive from 'libohos_rive.so';
import { Artboard } from './Artboard';
import { BindableArtboard } from './BindableArtboard';
import { FileAssetLoader } from './FileAssetLoader';
import { NativeObject } from './NativeObject';
import { ViewModel } from './ViewModel';
import { LifecycleScope } from './LifecycleScope';
export declare class File extends NativeObject {
    readonly rendererType: rive.RendererType;
    /**
     * Lifetime token for this File's in-flight async asset loads. Cancelled exactly
     * once when this File is disposed (refs drop to 0). Asset loaders read
     * `scope.alive` before touching a native FileAsset so a late callback after the
     * File is freed skips the now-dangling native call instead of crashing.
     */
    readonly scope: LifecycleScope;
    constructor(bytes: ArrayBuffer, rendererType?: rive.RendererType, fileAssetLoader?: FileAssetLoader | null);
    protected cppArtboardByIndex(cppPointer: BigInt, index: number): BigInt;
    protected cppViewModelByName(cppPointer: BigInt, viewModelName: string): BigInt;
    protected cppDelete(pointer: BigInt): void;
    /** Get the first (i.e. the default) artboard in the file. */
    get firstArtboard(): Artboard;
    /**
     * Get the artboard called [name] in the file.
     *
     * If multiple [Artboard]s have the same [name] it will return the first match.
     */
    artboardByName(name: string): Artboard;
    /**
     * Get the artboard at a given [index] in the [File].
     *
     * This starts at 0.
     */
    artboard(index: number): Artboard;
    /**
     * Create a [BindableArtboard] by name. This is can then be bound to a
     * [ViewModelArtboardProperty].
     *
     * ⚠️ Important: The bindable artboard can outlive this [File] instance, but in order to do so
     * it has an extra reference count. You need to call [BindableArtboard.release] when you are
     * done with it, otherwise it will leak memory.
     *
     * @param name The name of the artboard in the Rive file to create.
     * @return A new [BindableArtboard] instance.
     * @throws ArtboardException If no artboard with the given name exists.
     */
    createBindableArtboardByName(name: String): BindableArtboard;
    /**
     * Create the default [BindableArtboard], as marked in the Rive file. This is can then be bound
     * to a [ViewModelArtboardProperty].
     *
     * ⚠️ Important: The bindable artboard can outlive this [File] instance, but in order to do so
     * it has an extra reference count. You need to call [BindableArtboard.release] when you are
     * done with it, otherwise it will leak memory.
     *
     * @return A new [BindableArtboard] instance.
     * @throws ArtboardException If no default artboard exists.
     */
    createDefaultBindableArtboard(): BindableArtboard;
    /** Get the number of artboards in the file. Useful for index-based iteration. */
    get artboardCount(): number;
    /** Get the names of the artboards in the file. */
    get artboardNames(): string[];
    /** The available [enums][Enum] in the file. */
    get enums(): Array<rive.RiveEnumItem>;
    /** The number of [ViewModel]s in the file. Useful for index-based iteration. */
    get viewModelCount(): number;
    /**
     * Get the [ViewModel] definition from the file.
     *
     * @param viewModelIdx The Rive file 0-based index of the ViewModel.
     * @return The [ViewModel] definition.
     * @throws ViewModelException If the ViewModel is not found.
     */
    getViewModelByIndex(viewModelIdx: number): ViewModel;
    /**
     * Get the [ViewModel] definition from the file.
     *
     * @param viewModelName The Rive file name of the ViewModel.
     * @return The [ViewModel] definition.
     * @throws ViewModelException If the ViewModel is not found.
     */
    getViewModelByName(viewModelName: string): ViewModel;
    /**
     * Get the default [ViewModel] for an [Artboard]. Usually this will be the ViewModel intended
     * for use with this artboard.
     *
     * @param artboard The artboard to get the default ViewModel for.
     * @return The default ViewModel for the artboard.
     * @throws ViewModelException If the default ViewModel is not found.
     */
    defaultViewModelForArtboard(artboard: Artboard): ViewModel;
    release(): number;
}
```

## src/main/ets/runtime/core/FileAsset.d.ets

```typescript
import image from '@ohos.multimedia.image';
import { RendererType } from '../renderers/RendererType';
import { NativeObject } from './NativeObject';
import { LifecycleScope } from './LifecycleScope';
export declare abstract class FileAsset extends NativeObject {
    protected constructor(address: BigInt, rendererTypeIdx: number);
    /**
     * Attach the owning File's lifetime scope. Called by {@link FileAssetLoader.bindScope}
     * when the asset is dispatched to `loadContents`, so async callbacks that capture
     * this wrapper can later detect the File has been disposed.
     * @internal
     */
    attachScope(scope: LifecycleScope): void;
    /**
     * If the owning File's scope has been cancelled, the native FileAsset this
     * wrapper points to has already been freed by the rive runtime — zero out the
     * pointer so {@link hasCppObject} returns false and native-call guards skip.
     * Safe no-op when no scope was ever attached (e.g. test-constructed assets).
     */
    protected invalidateIfStale(): void;
    /** Lazily fetched asset name. */
    get name(): string;
    /** Lazily fetched unique filename used for caching/loading. */
    get uniqueFilename(): string;
    /** Hosted asset CDN URL (empty when not hosted). */
    get cdnUrl(): string;
    /** Decode provided bytes into this asset using the configured renderer. */
    decode(bytes: Uint8Array): boolean;
}
/**
 * A thin Kotlin wrapper for the underlying C++ image asset. Helpful to distinguish between various
 * [FileAsset] subclasses.
 */
export declare class ImageAsset extends FileAsset {
    constructor(address: BigInt, rendererTypeIdx: number);
    /** The [RiveRenderImage] object associated with this [ImageAsset]. */
    set image(value: RiveRenderImage);
    /**
     * This isn't safe to use outside tests.
     *
     * @return A light wrapper around a C++ address.
     */
    get image(): RiveRenderImage;
    /** @return The width of the image in pixels. */
    get width(): number;
    /** @return The height of the image in pixels. */
    get height(): number;
}
/**
 * A thin Kotlin wrapper for the underlying C++ font asset. Helpful to distinguish between various
 * [FileAsset] subclasses.
 */
export declare class FontAsset extends FileAsset {
    constructor(address: BigInt, rendererTypeIdx: number);
    /** The [RiveFont] object associated with this [FontAsset]. */
    set font(value: RiveFont);
    /**
     * This isn't safe to use outside tests.
     *
     * @return A light wrapper around a C++ address.
     */
    get font(): RiveFont;
}
/**
 * A thin Kotlin wrapper for the underlying C++ audio asset. Helpful to distinguish between various
 * [FileAsset] subclasses.
 */
export declare class AudioAsset extends FileAsset {
    constructor(address: BigInt, rendererTypeIdx: number);
    /** The [RiveAudio] object associated with this [AudioAsset]. */
    set audio(value: RiveAudio);
    /**
     * This isn't safe to use outside tests.
     *
     * @return A light wrapper around a C++ address.
     */
    get audio(): RiveAudio;
}
/**
 * A wrapper around a native C++ object representing a raster image that can be rendered in Rive.
 *
 * Use the companion object methods to create one from encoded bytes, pixel bytes, ARGB integers, or
 * an [Android Bitmap][Bitmap].
 */
export declare class RiveRenderImage extends NativeObject {
    constructor(address: BigInt);
    protected cppDelete(pointer: BigInt): void;
    /**
     * @deprecated Kept for parity with Android. Use {@link fromEncoded}.
     */
    static make(bytes: Uint8Array, rendererType?: RendererType): RiveRenderImage;
    /**
     * Creates a {@link RiveRenderImage} by decoding the {@link encodedBytes}.
     *
     * The caller is in charge of the ownership of this {@link NativeObject}. It must be freed by
     * calling {@link release}.
     *
     * @param encodedBytes Encoded bytes for the image.
     * @param rendererType The renderer for this image. This must match the renderer for the
     *    RiveAnimationView using this.
     * @param premultiplied Whether the decoded image is premultiplied.
     * @return The constructed {@link RiveRenderImage}.
     */
    static fromEncoded(encodedBytes: Uint8Array, rendererType?: RendererType, premultiplied?: boolean): RiveRenderImage;
    /**
     * Creates a {@link RiveRenderImage} from RGBA8888 pixel bytes.
     *
     * The byte array must be exactly width * height * 4 bytes.
     *
     * The caller is in charge of the ownership of this {@link NativeObject}. It must be freed by
     * calling {@link release}.
     *
     * @param pixelBytes RGBA8888 pixel bytes.
     * @param width The width of the image in pixels.
     * @param height The height of the image in pixels.
     * @param rendererType The renderer for this image. This must match the renderer for the
     *    RiveAnimationView using this.
     * @param premultiplied Whether your RGB pixels are already multiplied by alpha. If false,
     *    the native layer will premultiply RGB by alpha for you. Defaults to true as Rive
     *    expects premultiplied input.
     * @return The constructed {@link RiveRenderImage}.
     */
    static fromRGBABytes(pixelBytes: Uint8Array, width: number, height: number, rendererType?: RendererType, premultiplied?: boolean): RiveRenderImage;
    /**
     * Creates a {@link RiveRenderImage} from ARGB8888 packed pixel integers.
     *
     * The int array must be exactly width * height elements.
     *
     * The caller is in charge of the ownership of this {@link NativeObject}. It must be freed by
     * calling {@link release}.
     *
     * @param pixels ARGB8888 packed pixel integers.
     * @param width The width of the image in pixels.
     * @param height The height of the image in pixels.
     * @param rendererType The renderer for this image. This must match the renderer for the
     *    RiveAnimationView using this.
     * @param premultiplied Whether your RGB pixels are already multiplied by alpha. If false
     *    (default), the native layer will premultiply RGB by alpha for you.
     * @return The constructed {@link RiveRenderImage}.
     */
    static fromARGBInts(pixels: Uint32Array, width: number, height: number, rendererType?: RendererType, premultiplied?: boolean): RiveRenderImage;
    /**
     * Creates a {@link RiveRenderImage} from a {@link image.PixelMap}.
     *
     * The caller is in charge of the ownership of this {@link NativeObject}. It must be freed by
     * calling {@link release}.
     *
     * @param pixelMap The source PixelMap.
     * @param rendererType The renderer for this image. This must match the renderer for the
     *    RiveAnimationView using this.
     * @param premultiplied Whether the pixel data is premultiplied.
     * @return The constructed {@link RiveRenderImage}.
     */
    static fromPixelMap(pixelMap: image.PixelMap, rendererType?: RendererType, premultiplied?: boolean): RiveRenderImage;
}
/**
 * Wrapper around native Rive fonts.
 */
export declare class RiveFont extends NativeObject {
    constructor(address: BigInt);
    protected cppDelete(pointer: BigInt): void;
    /**
     * Creates a {@link RiveFont} by decoding {@link bytes}.
     *
     * The caller is in charge of the ownership of this {@link NativeObject}. It must be freed by
     * calling {@link release}.
     *
     * @param bytes Encoded bytes for a font.
     * @param rendererType The renderer decoding this font. This needs to match the renderer for
     *    the View using this.
     * @return The constructed {@link RiveFont} object.
     */
    static make(bytes: Uint8Array, rendererType?: RendererType): RiveFont;
}
/**
 * A wrapper around a native C++ object representing an audio clip that can be played in Rive.
 *
 * Use the companion object method to create one from encoded bytes.
 */
export declare class RiveAudio extends NativeObject {
    constructor(address: BigInt);
    protected cppDelete(pointer: BigInt): void;
    /**
     * Creates a [RiveAudio] by decoding [bytes].
     *
     * The caller is in charge of the ownership of this [NativeObject]. It must be freed by
     * calling [release].
     *
     * @param bytes Encoded bytes for an audio file.
     * @param rendererType The renderer decoding this object. This needs to match the renderer
     *    for the View using this.
     * @return The constructed [RiveAudio] object.
     */
    static make(bytes: Uint8Array, rendererType?: RendererType): RiveAudio;
}
```

## src/main/ets/runtime/core/FileAssetLoader.d.ets

```typescript
import { RendererType } from '../renderers/RendererType';
import { FileAsset } from './FileAsset';
import { NativeObject } from './NativeObject';
import { LifecycleScope } from './LifecycleScope';
/**
 * Base class for asset loading. Overload loadContents to customize the loading process.
 *
 *  - Allows choosing how assets (images, fonts, audio) are loaded when referenced by a Rive file.
 *  - Asset loaders are typed to a specific {@link RendererType} because images are renderer specific.
 *  - The loader creates {@link FileAsset}s, so it must share renderer details with C++.
 */
export declare abstract class FileAssetLoader extends NativeObject {
    protected rendererType: RendererType | null;
    protected constructor();
    /**
     * Attaches the importing File's lifetime scope. Called by {@link File} immediately
     * before the native import so that `loadContents` reads the correct scope.
     */
    attachScope(scope: LifecycleScope): void;
    /** The File lifetime currently associated with this loader (null before first import). */
    get currentScope(): LifecycleScope | null;
    /**
     * Captures the importing File's lifetime scope as an alive-check closure. Async
     * loaders MUST call this at `loadContents` entry and consult the returned closure
     * before `asset.decode()` in their completion callback.
     *
     * Reading `currentScope`/`isReleased` at *callback* time is incorrect: a later
     * import reuses the loader and `attachScope` overwrites the current scope, so a late
     * callback from an earlier (already-disposed) File would observe the NEW scope still
     * alive and decode a freed native FileAsset (SIGSEGV). Capturing at entry binds the
     * check to THIS import's File scope. Returns `true` while the scope is alive (or when
     * no scope was ever attached — matching the historical fall-through behavior).
     */
    protected captureScopeAlive(): () => boolean;
    /**
     * Attach the importing File's lifetime scope to a dispatched {@link FileAsset}.
     * Loaders that retain the asset beyond `loadContents` (e.g. a custom loader
     * caching assets for later background download) MUST call this on the asset at
     * `loadContents` entry. The asset then self-invalidates its native pointer once
     * the File is disposed (scope cancelled), so a late callback writing to the
     * asset after teardown/swap skips native instead of SIGSEGV (the native
     * FileAsset is freed by the rive runtime with the File, not tracked by the JS
     * wrapper's ref count — `hasCppObject` alone can't detect it). No-op when no
     * scope is attached (matches fall-through behavior for test-constructed assets).
     */
    protected bindScope(asset: FileAsset): void;
    /**
     * @deprecated since R3. Prefer reading {@link currentScope} and checking
     * `scope.alive`. Kept for view-teardown call sites; cancels the attached scope
     * (if any) so in-flight async loads void their native decode.
     */
    markReleased(): void;
    /**
     * @deprecated since R3. Returns whether the attached scope (if any) is cancelled.
     * New code should read {@link currentScope} directly.
     */
    get isReleased(): boolean;
    protected constructorCpp(): BigInt;
    protected cppDelete(pointer: BigInt): void;
    protected cppRef(pointer: BigInt): void;
    /**
     * Override this to customize how assets are loaded.
     * @param asset The {@link FileAsset} being loaded.
     * @param inBandBytes Bytes embedded inside the Rive file (empty when asset is referenced/hosted).
     * @returns true if the asset was loaded, false if the loader refused the asset.
     */
    abstract loadContents(asset: FileAsset, inBandBytes: Uint8Array): boolean;
    setRendererType(rendererType: RendererType): void;
    getRendererType(): RendererType | null;
    acquire(): number;
    getNativePtr(): BigInt;
}
/**
 * Asset loader with access to a Context-like object (for reflection-style instantiation).
 */
export declare abstract class ContextAssetLoader extends FileAssetLoader {
    protected readonly context: Context;
    protected constructor(context: Context);
}
/**
 * Default loader used when cascading multiple loaders (memory cache, local storage, network, etc.).
 */
export declare class FallbackAssetLoader extends FileAssetLoader {
    protected readonly loaders: FileAssetLoader[];
    constructor(context: Context | null, loadCDNAssets?: boolean, loader?: FileAssetLoader | null);
    appendLoader(loader: FileAssetLoader): void;
    prependLoader(loader: FileAssetLoader): void;
    protected cppDelete(pointer: BigInt): void;
    loadContents(asset: FileAsset, inBandBytes: Uint8Array): boolean;
    setRendererType(rendererType: RendererType): void;
    markReleased(): void;
}
/**
 * Loads assets from Rive's CDN when marked as "Hosted" in the editor.
 */
export declare class CDNAssetLoader extends ContextAssetLoader {
    constructor(context: Context);
    loadContents(asset: FileAsset, inBandBytes: Uint8Array): boolean;
}
```

## src/main/ets/runtime/core/Fit.d.ets

```typescript
export declare enum Fit {
    NONE = 0,
    FILL = 1,
    CONTAIN = 2,
    COVER = 3,
    FIT_WIDTH = 4,
    FIT_HEIGHT = 5,
    SCALE_DOWN = 6,
    LAYOUT = 7
}
export declare namespace Fit {
    /**
     * Returns the [Fit] associated to [index].
     *
     * @throws RangeError If the index is out of bounds.
     */
    function fromIndex(index: number): Fit;
    /**
     * Returns the [Fit] associated to the given string.
     * Defaults to [Fit.CONTAIN] if the string doesn't match any known fit type.
     */
    function fromString(fitString: string): Fit;
}
```

## src/main/ets/runtime/core/Helpers.d.ets

```typescript
import { Fit } from './Fit';
import { Alignment } from './Alignment';
export declare class PointF {
    x: number;
    y: number;
    constructor(x?: number, y?: number);
}
/**
 * Axis-aligned rectangle expressed as edges. Mirrors {@link rive.Bounds} but is a
 * plain, allocation-light interface used by the controller/view for surface/artboard
 * sizing. Kept here alongside the other geometry primitives ({@link PointF}/{@link RectF}).
 */
export interface Bounds {
    left: number;
    top: number;
    right: number;
    bottom: number;
}
export declare class RectF {
    left: number;
    top: number;
    right: number;
    bottom: number;
    constructor(left?: number, top?: number, right?: number, bottom?: number);
}
export declare class Helpers {
    static convertToArtboardSpace(touchBounds: RectF, touchLocation: PointF, fit: Fit, alignment: Alignment, artboardBounds: RectF, scaleFactor?: number): PointF;
}
```

## src/main/ets/runtime/core/ImageDecoder.d.ets

```typescript
interface ImageInfo {
    width: number;
    height: number;
}
export declare class ImageDecoder {
    static decodeToBitmap(encoded: Uint8Array): Uint8Array;
    static isValidImageData(data: Uint8Array): boolean;
    static getImageInfo(encoded: Uint8Array): ImageInfo | null;
}
export {};
```

## src/main/ets/runtime/core/LinearAnimationInstance.d.ets

```typescript
import { Loop } from './Loop';
import { NativeObject } from './NativeObject';
import { Direction } from './Direction';
import { AdvanceResult } from './AdvanceResult';
import { PlayableInstance } from './PlayableInstance';
export default class LinearAnimationInstance extends NativeObject implements PlayableInstance {
    name: string;
    constructor(unsafeCppPointer: BigInt, mix?: number);
    protected cppDelete(pointer: BigInt): void;
    /**
     * Advance the animation.
     *
     * @param elapsedTime The time in seconds to advance by.
     * @return The [Loop] type associated with the current animation if this advance caused a loop,
     *    otherwise null.
     */
    advance(elapsedTime: number): Loop | null;
    /**
     * Advance the animation and return the result.
     *
     * @param elapsedTime The time in seconds to advance by.
     * @return An [AdvanceResult] enum value indicating the outcome of the advance step
     */
    advanceAndGetResult(elapsedTime: number): AdvanceResult;
    /**
     * Applies the animation instance's current set of transformations to an [Artboard].
     *
     * Uses the [mix] property (a value between 0 and 1) to set the strength at which the animation
     * is mixed with other animations applied to the [Artboard].
     */
    apply(): void;
    /**
     * Applies and advances the animation instance in a single step.
     *
     * @return `true` if the animation will continue to animate after this advance.
     */
    applyAndAdvance(elapsed: number): boolean;
    /** The elapsed time that this instance has played to. */
    gettime(): number;
    /** Seeks the animation to [time]. */
    settime(time: number): void;
    /**
     * Configure the animation to play [forwards][Direction.FORWARDS] or
     * [backwards][Direction.BACKWARDS].
     */
    getdirection(): Direction;
    setdirection(value: Direction): void;
    /**
     * The duration of an animation in frames. This does not take [workStart] and [workEnd] into
     * account.
     */
    getduration(): number;
    /** The duration of this animation in frames, taking [workStart] and [workEnd] into account. */
    geteffectiveDuration(): number;
    /** The duration of an animation in seconds, taking [workStart] and [workEnd] into account. */
    geteffectiveDurationInSeconds(): number;
    /** Return the frames per second (FPS) configured for this animation. */
    getfps(): number;
    /**
     * The offset in frames to the beginning of an animations work area. Animations will start
     * playing from here.
     */
    getworkStart(): number;
    /**
     * The offset in frames to the end of an animations work area. Animations will execute their
     * loop behavior once this is reached.
     */
    getworkEnd(): number;
    /** The name given to this animation. */
    getname(): string;
    /**
     * The offset in seconds to the beginning of the animation. Animations will start playing from
     * here.
     */
    getstartTime(): number;
    /** The offset in seconds to the end of the animation. */
    getendTime(): number;
    /**
     * Configure the [Loop] mode for this animation. Can be either [Loop.LOOP], [Loop.ONESHOT],
     * [Loop.PINGPONG] or [Loop.AUTO].
     */
    getloop(): Loop;
    setloop(value: Loop): void;
}
```

## src/main/ets/runtime/core/Loop.d.ets

```typescript
export declare enum Loop {
    ONESHOT = 0,
    LOOP = 1,
    PINGPONG = 2,
    AUTO = 3
}
export declare class LoopUtils {
    /**
     * Returns the Loop associated to index.
     *
     * @throws Error If the index is out of bounds.
     */
    static fromIndex(index: number): Loop;
}
```

## src/main/ets/runtime/core/PlayableInstance.d.ets

```typescript
export interface PlayableInstance {
    name: string;
}
```

## src/main/ets/runtime/core/Rive.d.ets

```typescript
import { RendererType } from '../renderers/RendererType';
import { Alignment } from './Alignment';
import { Fit } from './Fit';
import { FontOpts } from '../fonts/FontHelpers';
interface Bounds {
    left: number;
    top: number;
    right: number;
    bottom: number;
}
declare class RectF {
    left: number;
    top: number;
    right: number;
    bottom: number;
    constructor(left?: number, top?: number, right?: number, bottom?: number);
    get width(): number;
    get height(): number;
    set(width: number, height: number): void;
}
export declare class RiveManager {
    static getInstance(): RiveManager;
    init(context: Context, defaultRenderer?: RendererType): void;
    initializeCppEnvironment(): void;
    /**
     * Calculate the required bounding rectangle
     *
     * This function calls the underlying C++ interface to compute the actual required bounding rectangle
     * based on fit mode, alignment, available bounds, and artboard bounds.
     *
     * @param fit The fit mode that determines how to scale content to fit the available space
     * @param alignment The alignment method that determines where content is positioned within the available space
     * @param availableBounds The available bounds that define the usable display area
     * @param artboardBounds The artboard bounds that define the original content boundaries
     * @param scaleFactor The scaling factor used to adjust the final scale ratio
     * @returns The computed required bounding rectangle
     */
    calculateRequiredBounds1(fit: Fit, alignment: Alignment, availableBounds: Bounds, artboardBounds: Bounds, scaleFactor: number): RectF;
    /**
     * Set a fallback font for the Rive runtime.
     *
     * @param byteArray The [Uint8Array] bytes for a font file.
     * @param opts The [FontOpts] specifying the desired font characteristics. If not
     *    provided, default options are used.
     * @return Whether the font was successfully registered.
     */
    setFallbackFont(context: Context, byteArray?: Uint8Array, opts?: FontOpts): boolean;
}
export {};
```

## src/main/ets/runtime/core/RiveEvent.d.ets

```typescript
import { NativeObject } from './NativeObject';
import { EventType } from './EventType';
/**
 * A class for Rive events.
 *
 * @param unsafeCppPointer Pointer to the C++ counterpart.
 * @see RiveOpenURLEvent
 * @see RiveGeneralEvent
 */
export declare class RiveEvent extends NativeObject {
    readonly delay: number;
    readonly riveEventCppPointer: BigInt;
    constructor(unsafeCppPointer: BigInt, delay: number);
    /** Name of the event. */
    get name(): string;
    /** Type of event. */
    get type(): EventType;
    /** Properties of the event. */
    get properties(): object;
    /** Data of the event. */
    get data(): Record<string, ESObject>;
    toString(): string;
}
```

## src/main/ets/runtime/core/RiveEventReport.d.ets

```typescript
import { NativeObject } from './NativeObject';
import { RiveEvent } from './RiveEvent';
/**
 * A class for reported Rive events to match its C++ counterpart.
 *
 * @param unsafeCppPointer Pointer to the C++ counterpart.
 */
export declare class RiveEventReport extends NativeObject {
    constructor(unsafeCppPointer: BigInt, secondsDelay: number);
    get event(): RiveEvent;
}
```

## src/main/ets/runtime/core/RiveGeneralEvent.d.ets

```typescript
import { RiveEvent } from './RiveEvent';
/**
 * A general Rive event.
 *
 * @param unsafeCppPointer Pointer to the C++ counterpart.
 * @see RiveOpenURLEvent
 */
export declare class RiveGeneralEvent extends RiveEvent {
    constructor(unsafeCppPointer: BigInt, delay: number);
    toString(): string;
}
```

## src/main/ets/runtime/core/RiveOpenURLEvent.d.ets

```typescript
import { RiveEvent } from './RiveEvent';
/**
 * An open URL Rive event.
 *
 * @param unsafeCppPointer Pointer to the C++ counterpart.
 * @see RiveGeneralEvent
 */
export declare class RiveOpenURLEvent extends RiveEvent {
    constructor(unsafeCppPointer: BigInt, delay: number);
    /** The URL of the event. */
    get url(): string;
    /** The target of the event. */
    get target(): string;
    toString(): string;
}
```

## src/main/ets/runtime/core/RiveTextValueRun.d.ets

```typescript
import { NativeObject } from './NativeObject';
/**
 * A class for text run instances.
 *
 * These instances allow modification of Rive text runs.
 *
 * @param unsafeCppPointer Pointer to the C++ counterpart.
 */
export declare class RiveTextValueRun extends NativeObject {
    constructor(unsafeCppPointer: BigInt);
    get text(): string;
    set text(value: string);
    toString(): string;
}
```

## src/main/ets/runtime/core/SMIBoolean.d.ets

```typescript
import { SMIInput } from './SMIInput';
/** A boolean state machine input. */
export declare class SMIBoolean extends SMIInput {
    constructor(unsafeCppPointer: BigInt);
    get value(): boolean;
    set value(newValue: boolean);
    toString(): string;
}
```

## src/main/ets/runtime/core/SMIInput.d.ets

```typescript
import { NativeObject } from './NativeObject';
/**
 * [SMIInput]s are a base class for state machine input instances.
 *
 * These instances allow modification of the state of the attached state machine.
 *
 * @param unsafeCppPointer Pointer to the C++ counterpart.
 */
export declare class SMIInput extends NativeObject {
    constructor(unsafeCppPointer: BigInt);
    /** The input name. */
    get name(): string;
    /** Whether this input a boolean input. */
    get isBoolean(): boolean;
    /** Whether this input a trigger input. */
    get isTrigger(): boolean;
    /** Whether this input a number input. */
    get isNumber(): boolean;
    /**
     * SMIInput cpp objects are tied to the lifecycle of the StateMachineInstances in cpp
     * Therefore we do not have a cppDelete implementation
     */
    protected cppDelete(pointer: BigInt): void;
    toString(): string;
}
```

## src/main/ets/runtime/core/SMINumber.d.ets

```typescript
import { SMIInput } from './SMIInput';
/** A floating point number state machine input. */
export declare class SMINumber extends SMIInput {
    constructor(unsafeCppPointer: BigInt);
    get value(): number;
    set value(newValue: number);
    toString(): string;
}
```

## src/main/ets/runtime/core/SMITrigger.d.ets

```typescript
import { SMIInput } from './SMIInput';
/** A trigger state machines input. */
export declare class SMITrigger extends SMIInput {
    constructor(unsafeCppPointer: BigInt);
    /**
     * Fire the trigger.
     * This method is typically called internally by the controller.
     */
    fire(): void;
    toString(): string;
}
```

## src/main/ets/runtime/core/StateMachineInstance.d.ets

```typescript
import { NativeObject } from './NativeObject';
import { ViewModelInstance, Transfer } from './ViewModelInstance';
import { PlayableInstance } from './PlayableInstance';
import { SMIInput } from './SMIInput';
import LayerState from './LayerState';
import { RiveEvent } from './RiveEvent';
/**
 * The [StateMachineInstance] is a helper to wrap common operations to play a state machine.
 *
 * This object has a counterpart in C++, which implements a lot of functionality. The
 * [unsafeCppPointer] keeps track of this relationship.
 *
 * Use this to keep track of a state machine's current state and progress, and to help [apply]
 * changes that the state machine makes to components in an [Artboard].
 */
export declare class StateMachineInstance extends NativeObject implements PlayableInstance {
    constructor(unsafeCppPointer: BigInt);
    /** @return The name of state machine. */
    get name(): string;
    /** @return The number of layers configured for the state machine. */
    get layerCount(): number;
    /**
     * The [ViewModelInstance] assigned to this artboard. Once assigned, modifications to the
     * properties of the instance will be reflected in the bindings of this state machine.
     *
     * Assigning will apply to both the [StateMachineInstance] and the parent [Artboard]. Assigning
     * null will do nothing.
     */
    get viewModelInstance(): ViewModelInstance | null;
    set viewModelInstance(value: ViewModelInstance | null);
    /**
     * @throws Error If the instance contained by [transfer] has already been assigned or disposed.
     * Note: ViewModelInstance.Transfer is not yet implemented in ETS version
     */
    receiveViewModelInstance(transfer: Transfer): ViewModelInstance;
    /**
     * Advance the state machine.
     *
     * @param elapsed The time in seconds to advance by.
     * @return `true` if the state machine will continue to animate after this advance.
     */
    advance(elapsed: number): boolean;
    pointerDown(pointerID: number, x: number, y: number): void;
    pointerUp(pointerID: number, x: number, y: number): void;
    pointerMove(pointerID: number, x: number, y: number): void;
    pointerExit(pointerID: number, x: number, y: number): void;
    /** @return The number of inputs configured for the state machine. */
    get inputCount(): number;
    /** @return The number of states changed in the last advance. */
    /** @return The number of events fired in the last advance. */
    /**
     * Get the input instance at a given [index] in the state machine.
     *
     * This starts at 0.
     *
     * @throws Error If no [SMIInput] is found at the given [index].
     */
    input(index: number): SMIInput;
    /**
     * Get the input with a given [name] in the state machine.
     *
     * @throws Error If no [SMIInput] is found with the given [name].
     */
    inputByName(name: string): SMIInput;
    /** @return All inputs in the state machine. */
    get inputs(): SMIInput[];
    /** @return The names of all inputs in the state machine. */
    get inputNames(): string[];
    /**
     * Get a specific state changed in the last advance.
     *
     * @param index The index of the state.
     * @throws Error If no [LayerState] is found at the given [index].
     */
    stateChanged(index: number): LayerState;
    /**
     * Get a specific event fired in the last advance.
     *
     * @param index The index of the event.
     * @throws Error If no event is found at the given [index].
     */
    eventAt(index: number): RiveEvent;
    /** @return All layer states changed in the last advance. */
    get statesChanged(): LayerState[];
    /** @return All events fired in the last advance. */
    get eventsReported(): RiveEvent[];
    protected cppDelete(pointer: BigInt): void;
}
```

## src/main/ets/runtime/core/ViewModel.d.ets

```typescript
import { ViewModelInstance } from './ViewModelInstance';
import { NativeObject } from './NativeObject';
export declare class ViewModel extends NativeObject {
    constructor(unsafeCppPointer: BigInt);
    get name(): string;
    /** The number of instances of this ViewModel. Useful for index-based iteration. */
    get instanceCount(): number;
    /** The number of properties in this ViewModel. */
    get propertyCount(): number;
    /** The available properties of the ViewModel. */
    get properties(): PropertyData[];
    /**
     * Create a new blank ViewModelInstance. Use Artboard::setViewModel to apply it. The instance
     * name will be an empty string.
     *
     * Property values will be defaulted:
     * - Numbers will be 0
     * - Strings will be empty
     * - Booleans will be false
     * - Colors will be ARGB(0xFF, 0, 0, 0)
     * - Enums will be their first value
     *
     * Useful when you want to supply all property values yourself.
     *
     * @return A new instance of the ViewModel with initial values defaulted.
     * @throws ViewModelException If a blank instance cannot be created.
     */
    createBlankInstance(): ViewModelInstance;
    /**
     * Create a new ViewModelInstance. Use Artboard::setViewModel to apply it.
     *
     * Property values will be those of the instance marked as "Default" in the Rive editor.
     *
     * @return A new instance of the ViewModel with initial values supplied by the default instance.
     * @throws ViewModelException If the default instance cannot be created.
     */
    createDefaultInstance(): ViewModelInstance;
    /**
     * Create a new ViewModelInstance. Use Artboard::setViewModel to apply it.
     *
     * Useful when the Rive file has a set of default property values that you want to initialize
     * with.
     *
     * @param index Rive file 0-based index for this instance.
     * @return A new instance of the ViewModel with initial values supplied by the indexed instance.
     * @throws ViewModelException If the instance is not found.
     */
    createInstanceFromIndex(index: number): ViewModelInstance;
    /**
     * Create a new ViewModelInstance. Use Artboard::setViewModel to apply it.
     *
     * Useful when the Rive file has a set of default property values that you want to initialize
     * with.
     *
     * @param name Rive file name for this instance.
     * @return A new instance of the ViewModel with initial values supplied by the named instance.
     * @throws ViewModelException If the instance is not found.
     */
    createInstanceFromName(name: string): ViewModelInstance;
}
/**
 * A description of a property in the ViewModel.
 *
 * These can't be used to get or set the value of the property. For that, you will need a
 * ViewModelInstance and use its methods.
 */
export declare class PropertyData {
    readonly type: PropertyDataType;
    readonly name: string;
    constructor(type: PropertyDataType, name: string);
}
export declare enum PropertyDataType {
    NONE = 0,
    STRING = 1,
    NUMBER = 2,
    BOOLEAN = 3,
    COLOR = 4,
    LIST = 5,
    ENUM = 6,
    TRIGGER = 7,
    VIEW_MODEL = 8,
    INTEGER = 9,
    SYMBOL_LIST_INDEX = 10,
    ASSET_IMAGE = 11,
    ARTBOARD = 12
}
export declare class PropertyDataUtils {
    /**
     * Returns the PropertyDataType associated to index.
     *
     * @throws Error If the index is out of bounds.
     */
    static fromIndex(index: number): PropertyDataType;
}
```

## src/main/ets/runtime/core/ViewModelInstance.d.ets

```typescript
import { NativeObject } from './NativeObject';
import { Artboard } from './Artboard';
import { BindableArtboard } from './BindableArtboard';
import { RiveRenderImage } from './FileAsset';
export declare class ViewModelInstance extends NativeObject {
    ViewModelInstanceCppPointer: BigInt;
    constructor(unsafeCppPointer: BigInt);
    protected properties: Map<string, ViewModelNumberProperty | ViewModelStringProperty | ViewModelBooleanProperty | ViewModelColorProperty | ViewModelEnumProperty | ViewModelTriggerProperty | ViewModelImageProperty | ViewModelListProperty | ViewModelArtboardProperty>;
    protected children: Map<string, ViewModelInstance>;
    protected cppDelete(pointer: BigInt): void;
    get name(): string;
    pollChanges(): void;
    getNativePointer(): BigInt;
    transfer(): Transfer;
    getNumberProperty(path: string): ViewModelNumberProperty;
    getStringProperty(path: string): ViewModelStringProperty;
    getBooleanProperty(path: string): ViewModelBooleanProperty;
    getColorProperty(path: string): ViewModelColorProperty;
    getEnumProperty(path: string): ViewModelEnumProperty;
    getTriggerProperty(path: string): ViewModelTriggerProperty;
    getImageProperty(path: string): ViewModelImageProperty;
    getListProperty(path: string): ViewModelListProperty;
    getArtboardProperty(path: string): ViewModelArtboardProperty;
    getInstanceProperty(path: string): ViewModelInstance;
    setInstanceProperty(path: string, instance: ViewModelInstance): void;
}
export declare class Transfer {
    constructor(instance: ViewModelInstance);
    dispose(): void;
    end(): ViewModelInstance;
}
export declare abstract class ViewModelProperty<T> extends NativeObject {
    constructor(pointer: BigInt);
    get name(): string;
    get value(): T;
    set value(next: T);
    get valueFlow(): ValueSubject<T>;
    get isSubscribed(): boolean;
    pollChanges(): void;
    protected abstract nativeGetValue(): T;
    protected abstract nativeSetValue(value: T): void;
}
declare class ValueSubject<T> {
    constructor(current: T);
    get value(): T;
    set value(next: T);
    subscribe(listener: (value: T) => void): () => void;
    hasSubscribers(): boolean;
}
export declare class ViewModelNumberProperty extends ViewModelProperty<number> {
    protected nativeGetValue(): number;
    protected nativeSetValue(value: number): void;
}
export declare class ViewModelStringProperty extends ViewModelProperty<string> {
    protected nativeGetValue(): string;
    protected nativeSetValue(value: string): void;
}
export declare class ViewModelBooleanProperty extends ViewModelProperty<boolean> {
    protected nativeGetValue(): boolean;
    protected nativeSetValue(value: boolean): void;
}
export declare class ViewModelColorProperty extends ViewModelProperty<number> {
    protected nativeGetValue(): number;
    protected nativeSetValue(value: number): void;
}
export declare class ViewModelEnumProperty extends ViewModelProperty<string> {
    protected nativeGetValue(): string;
    protected nativeSetValue(value: string): void;
}
export declare class ViewModelTriggerUnit {
}
export declare class ViewModelTriggerProperty extends ViewModelProperty<ViewModelTriggerUnit> {
    protected nativeGetValue(): ViewModelTriggerUnit;
    protected nativeSetValue(_: ViewModelTriggerUnit): void;
    trigger(): void;
}
export declare class ViewModelImageProperty extends ViewModelProperty<void> {
    protected nativeGetValue(): void;
    protected nativeSetValue(_: void): void;
    set(image: RiveRenderImage | null): void;
}
export declare class ViewModelListProperty extends ViewModelProperty<void> {
    get(index: number): ViewModelInstance;
    protected nativeGetValue(): void;
    protected nativeSetValue(_: void): void;
    protected cppDelete(pointer: BigInt): void;
    get size(): number;
    elementAt(index: number): ViewModelInstance;
    add(item: ViewModelInstance): void;
    addAt(index: number, item: ViewModelInstance): void;
    remove(item: ViewModelInstance): void;
    removeAt(index: number): void;
    swap(index1: number, index2: number): void;
}
export declare class ViewModelArtboardProperty extends ViewModelProperty<void> {
    protected nativeGetValue(): void;
    protected nativeSetValue(_: void): void;
    setArtboard(artboard: Artboard): void;
    setBindableArtboard(bindableArtboard: BindableArtboard | null): void;
}
export {};
```

## src/main/ets/runtime/core/errors/AnimationException.d.ets

```typescript
import { RiveException } from './RiveException';
/**
 * Error thrown when an animation name is invalid or unavailable.
 */
export declare class AnimationException extends RiveException {
    constructor(message: string);
}
```

## src/main/ets/runtime/core/errors/ArtboardException.d.ets

```typescript
import { RiveException } from './RiveException';
/**
 * Error thrown when an artboard name is invalid or unavailable.
 */
export declare class ArtboardException extends RiveException {
    constructor(message: string);
}
```

## src/main/ets/runtime/core/errors/MalformedFileException.d.ets

```typescript
import { RiveException } from './RiveException';
/**
 * Error thrown when file data is malformed or unsupported.
 */
export declare class MalformedFileException extends RiveException {
    constructor(message: string);
}
```

## src/main/ets/runtime/core/errors/RiveException.d.ets

```typescript
export declare class RiveException extends Error {
    constructor(message: string);
}
```

## src/main/ets/runtime/core/errors/StateMachineException.d.ets

```typescript
import { RiveException } from './RiveException';
/**
 * Error thrown when a state machine name is invalid or unavailable.
 */
export declare class StateMachineException extends RiveException {
    constructor(message: string);
}
```

## src/main/ets/runtime/core/errors/StateMachineInputException.d.ets

```typescript
import { RiveException } from './RiveException';
/**
 * Error thrown when a state machine input name is invalid.
 */
export declare class StateMachineInputException extends RiveException {
    constructor(message: string);
}
```

## src/main/ets/runtime/core/errors/TextValueRunException.d.ets

```typescript
import { RiveException } from './RiveException';
/**
 * Error thrown when a text value run is invalid or unavailable.
 */
export declare class TextValueRunException extends RiveException {
    constructor(message: string);
}
```

## src/main/ets/runtime/core/errors/UnsupportedRuntimeVersionException.d.ets

```typescript
import { RiveException } from './RiveException';
/**
 * Error thrown when the current file does not support this runtime version.
 */
export declare class UnsupportedRuntimeVersionException extends RiveException {
    constructor(message: string);
}
```

## src/main/ets/runtime/core/errors/ViewModelException.d.ets

```typescript
import { RiveException } from './RiveException';
/**
 * Error thrown when working with a ViewModel or ViewModelInstance fails.
 */
export declare class ViewModelException extends RiveException {
    constructor(message: string);
}
```

## src/main/ets/runtime/fonts/FontFallbackStrategy.d.ets

```typescript
import { Weight } from './FontHelpers';
/**
 * 字体字节数组类型别名
 */
export type FontBytes = Uint8Array;
/**
 * 定义一种策略，用于在 Rive 文件中找不到字符或未提供字体时，
 * 提供具有特定字重的回退字体。
 *
 * 此接口允许基于指定的字重提供不同回退字体集的自定义实现。
 *
 * ## 实现策略：
 * - **在给定作用域内**：可以在组件中实现策略
 * - **在全局级别**：可以在加载需要回退字体的 Rive 文件之前全局设置回退策略
 *
 * `stylePicker` 使用弱引用管理，允许垃圾回收器自动清理未使用的 `FontFallbackStrategy` 引用。
 * 一旦引用的对象被垃圾回收，弱引用将返回 `null`，确保内存得到有效管理和释放。
 *
 * ## 用法
 * - 实现 `getFont()` 以返回指定字重的 `FontBytes` 列表。
 * - 使用静态属性 `stylePicker` 管理回退策略。
 * - `pickFont()` 从原生 C++ 代码静态调用，当检测到缺失字符时提供回退字体。
 */
export declare abstract class FontFallbackStrategy {
    /**
     * 返回一个 `FontBytes`（即 `Uint8Array`）列表，表示运行时将用于尝试匹配
     * Rive 文件中缺失字符的字体。
     *
     * 运行时按先进先出（FIFO）顺序尝试匹配字符，从索引 0 的字体开始，然后继续到索引 1，依此类推，
     * 直到找到包含所需字符的字体或列表耗尽。
     *
     * **缓存行为：** 此函数仅在运行时的内部原生缓存不包含请求的 `weight` 的回退字体数据时
     * 由 Rive 运行时调用。返回的 `FontBytes` 列表会立即解码为原生字体表示并缓存在内部，
     * 以 `weight` 为键。对*相同字重*的后续请求将使用此缓存，并且此函数**不会再次为该字重调用**。
     * 与特定 [FontFallbackStrategy] 实例关联的原生缓存仅在为 Rive 运行时配置*新*策略实例时清除
     * （即通过设置新的 [stylePicker] 或等效配置）。您的实现应在初始调用期间返回请求的 `weight`
     * 的完整有序回退字体列表，因为它代表该字重类别在该策略实例处于活动状态时的确定集合。
     *
     * @param weight 需要回退的字体的字重。
     * @return 用于字符回退的字体字节数组列表，按优先级排序。
     */
    abstract getFont(weight: Weight): FontBytes[];
    /**
     * 获取或设置当前的字体回退策略
     */
    static get stylePicker(): FontFallbackStrategy | null;
    static set stylePicker(value: FontFallbackStrategy | null);
    /**
     * 重置字体缓存（从原生代码调用）
     */
    /**
     * 从原生 C++ 代码静态调用以获取字体
     * @param uWeight 字重的整数值
     * @return 字体字节数组列表
     */
    static pickFont(uWeight: number): FontBytes[];
}
```

## src/main/ets/runtime/fonts/FontHelpers.d.ets

```typescript
import { Context } from "@ohos.abilityAccessCtrl";
/**
 * 字体样式常量
 */
export declare const FONT_STYLE_NORMAL: string;
export declare const FONT_STYLE_ITALIC: string;
/**
 * 字体类
 */
export declare class Font {
    weight: Weight;
    style: string;
    name: string;
    axis: Axis[] | null;
    ttcIndex: number;
    postScriptName: string | null;
    fallbackFor: string | null;
    constructor(weight: Weight, style: string, name: string, axis?: Axis[] | null, ttcIndex?: number, postScriptName?: string | null, fallbackFor?: string | null);
}
/**
 * 字体轴类（用于可变字体）
 */
export declare class Axis {
    tag: string;
    styleValue: string;
    constructor(tag: string, styleValue: string);
}
/**
 * 字体族类
 */
export declare class Family {
    name: string | null;
    variant: string | null;
    lang: string | null;
    fonts: Map<Weight, Font[]>;
    constructor(fonts: Map<Weight, Font[]>, name?: string | null, variant?: string | null, lang?: string | null);
}
/**
 * 字体别名类
 */
export declare class Alias {
    name: string;
    original: string;
    weight: Weight | null;
    constructor(name: string, original: string, weight?: Weight | null);
}
/**
 * 字重类
 */
export declare class Weight {
    weight: number;
    static readonly NORMAL: Weight;
    static readonly BOLD: Weight;
    constructor(weight?: number);
    static fromString(stringValue: string | null | undefined): Weight;
    static fromInt(intValue?: number): Weight;
    compareTo(other: Weight): number;
}
/**
 * 字体选项类
 */
export declare class FontOpts {
    familyName: string | null;
    lang: string | null;
    weight: Weight | null;
    style: string | null;
    /**
     * 默认配置，用于一般用途
     */
    static readonly DEFAULT: FontOpts;
    constructor(familyName?: string | null, lang?: string | null, weight?: Weight | null, style?: string | null);
}
/**
 * 文件字体类
 */
export declare class FileFont {
    name: string;
    variant: string | null;
    lang: string | null;
    constructor(name: string, variant?: string | null, lang?: string | null);
}
/**
 * 字体辅助类
 */
export declare class FontHelper {
    /**
     * 获取所有可用系统字体的映射。
     *
     * **已弃用**：使用 [getSystemFontList] 代替，以便更可靠地处理未命名字体族。
     * 当多个未命名族具有相同文件名的第一个字体时，此方法可能会丢失数据。
     *
     * @return 表示所有可用字体族的 [Map]<String, Family>，如果未找到有效 XML 则返回空映射。
     * @deprecated Use getSystemFontList() instead. Map approach can lose unnamed
     *   families with colliding first font names.
     */
    static getSystemFonts(context: Context): Map<string, Family>;
    /**
     * 获取所有可用系统字体的列表。
     *
     * 这是访问系统字体的首选方法，因为它保留了所有字体族，包括可能具有相同第一个字体文件名的多个未命名族。
     * 基于 Map 的方法（[getSystemFonts]）可能由于键冲突而丢失数据。
     *
     * @return 表示所有可用字体族的 [List]<Family>，如果未找到有效 XML 则返回空列表。
     */
    static getSystemFontList(context: Context): Family[];
    /**
     * 从第一个可用的 XML 文件加载并解析系统字体配置，根据字体文件存在性过滤结果，并更新内部字体缓存。
     *
     * @return 字体族名称到 [Family] 对象的 [Map]，仅包含在文件系统上找到字体的字体。
     * 如果未找到配置文件、解析失败或没有字体通过文件系统存在性检查，则返回空映射。
     */
    /**
     * 根据可选的字体首选项获取回退字体。
     *
     * @param opts 可选的 [FontOpts] 指定所需的字体特征。如果未提供，则使用默认设置。
     * @return 匹配指定选项的 [Font]，如果未找到合适的字体则返回 `null`。
     */
    static getFallbackFont(context: Context, opts?: FontOpts | null): Font | null;
    /**
     * 根据可选的字体首选项获取回退字体列表。
     *
     * @param opts 可选的 [FontOpts] 指定所需的字体特征。如果未提供，则使用默认设置。
     * @return 匹配指定选项的 [Font] 列表，如果未找到合适的字体则返回空列表。
     */
    static getFallbackFonts(context: Context, opts?: FontOpts): Font[];
    /**
     * 在提供的字体族映射中搜索匹配指定条件的字体，返回有序的唯一匹配列表。
     *
     * @param fontFamilies 要搜索的字体族名称到 [Family] 对象的映射。
     * @param opts 指定所需字体特征（族、语言、字重、样式）的 [FontOpts]。
     * @return 匹配条件的唯一 [Font] 对象列表，按优先级排序，如果未找到匹配则返回空列表。
     */
    static findMatches(fontFamilies: Map<string, Family>, opts?: FontOpts): Font[];
    /**
     * 在提供的字体族列表中搜索匹配指定条件的字体，返回有序的唯一匹配列表。
     *
     * @param fontFamiliesList 要搜索的 [Family] 对象列表。
     * @param opts 指定所需字体特征（族、语言、字重、样式）的 [FontOpts]。
     * @return 匹配条件的唯一 [Font] 对象列表，按优先级排序，如果未找到匹配则返回空列表。
     */
    static findMatchesList(fontFamiliesList: Family[], opts?: FontOpts): Font[];
    /**
     * 处理匹配的字体族，根据语言、字重和样式进行过滤和排序。
     */
    /**
     * 根据字重和样式过滤字体族，并将它们添加到结果集中以确保唯一性。
     */
    /**
     * 从系统的字体路径中获取指定字体的文件。
     *
     * @param font 表示要查找字体的 [Font] 对象。
     * @return 指向字体文件的文件路径字符串，如果文件不存在则返回 `null`。
     */
    static getFontFile(font: Font): string | null;
    /**
     * 读取并返回指定字体文件的字节。
     *
     * @param font 表示要读取字体的 [Font] 对象。
     * @return 包含字体文件字节的 [Uint8Array]，如果无法找到或读取文件则返回 `null`。
     */
    static getFontBytes(font: Font): Uint8Array | null;
    /**
     * 过滤掉文件系统上不存在的字体。
     */
    /**
     * 获取由可选字体选项指定的回退字体的字节数组。
     *
     * @param opts 可选的 [FontOpts] 指定所需的字体特征。如果未提供，则使用默认选项。
     * @return 包含字体数据的 [Uint8Array]，如果未找到合适的字体或访问字体文件时出错则返回 `null`。
     */
    static getFallbackFontBytes(context: Context, opts?: FontOpts | null): Uint8Array | null;
    /**
     * 重置缓存（用于测试）
     */
    static resetForTesting(): void;
}
/**
 * 系统字体解析器
 */
export declare class SystemFontsParser {
    static readonly FONTS_XML_PATH: string;
    static readonly SYSTEM_FONTS_PATHS: string[];
    /**
     * 解析字体 XML 为映射
     */
    static parseFontsXMLMap(xmlFileStream: Uint8Array): Map<string, Family>;
    /**
     * 解析字体 JSON 为列表
     */
    static parseFontsJSON(jsonFileStream: Uint8Array): Family[];
    /**
     * 解析字体 JSON 为映射
     */
    static parseFontsJSONMap(jsonFileStream: Uint8Array): Map<string, Family>;
    /**
     * 解析字体 XML 为列表
     */
    static parseFontsXML(xmlFileStream: Uint8Array): Family[];
}
/**
 * 原生字体辅助对象
 */
export declare class NativeFontHelper {
    static cppRegisterFallbackFont(fontBytes: Uint8Array): boolean;
}
```

## src/main/ets/runtime/renderers/RectF.d.ets

```typescript
import rive from 'libohos_rive.so';
export declare class RectF implements rive.Bounds {
    left: number;
    top: number;
    right: number;
    bottom: number;
    constructor(left?: number, top?: number, right?: number, bottom?: number);
}
```

## src/main/ets/runtime/renderers/Renderer.d.ets

```typescript
import { NativeObject } from '../core/NativeObject';
import { RendererType } from './RendererType';
import { Fit } from '../core/Fit';
import { Alignment } from '../core/Alignment';
import { RectF } from './RectF';
import { SharedSurface } from './SharedSurface';
import { RiveFramCallBack } from './RiveFramCallBack';
export declare abstract class Renderer extends NativeObject {
    uiContext: UIContext;
    type: RendererType;
    trace: boolean;
    isPlaying: boolean;
    isAttached: boolean;
    everStarted: boolean;
    framCallBack: RiveFramCallBack | null;
    constructor(uiContext: UIContext, type?: RendererType, trace?: boolean);
    cppDoFrame(rendererPointer: BigInt): void;
    /**
     * Flags this renderer as disposing so any doFrame already queued on the shared
     * native worker bails out of its JS handshake wait instead of blocking on a
     * callback that won't arrive. Called by the view teardown BEFORE the File/Artboard
     * is released, to close the cross-thread use-after-free window (R6).
     */
    cppMarkDisposing(): void;
    protected cppDelete(pointer: BigInt): void;
    /**
     * Creates the native renderer object
     */
    make(): void;
    /**
     * Helper function to reassign the renderer type.
     */
    setRendererType(newType: number): void;
    /**
     * Abstract method to be implemented by concrete renderers
     */
    abstract draw(): void;
    /**
     * Abstract method to be implemented by concrete renderers
     */
    abstract advance(elapsed: number): void;
    /**
     * Starts the renderer and registers for frame callbacks
     */
    start(): void;
    /**
     * Sets the drawing surface for the renderer
     * @deprecated This method is dangerous as it does not correctly manage the Surface's lifecycle
     */
    setSurface(surfaceId: string): void;
    /**
     * Sets the drawing surface for the renderer using SharedSurface
     */
    setSharedSurface(surface: SharedSurface): void;
    /**
     * Marks the animation as stopped
     */
    stopThread(): void;
    /**
     * Calls stopThread and removes any pending frame callbacks
     */
    stop(): void;
    /**
     * Tears down the bound surface (stops rendering + releases the native surface).
     * Called by the view when the XComponent surface is destroyed, so the renderer does
     * not keep operating on a dead native window (EGL_BAD_NATIVE_WINDOW / SIGSEGV).
     */
    destroySurface(): void;
    scheduleFrame(): void;
    save(): void;
    restore(): void;
    get width(): number;
    get height(): number;
    get averageFps(): number;
    align(fit: Fit, alignment: Alignment, targetBounds: RectF, sourceBounds: RectF, scaleFactor?: number): void;
    transform(x: number, sy: number, sx: number, y: number, tx: number, ty: number): void;
    scale(sx: number, sy: number): void;
    translate(dx: number, dy: number): void;
    /**
     * Tears down the renderer and releases the underlying C++ object via the
     * ref-count disposal path (NativeObject.dispose), NOT a direct delete.
     *
     * Order matters: the worker/surface must be stopped and detached before the
     * native Renderer is freed. The Renderer is single-owner (only ever created
     * via make(), never externally acquired), so one release() drops refs to 0
     * and triggers dispose(), which releases dependencies (the controller) and
     * runs cppDelete. The SharedSurface is held in a dedicated field (not in the
     * dependency list) so it is released explicitly here first.
     */
    delete(): void;
    /**
     * Releases all of this renderer's dependents
     */
    protected disposeDependencies(): void;
}
```

## src/main/ets/runtime/renderers/RendererAttributes.d.ets

```typescript
import { Alignment } from '../core/Alignment';
import { Fit } from '../core/Fit';
import { Loop } from '../core/Loop';
import { RendererType } from './RendererType';
import { FileAssetLoader } from '../core/FileAssetLoader';
import { File } from '../core/File';
export interface ResourceType {
    type: string;
}
export declare class ResourceId implements ResourceType {
    type: string;
    value: number | string;
    constructor(id: number | string);
}
export declare class ResourceUrl implements ResourceType {
    type: string;
    value: string;
    constructor(url: string);
}
export declare class ResourceBytes implements ResourceType {
    type: string;
    value: ArrayBuffer;
    constructor(bytes: ArrayBuffer);
}
export declare class ResourceRiveFile implements ResourceType {
    type: string;
    value: File;
    constructor(file: File);
}
export declare class ResourceTypeFactory {
    static makeMaybeResource(value: number | string | ArrayBuffer | File): ResourceType | null;
}
export declare class RendererAttributes {
    alignmentIndex: number;
    fitIndex: number;
    loopIndex: number;
    autoplay: boolean;
    autoBind: boolean;
    riveTraceAnimations: boolean;
    artboardName: string | null;
    stateMachineName: string | null;
    animationName: string | null;
    rendererIndex: number;
    assetLoader: FileAssetLoader | null;
    resource?: ResourceType;
    get loop(): Loop;
    set loop(loop: Loop);
    set alignment(value: Alignment);
    get alignment(): Alignment;
    set fit(value: Fit);
    get fit(): Fit;
    set rendererType(value: RendererType);
    get rendererType(): RendererType;
    constructor(alignmentIndex?: number, fitIndex?: number, loopIndex?: number, rendererIndex?: number, autoplay?: boolean, autoBind?: boolean, riveTraceAnimations?: boolean, artboardName?: string | null, animationName?: string | null, stateMachineName?: string | null, resource?: ResourceType, assetLoader?: FileAssetLoader | null);
    static default(): RendererAttributes;
}
```

## src/main/ets/runtime/renderers/RendererType.d.ets

```typescript
export declare enum RendererType {
    None = -1,
    Rive = 0,
    Canvas = 1
}
export declare namespace RendererType {
    function fromIndex(index: number): RendererType;
}
export declare function rendererTypeToIndex(rendererType: RendererType): number;
export declare function rendererTypeFromIndex(index: number): RendererType;
export declare function rendererTypeFromString(type: string | null): RendererType;
```

## src/main/ets/runtime/renderers/RiveArtboardRenderer.d.ets

```typescript
import { RiveFileController } from '../controllers/RiveFileController';
import { RendererType } from './RendererType';
import { Renderer } from './Renderer';
/**
 * Open class for Rive artboard renderers in HarmonyOS/ETS
 */
export declare class RiveArtboardRenderer extends Renderer {
    constructor(uiContext: UIContext, controller: RiveFileController, trace?: boolean, rendererType?: RendererType);
    get controller(): RiveFileController;
    /**
     * Resizes the artboard based on the current fit and scale factor
     */
    /**
     * Draws the artboard - be aware of thread safety!
     */
    draw(): void;
    /**
     * Advances the animation - be aware of thread safety!
     */
    advance(elapsed: number): void;
    /**
     * Resets the renderer and controller
     */
    reset(): void;
    /**
     * Disposes dependencies in an orderly manner.
     *
     * R6: the controller's native Artboard (`reset()`) and File (`file.release()`) are
     * released HERE, from the DISPOSE threadsafe callback — NOT synchronously in
     * aboutToDisappear. The DISPOSE TSFN is fired by ScheduleDispose AFTER the worker
     * ran `m_workerImpl->destroy()`, which is queued behind every in-flight doFrame. So
     * by the time this runs, no doFrame — including one already past its DRAW handshake
     * and mid-`draw()` dereferencing the Artboard — remains on the shared worker. The
     * Artboard/File can be released safely (no cross-thread UAF), and the release happens
     * on the app's main JS context (which outlives the page), so it is reliable.
     *
     * This requires TSFNCallback to let the DISPOSE callback through even though
     * m_isDisposeScheduled is set (the old H1 bail discarded it and leaked). ADVANCE/DRAW
     * callbacks are still bailed (their doFrame exits via the IsDisposeScheduled wait
     * predicate instead), but DISPOSE must run.
     *
     * Only reached when the renderer was started (cppStart created the TSFN). A renderer
     * that never started has no TSFN, so ScheduleDispose skips DISPOSE — the view releases
     * synchronously in aboutToDisappear instead (see RiveAnimationView.aboutToDisappear).
     */
    protected disposeDependencies(): void;
}
```

## src/main/ets/test/test_file.d.ets

```typescript
export declare function test_file_import(context: Context): Promise<BigInt>;
export declare function test_ArtboardByName_withValidName(filePtr: BigInt): void;
export declare function test_ArtboardCount_ValidFile(filePtr: BigInt): void;
export declare function test_Artboard_ByIndexValid(filePtr: BigInt): void;
export declare function test_ArtboardName_ValidIndex(filePtr: BigInt): void;
export declare function test_CreateDefault_BindableArtboard(filePtr: BigInt): void;
export declare function test_CreateBindableArtboard_ByName(filePtr: BigInt): void;
export declare function test_ViewModel_Count(filePtr: BigInt): void;
export declare function test_ViewModel_ByIndex(filePtr: BigInt): void;
export declare function test_ViewModel_ByName(filePtr: BigInt): void;
```

## src/main/ets/test/test_file_asset_loader.d.ets

```typescript
export declare function test_file_asset_loader(): void;
```
