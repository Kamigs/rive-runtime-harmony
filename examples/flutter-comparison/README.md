# Flutter Rive 对照

依赖精确锁定 `rive 0.14.11`、`rive_native 0.1.11`，锁文件保留归档校验值。素材与 ArkUI 宿主同字节，来源和 SHA 在 [素材清单](../../verification/fixtures-manifest.json)。

```bash
flutter pub get
flutter build web --release
python3 -m http.server 8765 --bind 127.0.0.1 --directory build/web
```

打开 `http://127.0.0.1:8765/`；查询参数 `fixture=rewards.riv` 等选择素材，`factory=rive`（默认）或 `factory=flutter` 选择后端。按钮验证暂停、恢复、bump、数字、文本和数据绑定。layout_test 按官方示例开启自动绑定、Fit.layout 和 scale 0.5。

历史迁移验收实际使用 Flutter 3.41.9+ohos-1.0.2 / Dart 3.11.5，验证平台是 Web。Factory.rive 加载官方包指定的 @rive-app/flutter-native-wasm@44.0.0，实际 WebGL2 经 ANGLE Metal 到 Apple M4 Pro；Factory.flutter 是 Flutter Web CanvasKit。此验证不能替代 Android/iOS 实机或证明 WASM 二进制与 runtime/ 逐字节同源。本轮只整理工程，未重复上述画面验收。

截图及后端记录在 MG_Club 的 `work/rive-validation/stage3/flutter/`。对照只判断已观察到的功能与画面，未做不同 DPI、色彩管理及采样时刻之间的逐像素等价断言。字体 OFL 随 assets/licenses 保留。


CLI技术样例 `runtime-contract.riv` 已与ArkUI rawfile按SHA同步，流程见 [CLI.md](../../docs/CLI.md)。历史记录中分析和Web Release构建完成，4条经典输入/文本API deprecated提示保留作为兼容调用记录；未执行新增样例的Flutter画面对照。通过 `?fixture=runtime-contract.riv&factory=rive` 选择。
