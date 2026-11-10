> 历史记录：提取自移植仓库提交 `52b666d4`。其中路径、包版本和阶段结论仅适用于原仓库；当前构建见 [BUILD](../BUILD.md)，验收边界见 [VALIDATION](../VALIDATION.md)。

# API26 真机验收与宿主修复

2026-11-10，`@ohos/rive 1.1.3-rn.0.1.11` 在 Mate70Pro+ / API26 Release / arm64-v8a 完成示例素材技术验收。完整原始证据在 MG_Club 工作区 `work/rive-validation/completion/device-1.1.3/README.md`。

## 两个HAP批次

HAR不变，SHA-256为 `50d1f06f72c484ff6bd0609801df0d01cd1c291e4ccf6139ddc90c0366d36a65`；核心、Node-API、71份公开声明均未修改。

| HAP | 证据范围 |
| --- | --- |
| 原交付 `c35411582137308eab573d0772dca71a62a17deb2b119f2d5b57253a61da181a`，versionCode1010300 | 与此前模拟器相同包的真机全量矩阵：CLI、两后端输入/事件/中文、生命周期、列表、多实例、官方专项、100启停、20重建、10冷启动、683秒播放、性能与GC。API检查后字节重载发现下述宿主错误，不判通过。 |
| 修复宿主 `d44c88069693321aa5c3a27e5ee2b028c8800bf6572040fb5e3d7edf6faa73dc`，versionCode1010301 | 先模拟器再真机，同一修复包在两后端各执行3次API检查→字节重载，再测暂停/恢复/重建，全部通过。117份rawfile及两份原生库与原包相同。未宣称新HAP重新跑过整套10分钟矩阵。 |

推荐使用 `rive-validation-1.1.3-rn.0.1.11-sdk26-release-hostfix-signed.hap`。HAR本身无需更换版本。SDK为26.0.0.105 Release；模拟器OS仍为26.0.0.32 Beta2，真机为OpenHarmony-7.0.0.111 / API26 Release。

## 已修复的问题

验收宿主 `Index.ets::checkApi` 从 `artboard.animation()` 取得由Artboard持有的依赖后，直接调用 `release()`。稍后 `setRiveBytes()` 释放旧File/Artboard时再次释放同一动画，报 `Reference count already zero: LinearAnimationInstance`，导致画布空白。

社区基线和当前库的Artboard均持有该返回对象的初始引用。宿主现在先 `acquire()` 临时持有，再在 `finally` 中 `release()`；实际日志为 `retained=2 remaining=1`。未通过改变引用计数器、忽略错误或修改核心来掩盖问题。

原模拟器 `specials/api/03-bytes.png` 也为空白，旧报告对此项的通过结论已撤回并更正。方法调用日志不是可见画面的证明。新增回归同时检查引用配对、重载后的onReady、错误日志、每次重载的非空画布，以及暂停/恢复像素变化。

```bash
# 已按API26.md构建并安装修复HAP后，使用新的绝对证据目录。
bash verification/capture-api-reload.sh 127.0.0.1:5555 /absolute/path/reload-emulator
bash verification/capture-api-reload.sh DEVICE_SERIAL /absolute/path/reload-device
```

## 主要真机结果

- 非激活停帧：Canvas6.369秒、GLES6.188秒均0帧；关闭门控对照约59.32帧/秒。列表离屏实例计数保持12.702秒；TSFN6/6释放。
- 100次启停前后native/UI vsync比例1.000/0.997；销毁后6.208秒0帧。
- 双实例退出后Graph30032→0KiB、GL48292→6000KiB；重建恢复。保留的GL缓存不等于泄漏。
- 两后端各120张连续截图无空白，车辆像素均存在；CLI和车辆trigger另有24张连续采样。截图采样不覆盖每次屏幕刷新。
- 中文由6个缺字占位变为“会员积分奖励”，沿用显式Rive字体fallback。
- vehicles的Rive::frame P95：Canvas39.256ms、GLES10.688ms；该片段包含等待，不是GPU执行时间。Canvas不承诺稳定60FPS。
- 同一PID连续683秒，advance675→44944；11个画面均可见。销毁/GC后PSS46942KiB，重建/GC91793KiB，再播放一分钟/GC90920KiB。未发现应用崩溃记录；有界采样不是长期无泄漏或电耗结论。

支持范围为API26；采用官方与CLI技术样例。正式素材、Flutter新增CLI样例视觉对照、完整VM故障注入、长期电耗和商店发布不包含在此次通过结论中。宿主部分白字浅底标签对比不足另有记录，未与Rive画布内容混为一谈。
