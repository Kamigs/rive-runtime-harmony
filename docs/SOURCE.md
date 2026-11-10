# 来源与补丁

来源机器可读记录在 [SOURCE.json](../SOURCE.json)。本次从提交`52b666d4d3c6219ee4b11747660eb5f2a3f5ee16`提取；原HAR基线为`b6a2d88ea408f66b0a2897fcd8efb5079a7c24d1`，之后仅修复验收宿主引用与完善证据。

| 基线 | 标识 |
| --- | --- |
| 社区源码 | `4b1609b2bdbf34e46ec37155f8aa5cc9a3612b2f`，未证明与OHPM1.0.4二进制完全同源 |
| 原引擎子模块 | `f27a90050386b5428589bddb9a4ce5e248e0e8b3`，仅作来源记录，不参与当前构建 |
| C++快照 | 官方`rive_native-0.1.11.tar.gz`中的`runtime/` |
| 归档SHA256 | `f1ae8a9ec4dab6b803fed006745e55c7de6cd568bd30750d4a6770479b9f8294` |
| Flutter对照 | `rive 0.14.11`、`rive_native 0.1.11` |

`verification/extraction-manifest.json`记录原路径、新路径和原文件SHA；`scripts/check-source.py`核对移入的核心、渲染器、ArkTS实现、原生绑定及素材不变。新仓库不复制旧子模块中的未提交工作内容，也不带无关samples或旧构建缓存。

## 平台补丁

现有补丁用途保存在[迁移记录](history/MIGRATION.md)、[API12–26研究](history/API12-26.md)和`verification/patches/`。这些patch针对原迁移基线，已应用在当前源码中，不能再次对当前树直接应用。

- 构建：OHOS clang/sysroot、Premake、shader、文字/布局/音频依赖与C++类布局宏一致。
- Canvas：消费fence等待与关闭、超时撤回buffer、Matrix释放、布局首帧尺寸。
- GLES：平台头文件、扩展符号可见性、DevEco模拟器Metal兼容分支。
- 绑定：显式seek边界、XComponent/Surface生命周期、绘制队列、TSFN空环境清理。
- ArkUI：非激活停帧、恢复状态、列表复用及显式字体fallback。

本次新增仅为目录、脚本、文档、包版本和API26构建元数据；CMake的旧`OHOS_SDK_HOME/12`兜底改为`26`。核心及渲染器算法没有修改。依赖由`dependencies.lock.json`恢复，所有许可证随源码保留。
