# AI Prompt：修改 whatsmeow 配对码逻辑

下面提供一段可直接复制给 AI（如 Cursor Agent）的提示词，用于在 `whatsmeow` fork 中做配对码相关改造。

## 使用前约束

- 仓库路径：`<ROOT_DIR>/whatsmeow`
- 保持 `go.mod` 的 module 为 `go.mau.fi/whatsmeow`
- 核心目标文件通常是：`pair-code.go`
- 本次目标是固定调试码 `11119999`，不要求改动或评估 gows 调用侧
- 修改后必须运行：`./scripts/test-local.sh`

## 可复制提示词

```text
You are editing my forked WhatsMeow repository at <ROOT_DIR>/whatsmeow.

Goal:
Implement fixed pairing code `11119999` in pairing flow for debugging, while keeping backward compatibility for default path (when fixed mode is not used).

Hard constraints:
1) Do NOT change module path in go.mod (must remain go.mau.fi/whatsmeow).
2) Focus on pair-code.go and related pairing code path only.
3) Keep existing default behavior working when fixed mode is not enabled.
4) Add concise comments only where logic is non-obvious.
5) After changes, run go tests (equivalent of ./scripts/test-local.sh) and report results.

What to do:
1) Locate PairPhone and pairing-code generation logic.
2) Add a fixed-code mode that always uses `11119999` (prefer minimal, low-risk implementation).
3) Validate fixed code format/length and return explicit errors if validation fails.
4) Keep old call path intact for existing callers.
5) Summarize changed files and behavior differences between default mode and fixed-code mode.

Output format:
- List of changed files
- Key behavior changes
- Test command and results
- Toggle method for fixed mode and expected runtime behavior
```

## 建议执行方式

1. 先在新分支修改：`git checkout -b feat/pairing-fixed-11119999`
2. 让 AI 按上方 prompt 修改代码
3. 执行 `./scripts/test-local.sh`
4. 通过 `./scripts/push-fork.sh` 推送到 fork
5. 运行 `./scripts/bump-gows-replace.sh` 验证 gows 侧联调
