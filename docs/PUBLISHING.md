# 仓库托管与同步

两端仓库名均为 **rive-runtime-harmony**，ArkTS包名保持 **@ohos/rive**。本仓库使用独立`main`历史，不推送社区samples集合或原迁移仓库的其他分支。

| 远端 | 仓库 |
| --- | --- |
| GitHub | [Kamigs/rive-runtime-harmony](https://github.com/Kamigs/rive-runtime-harmony) |
| 本地Gitea | `kamigs/rive-runtime-harmony`，服务地址由本机配置指定 |

本地Gitea的内网URL保存在Git remote配置与工作区上传记录中，不作为其他机器的固定服务地址。

## 克隆与构建

```bash
git clone https://github.com/Kamigs/rive-runtime-harmony.git
cd rive-runtime-harmony
python3 scripts/restore-dependencies.py
bash scripts/setup-host-tools.sh
export DEVECO_CLI_STUDIO_PATH=/Applications/DevEco-Studio.app
bash scripts/build.sh release
bash scripts/build-example.sh
```

私有仓库需要具备访问权限。也可从本地Gitea仓库页面复制克隆地址。详细环境要求和签名步骤见 [BUILD](BUILD.md)。源码中保存已导出的CLI素材，普通构建不需要Rive登录。

## 双端同步

当前工作副本使用`gitea`和`github`两个remote。新克隆只有`origin`，可按实际来源重命名并增加另一端：

```bash
# 从GitHub克隆后执行；GITEA_BASE_URL应由开发者设置为自己的服务地址。
git remote rename origin github
git remote add gitea "${GITEA_BASE_URL}/kamigs/rive-runtime-harmony.git"
git push -u gitea main
git push github main
git rev-parse main
git ls-remote gitea refs/heads/main
git ls-remote github refs/heads/main
```

每端分别核对SHA，一端成功不等于另一端成功。遇到同名仓库或远端新增提交时，先查看差异，不使用强制推送覆盖远端工作。

## 内容边界

- Git包含库源码、runtime快照、八项依赖锁、ArkUI/Flutter/CLI示例、固定素材、构建脚本、接口清单、许可证和验收摘要。
- HAR/HAP、工具链、Git依赖检出、构建缓存与示例签名配置保留在本机。交付产物和校验值按[验证说明](VALIDATION.md)查找。
- 当前源码版本是`1.1.4-rn.0.1.11`，历史设备验收对应1.1.3；新包只完成独立构建与产物验证，尚未设备复验。
- 托管说明与`repository`元数据更新不改变运行时实现；已构建HAR的哈希保持原记录，不冒充由后续文档提交重建。

源码上传不自动创建版本标签、Release或发布OHPM。需要分发二进制时，随HAR提供许可证、源码提交及本次构建SHA256，签名HAP使用开发者自己的证书。
