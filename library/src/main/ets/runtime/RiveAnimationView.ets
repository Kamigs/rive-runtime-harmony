/*
 * Copyright (C) 2025 Huawei Device Co., Ltd.
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import rive from 'libohos_rive.so';
import { File } from './core/File';
import {
  RiveFileController,
  PointerEvents,
  RiveFileControllerListener,
  RiveEventListener,
} from './controllers/RiveFileController';
import { Loop, LoopUtils } from './core/Loop';
import { Alignment } from './core/Alignment';
import { Fit } from './core/Fit';
import { Direction } from './core/Direction';
import {
  RendererAttributes,
  ResourceType,
  ResourceId,
  ResourceUrl,
  ResourceBytes,
  ResourceRiveFile,
  ResourceTypeFactory
} from './renderers/RendererAttributes';
import { RendererType, rendererTypeToIndex, rendererTypeFromIndex } from './renderers/RendererType';
import { FileAssetLoader, FallbackAssetLoader } from './core/FileAssetLoader';
import { StateMachineInstance } from './core/StateMachineInstance';
import LinearAnimationInstance from './core/LinearAnimationInstance';
import { Artboard } from './core/Artboard';
import { systemDateTime } from '@kit.BasicServicesKit';
import { Renderer } from './renderers/Renderer';
import { RiveArtboardRenderer } from './renderers/RiveArtboardRenderer';
import { SharedSurface } from './renderers/SharedSurface';
import { Bounds } from './core/Helpers';
import { ChangedInput } from './core/ChangedInput';
import { FileFetcher } from './services/FileFetcher';
import { JSON } from '@kit.ArkTS';

const TAG: string = 'RiveAnimationView';
const SINGLE_TOUCH_ID: number = 0;

const alignmentIndexDefault: number = Alignment.CENTER;
const fitIndexDefault: number = Fit.CONTAIN;
const loopIndexDefault: number = Loop.AUTO;
const traceAnimationsDefault: boolean = false;
const shouldLoadCDNAssetsDefault: boolean = true;

interface PointerInfo {
  id: number;
  x: number;
  y: number;
}

type EventProperties = Record<string, string | number | boolean>;

type PlayableInstance = LinearAnimationInstance | StateMachineInstance;

class RiveXComponentController extends XComponentController {
  private onSurfaceCreatedCallback?: (surfaceId: string) => void;
  private onSurfaceChangedCallback?: (surfaceId: string, rect: SurfaceRect) => void;
  private onSurfaceDestroyedCallback?: (surfaceId: string) => void;

  onSurfaceCreated(surfaceId: string): void {
    console.info(`${TAG}: onSurfaceCreated surfaceId: ${surfaceId}`);
    this.onSurfaceCreatedCallback?.(surfaceId);
  }

  onSurfaceChanged(surfaceId: string, rect: SurfaceRect): void {
    console.info(`${TAG}: onSurfaceChanged surfaceId: ${surfaceId}, rect: ${JSON.stringify(rect)}`);
    this.onSurfaceChangedCallback?.(surfaceId, rect);
  }

  onSurfaceDestroyed(surfaceId: string): void {
    console.info(`${TAG}: onSurfaceDestroyed surfaceId: ${surfaceId}`);
    this.onSurfaceDestroyedCallback?.(surfaceId);
  }

  setOnSurfaceCreated(callback: (surfaceId: string) => void): void {
    this.onSurfaceCreatedCallback = callback;
  }

  setOnSurfaceChanged(callback: (surfaceId: string, rect: SurfaceRect) => void): void {
    this.onSurfaceChangedCallback = callback;
  }

  setOnSurfaceDestroyed(callback: (surfaceId: string) => void): void {
    this.onSurfaceDestroyedCallback = callback;
  }
}

export class RiveAnimationViewBuilder {
  private context: Context;
  public alignment: Alignment | null = null;
  public fit: Fit | null = null;
  public loop: Loop | null = null;
  public rendererType: RendererType | null = null;
  public autoplay: boolean | null = null;
  public autoBind: boolean = false;
  public traceAnimations: boolean | null = null;
  public artboardName: string | null = null;
  public animationName: string | null = null;
  public stateMachineName: string | null = null;
  public assetLoader: FileAssetLoader | null = null;
  public shouldLoadCDNAssets: boolean = shouldLoadCDNAssetsDefault;
  public touchPassThrough: boolean = false;
  public multiTouchEnabled: boolean = false;
  public resource: number | string | Uint8Array | File | null = null;
  public resourceType: ResourceType | null = null;

  constructor(context: Context) {
    this.context = context;
  }

  setAlignment(value: Alignment): RiveAnimationViewBuilder {
    this.alignment = value;
    return this;
  }

  setFit(value: Fit): RiveAnimationViewBuilder {
    this.fit = value;
    return this;
  }

  setLoop(value: Loop): RiveAnimationViewBuilder {
    this.loop = value;
    return this;
  }

  setRendererType(value: RendererType): RiveAnimationViewBuilder {
    this.rendererType = value;
    return this;
  }

  setAutoplay(value: boolean): RiveAnimationViewBuilder {
    this.autoplay = value;
    return this;
  }

  setAutoBind(value: boolean): RiveAnimationViewBuilder {
    this.autoBind = value;
    return this;
  }

  setTraceAnimations(value: boolean): RiveAnimationViewBuilder {
    this.traceAnimations = value;
    return this;
  }

  setArtboardName(value: string): RiveAnimationViewBuilder {
    this.artboardName = value;
    return this;
  }

  setAnimationName(value: string): RiveAnimationViewBuilder {
    this.animationName = value;
    return this;
  }

  setStateMachineName(value: string): RiveAnimationViewBuilder {
    this.stateMachineName = value;
    return this;
  }

  setResource(value: number | string | Uint8Array | File): RiveAnimationViewBuilder {
    this.resourceType = ResourceTypeFactory.makeMaybeResource(value);
    this.resource = value;
    return this;
  }

  setAssetLoader(value: FileAssetLoader): RiveAnimationViewBuilder {
    this.assetLoader = value;
    return this;
  }

  setShouldLoadCDNAssets(value: boolean): RiveAnimationViewBuilder {
    this.shouldLoadCDNAssets = value;
    return this;
  }

  setTouchPassThrough(value: boolean): RiveAnimationViewBuilder {
    this.touchPassThrough = value;
    return this;
  }

  setMultiTouchEnabled(value: boolean): RiveAnimationViewBuilder {
    this.multiTouchEnabled = value;
    return this;
  }

  build(): RiveAnimationView {
    const view = new RiveAnimationView();
    view.applyBuilder(this);
    return view;
  }
}

@Component
export struct RiveAnimationView {

  public onReady?: (view: RiveAnimationView) => void;
  public riveResource: string = '';
  public riveUrl: string = '';
  public riveLoop : number = Loop.AUTO;
  public riveFit: string = 'contain';
  public shouldLoadCDNAssets: boolean = shouldLoadCDNAssetsDefault;
  public touchPassThrough: boolean = false;
  public multiTouchEnabled: boolean = false;
  public rendererType: RendererType = RendererType.Rive;
  public alignmentIndex: number = alignmentIndexDefault;
  public riveArtboard: string = '';
  public riveAnimation: string = '';
  public riveStateMachine: string = '';
  public riveAutoPlay: boolean = true;
  public riveAutoBind: boolean = false;
  public riveTraceAnimations: boolean = traceAnimationsDefault;
  public creatRendererFun: () => Promise<Renderer | null> = async (): Promise<Renderer | null> => {
    if (this.controller == null) {
      console.error(`RiveAnimationView creatRenderer controller is null`)
      return null
    }
    return new RiveArtboardRenderer(
      this.getUIContext(),
      this.controller,
      this.rendererAttributes.riveTraceAnimations,
      this.rendererAttributes.rendererType
    )
  }

  private defaultAutoplay: boolean = true;
  private rendererAttributes: RendererAttributes = RendererAttributes.default();
  private context: Context = getContext() as Context;
  public riveAssetLoaderClass: FileAssetLoader | null = null
  private xComponentController: RiveXComponentController = new RiveXComponentController();
  public controller: RiveFileController | null = null;
  private pointersInsideView: Map<number, boolean> = new Map<number, boolean>();
  private resourceFromValue: ResourceType | null = null;
  private customLoader: FileAssetLoader | null = null;
  // The root loader THIS view allocated (ctor self-ref owned by the view). Set in
  // init() (the Fallback it constructs) and in applyBuilder()'s else branch (the
  // Fallback it constructs when no loader is injected). Null when the loader is
  // injected (riveAssetLoaderClass / builder.assetLoader) — those are borrowed,
  // caller-owned, and must NOT be released by the view. Released in
  // aboutToDisappear to drop the ctor ref the view holds.
  private ownedRootLoader: FileAssetLoader | null = null;
  private targetBounds: Bounds | null = null;
  private listeners: Set<RiveFileControllerListener> = new Set();
  private eventListeners: Set<RiveEventListener> = new Set();

  private renderer: Renderer | null = null

  build() {
    Stack() {
      XComponent({
        id: 'RiveAnimComponent',
        type: XComponentType.SURFACE,
        controller: this.xComponentController
      })
        .backgroundColor(Color.Transparent)
        .onTouch((event: TouchEvent) => {
          return this.handleTouchEvent(event);
        })
    }
  }

  async aboutToAppear() {
    console.info(`${TAG}: aboutToAppear`);
    await this.init();
    this.setupSurfaceCallbacks();
    if (this.onReady) {
      console.info(`${TAG}: Calling onReady callback`);
      this.onReady(this);
    }
  }

  applyBuilder(builder: RiveAnimationViewBuilder): void {
    this.rendererAttributes = new RendererAttributes(
      builder.alignment ? builder.alignment.valueOf() : alignmentIndexDefault,
      builder.fit ? builder.fit.valueOf() : fitIndexDefault,
      builder.loop ? builder.loop.valueOf() : loopIndexDefault,
      builder.rendererType ? rendererTypeToIndex(builder.rendererType) : rendererTypeToIndex(RendererType.Rive),
      builder.autoplay ?? this.defaultAutoplay,
      builder.autoBind,
      builder.traceAnimations ?? traceAnimationsDefault,
      builder.artboardName,
      builder.animationName,
      builder.stateMachineName,
      builder.resourceType || undefined,
      builder.assetLoader || null
    );

    this.touchPassThrough = builder.touchPassThrough;
    this.multiTouchEnabled = builder.multiTouchEnabled;

    if (builder.resourceType) {
      this.resourceFromValue = builder.resourceType;
    }

    if (builder.assetLoader) {
      this.customLoader = builder.assetLoader;
      // Injected loader — borrowed, caller owns its ctor ref. View must not release.
      this.ownedRootLoader = null;
    } else {
      this.customLoader = new FallbackAssetLoader(
        this.context,
        builder.shouldLoadCDNAssets,
        null
      );
      // View-constructed Fallback — view owns its ctor ref.
      this.ownedRootLoader = this.customLoader;
    }

    if (!this.controller) {
      this.controller = new RiveFileController(
        this.rendererAttributes.loop,
        this.rendererAttributes.autoplay
      );
    }
    this.bindExistingListeners();

    if (this.resourceFromValue) {
      this.loadFileFromResource((file: File) => {
        if (this.controller && file) {
          this.controller.setRiveFile(file);
          this.controller.setupScene(this.rendererAttributes);
        }
      });
    }
  }

  async init() {
    console.info(`${TAG}: init`);

    let assetLoader: FileAssetLoader | null = null;
    try {
      if (this.riveResource !== '') {
        this.resourceFromValue = new ResourceId(this.riveResource);
      } else if (this.riveUrl !== '') {
        this.resourceFromValue = new ResourceUrl(this.riveUrl);
      } else {
        this.resourceFromValue = null;
      }

      // Builder path: applyBuilder() may have already constructed a view-owned
      // FallbackAssetLoader (when no loader was injected) and stored it in BOTH
      // ownedRootLoader and customLoader. aboutToAppear() then runs init(), which
      // constructs a SECOND Fallback below and reassigns ownedRootLoader. Without
      // releasing the previous one first, its ctor self-ref (refs=1) is never
      // dropped — aboutToDisappear only releases the latest ownedRootLoader — so
      // the first Fallback (and its owned CDN child) leaks its native object on
      // every Builder-constructed view. Release it here before the reassignment.
      // Only release a loader the view OWNS (ownedRootLoader); borrowed/injected
      // loaders (riveAssetLoaderClass / builder.assetLoader) keep ownedRootLoader
      // null and are left untouched. Clear customLoader too when it pointed at the
      // released loader, so it does not dangle.
      const previousOwned = this.ownedRootLoader;
      if (previousOwned) {
        if (this.customLoader === previousOwned) {
          this.customLoader = null;
        }
        previousOwned.release();
        this.ownedRootLoader = null;
      }

      assetLoader = new FallbackAssetLoader(
        this.context,
        this.shouldLoadCDNAssets,
        this.riveAssetLoaderClass,
      );
      // View constructed this Fallback — view owns its ctor ref (released in
      // aboutToDisappear). riveAssetLoaderClass, if injected, is a borrowed child
      // passed via the ctor `loader` param; its ctor ref stays caller-owned.
      this.ownedRootLoader = assetLoader;
      console.info(`${TAG}: FallbackAssetLoader created successfully`);
    } catch (error) {
      console.error(`${TAG}: Error creating FallbackAssetLoader: ${error}`);
      assetLoader = null;
    }

    this.rendererAttributes = new RendererAttributes(
      this.alignmentIndex,
      Fit.fromString(this.riveFit).valueOf(),
      this.riveLoop,
      rendererTypeToIndex(this.rendererType),
      this.riveAutoPlay,
      this.riveAutoBind,
      this.riveTraceAnimations,
      this.riveArtboard || null,
      this.riveAnimation || null,
      this.riveStateMachine || null,
      this.resourceFromValue || undefined,
      assetLoader
    );

    if (!this.controller) {
      this.controller = new RiveFileController(
        this.rendererAttributes.loop,
        this.rendererAttributes.autoplay
      );
    }

    this.bindExistingListeners();

    if (this.resourceFromValue) {
      this.loadFileFromResource((file: File) => {
        console.info(`${TAG}: Loading file from resource`,file ,'controller===',this.controller);
        if (this.controller && file) {
          this.controller.setRiveFile(file);
          this.controller.setupScene(this.rendererAttributes);
          if (this.onReady) {
            console.info(`${TAG}: Calling onReady callback`);
            this.onReady(this);
          }
        }
      });
    }

    try {
      this.renderer = await this.creatRendererFun()
      console.info(`${TAG}: init this.renderer = ${this.renderer}`);
      if (this.renderer) {
        console.info(`${TAG}: init this.renderer != null`);
        this.renderer.make()
        this.renderer.start()
      }
    } catch (error) {
      const err = error as Error;
      console.error(`${TAG}: init creatRendererFun error = ${err?.message ?? error}`);
    }
  }

  getRenderer(): Renderer | null {
    try {
      if (this.renderer instanceof  RiveArtboardRenderer) {
        return this.renderer as RiveArtboardRenderer
      }else{
        return this.renderer;
      }
    }catch (error) {
      console.error(`${TAG}, Expected RiveArtboardRenderer but got ${
      this.renderer?.constructor?.name ? this.renderer?.constructor?.name : 'NULL'}`)
      return null
    }
  }

  private setupSurfaceCallbacks(): void {
    this.xComponentController.setOnSurfaceCreated((surfaceId: string) => {
      console.info(`${TAG}: Surface created: ${surfaceId}`);
      if (this.controller) {
        this.controller.isActive = true;
      }
      this.updateTargetBounds();
      this.onSurfaceReady();
    });

    this.xComponentController.setOnSurfaceChanged((surfaceId: string, rect: SurfaceRect) => {
      console.info(`${TAG}: Surface changed: ${surfaceId}, offsetX: ${rect.offsetX}, offsetY: ${rect.offsetY}`);
      this.updateTargetBounds(rect);
      if (this.renderer) {
        this.renderer.stop();
        const newSurface = new SharedSurface(surfaceId);
        this.renderer.setSharedSurface(newSurface);
      }
    });

    this.xComponentController.setOnSurfaceDestroyed((surfaceId: string) => {
      console.info(`${TAG}: Surface destroyed: ${surfaceId}`);
      this.targetBounds = null;
      // The XComponent surface is going away. Destroy the renderer's surface BEFORE the
      // native window is freed, otherwise a pending frame would draw/SwapBuffers against
      // a dead window (EGL_BAD_NATIVE_WINDOW / SIGSEGV). destroySurface() also stops the
      // frame loop so no callback touches objects during controller teardown below.
      if (this.renderer) {
        this.renderer.destroySurface();
      }
      // We deliberately do NOT call controller.reset() here. reset() releases the
      // ArtboardInstance synchronously on the JS thread, but a doFrame already past its JS
      // handshake is uninterruptible (MarkDisposing only bails the handshake wait, not a
      // draw() already in progress) and may be traversing that Artboard's drawable list
      // (Artboard::draw -> m_FirstDrawable) on the shared worker. Freeing the instance
      // under it is a use-after-free (cppcrash 20260628165032/165126/153432, SIGSEGV in
      // Artboard::draw). Keeping the Artboard alive here is safe: any in-flight worker
      // draw() references live memory, and no new draw stages after destroySurface() (the
      // frame loop is stopped). The Artboard/File is released later:
      //   - page exit: aboutToDisappear -> worker-drained disposeDependencies() (safe,
      //     no draw remains on the worker);
      //   - surface rebuild: the same Artboard stays alive and re-renders on the new
      //     surface (correct, leak-free).
      if (this.controller) {
        this.controller.stopAllAnimations();
        this.controller.isActive = false;
      }
    });
  }

  private updateTargetBounds(rect?: SurfaceRect): void {
    console.info(`${TAG}, updateTargetBounds, rect = ${JSON.stringify(rect)}`)
    if (!this.controller) {
      return;
    }
    const bounds: Bounds = {
      left: rect?.offsetX ?? 0,
      top: rect?.offsetY ?? 0,
      right: (rect?.surfaceWidth ?? 0),
      bottom: (rect?.surfaceHeight ?? 0)
    };
    this.targetBounds = bounds;
    this.controller.targetBounds = bounds;
    this.controller.requireArtboardResize = true;
  }

  private bindExistingListeners(): void {
    if (!this.controller) {
      return;
    }
    this.listeners.forEach(listener => {
      this.controller?.registerListener(listener);
    });
    this.eventListeners.forEach(listener => {
      this.controller?.addEventListener(listener);
    });
  }

  private onSurfaceReady(): void {
    console.info(`${TAG}: Surface ready`);
    if (this.controller && !this.controller.file) {
      this.loadFileFromResource((file: File) => {
        if (this.controller && file) {
          this.controller.setRiveFile(file);
          this.controller.setupScene(this.rendererAttributes);
        }
      });
    }
  }

  private loadFileFromResource(onComplete: (file: File) => void): void {
    const resource = this.rendererAttributes.resource;
    if (resource === null || resource === undefined) {
      console.warn(`${TAG}: loadResource: no resource to load`);
      return;
    }

    try {
      const context = getContext() as Context;
      FileFetcher.fetch(
        resource,
        this.rendererAttributes.rendererType,
        this.rendererAttributes.assetLoader,
        context
      )
        .then((file: File) => {
          if (!file) {
            console.error(`${TAG}: Failed to create RiveFile instance`);
            return;
          }
          // Ownership handshake: fetcher returns refs==1. onComplete's setRiveFile()
          // acquires (refs==2); we then release (refs==1) so the controller owns it.
          // `resourceRiveFile` is an exception: the caller already owns it, so skip the
          // release and let the caller's existing ownership stand.
          onComplete(file);
          if (resource.type !== 'resourceRiveFile') {
            file.release();
          }
        })
        .catch((error: Error) => {
          console.error(`${TAG}: Error in loadFileFromResource: ${error}`);
        });
    } catch (error) {
      console.error(`${TAG}: Error in loadFileFromResource: ${error}`);
    }
  }

  pause(): void {
    this.renderer?.stop()
    if (this.controller) {
      this.controller.pauseAllAnimations();
    }
  }

  pauseAnimation(animationName: string, isStateMachine: boolean = false): void {
    if (this.controller) {
      this.controller.pauseAnimations(animationName, isStateMachine);
      console.info(`${TAG}: pause animation: ${animationName}, isStateMachine: ${isStateMachine}`);
    }
  }

  pauseAnimations(animationNames: string[], areStateMachines: boolean = false): void {
    if (this.controller) {
      this.controller.pauseMultipleAnimations(animationNames, areStateMachines);
      console.info(`${TAG}: pause animations: ${animationNames.join(', ')}, areStateMachines: ${areStateMachines}`);
    }
  }

  stop(): void {
    if (this.controller) {
      this.controller.stopAllAnimations();
    }
  }

  stopAnimation(animationName: string, isStateMachine: boolean = false): void {
    if (this.controller) {
      console.info(`${TAG}: stop animation: ${animationName}, isStateMachine: ${isStateMachine}`);
      this.controller.stopAnimations(animationName, isStateMachine);
    }
  }

  stopMultipleAnimations(animationNames: string[], areStateMachines: boolean = false): void {
    if (this.controller) {
      console.info(`${TAG}: stop animations: ${animationNames.join(', ')}, areStateMachines: ${areStateMachines}`);
      this.controller.stopMultipleAnimations(animationNames, areStateMachines);
    }
  }

  play(
    animationName?: string,
    loop: Loop = Loop.AUTO,
    direction: Direction = Direction.AUTO,
    isStateMachine: boolean = false,
    settleInitialState: boolean = true
  ): void {
    console.info(`${TAG}: play animationName: ${animationName}`);
    if (animationName) {
      this.rendererAttributes.animationName = isStateMachine ? null : animationName
      this.rendererAttributes.stateMachineName = isStateMachine ? animationName : null
    }
    this.rendererAttributes.loop = loop

    if (this.controller) {
      if (animationName) {
        this.controller.play(animationName, loop, direction, isStateMachine, settleInitialState);
      } else {
        this.controller.play(loop, direction, settleInitialState);
        console.info(`${TAG}: play first animation with loop ${loop} and direction ${direction}`);
      }
    }
  }

  playAnimations(
    animationNames: string[],
    loop: Loop = Loop.AUTO,
    direction: Direction = Direction.AUTO,
    areStateMachines: boolean = false,
    settleInitialState: boolean = true
  ): void {
    if (this.controller) {
      this.rendererAttributes = new RendererAttributes(
        this.rendererAttributes.alignmentIndex,
        this.rendererAttributes.fitIndex,
        loop.valueOf(),
        this.rendererAttributes.rendererIndex,
        this.rendererAttributes.autoplay,
        this.rendererAttributes.autoBind,
        this.rendererAttributes.riveTraceAnimations,
        this.rendererAttributes.artboardName,
        null,
        null,
        this.rendererAttributes.resource,
        this.rendererAttributes.assetLoader
      );

      this.controller.play(animationNames, loop, direction, areStateMachines, settleInitialState);
      console.info(`${TAG}: play animations: ${animationNames.join(', ')}, areStateMachines: ${areStateMachines}`);
    }
  }

  reset(): void {
    if (this.renderer instanceof RiveArtboardRenderer) {
      this.renderer.reset()
    }
    console.info(`${TAG}: reset`);
  }

  fireState(stateMachineName: string, inputName: string): void {
    if (this.controller) {
      this.controller.fireState(stateMachineName, inputName);
      console.info(`${TAG}: fireState - stateMachine: ${stateMachineName}, input: ${inputName}`);
    }
  }

  setBooleanState(stateMachineName: string, inputName: string, value: boolean): void {
    if (this.controller) {
      this.controller.setBooleanState(stateMachineName, inputName, value);
      console.info(
        `${TAG}: setBooleanState - stateMachine: ${stateMachineName}, input: ${inputName}, value: ${value}`
      );
    }
  }

  setNumberState(stateMachineName: string, inputName: string, value: number): void {
    if (this.controller) {
      this.controller.setNumberState(stateMachineName, inputName, value);
    }
  }

  fireStateAtPath(inputName: string, path: string): void {
    if (this.controller) {
      this.controller.fireStateAtPath(inputName, path);
      console.info(`${TAG}: fireStateAtPath - input: ${inputName}, path: ${path}`);
    }
  }

  setBooleanStateAtPath(inputName: string, value: boolean, path: string): void {
    if (this.controller) {
      this.controller.setBooleanStateAtPath(inputName, value, path);
      console.info(`${TAG}: setBooleanStateAtPath - input: ${inputName}, value: ${value}, path: ${path}`);
    }
  }

  setNumberStateAtPath(inputName: string, value: number, path: string): void {
    if (this.controller) {
      this.controller.setNumberStateAtPath(inputName, value, path);
      console.info(`${TAG}: setNumberStateAtPath - input: ${inputName}, value: ${value}, path: ${path}`);
    }
  }

  setMultipleStates(...inputs: ChangedInput[]): void {
    if (this.controller) {
      this.controller.queueInputs(...inputs);
      console.info(`${TAG}: setMultipleStates - inputs: ${inputs.length}`);
    }
  }

  getTextRunValue(textRunName: string, path?: string): string | null {
    if (this.controller) {
      const value = this.controller.getTextRunValue(textRunName, path);
      console.info(`${TAG}: getTextRunValue - textRunName: ${textRunName}, path: ${path}, value: ${value}`);
      return value;
    }
    return null;
  }

  setTextRunValue(textRunName: string, textValue: string, path?: string): void {
    if (this.controller) {
      this.controller.setTextRunValue(textRunName, textValue, path);
      console.info(`${TAG}: setTextRunValue - textRunName: ${textRunName}, textValue: ${textValue}, path: ${path}`);
    }
  }

  getVolume(): number | null {
    return this.controller?.getVolume() ?? null;
  }

  setVolume(value: number): void {
    if (this.controller) {
      this.controller.setVolume(value);
      console.info(`${TAG}: setVolume - value: ${value}`);
    }
  }

  setRiveResource(
    resId: number | string,
    artboardName?: string,
    animationName?: string,
    stateMachineName?: string,
    autoplay?: boolean,
    autoBind?: boolean,
    fit?: Fit,
    alignment?: Alignment,
    loop?: Loop
  ): void {
    const attrs = this.rendererAttributes;
    if (alignment !== undefined) {
      attrs.alignmentIndex = alignment.valueOf();
      attrs.alignment = alignment;
    }
    if (fit !== undefined) {
      attrs.fitIndex = fit.valueOf();
      attrs.fit = fit;
    }
    if (loop !== undefined) {
      attrs.loopIndex = loop.valueOf();
      attrs.loop = loop;
    }
    attrs.autoplay = autoplay ?? this.controller?.autoplay ?? this.defaultAutoplay;
    attrs.autoBind = autoBind ?? false;
    attrs.artboardName = artboardName ?? null;
    attrs.animationName = animationName ?? null;
    attrs.stateMachineName = stateMachineName ?? null;
    attrs.resource = ResourceTypeFactory.makeMaybeResource(resId) || undefined;

    this.loadFileFromResource((file: File) => {
      if (this.controller && file) {
        this.controller.setRiveFile(file);
        this.controller.setupScene(this.rendererAttributes);
        if (this.onReady) {
          console.info(`${TAG}: Calling onReady callback`);
          this.onReady(this);
        }
      }
    });
  }

  setRiveBytes(
    bytes: ArrayBuffer,
    artboardName?: string,
    animationName?: string,
    stateMachineName?: string,
    autoplay?: boolean,
    autoBind?: boolean,
    fit?: Fit,
    alignment?: Alignment,
    loop?: Loop
  ): void {
    const attrs = this.rendererAttributes;
    if (alignment !== undefined) {
      attrs.alignmentIndex = alignment.valueOf();
      attrs.alignment = alignment;
    }
    if (fit !== undefined) {
      attrs.fitIndex = fit.valueOf();
      attrs.fit = fit;
    }
    if (loop !== undefined) {
      attrs.loopIndex = loop.valueOf();
      attrs.loop = loop;
    }
    attrs.autoplay = autoplay ?? this.controller?.autoplay ?? this.defaultAutoplay;
    attrs.autoBind = autoBind ?? false;
    attrs.artboardName = artboardName ?? null;
    attrs.animationName = animationName ?? null;
    attrs.stateMachineName = stateMachineName ?? null;
    attrs.resource = ResourceTypeFactory.makeMaybeResource(bytes) || undefined;
    this.loadFileFromResource((file: File) => {
      if (this.controller && file) {
        this.controller.setRiveFile(file);
        this.controller.setupScene(this.rendererAttributes);
        if (this.onReady) {
          console.info(`${TAG}: Calling onReady callback`);
          this.onReady(this);
        }
      }
    });
  }

  setRiveFile(
    file: File,
    artboardName?: string,
    animationName?: string,
    stateMachineName?: string,
    autoplay?: boolean,
    autoBind?: boolean,
    fit?: Fit,
    alignment?: Alignment,
    loop?: Loop
  ): void {
    if (file.rendererType !== this.rendererAttributes.rendererType) {
      throw new Error(
        `Incompatible Renderer types: file initialized with ${file.rendererType} ` +
        `but View is set up for ${this.rendererAttributes.rendererType}`
      );
    }

    const attrs = this.rendererAttributes;
    if (alignment !== undefined) {
      attrs.alignmentIndex = alignment.valueOf();
      attrs.alignment = alignment;
    }
    if (fit !== undefined) {
      attrs.fitIndex = fit.valueOf();
      attrs.fit = fit;
    }
    if (loop !== undefined) {
      attrs.loopIndex = loop.valueOf();
      attrs.loop = loop;
    }
    attrs.autoplay = autoplay ?? this.controller?.autoplay ?? this.defaultAutoplay;
    attrs.autoBind = autoBind ?? false;
    attrs.artboardName = artboardName ?? null;
    attrs.animationName = animationName ?? null;
    attrs.stateMachineName = stateMachineName ?? null;
    attrs.resource = ResourceTypeFactory.makeMaybeResource(file) || undefined;

    if (this.controller) {
      this.controller.setRiveFile(file);
      this.controller.setupScene(this.rendererAttributes);
      if (this.onReady) {
        console.info(`${TAG}: Calling onReady callback`);
        this.onReady(this);
      }
    }
  }

  setAssetLoader(assetLoader: FileAssetLoader | null): void {
    if (assetLoader === this.rendererAttributes.assetLoader) {
      return;
    }

    const currentAssetLoader = this.rendererAttributes.assetLoader;
    this.rendererAttributes.assetLoader = assetLoader;

    if (assetLoader) {
      assetLoader.acquire();
    }
    if (currentAssetLoader) {
      currentAssetLoader.release();
    }
  }

  getFile(): File | null {
    return this.controller?.file || null;
  }

  getArtboardName(): string | null {
    return this.controller?.activeArtboard?.name || null;
  }

  setArtboardName(name: string | null) {
    if (this.controller && this.controller.file) {
      try {
        this.controller.selectArtboard(name)
      } catch (error) {
        console.error(`${TAG}: Error setting artboard name: ${error}`);
      }
    }
  }

  getAutoplay(): boolean {
    return this.controller?.autoplay ?? this.defaultAutoplay;
  }

  setAutoplay(value: boolean) {
    if (this.controller) {
      this.controller.autoplay = value;
    }
  }

  getFit(): Fit {
    return this.controller?.fit ?? Fit.CONTAIN;
  }

  setFit(value: Fit) {
    if (this.controller) {
      this.controller.fit = value;
    }
  }

  getAlignment(): Alignment {
    return this.controller?.alignment ?? Alignment.CENTER;
  }

  setAlignment(value: Alignment) {
    if (this.controller) {
      this.controller.alignment = value;
    }
  }

  getLayoutScaleFactor(): number | null {
    return this.controller?.layoutScaleFactor ?? null;
  }

  setLayoutScaleFactor(value: number | null) {
    if (this.controller) {
      this.controller.layoutScaleFactor = value;
      console.info(`${TAG}: set layoutScaleFactor: ${value}`);
    }
  }

  getAnimations(): LinearAnimationInstance[] {
    return this.controller?.animations ?? [];
  }

  getStateMachines(): StateMachineInstance[] {
    return this.controller?.stateMachines ?? [];
  }

  getPlayingAnimations(): Set<LinearAnimationInstance> {
    return this.controller?.playingAnimations ?? new Set();
  }

  getPlayingStateMachines(): Set<StateMachineInstance> {
    return this.controller?.playingStateMachines ?? new Set();
  }

  isPlaying(): boolean {
    return this.renderer?.isPlaying ?? false
  }

  private handleTouchEvent(event: TouchEvent): boolean {
    const returnVal = !this.touchPassThrough;

    try {
      switch (event.type) {
        case TouchType.Down:
          {
            const firstPointer = event.touches[0];
            const firstId = this.multiTouchEnabled ? firstPointer.id : SINGLE_TOUCH_ID;
            const firstInfo: PointerInfo = { id: firstId, x: firstPointer.x, y: firstPointer.y };
            this.pointersInsideView.set(firstId, this.inBounds(firstInfo.x, firstInfo.y));
            this.sendPointerEvent(PointerEvents.POINTER_DOWN, firstInfo.id, firstInfo.x, firstInfo.y);
          }
          break;

        case TouchType.Move:
          {
            const upperBound = this.multiTouchEnabled ? event.touches.length : 1;
            for (let i = 0; i < upperBound && i < event.touches.length; i++) {
              const pointer = event.touches[i];
              const id = this.multiTouchEnabled ? pointer.id : SINGLE_TOUCH_ID;
              const info: PointerInfo = { id: id, x: pointer.x, y: pointer.y };
              const wasInside = this.pointersInsideView.get(id) || false;
              const nowInside = this.inBounds(info.x, info.y);
              if (wasInside && !nowInside) {
                this.sendPointerEvent(PointerEvents.POINTER_EXIT, info.id, info.x, info.y);
              }
              this.pointersInsideView.set(id, nowInside);
              this.sendPointerEvent(PointerEvents.POINTER_MOVE, info.id, info.x, info.y);
            }
          }
          break;

        case TouchType.Up:
          {
            const upPointer = event.changedTouches[0];
            const upId = this.multiTouchEnabled ? upPointer.id : SINGLE_TOUCH_ID;
            const upInfo: PointerInfo = { id: upId, x: upPointer.x, y: upPointer.y };
            this.sendPointerEvent(PointerEvents.POINTER_UP, upId, upInfo.x, upInfo.y);
            this.sendPointerEvent(PointerEvents.POINTER_EXIT, upId, upInfo.x, upInfo.y);
            if (event.touches.length === 0) {
              this.pointersInsideView.clear();
            } else {
              this.pointersInsideView.delete(upId);
            }
          }
          break;

        case TouchType.Cancel:
          {
            const keyIterator = this.pointersInsideView.keys();
            let next = keyIterator.next();
            while (!next.done) {
              const id = next.value;
              this.sendPointerEvent(PointerEvents.POINTER_UP, id, -1, -1);
              this.sendPointerEvent(PointerEvents.POINTER_EXIT, id, -1, -1);
              next = keyIterator.next();
            }
            this.pointersInsideView.clear();
          }
          break;

        default:
          console.warn(`${TAG}: Unhandled touch event type: ${event.type}`);
          break;
      }
    } catch (error) {
      console.error(`${TAG}: Error handling touch event: ${error}`);
    }

    return returnVal;
  }

  private inBounds(x: number, y: number): boolean {
    try {
      const bounds = this.targetBounds ?? this.controller?.targetBounds;
      if (!bounds) {
        return x >= 0 && y >= 0;
      }
      return (
        x >= bounds.left &&
          y >= bounds.top &&
          x <= bounds.right &&
          y <= bounds.bottom
      );
    } catch (error) {
      console.error(`${TAG}: Error in inBounds calculation: ${error}`);
      return false;
    }
  }

  private sendPointerEvent(type: PointerEvents, id: number, x: number, y: number): void {
    if (!this.controller) {
      return;
    }

    try {
      const bounds = this.targetBounds ?? this.controller.targetBounds;
      const offsetX = bounds ? bounds.left : 0;
      const offsetY = bounds ? bounds.top : 0;
      const locallx = x - offsetX;
      const locally = y - offsetY;
      this.controller.pointerEvent(type, id, locallx, locally);
    } catch (error) {
      console.error(`${TAG}: Error sending pointer event: ${error}`);
    }
  }

  registerListener(listener: RiveFileControllerListener): void {
    this.listeners.add(listener);
    this.controller?.registerListener(listener);
  }

  unregisterListener(listener: RiveFileControllerListener): void {
    this.listeners.delete(listener);
    this.controller?.unregisterListener(listener);
  }

  addEventListener(listener: RiveEventListener): void {
    this.eventListeners.add(listener);
    this.controller?.addEventListener(listener);
  }

  removeEventListener(listener: RiveEventListener): void {
    this.eventListeners.delete(listener);
    this.controller?.removeEventListener(listener);
  }

  aboutToDisappear() {
    console.info(`${TAG}: aboutToDisappear`);
    this.pointersInsideView.clear();
    this.listeners.clear();
    this.eventListeners.clear();

    // Stop rendering immediately so no frame callback touches objects we're about to release.
    this.renderer?.stop();

    // Mark every asset loader as torn down BEFORE releasing the File. CDN/hosted
    // assets are fetched asynchronously; their completion callbacks capture the
    // FileAsset JS wrapper. Once we release the File below, the native FileAsset is
    // destroyed and a late callback would dereference a dangling pointer (SIGSEGV).
    // The released flag makes those callbacks skip the unsafe decode() call.
    this.rendererAttributes?.assetLoader?.markReleased();
    this.customLoader?.markReleased();
    this.riveAssetLoaderClass?.markReleased();

    // Release the ctor self-ref of the root loader THIS view allocated. The
    // loader's ref is ctor(1) + File.addDependency(1) = 2; this drops it to 1
    // (the File's dependency ref keeps it alive — no UAF, no race with the worker,
    // which only touches loaders during Napi_File_import/loadContents, long done by
    // teardown). The borrowed/injected loaders (riveAssetLoaderClass, builder's
    // assetLoader) are NOT released here — their ctor ref belongs to the caller.
    // The deferred File.dispose (or the sync path below) later drops the remaining
    // dependency ref → loader reaches 0 → its own dispose releases its owned CDN
    // children. Safe in both started (deferred) and never-started (sync) paths.
    if (this.ownedRootLoader) {
      try {
        this.ownedRootLoader.release();
      } catch (error) {
        const err = error as Error;
        console.error(`${TAG}: ownedRootLoader release failed: ${err?.message ?? error}`);
      }
      this.ownedRootLoader = null;
    }

    // R6: close the cross-thread use-after-free window WITHOUT blocking the JS thread.
    // The native render worker is a single process-wide thread shared by all Renderers;
    // a doFrame already queued on it may be past its JS DRAW handshake and mid-draw()
    // dereferencing this renderer's Artboard. Releasing the Artboard/File on the JS
    // thread races that draw() → SIGSEGV.
    //
    // MarkDisposing flags this renderer AND notifies the worker's handshake wait, so
    // any in-flight doFrame still in its ADVANCE/DRAW wait_for bails out immediately
    // (no draw, no Artboard deref). A doFrame already past the wait (mid-draw()) can't
    // be interrupted — but it doesn't need JS, so it finishes in a few ms on its own.
    //
    // The Artboard/File release is therefore DEFERRED to disposeDependencies(), fired by
    // ScheduleDispose's DISPOSE TSFN AFTER the worker ran m_workerImpl->destroy() —
    // queued behind every doFrame, so no frame (mid-draw or otherwise) remains. The
    // DISPOSE callback runs on the app's main JS context (outlives the page), so it is
    // reliable (a setTimeout on the page's own context could be dropped when the page is
    // torn down). TSFNCallback lets DISPOSE through (only ADVANCE/DRAW are bailed).
    //
    // We do NOT block the JS thread to flush the worker: the worker's doFrame needs the
    // JS thread to answer its ADVANCE/DRAW TSFN, so a JS→worker RunAndWait pins both and
    // deadlocked (appfreeze, RecyclerPage teardown).
    this.renderer?.cppMarkDisposing();

    if (this.controller) {
      this.controller.isActive = false;
      console.info(`${TAG}: Disposing controller`);
      this.controller.stopAllAnimations();
      // If this renderer never started there is no TSFN, so ScheduleDispose skips DISPOSE
      // and disposeDependencies() never runs — release synchronously here (safe: no
      // worker frames exist, nothing can touch the Artboard). If it started, an in-flight
      // doFrame may be mid-draw() on the shared worker; defer reset()/file.release() to
      // disposeDependencies() (the worker-drained DISPOSE callback).
      if (!this.renderer?.everStarted) {
        this.controller.reset();
        if (this.controller.file) {
          this.controller.file.release();
        }
      }
      this.controller = null;
    }

    if (this.renderer) {
      this.renderer.delete()
      this.renderer = null
    }
  }

  onPageShow(): void {
    this.renderer?.start()
  }

  onPageHide(): void {
    this.renderer?.stop()
  }
}
