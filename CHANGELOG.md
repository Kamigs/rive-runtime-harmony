# Changelog

## 1.1.4-rn.0.1.11 — 2026-11-10

- 将已验收的 `1.1.3-rn.0.1.11` 整理为独立库，不携带社区 samples 集合及旧引擎子模块。
- 库、ArkUI/Flutter/CLI 示例、验证工具、历史说明分别归档；保留原始版权和依赖许可证。
- 固定第三方提交，构建工具使用本地 `.tools/`；示例通过 `examples/libs/rive.har` 引用实际构建 HAR。
- 库和示例的 target/min SDK 均为 API26；包名、71 个 ArkTS 声明、Node-API 和核心保持兼容。
- 保留 `1.1.3` 验收宿主 acquire/release 修复。新旧包及验证范围分开记录。

## 1.1.3-rn.0.1.11

原移植交付：API26 适配、非激活停帧、显式中文字体回退、TSFN 空环境清理、CLI 技术样例；模拟器及 Mate70Pro+ 真机验收和后续宿主修复详见 `docs/history/DEVICE26.md`。
