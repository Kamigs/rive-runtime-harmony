/*
 * Copyright (c) 2026 Huawei Device Co., Ltd.
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

import {
  RiveAnimationView, RendererType, Loop, RiveFileControllerListener,
  RiveEventListener, PlayableInstance, RiveEvent, SMIBoolean, SMINumber,
  FileAssetLoader, FileAsset, FontAsset, RiveManager
} from '@ohos/rive';

class LocalFontLoader extends FileAssetLoader {
  private fontBytes: Uint8Array;
  private monoBytes: Uint8Array;
  constructor(fontBytes: Uint8Array, monoBytes: Uint8Array) { super(); this.fontBytes = fontBytes; this.monoBytes = monoBytes; }
  loadContents(asset: FileAsset, bytes: Uint8Array): boolean {
    if (asset instanceof FontAsset && bytes.length === 0) {
      const decoded = asset.decode(asset.name === 'JetBrains Mono' ? this.monoBytes : this.fontBytes);
      console.info(`RiveValidation FONT_DECODE ${asset.name} result=${decoded}`);
      return decoded;
    }
    return false;
  }
}

class InputControl {
  machine: string = '';
  name: string = '';
  kind: string = '';
}

class ValidationListener implements RiveFileControllerListener, RiveEventListener {
  frameIntervals: number[] = [];
  firstAdvanceMs: number = 0;
  totalFrames: number = 0;
  notifyAdvance(elapsed: number): void {
    this.totalFrames++;
    if (this.firstAdvanceMs === 0) {
      this.firstAdvanceMs = Date.now();
      console.info(`RiveValidation FIRST_ADVANCE launch_ms=${this.firstAdvanceMs - (AppStorage.get<number>('launchMs') ?? this.firstAdvanceMs)}`);
    }
    if (this.frameIntervals.length < 10000) { this.frameIntervals.push(elapsed * 1000); }
  }
  report(): void {
    console.info(`RiveValidation CALLBACK_COUNT total=${this.totalFrames}`);
    const values = this.frameIntervals.slice(60).sort((a: number, b: number) => a - b);
    if (values.length > 0) {
      console.info(`RiveValidation FRAME_INTERVAL count=${values.length} p50_ms=${values[Math.floor(values.length * 0.5)]} p95_ms=${values[Math.floor(values.length * 0.95)]} max_ms=${values[values.length - 1]}`);
    }
  }
  notifyPlay(animation: PlayableInstance): void {
    console.info(`RiveValidation PLAY ${animation.name}`);
  }
  notifyPause(animation: PlayableInstance): void {
    console.info(`RiveValidation PAUSE ${animation.name}`);
  }
  notifyStop(animation: PlayableInstance): void {
    console.info(`RiveValidation STOP ${animation.name}`);
  }
  notifyLoop(animation: PlayableInstance): void {
    console.info(`RiveValidation LOOP ${animation.name}`);
  }
  notifyStateChanged(machine: string, state: string): void {
    console.info(`RiveValidation STATE ${machine} -> ${state}`);
  }
  notifyEvent(event: RiveEvent): void {
    console.info(`RiveValidation EVENT ${event.name} type=${event.type} properties=${JSON.stringify(event.properties)}`);
  }
}

@Entry
@Component
struct Index {
  private fixture: string = AppStorage.get<string>('fixture') ?? 'vehicles.riv';
  private baseline: string = AppStorage.get<string>('baseline') ?? 'native 0.1.11';
  private renderer: RendererType = AppStorage.get<string>('renderer') === 'rive' ? RendererType.Rive : RendererType.Canvas;
  private fontLoader: LocalFontLoader | null = null;
  @State private secondMounted: boolean = false;
  @State private mounted: boolean = true;
  @State private status: string = '等待文件加载';
  @State private artboardNames: string[] = [];
  @State private machineNames: string[] = [];
  @State private inputs: InputControl[] = [];
  @State private selectedArtboard: string = '';
  @State private selectedMachine: string = '';
  private view: RiveAnimationView | null = null;
  private listener: ValidationListener = new ValidationListener();

  aboutToAppear(): void {
    if (AppStorage.get<string>('cjkFallback') === 'true') {
      const context = this.getUIContext().getHostContext()!;
      const bytes = context.resourceManager.getRawFileContentSync('NotoSansCJKsc-Regular.otf');
      const registered = RiveManager.getInstance().setFallbackFont(context, bytes);
      console.info(`RiveValidation CJK_FALLBACK registered=${registered} bytes=${bytes.length}`);
    }
    this.fontLoader = new LocalFontLoader(this.getUIContext().getHostContext()!.resourceManager.getRawFileContentSync('Inter-Regular.ttf'), this.getUIContext().getHostContext()!.resourceManager.getRawFileContentSync('JetBrainsMono.ttf'));
  }

  private ready(view: RiveAnimationView): void {
    const file = view.getFile();
    const artboard = view.controller?.activeArtboard;
    if (!file || !artboard) {
      console.info('RiveValidation ON_READY file not loaded yet');
      return;
    }
    if (this.view !== view) {
      this.view = view;
      view.registerListener(this.listener);
      view.addEventListener(this.listener);
    }
    this.artboardNames = file.artboardNames;
    this.selectedArtboard = artboard.name;
    this.machineNames = artboard.stateMachineNames;
    console.info(`RiveValidation FILE artboards=${JSON.stringify(this.artboardNames)}`);
    console.info(`RiveValidation ARTBOARD ${artboard.name} animations=${JSON.stringify(artboard.animationNames)} machines=${JSON.stringify(this.machineNames)}`);
    if (this.machineNames.length > 0) {
      this.selectMachine(this.machineNames[0]);
    }
    this.status = `文件已加载 · ${artboard.name}`;
    if (this.fixture === 'layout_test.riv') {
      view.setLayoutScaleFactor(0.5);
      setTimeout(() => {
        console.info(`RiveValidation LAYOUT surface=${view.getRenderer()?.width}x${view.getRenderer()?.height} artboard=${artboard.width}x${artboard.height} bounds=${JSON.stringify(artboard.bounds)}`);
      }, 500);
    }
    console.info(`RiveValidation LOADED fixture=${this.fixture} renderer=${this.renderer}; visible frame requires screenshot`);
  }

  private selectMachine(name: string): void {
    const view = this.view;
    if (!view) { return; }
    view.stop();
    view.play(name, Loop.AUTO, undefined, true);
    this.selectedMachine = name;
    const controls: InputControl[] = [];
    view.getStateMachines().forEach((machine) => {
      if (machine.name !== name) { return; }
      machine.inputs.forEach((input) => {
        const control = new InputControl();
        control.machine = name;
        control.name = input.name;
        control.kind = input.isBoolean ? 'boolean' : input.isNumber ? 'number' : 'trigger';
        controls.push(control);
        let value: string = '';
        if (input.isBoolean) { value = `${(input as SMIBoolean).value}`; }
        if (input.isNumber) { value = `${(input as SMINumber).value}`; }
        console.info(`RiveValidation INPUT machine=${name} name=${input.name} type=${control.kind} initial=${value}`);
      });
    });
    this.inputs = controls;
  }

  private setInput(input: InputControl, value: number): void {
    if (input.kind === 'boolean') {
      this.view?.setBooleanState(input.machine, input.name, value !== 0);
    } else if (input.kind === 'number') {
      this.view?.setNumberState(input.machine, input.name, value);
    } else {
      this.view?.fireState(input.machine, input.name);
    }
    this.status = `${input.name} = ${value}`;
    console.info(`RiveValidation SET_INPUT ${input.machine}/${input.name}=${value}`);
  }

  private checkApi(): void {
    const view = this.view;
    if (!view) { return; }
    try {
      const artboard = view.controller?.activeArtboard;
      console.info(`RiveValidation API stateMachines=${view.getStateMachines().length} playing=${view.isPlaying()} artboard=${artboard?.name}`);
      if (artboard && artboard.animationNames.length > 0) {
        const animation = artboard.animation(artboard.animationNames[0]);
        // Artboard owns the returned dependency. Retain our temporary reference
        // before releasing it; otherwise a later file swap releases it twice.
        const retained = animation.acquire();
        try {
          animation.settime(-1);
          const lower = animation.gettime();
          animation.settime(999999);
          console.info(`RiveValidation SEEK lower=${lower} upper=${animation.gettime()} duration_s=${animation.geteffectiveDurationInSeconds()}`);
        } finally {
          const remaining = animation.release();
          console.info(`RiveValidation SEEK_OWNERSHIP retained=${retained} remaining=${remaining}`);
        }
      }
      view.playAnimations(['idle']); view.pauseAnimations(['idle']);
      view.stopAnimation('idle');
      view.pause(); view.play(); view.stop(); view.reset();
      const file = view.getFile();
      if (file) { view.setRiveFile(file); }
      console.info('RiveValidation API play_pause_stop_reset_setRiveFile=PASS');
    } catch (error) { console.error(`RiveValidation API FAIL ${error}`); }
  }

  private editValue(): void {
    const view = this.view;
    if (!view) { return; }
    try {
      if (this.fixture === 'electrified_button_nested_text.riv' || this.fixture === 'runtime-contract.riv') {
        const before = view.getTextRunValue('button_text');
        view.setTextRunValue('button_text', AppStorage.get<string>('textValue') ?? 'MG CLUB');
        const after = view.getTextRunValue('button_text');
        console.info(`RiveValidation TEXT before=${before} after=${after}`);
      } else if (this.fixture === 'rewards.riv') {
        const instance = view.controller?.activeArtboard?.viewModelInstance;
        if (!instance) { throw new Error('No bound view model instance'); }
        const value = instance.getNumberProperty('Energy_Bar/Energy_Bar');
        const before = value.value;
        value.value = before > 50 ? 20 : 90;
        const title = instance.getStringProperty('Button/State_1');
        title.value = 'MG CLUB';
        console.info(`RiveValidation DATA_BIND energy_before=${before} after=${value.value} title=${title.value}`);
      } else {
        const bytes = this.getUIContext().getHostContext()!.resourceManager.getRawFileContentSync(this.fixture);
        view.setRiveBytes(bytes.buffer as ArrayBuffer);
        console.info('RiveValidation RESOURCE setRiveBytes requested');
      }
    } catch (error) { console.error(`RiveValidation EDIT FAIL ${error}`); }
  }

  private unmount(): void {
    this.view?.unregisterListener(this.listener);
    this.view?.removeEventListener(this.listener);
    this.view = null;
    this.mounted = false;
    this.inputs = [];
    this.status = '组件已退出';
    console.info('RiveValidation UNMOUNT requested');
  }

  aboutToDisappear(): void {
    this.view?.unregisterListener(this.listener);
    this.view?.removeEventListener(this.listener);
    this.view = null;
    this.fontLoader?.release();
    this.fontLoader = null;
    console.info('RiveValidation PAGE_DISAPPEAR');
  }

  build() {
    Column({ space: 10 }) {
      Text(`Rive · ${this.baseline} 验收`).fontSize(22).fontWeight(FontWeight.Bold)
      Text(`${this.fixture} · rawfile · ${this.renderer === RendererType.Canvas ? 'Canvas' : 'Rive GLES'}`).fontSize(12)
      Text(this.status).id('validation-status').fontSize(14)
      if (this.mounted) {
        RiveAnimationView({
          riveResource: `@rawfile/${this.fixture}`,
          riveFit: this.fixture === 'layout_test.riv' ? 'layout' : 'contain',
          riveAutoPlay: true,
          riveTraceAnimations: true,
          rendererType: this.renderer,
          riveAutoBind: this.fixture === 'rewards.riv' || this.fixture === 'layout_test.riv',
          riveAssetLoaderClass: this.fontLoader,
          shouldLoadCDNAssets: false,
          onReady: (view: RiveAnimationView) => { this.ready(view); }
        }).width('100%').height(300).id('rive-surface')
      } else {
        Text('已销毁 Rive 组件').height(300).width('100%')
      }
      if (this.secondMounted) {
        RiveAnimationView({
          riveResource: '@rawfile/vehicles.riv', rendererType: this.renderer,
          riveStateMachine: 'bumpy', shouldLoadCDNAssets: false
        }).width('100%').height(150).id('rive-second')
      }
      Row({ space: 8 }) {
        Button('暂停').id('pause').onClick(() => {
          this.view?.pause();
          this.status = '已请求暂停';
          console.info(`RiveValidation PAUSE_REQUEST isPlaying=${this.view?.isPlaying()}`);
        })
        Button('恢复').id('resume').onClick(() => {
          this.view?.play();
          this.status = '已请求恢复';
          console.info(`RiveValidation RESUME_REQUEST isPlaying=${this.view?.isPlaying()}`);
        })
        Button(this.mounted ? '退出组件' : '重新进入').id('mount-toggle').onClick(() => {
          if (this.mounted) { this.unmount(); }
          else {
            this.status = '重新加载中';
            this.mounted = true;
            console.info('RiveValidation REMOUNT requested');
          }
        })
      }
      Scroll() {
        Column({ space: 8 }) {
          Text(`画板：${this.selectedArtboard} / 状态机：${this.selectedMachine}`).fontSize(12)
          Row({ space: 4 }) {
            Button('统计').id('report-metrics').fontSize(11).onClick(() => { this.listener.report(); })
            Button('双实例').id('multi-instance').fontSize(11).onClick(() => { this.secondMounted = !this.secondMounted; })
            Button('API').id('api-check').fontSize(11).onClick(() => { this.checkApi(); })
            Button('改值').id('edit-value').fontSize(11).onClick(() => { this.editValue(); })
          }
          Button('退出验收页面').id('leave-page').fontSize(11).onClick(() => {
            this.getUIContext().getRouter().replaceUrl({ url: 'pages/Blank' });
          })
          ForEach(this.artboardNames, (name: string) => {
            Button(`画板 ${name}`).id(`artboard-${name}`).fontSize(12).onClick(() => {
              this.view?.setArtboardName(name);
              if (this.view) { this.ready(this.view); }
            })
          })
          ForEach(this.machineNames, (name: string) => {
            Button(`状态机 ${name}`).fontSize(12).onClick(() => { this.selectMachine(name); })
          })
          ForEach(this.inputs, (input: InputControl) => {
            Column({ space: 4 }) {
              Text(`${input.name} (${input.kind})`).fontSize(14)
              Row({ space: 6 }) {
                if (input.kind === 'trigger') {
                  Button('触发').id(`trigger-${input.name}`).onClick(() => { this.setInput(input, 1); })
                } else {
                  Button('0').id(`input-${input.name}-0`).onClick(() => { this.setInput(input, 0); })
                  Button('1').id(`input-${input.name}-1`).onClick(() => { this.setInput(input, 1); })
                  if (input.kind === 'number') {
                    Button('2').id(`input-${input.name}-2`).onClick(() => { this.setInput(input, 2); })
                    Button('3').id(`input-${input.name}-3`).onClick(() => { this.setInput(input, 3); })
                  }
                }
              }
            }
          })
        }.width('100%')
      }.layoutWeight(1).width('100%')
    }.padding({ top: 48, left: 16, right: 16, bottom: 24 })
    .width('100%').height('100%').backgroundColor('#F3F4F6')
  }
}
