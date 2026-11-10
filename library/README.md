# @ohos/rive

HarmonyOS API26 / arm64-v8a 原生Rive库，版本1.1.4-rn.0.1.11。
固定rive_native0.1.11核心，保留OHPM1.0.4的71份ArkTS声明。

```typescript
import { RiveAnimationView, RendererType } from '@ohos/rive';
// 在ArkUI build中使用：
// RiveAnimationView({ riveResource: '@rawfile/vehicles.riv', rendererType: RendererType.Rive })
```

组件默认GLES/EGL，也可选OH_Drawing Canvas。中文使用显式字体fallback。
借用Artboard依赖不能直接释放其所有者引用。完整可运行示例、接入和构建文档随独立源码仓库提供。
运行时与依赖许可证在HAR的rawfile/rive_licenses中；SDK/LLVM及字体声明随源码licenses目录提供。
