> 历史记录：提取自移植仓库提交 `52b666d4`。其中路径、包版本和阶段结论仅适用于原仓库；当前构建见 [BUILD](../BUILD.md)，验收边界见 [VALIDATION](../VALIDATION.md)。

# Rive CLI 与鸿蒙运行时

CLI 负责将 RML 编译、签名导出成 `.riv`；ArkUI 宿主通过 `@ohos/rive` HAR 加载这份文件。两者通过素材及交互约定配合，无需把 CLI 安装到鸿蒙设备，也不需要改变 Node-API 或 ArkTS 公开接口。

本次使用 Rive CLI **1.9.2**、`@ohos/rive 1.1.3-rn.0.1.11`、C++ 快照 `rive_native 0.1.11`。Flutter 对照工程继续锁定 `rive 0.14.11 + rive_native 0.1.11`。CLI样例已在鸿蒙模拟器和Mate70Pro+真机的两后端验收；Flutter仅完成分析和Web Release构建。后续发现并修复的验收宿主引用问题及两个HAP批次见 [DEVICE26.md](DEVICE26.md)。

## 已提供的技术样例

源码在 [cli-projects/runtime-contract](cli-projects/runtime-contract/)，导出记录在 [cli-fixture-manifest.json](cli-fixture-manifest.json)。用户确认没有正式业务素材，本样例用于技术验收。

| 对象 | 名称 / 行为 |
| --- | --- |
| 画板 | `CLI Contract`，400 × 240 |
| 状态机 | `bumpy` |
| trigger | `bump`：卡片上跳后返回；进入 Bounce 发出事件 |
| boolean | `enabled`：灰蓝 / 绿色切换 |
| number | `Level`：小于2时原宽，至少2时宽度变为1.5倍 |
| 事件 | `cli_bump`，使用既有 `RiveEventListener` 接收 |
| 文本 | `button_text`，初始 `MG CLUB`；宿主可改成中文 |
| 连续动画 | 黄色标记来回移动；用于判断暂停与恢复 |
| 字体 | 内嵌 Inter；中文沿用宿主显式 Noto Sans CJK SC 回退，OFL 保留于资源许可证目录 |

这份样例刻意覆盖现有71份声明中的经典输入 API。CLI 文档和 Flutter 运行时将它们标为 deprecated，但本迁移继续保留；数据绑定另外由官方 `rewards.riv`、`layout_test.riv` 验收。脚本、3D和未覆盖的新对象需要各自的目标运行时用例，不能由本样例外推兼容。

实际 `.riv` 为418028字节，格式头7.5；SHA-256：

```text
4bb57f3d12969f90ddc67799f62e3f408b8bc7a7db3f8a30c02edcd76d755ee4
```

目标核心检查主格式版本7。主版本一致只是加载前检查；本次还实际验证了画面、输入、事件和文本。发布服务在导出文件中附带 `NuRiveWordmark01`、`NuRiveBrandmark01` 画板，文件按导出原样保留，宿主选用 `CLI Contract`。

## 重新导出与同步

在 `modules/rive-harmony/` 执行，输出目录使用绝对路径：

```bash
# 离线检查，不导出文件，不需要登录。
python3 verification/cli-fixture.py --evidence /absolute/path/cli-check

# 首次由开发者在终端完成账号授权。
rive login

# 编译、核对约定、本地签名导出，并复制同字节资源到两个宿主。
python3 verification/cli-fixture.py \
  --evidence /absolute/path/cli-export --publish-local
```

本地发布需要账号及发布额度；脚本不会使用 `push` 或 `--publish=web`。发布服务可能改变签名或附加元数据，重新导出不保证二进制哈希重复，因此每次保存CLI版本、RML/YAML/字体哈希、导出哈希，并在目标运行时复验。已交付 `.riv` 可离线构建消费，无需用户登录。

已有从同一 RML 导出的签名文件，可以用 `--exported /absolute/path/runtime-contract.riv` 代替 `--publish-local`。此选项记录调用者提供的导出文件，不会从文件头推断它和当前 RML 同源，也不会证明其全部功能受旧核心支持；必须核对导出记录并执行验收。`--verify` 和 `inspect` 核查的是CLI工程，目标文件行为由设备测试核查。

同步位置：

- `har-consumer/entry/src/main/resources/rawfile/runtime-contract.riv`
- `flutter-comparison/assets/runtime-contract.riv`

两份资源与导出文件的 SHA 必须相同。字体许可来源继续使用 [fixtures-manifest.json](fixtures-manifest.json) 和两个宿主的 `licenses/`，不把生成的 `.riv` 当作字体许可的替代品。

## 构建和验收

HAR与宿主构建命令见 [API26.md](API26.md)。安装新HAP后，在Rive仓库根目录执行：

```bash
bash verification/capture-cli.sh 127.0.0.1:5555 /absolute/path/cli-rive rive
bash verification/capture-cli.sh 127.0.0.1:5555 /absolute/path/cli-canvas canvas
```

脚本校验按本次PID过滤的文件加载、trigger/boolean/number、事件和文本日志，并保存13个画面检查点及24张trigger连续采样。持续日志避免真机共享缓冲区提前滚出事件。还需核对灰蓝/绿色、宽度、中文、暂停静止、恢复和重建画面；不能只凭日志宣称画面正确。所有同一设备的 UI 脚本串行执行。

Flutter 宿主可用 `?fixture=runtime-contract.riv&factory=rive` 加载同一文件，提供 bump、Level 2、Enabled、Edit text、Pause/Resume。当前只完成构建，后续画面对照仍使用固定依赖、同一文件和明确记录的后端。

官方文档：[CLI概览](https://rive.app/docs/cli/overview)、[本地导出与签名](https://rive.app/docs/cli/publishing)。本次具体语法依据安装的1.9.2文档（`rive docs --path`）、`rive schema`和实际编译结果。
