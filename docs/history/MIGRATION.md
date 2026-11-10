> 历史记录：提取自移植仓库提交 `52b666d4`。其中路径、包版本和阶段结论仅适用于原仓库；当前构建见 [BUILD](../BUILD.md)，验收边界见 [VALIDATION](../VALIDATION.md)。

# Rive Harmony 原生运行时迁移

当前版本与复现入口见 [API26.md](API26.md)，版本 `1.1.3-rn.0.1.11`；CLI导出及双宿主素材同步见 [CLI.md](CLI.md)。用户最新要求仅支持API26，本轮只进行模拟器验收。历史API12–26研究和1.1.2真机记录保存在 [API12-26.md](API12-26.md)，下文保留1.1.0迁移基线，历史双环境结果不自动覆盖新版。

本工程独立于 Spine，包名保留 `@ohos/rive`，迁移版号为 `1.1.0-rn.0.1.11`。ArkUI 宿主通过实际 HAR 文件引用，不直接编译源码模块。完整验收证据在 MG_Club 根目录 `work/rive-validation/`；`stage0`、`stage1`、`stage2`、`stage3` 分开保存。

## 固定基线

| 项目 | 标识 |
| --- | --- |
| OHPM 发布 HAR | @ohos/rive 1.0.4；SHA-256 `dd9d286869a702340941e60f57480909518dd885e15fad03395032d1c32851ec` |
| 社区源码 | CPF-ApplicationTPC/openharmony_tpc_samples `4b1609b2bdbf34e46ec37155f8aa5cc9a3612b2f`，保留 `ohos_rive/` 结构 |
| 原引擎子模块 | `f27a90050386b5428589bddb9a4ce5e248e0e8b3` |
| 修复后社区基线 | 分支 baseline/rive-1.0.4，提交 `f4a90b7875efcc884ea8bfc8df49587c33ac98e0` |
| C++ 目标 | https://pub.dev/api/archives/rive_native-0.1.11.tar.gz 的完整 runtime/ |
| 归档 SHA-256 | `f1ae8a9ec4dab6b803fed006745e55c7de6cd568bd30750d4a6770479b9f8294` |
| 纯快照导入提交 | `af8873b27b7fba60b952ef06cfe70cb9ddd3ab88`，2217 个文件逐文件核对一致 |
| 基础迁移提交 | `5655f4b0b3ca837c8920dfb32c6b518b3eb4b9b6` |
| Flutter 对照 | rive 0.14.11 + rive_native 0.1.11；`flutter-comparison/pubspec.lock` |

发布二进制与社区 SHA 的对应关系没有得到上游证明。两者的 71 个 ArkTS 声明文件一致，不能由此推断二进制同源。用户指定的备用 `26eb3091677742d83c7838b9a35cb397d98e87b6` 经核对是后续 1.0.5 源码，未拿它冒充 1.0.4。

## 构建

本次实际使用 macOS arm64、DevEco Studio SDK 26.0.0.32 Beta2、devecocli 1.3.2。最低兼容声明 API 12；运行验证是 API 26。两个目标均为 arm64-v8a。没有构建或宣称验证 x86_64、Windows、Linux 主机和 API 12 设备。

在 `modules/rive-harmony/` 执行：

```bash
python3 verification/restore-community-dependencies.py verification/native-0.1.11-dependencies.lock.json
bash verification/setup-host-tools.sh
# 仅首次检出时创建本机配置；不要覆盖已有签名配置。
test -f ohos_rive/build-profile.json5 || cp verification/community-build-profile.template.json5 ohos_rive/build-profile.json5
bash verification/build-har.sh release
mkdir -p ../../work/rive-validation/stage3/artifacts
cp ohos_rive/library/build/default/outputs/default/rive_ohos.har \
  ../../work/rive-validation/stage3/artifacts/rive-harmony-1.1.0-rn.0.1.11-release.har
```

实际 HAR 输出：`ohos_rive/library/build/default/outputs/default/rive_ohos.har`。`build-har.sh` 通过 devecocli 清理 Hvigor 包装层，再让 Premake/Ninja 增量核对外置 runtime 树，避免“源码已改、HAR 仍是旧静态库”。源码树下的 `cpp/out/` 为可删除的编译缓存，不属于官方快照。

`OHOS_NDK` 默认指向 DevEco 自带 native SDK；`RIVE_HOST_TOOLS`、`RIVE_NINJA` 可覆盖宿主工具位置。未修改 SDK 里的 x86_64 Ninja，使用本地 ARM64 Ninja 1.11.1.3。旧社区基线需要 Premake beta2 的现代 macOS 补丁；目标快照使用自身固定的 Premake beta7。PLY 固定 3.11。依赖锁包含 Yoga grid、HarfBuzz 13.1.1、SheenBidi 和鸿蒙 miniaudio fork 的提交，必须先恢复依赖再构建，避免上游脚本按分支抓取不同源码。

### 独立宿主

将 `har-consumer/entry/oh-package.json5` 的 `@ohos/rive` 指向所构建 HAR 的相对 `file:` 路径。当前路径指向 `work/rive-validation/stage3/artifacts/`。其余 ArkTS 调用无需随 HAR 切换。

```bash
cd verification/har-consumer
test -f build-profile.json5 || cp build-profile.template.json5 build-profile.json5
# 仅新设备/新工作区需要生成本机签名；已有签名可直接复用。
devecocli signature generate --product default
devecocli build --build-mode release
devecocli run --skip-build --build-mode release --device 127.0.0.1:5555
```

模拟器验收通过后，同一签名 HAP 安装到真机。若签名 profile 不包含新设备，用自己的开发者账号重新生成签名并构建。私钥、密码、证书和本机 build-profile 均不纳入源码交付。

验收启动参数 `fixture` 指定 rawfile 名，`renderer` 为 `canvas` 或 `rive`。`launch-fixture.sh`、`capture-baseline.sh`、`capture-performance.sh` 保存操作和证据，不会仅因命令返回成功就判定画面通过。

`capture-specials.sh` 运行固定专项素材与 20 次组件重建；`capture-lifecycle.sh` 检查多实例和前后台；`capture-disposed-trace.sh` 检查退出后的原生帧；`capture-page-reentry.sh` 通过独立空白页真实销毁/重建验收页面。短屏幕控件定位由 `click-control.sh` 根据实际 Scroll 边界完成。每台设备的脚本串行执行。

可用 `python3 verification/audit-artifacts.py PUBLISHED.har TARGET.har HOST.hap report.json` 重复检查声明、ARM64 ELF、许可证文件及 HAR/HAP 原生库一致性。签名 HAP 的实际输出在 `har-consumer/entry/build/default/outputs/default/entry-default-signed.hap`。

## 鸿蒙补丁目录

| 修改 | 用途与升级处理 |
| --- | --- |
| OHOS clang/Premake/CMake | OHOS triple/sysroot/PIC；API 宏与静态库一致；新快照 Yoga grid include、Makefile.rive shader 构建；仅构建适配 |
| GLES 平台条件 | 为 RIVE_OHOS 使用 GLES3/gl3.h、gl31.h、GLES2/gl2ext.h；SDK 无 GLES3/gl3ext.h；不误入 WebGL/ANGLE 入口 |
| GLES 扩展符号隐藏 | OHOS libGLES 已导出同名函数，Rive 的可写指针必须隐藏以阻止 ELF 抢占；保留扩展入口校验 |
| DevEco Metal GL 4.1 兼容 | 仅识别 `OpenGL ES 3.0 (4.1 Metal`：软件解包 half，并禁用实际不支持的 KHR 高级混合声明；使用目标 runtime 的 MSAA/destination-read 路径。真机不命中这一分支 |
| Canvas consumer fence | RequestBuffer 返回的消费完成 fence 必须等待并关闭；超时 AbortBuffer；CPU 拷贝完成后 FlushBuffer fence=-1，修复整画面频闪 |
| Canvas 新接口 | const RenderPath、modulateOpacity 的 save/restore 叠加，临时 paint alpha 恢复；GPUTextureFormat::rgba32；DimensionsHelper 对透明度不改变几何 |
| OH_Drawing Matrix 生命周期 | Path transform、Canvas concat 创建的 Matrix 调用对应销毁，消除每帧 native 分配泄漏 |
| Canvas 首帧尺寸 | 布局计算发生于 BindCanvas 之前，尺寸从已创建 Worker Surface 读取；Surface 改变时重新标记画板 resize |
| 显式 seek 边界 | 1.0.4 将 ArkTS settime 限制到 startSeconds/endSeconds；在 Node-API 绑定层保留此行为，不改变目标核心内部 time/advance |
| HiTrace | 使用嵌套同步 StartTrace/FinishTrace 而非分布式 BeginChain/EndChain；Rive::frame 包含 ArkTS 往返、绘制、提交；公开 riveTraceAnimations 默认不变 |

旧 fork 的 `dataContext const` 与空上下文保护已由新快照覆盖。旧 fork 自制的 MSAA 高级混合改动由新核心现有 destination-read 流程替代；不重复叠加旧绘制算法。新核心内部的时间推进、布局 dirty pass、音频生命周期按官方快照保留；显式 ArkTS seek 通过绑定层兼容。相关可观察差异在 API 兼容报告记录。

XComponent 生命周期和 Node-API 导出沿用社区适配。File/Artboard 的在途引用保留，销毁先停止帧循环并排空 worker，再回调 ArkTS 释放依赖。Rive GPU worker 在最后一个外部引用退出后释放 renderer 资源，EGL context 可缓存复用；不能将缓存 context 等同于泄漏。

## 能力与边界

Canvas 使用 HarmonyOS OH_Drawing；Rive 使用目标 runtime 的 GLES renderer。包含柔化阴影等 Rive 特效的素材应使用 Rive 后端，Canvas 不因升级核心而自动获得这些效果。Flutter 本轮使用 Web 对照：Factory.rive 是 rive_native 提供的 WASM + WebGL2，实际为 ANGLE Metal / Apple M4 Pro；这不能替代 Android/iOS 真机验收。

正式项目素材尚未提供。官方样例覆盖基础播放、触发/布尔/数字输入、事件、文本、自定义字体、数据绑定、布局和渲染对照。正式素材的所有画板/输入/事件、字体授权、中文字形、音频、特殊混合/裁剪、导出版本和性能预算仍须按实际资产验收。

## 许可证

官方 runtime、renderer 和社区版权头原样保留。`licenses/` 保存固定依赖的许可证与提交清单。HAR 的 rawfile/rive_licenses 内附运行时和链接依赖的 10 个许可证/说明文件；随包的 libc++_shared.so 所属 SDK LLVM NOTICE 和 native SDK NOTICE 另保存在 `licenses/ohos-*`，最终交付的 LICENSES 目录一并提供。验收字体的 OFL 及嵌入版权元数据随独立宿主与 Flutter 工程保留。官方样例的来源与 SHA-256 在 `fixtures-manifest.json`，样例用于技术验收，不能把运行时 MIT 许可证自动解释成素材的独立商业授权。
