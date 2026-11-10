# Rive Runtime for HarmonyOS

独立的 HarmonyOS Rive 原生运行时库。ArkTS 包名 **`@ohos/rive`**，整理版 **`1.1.4-rn.0.1.11`**，支持 **HarmonyOS API26 / arm64-v8a**。底层固定为官方 `rive_native 0.1.11` 的 `runtime/` 快照，保留 OHPM 1.0.4 的 71 个 ArkTS 声明文件与现有 Node-API 导出。

从 MG_Club 已验收的 `1.1.3-rn.0.1.11` / 提交 `52b666d4` 提取。整理版调整工程布局、依赖路径、构建入口和 API26 元数据，运行时及组件实现不变。原移植仓库和历史证据继续保留；新包构建与历史设备验收分别记录在 [验证说明](docs/VALIDATION.md)。此包尚未发布到 OHPM。

源码仓库：[GitHub · Kamigs/rive-runtime-harmony](https://github.com/Kamigs/rive-runtime-harmony)，以及本地 Gitea 的 `kamigs/rive-runtime-harmony`。两端同步 `main`，克隆与同步方法见 [仓库托管](docs/PUBLISHING.md)。

## 使用入口

- [ArkUI 接入与对象所有权](docs/INTEGRATION.md)
- [独立构建、工具与依赖恢复](docs/BUILD.md)
- [验证范围及待验项](docs/VALIDATION.md)
- [CLI 素材流程与 Flutter 对照](docs/CLI.md)
- [源码基线与鸿蒙补丁](docs/SOURCE.md)
- [仓库克隆与双端同步](docs/PUBLISHING.md)
- [变更记录](CHANGELOG.md)、[来源元数据](SOURCE.json)、[许可证](NOTICE)

```text
library/                 ArkTS + Node-API + 鸿蒙绘制适配，构建 HAR
runtime/rive-native-0.1.11/ 官方快照与已验收的鸿蒙平台补丁
examples/har-consumer/   独立 ArkUI 宿主，仅通过实际 HAR 依赖库
examples/flutter-comparison/ 固定 Flutter 依赖的对照宿主
examples/cli-projects/   RML 技术样例，已签名 .riv 随示例保存
scripts/                依赖恢复、构建、产物及源码检查
verification/           API 快照、素材清单、补丁、设备采集脚本
licenses/               依赖、SDK、字体版权及历史声明
docs/                   当前指南；history/ 保存原迁移记录
dist/                   本机生成的 HAR/HAP，不纳入源码版本控制
```

## 快速构建

在本仓库根目录执行，先安装 DevEco Studio（API26 Release SDK）、devecocli、Git、Python3 及 Xcode Command Line Tools。当前验证构建主机为 macOS ARM64。

```bash
python3 scripts/restore-dependencies.py
bash scripts/setup-host-tools.sh
export DEVECO_CLI_STUDIO_PATH=/Applications/DevEco-Studio.app
bash scripts/build.sh release
bash scripts/build-example.sh
```

默认生成未签名的示例 HAP。设备安装需开发者在示例工程配置本机签名。已交付的 CLI `.riv` 可直接构建，不需要登录或重新导出。工具与依赖均使用仓库内路径或显式环境变量，不依赖 MG_Club 的 `work/`。

## 最小 ArkUI 使用

将构建的 HAR 复制到目标工程 `libs/rive.har`，在 `entry/oh-package.json5` 设置 `"@ohos/rive": "file:../libs/rive.har"`。将 `vehicles.riv` 放入模块 `resources/rawfile/`：

```typescript
import { RiveAnimationView, RendererType } from '@ohos/rive';

@Entry
@Component
struct Index {
  build() {
    Column() {
      RiveAnimationView({
        riveResource: '@rawfile/vehicles.riv',
        riveArtboard: 'Truck',
        riveStateMachine: 'bumpy',
        rendererType: RendererType.Rive,
        shouldLoadCDNAssets: false
      }).width('100%').height(300)
    }
  }
}
```

Canvas 使用 OH_Drawing / NativeWindow，Rive 后端使用 GLES / EGL。后端功能和性能不同，应按素材选择；正式业务素材仍需独立验收。API12 旧系统、x86_64 ABI、其他构建主机不在本整理版支持承诺内。
