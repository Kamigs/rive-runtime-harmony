> 历史记录：提取自移植仓库提交 `52b666d4`。其中路径、包版本和阶段结论仅适用于原仓库；当前构建见 [BUILD](../BUILD.md)，验收边界见 [VALIDATION](../VALIDATION.md)。

# Rive HAR 独立验收宿主

`har-consumer/` 通过 HAR 消费 Rive，不依赖社区 `library/` 源码模块。阶段 0 锁定 OHPM 的 `@ohos/rive: 1.0.4`；阶段 1 通过本地 file 依赖切换到实际构建的社区 HAR。`rawfile/vehicles.riv` 始终为同一份官方素材。

阶段 0 的宿主源码、依赖锁和配置已整体归档到 `work/rive-validation/stage0/artifacts/host-source-published-1.0.4.tar.gz`，可独立恢复。当前依赖以 `har-consumer/entry/oh-package.json5` 为准；当前页面显示“社区源码验收”。

当前选择发布包公开参数 `RendererType.Canvas`。本机 Mate 90 Pro Max ARM64 模拟器使用 `RendererType.Rive` 时出现 shader 编译失败并导致模拟器崩溃。Canvas 与 Rive GPU 后端的验收结论分开记录。

## 构建和运行

工具：DevEco Studio 26.0.0 Beta2，SDK 26.0.0.32，devecocli 1.3.2。宿主兼容 API 12，目标 API 26；这不等于已在 API 12 设备验收。

```bash
cd /absolute/path/mg-club/modules/rive-harmony/verification/har-consumer
# 首次检出时创建本地配置；已有配置不要覆盖。
test -f build-profile.json5 || cp build-profile.template.json5 build-profile.json5
devecocli build --modules entry --build-mode debug
# 真机需要已登录的华为开发者账号以及设备调试权限。
devecocli signature generate --product default
devecocli run --module entry --device 'Mate 90 Pro Max' --build-mode debug
```

`build-profile.json5` 含本地签名信息，已忽略；可复现配置保存于 `build-profile.template.json5`。不要提交签名私钥或密码。

## 复跑基础用例

宿主启动时调用 `initializeRive()`。组件通过 `RiveAnimationView` 从 rawfile 加载素材，并从发布版运行时读取画板、动画、状态机和输入名称。`onReady` 可能在文件加载前触发，因此宿主以 `getFile()` 和活动画板存在为加载依据。首帧是否可见仍由截图判断。

```bash
cd /absolute/path/mg-club
bash modules/rive-harmony/verification/capture-baseline.sh \
  127.0.0.1:5555 work/rive-validation/stage0/emulator/recheck
# 模拟器画面、交互通过后，再用同一构建安装到真机。
```

脚本记录播放间隔截图、暂停间隔截图、恢复、`bumpy/bump` 触发、组件销毁重建和进程退出重启。脚本不自动宣告视觉验收通过。`HDC` 环境变量可覆盖脚本使用的 SDK hdc 路径。

日志中的 `SET_INPUT` 仅证明发出调用；应同时检查 `STATE bumpy -> bounce` 及画面响应。车辆素材没有覆盖 Boolean、Number、数据绑定、文本和自定义 Rive 事件的全部能力。

## 输入与许可证

| 输入 | 来源 / 校验值 |
| --- | --- |
| @ohos/rive 1.0.4 | https://ohpm.openharmony.cn/ohpm/@ohos/rive/-/rive-1.0.4.har |
| HAR SHA-256 | `dd9d286869a702340941e60f57480909518dd885e15fad03395032d1c32851ec` |
| vehicles.riv | https://cdn.rive.app/animations/vehicles.riv |
| 素材 SHA-256 | `46bb250cde0b0223a15faddac33d08fa00d4b6acebc2e4e827391ae0113768a3` |

原版 HAR 的 MIT LICENSE 和 README.OpenSource 保存在原包及 `work/rive-validation/inputs/published-1.0.4/package/`。官方 CDN 素材用作技术验收样例；未将库许可证扩展解释为该素材的独立商业授权。DevEco 生成的宿主模板保留 Apache-2.0 版权头。

实际产物、设备、日志和画面见项目根目录 `work/rive-validation/stage0/`。后续只通过切换 `entry/oh-package.json5` 的 HAR 依赖消费源码构建产物。

## 社区源码 HAR 构建

源码提交 `4b1609b2bdbf34e46ec37155f8aa5cc9a3612b2f`，Runtime 子模块 `f27a90050386b5428589bddb9a4ce5e248e0e8b3`。完整依赖提交在 `community-dependencies.lock.json`。发布包与此源码的 71 个声明文件一致，但尚无发布二进制对应提交证明。

```bash
cd /absolute/path/mg-club/modules/rive-harmony
git submodule update --init ohos_rive/submodules/rive-runtime \
  ohos_rive/library/src/main/cpp/boundscheck/third_party_bounds_checking_function
python3 verification/restore-community-dependencies.py
bash verification/setup-host-tools.sh
# 新检出时，应用 Runtime 的 macOS→OHOS shader 构建补丁。
git -C ohos_rive/submodules/rive-runtime apply ../../..//verification/patches/community-runtime-macos-ohos.patch
cp verification/community-build-profile.template.json5 ohos_rive/build-profile.json5
bash verification/build-har.sh debug
```

实际 HAR 输出为 `ohos_rive/library/build/default/outputs/default/rive_ohos.har`。CMake 和 `host-ninja.cjs` 使用 `RIVE_NINJA` 指向本地 ARM64 Ninja，避免覆盖安装目录中的 x86_64 SDK 工具；禁用本项目 Hvigor daemon，避免其缓存旧的工具环境。`RIVE_HOST_TOOLS`、`OHOS_NDK` 可覆盖工具路径。SDK 的 clang/clang++/llvm-ar 在当前 Mac 上为 ARM64。

社区 Canvas 频闪修复位于 `worker_impl.cpp`，独立补丁另存 `patches/community-canvas-fence.patch`。该修复未切换 Runtime 核心，ArkTS 声明未改动。完整对照见 `work/rive-validation/flicker/`。连续采样使用 `capture-burst.sh`；应在加载完成后运行，启动空白另行记录。
