# CLI素材与Flutter对照

CLI将RML编译、签名导出成`.riv`，鸿蒙HAR和Flutter通过同一素材及交互约定配合。设备内无需安装CLI。固定版本为CLI **1.9.2**、Flutter **rive 0.14.11 + rive_native 0.1.11**；核心升级另行评估。

RML工程位于`examples/cli-projects/runtime-contract/`，已签名的`.riv`分别位于两个宿主资产目录，SHA256：

```text
4bb57f3d12969f90ddc67799f62e3f408b8bc7a7db3f8a30c02edcd76d755ee4
```

画板`CLI Contract`、状态机`bumpy`、trigger`bump`、boolean`enabled`、number`Level`、事件`cli_bump`、文本`button_text`。`Level >= 2`时宽度为原来的1.5倍。详细来源见`verification/cli-fixture-manifest.json`；清单内相对资产路径以`examples/`为根。

```bash
# 检查项目及约定，不登录、不导出、不上传。
python3 verification/cli-fixture.py --evidence /absolute/path/cli-check

# 需要重新导出时，由开发者先在终端登录，再显式选择本地签名导出。
rive login
python3 verification/cli-fixture.py --evidence /absolute/path/cli-export --publish-local
```

`--publish-local`需要账号与额度，会同步两宿主资产，不发布网页。普通HAR/HAP构建直接使用已保存素材，无须再次执行。新导出的签名/附加信息可能不同，每次记录哈希并重新验证目标运行时；导出成功和格式主版本一致都不能替代实际播放验证。

Flutter工程位于`examples/flutter-comparison/`，保留依赖锁。运行时用`?fixture=runtime-contract.riv&factory=rive`选择本样例。历史记录中该CLI素材在鸿蒙两后端、模拟器/真机通过，Flutter仅完成分析和Web Release构建，尚缺实际画面对照。目录整理不会改变这个验收边界。

官方来源：[CLI概览](https://rive.app/docs/cli/overview)、[发布与签名](https://rive.app/docs/cli/publishing)。
