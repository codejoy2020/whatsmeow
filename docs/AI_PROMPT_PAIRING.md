# AI Prompt：whatsmeow fork 固定配对码

可复制给 Cursor Agent 等的提示词，用于在本 fork 中把**数字配对码**固定为调试值（无开关、始终生效）。

## 约束（先读）

| 项 | 说明 |
|----|------|
| 仓库 | `<ROOT_DIR>/whatsmeow` |
| `go.mod` module | 必须保持 `go.mau.fi/whatsmeow`，勿改路径 |
| 改动范围 | 以 `pair-code.go` 及配对码生成路径为主，避免无关重构 |
| 配对码 | 固定为 `11119999`（展示为 `1111-9999`），**不要**再做环境变量或运行时开关 |
| 校验 | 常量须在 `init` 或等价路径校验长度与字符集；非法常量应导致进程无法启动（如 `panic`）或明确失败 |
| 验证 | 改完后运行 `./scripts/test-local.sh` 并汇报结果 |
| gows | 不要求评估或改动 gows 调用侧 |

## 可复制提示词（英文）

```text
You are editing my forked WhatsMeow repo at <ROOT_DIR>/whatsmeow.

Goal:
Pairing-code flow must ALWAYS emit the fixed debug code `11119999` (formatted as `1111-9999` for display). No env vars, no runtime toggle, no “opt-in fixed mode” — every PairPhone / generateCompanionEphemeralKey path uses this constant.

Hard constraints:
1) Do NOT change go.mod module (must remain go.mau.fi/whatsmeow).
2) Touch pair-code.go and the minimal pairing-code path only; no unrelated refactors.
3) Validate the constant once at startup (e.g. init + panic on failure) so a bad build fails fast; keep validateFixedPairingCode (or equivalent) testable for length/alphabet rules.
4) Keep comments concise; only explain non-obvious fork-specific behavior.
5) After edits, run tests equivalent to ./scripts/test-local.sh and report pass/fail.

Tasks:
1) Find PairPhone and generateCompanionEphemeralKey (or equivalent linking-code generation).
2) Remove random linking-code generation; always use the fixed 8-character code that matches WhatsApp’s linking alphabet.
3) Ensure tests cover: constant validates; repeated key generation always returns the same code; ephemeral payload length unchanged (80 bytes).

Deliverables (reply format):
- Changed files (paths)
- Behavior summary (one short paragraph)
- Command run + test output summary
```

## 建议执行方式

1. 新分支：`git checkout -b feat/pairing-always-11119999`
2. 粘贴上方 prompt（替换 `<ROOT_DIR>`）
3. `./scripts/test-local.sh`
4. `./scripts/push-fork.sh` 推 fork
5. 需要时 `./scripts/bump-gows-replace.sh` 做 gows 联调
