# whatsmeow fork 维护流程

本文档约定在 `<ROOT_DIR>/whatsmeow` 维护你的 fork，并在 `<ROOT_DIR>/WahaForge/gows/src` 更新依赖验证联调。

## 目录与仓库约定

- fork 本地路径：`<ROOT_DIR>/whatsmeow`
- WahaForge 根目录：`<ROOT_DIR>/WahaForge`
- gows Go module 目录：`<ROOT_DIR>/WahaForge/gows/src`
- `go.mod` 的 module 必须保持：`go.mau.fi/whatsmeow`

## 一键脚本

脚本位于 `<ROOT_DIR>/whatsmeow/scripts`：

- `sync-upstream.sh`：同步上游 `tulir/whatsmeow` 并 merge 到当前分支
- `test-local.sh`：运行 `go test ./...`
- `push-fork.sh`：推送当前分支到 fork（可选 `--tags`）
- `bump-gows-replace.sh`：更新 gows 的 `replace` 指向本地 fork，并执行 `go mod tidy`

## 推荐操作顺序

1. 在 `whatsmeow` 仓库目录同步上游：
   - `./scripts/sync-upstream.sh`
2. 手工或用 AI 修改代码（例如 `pair-code.go`）
3. 在 fork 本地跑测试：
   - `./scripts/test-local.sh`
4. 推送到你自己的 fork：
   - `./scripts/push-fork.sh`
5. 更新 gows 依赖并整理模块：
   - `./scripts/bump-gows-replace.sh`
6. 在 gows 目录验证构建：
   - `cd "$ROOT_DIR/WahaForge/gows/src" && go build ./...`

## 环境变量

以下变量可在运行脚本时覆盖默认值：

- `UPSTREAM_URL`：默认 `https://github.com/tulir/whatsmeow.git`
- `UPSTREAM_BRANCH`：默认 `main`
- `ORIGIN_REMOTE`：默认 `origin`
- `WHATSMMEOW_ROOT`：默认 `scripts` 上一级目录（即当前 `whatsmeow` 仓库根）
- `WAHA_FORGE_ROOT`：默认 `WHATSMMEOW_ROOT` 的同级目录下 `WahaForge`
- `GOWS_SRC`：默认 `$WAHA_FORGE_ROOT/gows/src`

## 生产/CI 与本地联调说明

- 本地联调推荐使用 `replace go.mau.fi/whatsmeow => <ROOT_DIR>/whatsmeow`，速度快，便于快速验证。
- 生产或 CI 可以改用 GitHub fork + commit 版本（例如 `go get github.com/<you>/whatsmeow@<commit>`），让依赖来源更可追踪。

## 常见问题

- `sync-upstream.sh` merge 冲突：按 git 提示手工解决后重新测试。
- `test-local.sh` 失败：先修复 fork 的问题再 push。
- `bump-gows-replace.sh` 失败：确认 `GOWS_SRC` 路径存在，且本机 Go 环境可用。
