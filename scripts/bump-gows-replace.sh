#!/usr/bin/env bash
#
# =============================================================================
# == 使用文档 ==  bump-gows-replace.sh
# =============================================================================
#
# 切换 gows/src/go.mod 中  `replace go.mau.fi/whatsmeow => ...` 指令的目标，
# 在以下两种模式之间快速切换：
#
#   1) github  —— 指向 fork 仓库（默认 github.com/codejoy2020/whatsmeow）
#                 的最新 commit（或指定 ref），自动解析 pseudo-version。
#   2) local   —— 指向本地 whatsmeow clone（默认 /home/boss/workspace/whatsmeow），
#                 用于本地补丁/调试。
#
# 用法：
#   scripts/bump-gows-replace.sh github [REF]    # 默认 HEAD；REF 可为分支/tag/commit
#   scripts/bump-gows-replace.sh local  [PATH]   # 默认 $WHATSMEOW_LOCAL_PATH
#   scripts/bump-gows-replace.sh status          # 打印当前 replace 行
#   scripts/bump-gows-replace.sh help
#
# 环境变量：
#   WHATSMEOW_FORK_REPO      默认 github.com/codejoy2020/whatsmeow
#   WHATSMEOW_FORK_GIT_URL   默认 https://${WHATSMEOW_FORK_REPO}.git
#   WHATSMEOW_LOCAL_PATH     默认 /home/boss/workspace/whatsmeow
#   GOWS_SKIP_TIDY=1         跳过 go mod tidy
#   GOWS_SKIP_BUILD=1        跳过 go build ./... 验证
#
# 示例：
#   scripts/bump-gows-replace.sh github                  # 升级到 fork HEAD
#   scripts/bump-gows-replace.sh github master           # 升级到 fork master 分支头
#   scripts/bump-gows-replace.sh github 2f653fa6939f     # 锁定到指定 commit
#   scripts/bump-gows-replace.sh local                   # 切回本地路径开发
#   scripts/bump-gows-replace.sh local /custom/path      # 自定义本地路径
#
# 注意：
#   · 本脚本只改 gows/src/go.mod 与 go.sum（通过 go mod tidy），不会自动 git commit。
#   · local 模式生成的 replace 不应进入 master，提交前请切回 github 模式。
#

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GOWS_SRC="${ROOT}/gows/src"
GOMOD="${GOWS_SRC}/go.mod"

UPSTREAM_MODULE="go.mau.fi/whatsmeow"
FORK_REPO="${WHATSMEOW_FORK_REPO:-github.com/codejoy2020/whatsmeow}"
FORK_GIT_URL="${WHATSMEOW_FORK_GIT_URL:-https://${FORK_REPO}.git}"
LOCAL_DEFAULT_PATH="${WHATSMEOW_LOCAL_PATH:-/home/boss/workspace/whatsmeow}"

log() { echo "[bump-gows-replace] $*" >&2; }
err() { echo "[bump-gows-replace] ERROR: $*" >&2; }

ensure_tools() {
  command -v go  >/dev/null || { err "go: command not found";  exit 1; }
  command -v git >/dev/null || { err "git: command not found"; exit 1; }
}

ensure_gomod() {
  if [[ ! -f "${GOMOD}" ]]; then
    err "go.mod not found at ${GOMOD}"
    exit 1
  fi
}

show_status() {
  ensure_gomod
  if ! awk '/^replace[[:space:]]+go\.mau\.fi\/whatsmeow[[:space:]]*=>/ {found=1; print} END {exit !found}' "${GOMOD}"; then
    log "no replace directive for ${UPSTREAM_MODULE} in go.mod"
    return 1
  fi
}

post_update() {
  cd "${GOWS_SRC}"
  if [[ "${GOWS_SKIP_TIDY:-0}" != "1" ]]; then
    log "go mod tidy ..."
    go mod tidy
  fi
  if [[ "${GOWS_SKIP_BUILD:-0}" != "1" ]]; then
    log "go build ./... (verify)"
    go build ./...
  fi
  log "done. Current replace:"
  show_status || true
}

bump_local() {
  ensure_tools
  ensure_gomod
  local path="${1:-${LOCAL_DEFAULT_PATH}}"
  if [[ ! -d "${path}" ]]; then
    err "local path not found: ${path}"
    err "set WHATSMEOW_LOCAL_PATH or pass an explicit path."
    exit 1
  fi
  if [[ ! -f "${path}/go.mod" ]]; then
    err "path is not a Go module (no go.mod): ${path}"
    exit 1
  fi
  # normalize to absolute path
  path="$(cd "${path}" && pwd)"

  cd "${GOWS_SRC}"
  go mod edit -dropreplace="${UPSTREAM_MODULE}"
  go mod edit -replace="${UPSTREAM_MODULE}=${path}"
  log "replace -> local ${path}"
  echo "  WARNING: 本地 replace 不应提交到 master，开发完成后请运行: $0 github"
  post_update
}

git_ls_remote_retry() {
  # 网络偶发故障（GnuTLS / 502 等）下重试 3 次，间隔 2s/4s
  local attempt
  for attempt in 1 2 3; do
    if git ls-remote "$@"; then
      return 0
    fi
    if (( attempt < 3 )); then
      log "git ls-remote failed, retrying in $((attempt*2))s ..."
      sleep $((attempt*2))
    fi
  done
  return 1
}

resolve_commit_sha() {
  local ref="$1"
  if [[ "${ref}" =~ ^[0-9a-fA-F]{7,40}$ ]]; then
    echo "${ref}"
    return
  fi
  local out
  if [[ -z "${ref}" || "${ref}" == "HEAD" ]]; then
    out="$(git_ls_remote_retry "${FORK_GIT_URL}" HEAD)" || return 1
  else
    out="$(git_ls_remote_retry "${FORK_GIT_URL}" \
      "refs/heads/${ref}" "refs/tags/${ref}" "refs/heads/${ref}^{}" "refs/tags/${ref}^{}")" || return 1
  fi
  printf '%s\n' "${out}" | head -n1 | awk '{print $1}'
}

bump_github() {
  ensure_tools
  ensure_gomod
  local ref="${1:-HEAD}"
  log "resolving ${FORK_REPO}@${ref} ..."

  local sha
  if ! sha="$(resolve_commit_sha "${ref}")" || [[ -z "${sha}" ]]; then
    err "failed to resolve ref '${ref}' from ${FORK_GIT_URL}"
    exit 1
  fi
  if ! [[ "${sha}" =~ ^[0-9a-fA-F]{40}$ ]]; then
    err "got malformed sha: ${sha}"
    exit 1
  fi
  local commit_short="${sha:0:12}"
  log "commit: ${sha} (using ${commit_short})"

  cd "${GOWS_SRC}"
  log "resolving pseudo-version (this may take a few seconds) ..."
  local meta
  # 默认走 Go module proxy（更稳），失败时 fallback 到 direct（GitHub 直连）。
  # 用户可通过外部 GOPROXY=... 覆盖。
  if ! meta="$(go list -m -json "${FORK_REPO}@${commit_short}" 2>&1)"; then
    log "default GOPROXY failed, retrying with GOPROXY=direct ..."
    if ! meta="$(GOPROXY=direct go list -m -json "${FORK_REPO}@${commit_short}" 2>&1)"; then
      err "go list -m failed via both proxy and direct."
      err "raw output: ${meta}"
      exit 1
    fi
  fi
  local pv
  pv="$(printf '%s\n' "${meta}" | awk -F'"' '/"Version":[[:space:]]*"/ {print $4; exit}')"
  if [[ -z "${pv}" ]]; then
    err "failed to resolve pseudo-version for ${FORK_REPO}@${commit_short}"
    err "raw output: ${meta}"
    exit 1
  fi

  go mod edit -dropreplace="${UPSTREAM_MODULE}"
  go mod edit -replace="${UPSTREAM_MODULE}=${FORK_REPO}@${pv}"
  log "replace -> ${FORK_REPO} ${pv}"
  post_update
}

print_help() {
  # 打印文件头部的注释块（直到第一个非空且非 # 开头的行为止），去掉行首 "# "
  awk '
    NR==1 && /^#!/ { next }
    /^#/ { sub(/^# ?/, ""); print; next }
    /^[[:space:]]*$/ { print ""; next }
    { exit }
  ' "$0"
}

cmd="${1:-help}"
shift || true
case "${cmd}" in
  status)              show_status || exit 0 ;;
  local)               bump_local  "${1:-}" ;;
  github|gh|remote)    bump_github "${1:-}" ;;
  help|-h|--help)      print_help ;;
  *)                   print_help; exit 1 ;;
esac
