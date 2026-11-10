> 历史记录：提取自移植仓库提交 `52b666d4`。其中路径、包版本和阶段结论仅适用于原仓库；当前构建见 [BUILD](../BUILD.md)，验收边界见 [VALIDATION](../VALIDATION.md)。

# API26 交付与复现

当前版本 `@ohos/rive 1.1.3-rn.0.1.11`。用户于2026-11-10明确将支持及验收范围收敛到 **API26**，不再要求低版本兼容；正式业务素材缺席，本轮采用官方专项素材和CLI技术样例，先完成模拟器验证，随后按用户授权完成Mate70Pro+真机补验；宿主引用配对修复另外做了先模拟器、后真机的定向回归，见 [真机结果与修复](DEVICE26.md)。

历史API12–26研究和1.1.2真机结果保存在 [API12-26.md](API12-26.md)。已有包的 `compatibleSdkVersion=5.0.0(12)` 元数据沿用，未作为API12–24支持承诺；本轮不补旧系统设备或镜像。当前源码继续保留旧钩子示例便于对照，无旧系统验收结论。

## 本轮增量

- 接通 [CLI导出、素材约定与双宿主同步](CLI.md)，保留导出版本、格式和校验值。
- 修正 `renderer.cpp::TSFNCallback` 的空环境清理：释放队列数据；销毁消息完成通知以解除worker等待；不调用JS，也不访问可能失效的renderer context或执行帧任务中捕获的WorkerImpl回调。
- 增加实际回调函数体的ASan/UBSan测试、CLI设备验收脚本和有界稳定性采样脚本。
- 保持rive_native 0.1.11核心、71份ArkTS声明、根导出与现有Node-API注册不变。新增行为位于平台绑定层及独立验收宿主。

TSFN空环境问题依据 [Node-API回调契约](https://nodejs.org/api/n-api.html#napi_threadsafe_function_call_js) 和 [OpenHarmony清理队列实现](https://github.com/openharmony/arkui_napi/blob/master/native_engine/native_safe_async_work.cpp)。它不是API26新增签名变更。旧函数在隔离测试中保留队列数据，修正后8种空环境/空回调组合以及正常、过期帧、销毁分支通过；这不等于已在完整Harmony VM退出时复现。模拟器进程重启和页面销毁结果另行记录。

迁移基础与补丁用途见 [MIGRATION.md](MIGRATION.md)，API26绑定层累计差异保存在 `patches/harmony-api26-bindings.patch`。`WaitDisposeDependencies`的正常JS依赖释放顺序保持不变，没有加入超时后直接删除对象的逻辑。

## 构建

本次：macOS ARM64、DevEco26.0.0.865、SDK **26.0.0.105 Release**。当前本地模拟器是Mate 90 Pro Max、ARM64、系统 **26.0.0.32 Beta2**；正式SDK构建与模拟器OS版本分别记录，不能称为Release OS模拟器通过。1.1.3的Mate70Pro+ Release记录已独立补齐；原HAP全量矩阵与修复宿主HAP定向回归按哈希分别记录。

在 `modules/rive-harmony/`：

```bash
python3 verification/restore-community-dependencies.py verification/native-0.1.11-dependencies.lock.json
bash verification/setup-host-tools.sh
export DEVECO_CLI_STUDIO_PATH=/private/tmp/spine-deveco-release/DevEco-Studio.app
export OHOS_NDK="$DEVECO_CLI_STUDIO_PATH/Contents/sdk/default/openharmony/native"
test -f ohos_rive/build-profile.json5 || cp verification/community-build-profile.template.json5 ohos_rive/build-profile.json5
python3 verification/test-tsfn-cleanup.py
bash verification/build-har.sh release
mkdir -p ../../work/rive-validation/completion/artifacts
cp ohos_rive/library/build/default/outputs/default/rive_ohos.har \
  ../../work/rive-validation/completion/artifacts/rive-harmony-1.1.3-rn.0.1.11-sdk26-release.har
cd verification/har-consumer
test -f build-profile.json5 || cp build-profile.template.json5 build-profile.json5
# 新工作区由开发者配置自己的签名；现有本机签名直接复用。
"$DEVECO_CLI_STUDIO_PATH/Contents/tools/ohpm/bin/ohpm" install --all
devecocli build --modules entry --build-mode release
devecocli run --module entry --build-mode release --device 127.0.0.1:5555 --skip-build
```

换机器时将IDE变量替换为已安装的Release SDK路径；签名配置及私钥不随源码交付。CLI导出文件已入源码，可离线消费，不要求重新登录或发布。

产物目录（本工作区绝对路径）：

```text
/Users/kamigs/Workspace/Dev/Project/mg-club/work/rive-validation/completion/artifacts/
```

HAR、签名HAP、源码归档、SHA256SUMS和实际证据在该目录上一级的 `README.md` 与 `manifest.json`。宿主HAP的原生库必须与HAR字节一致；使用 `audit-artifacts.py`、`audit-native-libs.py` 重复检查。

## 验收顺序及边界

1. 模拟器：CLI两后端、vehicles基础与连续帧、API26回收池/列表、100次启停、门控开关对照、中文字体冷启动A/B。
2. 模拟器：官方输入/事件/文本/数据绑定/布局/渲染专项、多实例、页面退出重进、20次组件重建、10次进程冷启动。
3. 模拟器：同素材同后端HiTrace首帧观测/P95/内存，10分钟连续播放及销毁后资源采样。P95为包含等待的帧片段墙钟时间，不是GPU耗时；模拟器不用于真机电耗结论。
4. 已用原同一HAP在Mate70Pro+复跑。真机发现验收宿主API检查提前释放Artboard持有的动画，已修正；新HAP在模拟器和真机两后端各重复3次字节重载并复验暂停/恢复/重建。HAR不变，新HAP哈希及两批范围见 [DEVICE26.md](DEVICE26.md)。

正式MG_Club素材、Flutter新增CLI样例的画面对照、完整VM异常退出故障注入、长时实机电耗与商店发布不属于本轮已通过的证明范围。技术样例通过后，正式素材仍需独立列出其画板、输入、事件、字体和性能预算。
