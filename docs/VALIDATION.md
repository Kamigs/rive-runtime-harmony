# 验证范围

## 整理版 1.1.4-rn.0.1.11

本轮验证独立目录、全新构建及HAR消费链路。记录位于MG_Club工作区`work/rive-validation/2026-11-10-standalone/`。已用SDK26.0.0.105 Release从新提取目录构建HAR及独立未签名Release HAP，均通过。

- 71份声明与OHPM1.0.4快照一致，无增删改。
- HAP消费HAR内的两份arm64-v8a原生库，逐字节一致；重复.so扫描为0组。
- 首轮重建的两份.so也与已验收1.1.3 HAR逐字节一致；此证据不替代新包元数据和安装验证。
- HAR内10份运行时/链接依赖许可证与说明保留，SDK/LLVM声明随源码licenses目录保存。
- HAR元数据`compatibleSdkVersion=26`，组件实现与核心保留。
- 初次HAR SHA256：`a17db3d6d026df51b1b721322a19fbb9421f9bd4c8b40acb8b07de7079e53347`。
- 初次未签名HAP SHA256：`355566d9116dadec13a47e0b5f5ee74532b10416c3ed802f3d8c31601da53b26`。

编译保留既有deprecated/异常处理提示；Hvigor仍对带`rn.0.1.11`的版本标识给出版本格式警告，本地HAR解析和HAP构建通过。未执行OHPM发布校验，未来发布前需另核对注册表版本规则。

干净Git检出提交`ff5bf866f0dade27dc686bf42a96ad8fb360e90f`后，重新恢复八项锁定依赖并全量构建HAR、独立HAP，均通过；构建后检出无已跟踪改动。复用同一主机SDK/Ninja和只读Git对象缓存，未复用项目编译对象，不能等同于另一台机器验收。71声明、HAR/HAP原生库及许可核查再次通过。

最终交付采用干净检出的产物：

| 产物 | SHA256 |
| --- | --- |
| Release HAR | `818ca436d7c083b2d1b40c0bdb8c6bedb3f469b94ee426e9dbd83411b1daa96c` |
| 未签名Release HAP | `f6572efef51d9871dfcdd3f12317455785de48d580f20d15526b5b949c6a19d2` |

两次构建及历史1.1.3的原生库逐字节相同；HAR/HAP整体哈希因打包内容/元数据不同而分别登记，不承诺容器字节可重复。最终源码在上述构建提交基础上仅补充文档与历史接口清单的范围说明。

核心/渲染器、ArkTS实现、Node-API绑定和示例素材按提取清单与`52b666d4`逐文件核对。CLI工程在新目录通过verify/inspect约定检查，未重新导出或发布素材。

本轮未安装新包或重新执行设备用例。新包版本、API26最低版本元数据和打包结果不自动继承旧包的安装结论。

## 历史 1.1.3 设备证据

原HAR SHA256：`50d1f06f72c484ff6bd0609801df0d01cd1c291e4ccf6139ddc90c0366d36a65`。

- SDK26.0.0.105 Release构建；先Mate90ProMax ARM64模拟器（OS26.0.0.32 Beta2），后Mate70Pro+（API26 Release）。
- 两后端加载、播放、输入/事件、中文、暂停/恢复、列表/页面生命周期和多实例有证据。
- 原HAP完成100次启停、20次重建、10次冷启动及683秒持续播放采样。
- 原宿主API检查提前释放Artboard持有的动画，后续字节重载为空。修复后同一新HAP在两环境、两后端各3次重载及暂停/恢复/重建通过；该新HAP没有再次执行完整长时矩阵。

两批HAP及更正详见[历史真机与修复说明](history/DEVICE26.md)。完整原始日志、截图与性能在原工作区`work/rive-validation/completion/device-1.1.3/`，未复制进源码或改写其哈希。

## 后续设备回归

使用整理版签名HAP，先模拟器后Mate70Pro+。同一素材固定同一后端，至少复跑：vehicles/CLI首帧和交互、API检查→字节重载、暂停恢复、页面退出重进、列表非激活停帧和恢复。通过后再登记整理版设备结论。

`verification/capture-api-reload.sh DEVICE_SERIAL /absolute/evidence/path`等采集入口保留。构建、安装、可见画面、交互分别判定，所有同设备UI采集串行执行。

## 保留的边界

支持范围仅API26/arm64-v8a，正式素材尚未提供。新增CLI素材的Flutter实际画面对照、Android/iOS设备覆盖、完整VM异常销毁故障注入、长期电耗及商店发布尚未由当前记录证明。有限内存/GC采样不构成长期无泄漏证明。目录整理不扩大原验收范围。
