> 历史记录：提取自移植仓库提交 `52b666d4`。其中路径、包版本和阶段结论仅适用于原仓库；当前构建见 [BUILD](../BUILD.md)，验收边界见 [VALIDATION](../VALIDATION.md)。

# Rive HAR 独立验收入口

当前版为 `1.1.3-rn.0.1.11`，保留 OHPM 1.0.4 的71份公开 ArkTS 声明。支持范围按用户最新要求收敛到API26，已用正式SDK26.0.0.105构建并完成模拟器、Mate70Pro+真机补验；验收宿主引用配对修复按新HAP两环境定向回归，见 [真机记录](DEVICE26.md)。当前入口见 [API26交付与复现](API26.md) 和 [Rive CLI配合流程](CLI.md)，实际验收记录在工作区 `work/rive-validation/completion/`。历史双环境迁移交付为 `1.1.0-rn.0.1.11`，1.1.2真机结果单独保留。

- [完整迁移与构建说明](MIGRATION.md)
- [API12–26适配、回退与验收](API12-26.md)
- [ArkTS 兼容清单](api/compatibility.md)
- [素材来源和校验值](fixtures-manifest.json)
- [新 runtime 固定依赖](native-0.1.11-dependencies.lock.json)
- [Flutter 对照宿主](flutter-comparison/)

`har-consumer/` 是独立 DevEco 工程，通过 `entry/oh-package.json5` 的 HAR 文件依赖切换发布版、社区源码版和迁移版。

历史社区基线构建说明保存在 [BASELINE.md](BASELINE.md)。各阶段实际日志、截图、产物和结果在 MG_Club 根目录的 `work/rive-validation/`，请以阶段报告判断验收状态。
