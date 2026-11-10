# 独立 HAR 示例

从仓库根目录运行 `bash scripts/build.sh release` 和 `bash scripts/build-example.sh`。
entry仅通过 `file:../../libs/rive.har` 消费实际构建产物，不直接依赖library源码模块。
默认模板为API26、无签名；开发者自己的签名配置保留在本目录build-profile.json5且不提交。

当前页面和素材直接保留已验收提交52b666d4，包括API检查时acquire/release配对修复。
vehicles、CLI、字体、状态机、事件、数据绑定和列表复用均为技术样例，不是正式MG_Club业务素材。
详细操作及结果边界见[验证说明](../../docs/VALIDATION.md)。
