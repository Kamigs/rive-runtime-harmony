# ArkTS 兼容基线

版本依据为 OHPM `@ohos/rive 1.0.4` 的发布 HAR，SHA-256 为 `dd9d286869a702340941e60f57480909518dd885e15fad03395032d1c32851ec`。完整参数、返回类型、回调及枚举见 [发布声明清单](published-api.md)，逐文件原始声明和哈希见 [机器可读快照](published-api.json)。共 71 个声明文件、50 组包根导出，包含发布包公开的测试函数；不擅自删除这些导出。

## 声明与打包结果

最终迁移 HAR `1.1.0-rn.0.1.11` 与发布 HAR 的 71 个 `.d.ets` 文件逐字一致（仅统一 CRLF），没有增加、删除或修改声明。包根导出仍为 50 组；Node-API 导出表与 `libohos_rive/Index.d.ts` 也未修改。原生库是 ARM64，独立宿主消费的 `.so` 与 HAR 内相同。可用 `verification/audit-artifacts.py` 重复核对；实际结果见 `work/rive-validation/stage3/final-audit.json`。

下表区分接口冻结与行为验收。阶段 2 Canvas 和阶段 3 Release 的已列用例均分别在模拟器及 Mate 70 Pro+ 留证；未专项验证的组合明确保留，不由声明一致推导行为通过。

## 核心范围与行为证据

| 接口范围 | 需要保持的契约 | 当前验证 |
| --- | --- | --- |
| `RiveAnimationView` 参数 | `riveResource`、`riveUrl`、画板/动画/状态机名、自动播放、自动绑定、Fit、Alignment、Loop、rendererType、自定义 renderer、资产加载器、触控参数 | rawfile、画板切换、contain/layout、autoplay、autoBind、onReady、自定义字体 loader 已使用；双环境 Canvas/GLES 均可见 |
| 资源加载 | `setRiveResource(number|string, …): void`、`setRiveBytes(ArrayBuffer, …): void`、`setRiveFile(File, …): void`、`setAssetLoader(FileAssetLoader|null): void`、`getFile(): File|null` | rawfile、setRiveBytes、setRiveFile、字体 Asset.decode 双环境通过；网络 URL/CDN 与数字资源 ID 未做专项 |
| 播放控制 | `play`/`playAnimations`、`pause`/单个/多个、`stop`/单个/多个、`reset`，均返回 void；播放查询保留数组/Set/boolean 类型 | 双环境基础循环/暂停/恢复通过；Release 双环境 playAnimations、pauseAnimations、stopAnimation、stop/reset/setRiveFile 通过 |
| 状态机输入 | `fireState`、`setBooleanState`、`setNumberState`、对应 `AtPath` 方法、`setMultipleStates`；SMIInput 与三类子类接口保持 | Truck/bumpy/bump 双环境通过；Release 双环境 Jeep/weather/Raining=1、skills/Level=2 有日志及画面响应；AtPath/批量输入未专项 |
| 控制器回调 | `notifyPlay/Pause/Stop/Loop(PlayableInstance): void`，`notifyStateChanged(string,string): void`，可选 `notifyAdvance(number): void` | Play/Pause/Stop/StateChanged/Advance 有日志；Advance 帧间隔仅作节奏指标，不能冒充绘制耗时；独立 Loop 回调未专项 |
| Rive 事件 | `addEventListener`/`removeEventListener`，`notifyEvent(RiveEvent): void`，General/OpenURL/Report 类型 | 双环境 rating 返回 Star/type=128/{rating:3}；url_event_button 返回 OpenRiveURL/type=131；退出时移除监听 |
| 文本、音量、数据绑定 | 文本读写及路径、音量 nullable、ViewModel/Instance/Property、BindableArtboard、Font/Asset 类型 | 双环境 HOME→MG CLUB；rewards Energy 50→90、Button/State_1→MG CLUB；Inter/JetBrains 字体解码通过；音频/音量未专项 |
| 生命周期 | initializeRive、onReady、XComponent surface 生命周期、退出释放、前后台恢复、多实例 | 双环境双实例、前后台、20 次销毁重建、真实页面替换/返回通过；退出后 Advance 计数不变，独立 native trace 无 Rive 绘制；真机 GL/Graph 随销毁下降，Graph 归零 |

## 默认行为

发布 `.d.ets` 不包含全部默认值。下表读取独立源码基线 `4b1609b2bdbf34e46ec37155f8aa5cc9a3612b2f` 的 `RiveAnimationView.ets` / `RendererAttributes.ets`，是兼容目标的源码依据，不能据此证明发布二进制与该提交完全一致。

| 参数 | 源码默认值 |
| --- | --- |
| riveResource / riveUrl / riveArtboard / riveAnimation / riveStateMachine | 空字符串 |
| riveLoop / riveFit / alignmentIndex | Loop.AUTO / contain / Alignment.CENTER |
| rendererType | RendererType.Rive；阶段 0 显式选择 Canvas |
| riveAutoPlay / shouldLoadCDNAssets | true / true；宿主显式关闭 CDN 资产 |
| riveAutoBind / riveTraceAnimations / touchPassThrough / multiTouchEnabled | false |
| play / playAnimations | Loop.AUTO、Direction.AUTO、isStateMachine/areStateMachines=false、settleInitialState=true |
| pauseAnimation / stopAnimation 及多个版本 | isStateMachine/areStateMachines=false |

发布 HAR 的 `onReady` 在文件就绪前后均可能调用：宿主先检查 `getFile()` 和活动画板，再登记加载成功；首帧另外由截图核实。`pause()` 令运行停止，`play()` 恢复，已用相隔两秒截图及运行日志验证。发布、社区修复及移植三条基线的基础用例分别保留。

## 已知边界与行为变化

- 最低 API 声明仍是 12；实际构建和运行验证为 API 26，未声称在 API 12 设备通过。当前交付只有 arm64-v8a。
- Canvas 使用 OH_Drawing，不完整支持 rewards 的柔化阴影；Rive GLES 能显示对应效果。需要这些效果的调用方应保留 `RendererType.Rive`。默认 renderer 未改成 Canvas。
- 修复了 Canvas consumer fence 造成的整幅画面频闪，以及 Fit.layout 首帧读取无效 Surface 尺寸的问题；ArkTS 参数不变。
- 新核心内部时间推进、布局计算和音频生命周期使用官方快照。实测 1.0.4 将 `settime(-1)` / `settime(999999)` 限制为 0 / 2 秒；迁移初版为 -1 / 999999。最终版已在绑定层恢复 0 / 2，双环境回归通过，核心 `src/` 不变。该素材 `geteffectiveDurationInSeconds()` 在 1.0.4 与最终版均返回 0，这是既有查询行为，本次未修改。
- 正式素材未提供。音频、中文字形、网络/CDN 资产、嵌套输入路径、全部 ViewModel 属性类型、自定义 renderer、特殊混合/裁剪组合和各 Loop/Direction 模式仍须按项目实际使用补验。声明一致不等于这些组合均已动态验证。

最低 API、ABI、声明差异及行为结果在各阶段报告补充；本文件不会将“已保留声明”记作“全部行为通过”。
