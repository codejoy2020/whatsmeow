# whatsmeow fork 实施手册（可重复执行）

本文档用于你每次迭代时照单执行，减少遗漏。

## 0. 目标

在 `<ROOT_DIR>/whatsmeow` 维护 fork 改动，并让 `<ROOT_DIR>/WahaForge/gows/src` 使用最新联调版本。

---

## 1. 进入仓库并检查当前状态

```bash
export ROOT_DIR=/path/to/your/workspace-root
cd "$ROOT_DIR/whatsmeow"
git status -sb
git branch --show-current
```

检查点：

- 当前在你预期分支上（建议 feature 分支）
- 工作区没有意外脏改动（或你明确知道这些改动是什么）

---

## 2. 同步上游

```bash
./scripts/sync-upstream.sh
```

可选（覆盖上游地址/分支）：

```bash
UPSTREAM_URL=https://github.com/tulir/whatsmeow.git UPSTREAM_BRANCH=main ./scripts/sync-upstream.sh
```

检查点：

- 命令成功结束
- 若出现冲突，先手工解决冲突，再继续后续步骤

---

## 3. 修改代码（手工或 AI）

你可以把下面 prompt 直接给 AI（先把 `<ROOT_DIR>` 替换成你的实际目录）：

```text
你在本机仓库 <ROOT_DIR>/whatsmeow 中工作。

目标：
配对码流程始终只生成固定调试码 11119999（展示为 1111-9999）。不要环境变量或运行时开关；不要保留“随机配对码”分支。

必须遵守：
1) 不要修改 go.mod 的 module 路径，必须保持 go.mau.fi/whatsmeow。
2) 优先修改 pair-code.go 及配对码相关最小范围代码，不做无关重构。
3) 在 init（或等价路径）校验常量长度与字符集，非法常量应快速失败（如 panic）。
4) 代码注释保持简洁，只解释 fork 特有行为。
5) 修改完成后必须运行并汇报：<ROOT_DIR>/whatsmeow/scripts/test-local.sh
6) 不要求评估或改动 <ROOT_DIR>/WahaForge/gows/src/server/session.go。

实现要求：
- generateCompanionEphemeralKey（或等价逻辑）始终使用 11119999，不再随机生成 8 位 linking 码。
- 输出变更文件、关键逻辑、测试命令与结果。
```

检查点：

- 改动集中在预期文件（通常 `pair-code.go`）
- 没有误改 `go.mod` 的 module 行

---

## 4. 本地测试

```bash
./scripts/test-local.sh
```

检查点：

- `go test ./...` 通过
- 若失败，先修复再继续，不要带红测推送

---

## 5. 查看差异并提交本地改动

```bash
git status -sb
git diff
git add .
git commit -m "feat: always use fixed debug pairing code 11119999"
```

检查点：

- commit 内容仅包含本次改动
- commit message 清晰表达目的

---

## 6. 推送到你的 fork

```bash
./scripts/push-fork.sh
```

可选（远程名不是 origin）：

```bash
ORIGIN_REMOTE=myorigin ./scripts/push-fork.sh
```

检查点：

- 推送成功
- GitHub 上可看到这次 commit

---

## 7. 同步 gows 使用本地 fork（replace）

```bash
./scripts/bump-gows-replace.sh
```

可选（路径覆盖）：

```bash
WHATSMMEOW_ROOT="$ROOT_DIR/whatsmeow" WAHA_FORGE_ROOT="$ROOT_DIR/WahaForge" ./scripts/bump-gows-replace.sh
```

检查点：

- 脚本成功执行
- `"$ROOT_DIR/WahaForge/gows/src/go.mod"` 已更新 replace

---

## 8. 在 gows 侧编译验证

```bash
cd "$ROOT_DIR/WahaForge/gows/src"
go build ./...
```

检查点：

- 构建通过
- 若失败，回看 gows 调用侧是否需要适配（如 `session.go`）

---

## 9. 一条龙命令（常用）

```bash
export ROOT_DIR=/path/to/your/workspace-root
cd "$ROOT_DIR/whatsmeow"
./scripts/sync-upstream.sh
# 这里改代码（手工或 AI）
./scripts/test-local.sh
./scripts/push-fork.sh
./scripts/bump-gows-replace.sh
cd "$ROOT_DIR/WahaForge/gows/src" && go build ./...
```

---

## 10. 回滚/清理（可选）

如果你只是临时联调，不想保留 gows 的 replace 改动：

```bash
cd "$ROOT_DIR/WahaForge"
git checkout -- gows/src/go.mod gows/src/go.sum
```

注意：执行前先确认这两个文件没有你要保留的其它改动。
