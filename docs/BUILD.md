# 独立构建

从仓库根目录执行以下命令。当前支持 macOS ARM64 主机、HarmonyOS API26 Release SDK、arm64-v8a 目标；无须安装旧社区引擎子模块，也无须访问 MG_Club 的 `work/`。

## 工具和依赖

安装 DevEco Studio、devecocli、Python3、Git、Xcode Command Line Tools。SDK参考版本为 `26.0.0.105 Release`，参考IDE为 `26.0.0.865`。路径由环境变量指定，不修改系统SDK。

```bash
python3 scripts/restore-dependencies.py
bash scripts/setup-host-tools.sh
export DEVECO_CLI_STUDIO_PATH=/Applications/DevEco-Studio.app
python3 scripts/check-source.py
bash scripts/build.sh release
```

`dependencies.lock.json` 固定八个依赖提交。恢复脚本下载精确提交；如果现有检出提交不符或有已跟踪修改，则报错并保留现状。已有相同布局的源码检出可用 `--cache-root /absolute/source/root` 作为只读 Git 对象来源，仍按锁定 SHA 取源码，不复制其编译缓存。

Premake **5.0.0-beta7** 在首次构建时从锁定源码编译；Ninja Python发行版本 **1.11.1.3** 安装到 `.tools/`；PLY **3.11** 使用锁定源码。旧社区所需的 Premake beta2 不参与当前构建。shader由快照的构建流程生成。

| 变量 | 默认值 / 作用 |
| --- | --- |
| `DEVECO_CLI_STUDIO_PATH` | `/Applications/DevEco-Studio.app`，可选择并行安装的正式SDK |
| `OHOS_NDK` | 所选IDE的 `Contents/sdk/default/openharmony/native` |
| `RIVE_HOST_TOOLS` | 本仓库 `.tools/` |
| `RIVE_NINJA` | 工具目录下 `ninja-python/bin/ninja`；可覆盖为兼容宿主的Ninja绝对路径 |

`build.sh` 使用 devecocli 清理 Hvigor 包装层并构建库，使外置 `runtime/` 的变化进入 Premake/Ninja检查。SDK自带Ninja在ARM64主机的兼容处理仅对该构建进程生效。源码、依赖、shader生成与产物均不从旧项目读取。

HAR输出为 `dist/rive-harmony-1.1.4-rn.0.1.11-api26-release.har`，旁边生成 SHA256。原始输出在 `library/build/default/outputs/default/rive_ohos.har`。

## 独立HAR宿主

```bash
bash scripts/build-example.sh
# 或消费另一个明确指定的HAR：
bash scripts/build-example.sh --har /absolute/path/rive.har
```

脚本将实际HAR复制为 `examples/libs/rive.har`；示例 entry 依赖 `file:../../libs/rive.har`，没有库源码模块依赖。首次准备时从无签名模板创建 `examples/har-consumer/build-profile.json5`，不覆盖已有配置。

示例仅使用本地HAR，OHPM生成的entry锁文件含本机缓存目录标识，按次重新生成并忽略；实际依赖由构建HAR的SHA256及产物核查报告固定。第三方源码提交和Flutter外部包依赖分别保存在自己的锁文件中。

默认输出 `dist/rive-validation-1.1.4-rn.0.1.11-api26-release-unsigned.hap`。设备验收由开发者在示例工程配置自己的签名后，重新构建：

```bash
cd examples/har-consumer
devecocli build --modules entry --build-mode release
devecocli run --module entry --build-mode release --device DEVICE_SERIAL --skip-build
```

私钥、证书及本机签名配置不提交。安装先模拟器，后真机；构建成功不能替代画面和交互验证。

## 产物核查

```bash
python3 scripts/check-artifacts.py \
  dist/rive-harmony-1.1.4-rn.0.1.11-api26-release.har \
  dist/rive-validation-1.1.4-rn.0.1.11-api26-release-unsigned.hap \
  --report dist/artifact-audit.json
```

核对71个声明与OHPM1.0.4快照一致、HAP内原生库与HAR逐字一致、ARM64 ELF及许可证文件。`verification/audit-native-libs.py` 可另查重复原生库；`verification/test-tsfn-cleanup.py` 保留已有的隔离清理测试。

从新检出构建可以复验流程及接口/内容兼容，不保证不同SDK、路径和打包时间下HAR二进制哈希相同。每次交付保存本次SHA、工具版本和实际命令。
