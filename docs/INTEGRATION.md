# ArkUI 接入

包名保持 `@ohos/rive`。当前整理版支持API26及arm64-v8a，最低API元数据已从历史包的12调整为26。正式工程需配置对应SDK和ABI；不要将历史最低版本字段视为旧系统支持承诺。

## HAR和素材

构建步骤见 [BUILD](BUILD.md)。将HAR复制到应用根目录 `libs/rive.har`，在entry依赖中加入：

```json
{
  "dependencies": {
    "@ohos/rive": "file:../libs/rive.har"
  }
}
```

`.riv`放入entry的`src/main/resources/rawfile/`。使用 `riveResource: '@rawfile/vehicles.riv'`，其画板为`Truck`、状态机`bumpy`、输入`bump`（trigger）。可运行的完整接入位于 [独立示例](../examples/har-consumer/entry/src/main/ets/pages/Index.ets)。示例本身HAR路径为`file:../../libs/rive.har`，因为其libs位于examples目录。

## 就绪、输入、播放和事件

- `onReady(view)`可能在文件尚未就绪时进入，先检查`view.getFile()`和`view.controller?.activeArtboard`再读取输入；可见首帧需另外判断。
- `view.fireState('bumpy', 'bump')`触发输入，`setBooleanState`、`setNumberState`用于对应输入类型。
- `view.pause()`暂停；`view.play()`恢复。不要在列表重新激活时无条件覆盖用户主动暂停状态。
- `addEventListener`接收事件，组件退出时移除监听；同一个监听器避免重复注册。完整回调签名见[冻结声明](../verification/api/published-api.md)。

## 生命周期和所有权

优先让`RiveAnimationView`管理File、Artboard和渲染器生命周期。现有库已包含可见性/前后台停帧及恢复适配，复用示例在 [Lifecycle.ets](../examples/har-consumer/entry/src/main/ets/pages/Lifecycle.ets)。不额外启动独立定时器驱动同一实例。

直接使用低层对象时，区分借用与自己持有的引用。例如`artboard.animation(...)`返回的初始引用由Artboard持有，不能直接消耗该引用：

```typescript
const animation = artboard.animation(artboard.animationNames[0]);
animation.acquire();
try {
  // 临时持有期间执行需要的操作。
} finally {
  animation.release();
}
```

这是原验收宿主字节重载问题的修复方式，其他对象仍须按各自接口和所有权处理，不能机械地对所有getter调用release。跨异步操作和页面销毁时，避免继续访问已释放的view、file或artboard。[具体修复](history/DEVICE26.md)

## 后端和中文字体

`RendererType.Rive`为GLES/EGL后端，也是组件原默认值；`RendererType.Canvas`为OH_Drawing/NativeWindow后端。柔化阴影等特效应按实际素材选择Rive后端，Canvas不保证完全相同的视觉效果。一次对照固定后端，不把后端切换误记为版本性能变化。

中文缺字使用现有`RiveManager.getInstance().setFallbackFont(context, bytes)`显式注册可覆盖目标字符的字体，参考示例中的`cjkFallback`。该流程属于Rive字体链路，不声称由ArkGraphics字体路径API完成shaping。Noto完整示例字体较大，业务素材确定后再按授权及所需字符评估子集化。

## 兼容边界

71份`.d.ets`、包根导出、Node-API保持；接口保留不等于所有素材组合均已动态验收。音频、网络/CDN资产、复杂嵌套输入及特殊效果应按应用实际使用补验。正式MG_Club素材尚未提供，本仓库内素材是技术样例。
