#!/usr/bin/env bash
# codex-egress（Linux 版）：让 codex CLI 及其后台进程的全部请求只从指定代理 IP 出网，不影响其他应用。
#
#   安装:  bash codex-egress-linux.sh install 'http://用户名:密码@IP:端口'
#   自检:  ~/.codex-egress/codex-egress-linux.sh check [秒数]
#   卸载:  ~/.codex-egress/codex-egress-linux.sh uninstall
#
# 与 macOS 版的区别：Linux 没有 Codex 桌面版，没有 `open -a --env` 这种注入入口，
# 因此改用「PATH 前置 shim」在每次调用 codex 时注入代理环境变量；
# 转发器与守护由 systemd --user 托管（而非 launchd），进程信息来自 /proc（而非 ps eww）。
#
# 原理：本机起一个只供 codex 使用的转发器（127.0.0.1:7899，OpenAI 相关域名走代理、其余直连），
# shim 把 codex 指向它；系统代理、DNS、路由与其他应用均不改动。
set -euo pipefail

BASE="$HOME/.codex-egress"
SELF="$BASE/codex-egress-linux.sh"
SHIM_DIR="$BASE/shim"
UNIT_DIR="$HOME/.config/systemd/user"
FWD_UNIT=codex-egress-forwarder
GUARD_UNIT=codex-egress-guard
PORT=7899
API_PORT=9099
FWD="http://127.0.0.1:$PORT"
NO_PROXY_LIST='localhost,127.0.0.1,::1,10.0.0.0/8,172.16.0.0/12,192.168.0.0/16'
PROFILE="${CODEX_EGRESS_PROFILE:-}"
# 经代理出网的域名（含子域名）：OpenAI 自有域名及其登录、错误上报、统计、实验开关服务商。
# 未列出的域名一律直连；OpenAI 若启用新域名，需补到这里后重新执行 install。
PROXY_DOMAINS=(
  openai.com openai.org chatgpt.com oaistatic.com oaiusercontent.com sora.com
  auth0.com sentry.io segment.io segment.com statsig.com statsigapi.net featuregates.org
)
MIHOMO_VER=v1.19.31
MIHOMO_SHA_ARM64=9e0f11afbf38426b8bd88fdc594678f8161c57eccb4e1b77acb12b493904f1d4
MIHOMO_SHA_AMD64=04cf9f09671704f839ddbee2e93069dc831a4123a75281e725d1d96ab9ac1afc
GUARD_STAMP="$BASE/.guard-daemon-stamp"

ok()   { printf '  \033[32m✔\033[0m %s\n' "$*"; }
warn() { printf '  \033[33m!\033[0m %s\n' "$*"; }
bad()  { printf '  \033[31m✘\033[0m %s\n' "$*"; }
die()  { printf '\033[31m✘ %s\033[0m\n' "$*" >&2; exit 1; }
have() { command -v "$1" >/dev/null 2>&1; }
notify() { have notify-send && notify-send "Codex Proxy" "$1" >/dev/null 2>&1 || true; }

# ------------------------------------------------------------------ /proc 工具
proc_exe()  { readlink -f "/proc/$1/exe" 2>/dev/null || true; }
proc_args() { tr '\0' ' ' 2>/dev/null < "/proc/$1/cmdline" || true; }
proc_env()  { tr '\0' '\n' 2>/dev/null < "/proc/$1/environ" || true; }
# 不用管道：set -o pipefail 下 grep -q 命中后提前退出会让上游吃 SIGPIPE，
# 整条管道返回 141，导致「已代理」被误判成「未代理」。
env_proxied() {
  local e
  e=$(proc_env "$1")
  [[ $'\n'$e$'\n' == *$'\n'"HTTPS_PROXY=$FWD"$'\n'* ]]
}

# 候选进程粗筛：/proc/<pid>/comm 用 bash 内建 read 读取，不 fork。
# check 的监控循环每 0.5 秒跑一次全量扫描，先用它挡掉 99% 的进程，再做昂贵的 readlink/cmdline。
proc_candidates() {
  local d p comm
  for d in /proc/[0-9]*; do
    p=${d#/proc/}
    # 2>/dev/null 必须写在 < 之前：重定向从左到右生效，进程在扫描中途退出时
    # 打开 comm 失败的报错才不会漏到终端（/proc/<pid>/comm: No such file or directory）
    read -r comm 2>/dev/null < "$d/comm" || continue
    # comm 被内核截断到 15 字符：codex-code-mode-host -> codex-code-mod
    [[ $comm == codex* || $comm == node ]] || continue
    printf '%s\n' "$p"
  done
}

# 本机属于 codex 的进程
codex_pids() {
  local p exe args
  for p in $(proc_candidates); do
    exe=$(proc_exe "$p"); [[ -n $exe ]] || continue
    args=$(proc_args "$p")
    if [[ $exe == */.codex/* || $exe == */node_modules/@openai/codex/* \
       || ${exe##*/} == codex || ${exe##*/} == codex-* \
       || $args == *"@openai/codex"* ]]; then
      printf '%s\n' "$p"
    fi
  done
}

# 常驻 app-server daemon：不随调用它的 codex 退出，是最容易漏在体系外的进程
daemon_pids() {
  local p exe args
  for p in $(proc_candidates); do
    exe=$(proc_exe "$p"); [[ -n $exe ]] || continue
    [[ ${exe##*/} == codex ]] || [[ $exe == */.codex/packages/app-server-daemon/*/bin/codex ]] || continue
    args=$(proc_args "$p")
    if [[ $exe == */.codex/packages/app-server-daemon/*/bin/codex ]] \
    || [[ ${exe##*/} == codex && $args == *" app-server"* ]]; then
      printf '%s\n' "$p"
    fi
  done
}

# 存在「未指向转发器」的 daemon 时返回 0；没有 daemon 在跑也算正常。
daemon_leaking() {
  local dp
  for dp in $(daemon_pids); do
    env_proxied "$dp" || return 0
  done
  return 1
}

# 结束常驻 daemon，使其在下一次经 shim 调用 codex 时带着代理环境变量重建。
kill_daemons() {
  local dp i
  [[ -z $(daemon_pids) ]] && return 0
  for dp in $(daemon_pids); do kill -TERM "$dp" 2>/dev/null || true; done
  for i in $(seq 20); do
    [[ -z $(daemon_pids) ]] && return 0
    sleep 0.25
  done
  for dp in $(daemon_pids); do kill -KILL "$dp" 2>/dev/null || true; done
  sleep 0.5
}

# ------------------------------------------------------------------ 网络/系统工具
# 不依赖 nc：用 bash 内建 /dev/tcp 探测
forwarder_up() { (exec 3<>"/dev/tcp/127.0.0.1/$PORT") >/dev/null 2>&1; }
trace_ip() { curl -s -m 20 --noproxy '' -x "$1" https://chatgpt.com/cdn-cgi/trace 2>/dev/null | sed -n 's/^ip=//p' || true; }

# 代理不通时把 curl 的真实错误和排查方向打出来，避免只留一句「连不上」
proxy_diag() {
  local proxy=$1 out rc=0 host=${1##*@}; host=${host%%:*}
  out=$(curl -sS -m 20 --noproxy '' -x "$proxy" https://chatgpt.com/cdn-cgi/trace 2>&1 >/dev/null) || rc=$?
  printf '  curl 退出码 %s：%s\n' "$rc" "${out:-无额外输出}"
  case $rc in
    5)  echo "  → 解析不了代理主机名：检查地址拼写或本机 DNS" ;;
    6)  echo "  → 解析不了目标域名：本机 DNS 有问题" ;;
    7)  echo "  → 连不上代理端口：端口写错、代理没开，或本机出网被防火墙拦住了该端口" ;;
    28) echo "  → 超时：代理所在网络对本机不可达" ;;
    97) echo "  → TCP 通了但代理在握手阶段主动关闭：账号密码不对、出口 IP 不在白名单，或该账号已被别处占用（并发/粘性会话限制）" ;;
    *)  echo "  → TCP 若能通却始终失败，优先怀疑账号密码、出口 IP 白名单、账号并发限制" ;;
  esac
  if timeout 8 bash -c "(exec 3<>/dev/tcp/$host/${proxy##*:})" >/dev/null 2>&1; then
    echo "  代理端口 TCP：可连（说明是认证/策略层被拒，不是网络不通）"
  else
    echo "  代理端口 TCP：连不上（网络层就被挡住了，先查防火墙/出网策略）"
  fi
  echo "  本机公网出口 IP：$(curl -s -m 10 https://ifconfig.me 2>/dev/null || echo '取不到，本机可能完全不能直连外网')"
}
port_owner() { ss -ltnp 2>/dev/null | sed -n "s/.*:$1 .*pid=\([0-9]*\),.*/\1/p" | head -1; }
uctl() { systemctl --user "$@"; }

need_systemd_user() {
  have systemctl || die "未找到 systemctl，本脚本需要 systemd（用户级 unit）"
  [[ -n ${XDG_RUNTIME_DIR:-} ]] || die "XDG_RUNTIME_DIR 为空，当前不是完整的 systemd 用户会话；请在图形登录或 'ssh -t' 的登录会话中运行"
  uctl show-environment >/dev/null 2>&1 || die "systemctl --user 不可用（systemd 用户总线未就绪）"
}

detect_profile() {
  [[ -n $PROFILE ]] && return 0
  case "${SHELL:-}" in
    # zsh 先读 .zprofile 再读 .zshrc；写进 .zprofile 会被 .zshrc 里后续的 PATH 前置挤到后面
    */zsh)  PROFILE="$HOME/.zshrc" ;;
    */bash) PROFILE="$HOME/.bash_profile"; [[ -f $PROFILE ]] || PROFILE="$HOME/.profile" ;;
    *)      PROFILE="$HOME/.profile" ;;
  esac
}

remove_profile_block() {
  detect_profile
  local f
  # 清理所有可能写入过的 rc 文件，避免换 shell 后残留
  for f in "$PROFILE" "$HOME/.zprofile" "$HOME/.zshrc" "$HOME/.zshrc.local" "$HOME/.bash_profile" "$HOME/.profile" "$HOME/.bashrc"; do
    [[ -f $f ]] || continue
    grep -q '^# >>> codex-proxy' "$f" || continue
    awk '/^# >>> codex-proxy/{s=1;next} /^# <<< codex-proxy/{s=0;next} !s' "$f" > "$f.codex-egress.tmp"
    cat "$f.codex-egress.tmp" > "$f"
    rm -f "$f.codex-egress.tmp"
  done
}

# 在 PATH 中剔除 shim 目录后定位真正的 codex
find_real_codex() {
  local d cand real IFS=:
  for d in $PATH; do
    [[ -z $d || $d == "$SHIM_DIR" ]] && continue
    cand="$d/codex"
    [[ -x $cand && -f $cand ]] || continue
    real=$(readlink -f "$cand" 2>/dev/null || echo "$cand")
    [[ $real == "$SHIM_DIR/codex" ]] && continue
    printf '%s\n' "$real"
    return 0
  done
  return 1
}

write_unit() {
  local name=$1 content=$2
  mkdir -p "$UNIT_DIR"
  printf '%s\n' "$content" > "$UNIT_DIR/$name"
}

# ------------------------------------------------------------------ install
cmd_install() {
  local proxy="${1:-}"
  [[ $(uname -s) == Linux ]] || die "本脚本仅支持 Linux；macOS 请用 codex-egress.sh"
  [[ -f ${BASH_SOURCE[0]} ]] || die "请先把脚本保存成文件再运行：bash codex-egress-linux.sh install '代理地址'"
  have curl || die "缺少 curl"
  have ss   || die "缺少 ss（请安装 iproute2）"
  need_systemd_user
  detect_profile

  if [[ -z $proxy && -f $BASE/config.yaml ]]; then
    proxy=$(awk -F': ' '
      /^    type:/ {t=$2} /^    server:/ {s=$2} /^    port:/ {p=$2}
      /^    username:/ {u=$2} /^    password:/ {w=$2}
      END { gsub(/^\047|\047$/, "", u); gsub(/^\047|\047$/, "", w); printf "%s://%s:%s@%s:%s", t, u, w, s, p }' "$BASE/config.yaml")
    ok "沿用已安装的代理配置"
  fi
  if [[ -z $proxy ]]; then read -r -p "请输入代理地址（http://用户名:密码@IP:端口）: " proxy; fi
  proxy="${proxy//[[:space:]]/}"
  [[ $proxy =~ ^(http|socks5h?)://([^:@/]+):([^@/]+)@([^:@/]+):([0-9]+)/?$ ]] \
    || die "代理地址格式应为 http://用户名:密码@IP:端口（或 socks5:// / socks5h://…）"
  local scheme=${BASH_REMATCH[1]} user=${BASH_REMATCH[2]} pass=${BASH_REMATCH[3]} host=${BASH_REMATCH[4]} port=${BASH_REMATCH[5]}
  [[ $scheme == socks5h ]] && scheme=socks5
  local curl_proxy=$proxy
  [[ $scheme == socks5 ]] && curl_proxy="socks5h://${proxy#*://}"

  echo "1/6 测试代理"
  local ip
  ip=$(trace_ip "$curl_proxy")
  if [[ -z $ip ]]; then
    bad "代理连不上（本次未做任何修改）"
    proxy_diag "$curl_proxy"
    exit 1
  fi
  ok "代理可用，ChatGPT 看到的出口 IP：$ip"

  local p pid
  for p in $PORT $API_PORT; do
    pid=$(port_owner "$p")
    if [[ -n $pid && $(proc_exe "$pid") != "$BASE/bin/mihomo" ]]; then
      die "本机端口 ${p} 已被其他程序占用（pid ${pid}），无法安装"
    fi
  done

  echo "2/6 准备转发器 mihomo $MIHOMO_VER"
  mkdir -p "$BASE/bin" "$BASE/logs" "$SHIM_DIR" "$UNIT_DIR"
  chmod 700 "$BASE"
  if [[ -x $BASE/bin/mihomo ]] && [[ $("$BASE/bin/mihomo" -v 2>/dev/null) == *"$MIHOMO_VER"* ]]; then
    ok "已安装，跳过下载"
  else
    local asset sha tmp
    case $(uname -m) in
      aarch64|arm64)  asset=mihomo-linux-arm64-$MIHOMO_VER.gz;            sha=$MIHOMO_SHA_ARM64 ;;
      x86_64|amd64)   asset=mihomo-linux-amd64-compatible-$MIHOMO_VER.gz; sha=$MIHOMO_SHA_AMD64 ;;
      *) die "不支持的 CPU 架构：$(uname -m)" ;;
    esac
    tmp=$(mktemp -d)
    local url="https://github.com/MetaCubeX/mihomo/releases/download/$MIHOMO_VER/$asset"
    curl -fsSL -m 600 --noproxy '' -x "$curl_proxy" -o "$tmp/$asset" "$url" \
      || curl -fsSL -m 600 -o "$tmp/$asset" "$url" \
      || die "下载 mihomo 失败"
    [[ $(sha256sum "$tmp/$asset" | cut -d' ' -f1) == "$sha" ]] || die "mihomo 校验失败，已中止"
    gunzip -c "$tmp/$asset" > "$BASE/bin/mihomo.new"
    chmod 755 "$BASE/bin/mihomo.new"
    mv "$BASE/bin/mihomo.new" "$BASE/bin/mihomo"
    rm -rf "$tmp"
    ok "下载并校验通过"
  fi
  cp "${BASH_SOURCE[0]}" "$SELF.new" && chmod 755 "$SELF.new" && mv "$SELF.new" "$SELF"

  echo "3/6 写入配置"
  local secret real_codex
  secret=$(openssl rand -hex 16 2>/dev/null || head -c16 /dev/urandom | od -An -tx1 | tr -d ' \n')
  real_codex=$(find_real_codex || true)
  [[ -n $real_codex ]] || warn "当前 PATH 中找不到 codex，shim 会在运行时再尝试定位"
  # YAML 单引号标量里 ' 要写成 ''；必须在 heredoc 之外算好，heredoc 内的 \' 不会被当成转义。
  local user_esc=${user//"'"/"''"} pass_esc=${pass//"'"/"''"}
  (
    umask 077
    cat > "$BASE/config.yaml" <<EOF
# 由 codex-egress-linux.sh 生成：仅供 codex 使用的本地转发器
mixed-port: $PORT
bind-address: 127.0.0.1
allow-lan: false
mode: rule
log-level: warning
ipv6: false
external-controller: 127.0.0.1:$API_PORT
secret: $secret
proxies:
  - name: codex-egress
    type: $scheme
    server: $host
    port: $port
    username: '$user_esc'
    password: '$pass_esc'
rules:
$(printf '  - DOMAIN-SUFFIX,%s,codex-egress\n' "${PROXY_DOMAINS[@]}")
  - MATCH,DIRECT
EOF
    echo "$ip" > "$BASE/proxy-ip"
    printf '%s\n' "$real_codex" > "$BASE/real-codex"
    cat > "$BASE/env.sh" <<EOF
export HTTP_PROXY=$FWD HTTPS_PROXY=$FWD ALL_PROXY=$FWD NO_PROXY=$NO_PROXY_LIST
export http_proxy=$FWD https_proxy=$FWD all_proxy=$FWD no_proxy=$NO_PROXY_LIST
EOF
  )
  "$BASE/bin/mihomo" -d "$BASE" -t >/dev/null || die "转发器配置校验失败"

  # shim：每次调用 codex 都注入代理环境变量；转发器没起来就直接拒绝，避免静默直连。
  cat > "$SHIM_DIR/codex" <<EOF
#!/usr/bin/env bash
# 由 codex-egress-linux.sh 生成，请勿手工编辑。
set -euo pipefail
BASE="\$HOME/.codex-egress"
if ! (exec 3<>"/dev/tcp/127.0.0.1/$PORT") >/dev/null 2>&1; then
  echo "codex-egress 转发器未运行，已阻止 codex 直连；排查：\$BASE/codex-egress-linux.sh check" >&2
  exit 1
fi
. "\$BASE/env.sh"
REAL=\$(cat "\$BASE/real-codex" 2>/dev/null || true)
if [[ -z \$REAL || ! -x \$REAL ]]; then
  REAL=""
  IFS=: read -r -a _dirs <<< "\$PATH"
  for _d in "\${_dirs[@]}"; do
    [[ -z \$_d || \$_d == "$SHIM_DIR" ]] && continue
    if [[ -x \$_d/codex && -f \$_d/codex ]]; then
      _r=\$(readlink -f "\$_d/codex" 2>/dev/null || echo "\$_d/codex")
      [[ \$_r == "$SHIM_DIR/codex" ]] && continue
      REAL="\$_r"; break
    fi
  done
fi
[[ -n \$REAL ]] || { echo "codex-egress：找不到真正的 codex 可执行文件" >&2; exit 127; }
exec "\$REAL" "\$@"
EOF
  chmod 755 "$SHIM_DIR/codex"

  remove_profile_block
  cat >> "$PROFILE" <<EOF
# >>> codex-proxy >>>
# 把 codex 指向 codex-egress 的 shim（注入代理环境变量后再执行真正的 codex）
# 先从 PATH 中移除再前置，确保 shim 总在最前（即使之前已被其他目录挤到后面）
case ":\$PATH:" in
  *":$SHIM_DIR:"*) PATH=\$(printf '%s' ":\$PATH:" | sed -e "s#:$SHIM_DIR:#:#g" -e 's#^:##' -e 's#:\$##') ;;
esac
PATH="$SHIM_DIR\${PATH:+:\$PATH}"; export PATH
# <<< codex-proxy <<<
EOF
  ok "配置写入 ~/.codex-egress，并在 ${PROFILE/#$HOME/\~} 前置 shim 目录"

  echo "4/6 启动转发器（开机自启）"
  write_unit "$FWD_UNIT.service" "[Unit]
Description=codex-egress forwarder (mihomo, Codex only)
After=network-online.target

[Service]
ExecStart=$BASE/bin/mihomo -d $BASE
Restart=always
RestartSec=2

[Install]
WantedBy=default.target"
  uctl daemon-reload
  uctl enable --now "$FWD_UNIT.service" >/dev/null 2>&1 || die "启动转发器失败：journalctl --user -u $FWD_UNIT"
  uctl restart "$FWD_UNIT.service"
  local i
  for i in $(seq 20); do forwarder_up && break; sleep 0.5; done
  forwarder_up || die "转发器启动失败，查看 journalctl --user -u $FWD_UNIT"
  local via
  via=$(trace_ip "$FWD")
  [[ $via == "$ip" ]] || die "经转发器的出口 IP 为 ${via:-空}，与代理 IP $ip 不一致"
  ok "转发器运行中，出口 IP：$via"
  loginctl enable-linger "$(id -un)" >/dev/null 2>&1 \
    && ok "已启用 linger（注销后转发器继续运行）" \
    || warn "启用 linger 失败，注销后转发器会停止：sudo loginctl enable-linger $(id -un)"

  echo "5/6 重建后台 daemon"
  # 安装前残留的 app-server daemon 没有代理环境变量，必须结束，否则会被复用并继续直连。
  if [[ -n $(daemon_pids) ]]; then
    kill_daemons
    ok "已结束安装前残留的 app-server daemon，下次运行 codex 时会带代理重建"
  else
    ok "没有残留的 app-server daemon"
  fi

  echo "6/6 启用守护"
  write_unit "$GUARD_UNIT.service" "[Unit]
Description=codex-egress guard (kill app-server daemon that bypasses the forwarder)

[Service]
Type=oneshot
ExecStart=/usr/bin/env bash $SELF guard"
  write_unit "$GUARD_UNIT.timer" "[Unit]
Description=codex-egress guard timer

[Timer]
OnBootSec=30
OnUnitActiveSec=5
AccuracySec=1s

[Install]
WantedBy=timers.target"
  uctl daemon-reload
  uctl enable --now "$GUARD_UNIT.timer" >/dev/null 2>&1 || die "启用守护失败：journalctl --user -u $GUARD_UNIT"
  ok "发现后台 daemon 绕过转发器时，几秒内自动结束它（下次调用 codex 会带代理重建）"

  echo
  echo "✅ 安装完成。请重开一个登录 shell（或执行：export PATH=\"$SHIM_DIR:\$PATH\"）后再用 codex。"
  echo "   自检：$SELF check"
}

# ------------------------------------------------------------------ guard
cmd_guard() {
  daemon_leaking || return 0
  local now last
  now=$(date +%s)
  last=$(cat "$GUARD_STAMP" 2>/dev/null || echo 0)
  # 结束 daemon 会打断正在进行的 codex 会话，加 120 秒冷却，避免用户反复从未包装的 shell 启动时被连续打断。
  if (( now - last < 120 )); then return 0; fi
  echo "$now" > "$GUARD_STAMP"
  echo "$(date '+%F %T') 检测到 app-server daemon 未经转发器（pid $(daemon_pids | tr '\n' ' ')），已结束"
  notify "后台 daemon 绕过代理，已结束；请重新运行 codex"
  kill_daemons
}

# ------------------------------------------------------------------ check
cmd_check() {
  local secs=${1:-60} failed=0
  [[ -f $BASE/config.yaml ]] || die "未安装 codex-egress"
  have ss || die "缺少 ss（请安装 iproute2）"
  have jq || warn "缺少 jq，第 3 步将无法列出域名归属（apt install jq）"
  local expect secret
  expect=$(cat "$BASE/proxy-ip")
  secret=$(awk '/^secret:/{print $2}' "$BASE/config.yaml")

  echo "1. 转发器"
  if forwarder_up; then
    local via
    via=$(trace_ip "$FWD")
    [[ $via == "$expect" ]] && ok "运行中，出口 IP $via" || { bad "出口 IP 为 ${via:-空}，期望 $expect"; failed=1; }
  else
    bad "转发器未运行（systemctl --user status $FWD_UNIT）"; failed=1
  fi
  uctl is-enabled "$GUARD_UNIT.timer" >/dev/null 2>&1 && ok "守护已启用" || { bad "守护未启用"; failed=1; }

  echo "2. codex 与后台进程"
  if [[ -x $SHIM_DIR/codex ]]; then
    local resolved real
    resolved=$(command -v codex 2>/dev/null || true)
    real=$(cat "$BASE/real-codex" 2>/dev/null || true)
    if [[ $resolved == "$SHIM_DIR/codex" ]]; then
      ok "codex 已指向 shim（真实路径：${real:-运行时动态定位}）"
    else
      bad "当前 shell 的 codex 解析为 ${resolved:-未找到}，不是 shim；请重开登录 shell"; failed=1
    fi
  else
    bad "shim 不存在"; failed=1
  fi
  local dp bad_daemons=""
  for dp in $(daemon_pids); do
    env_proxied "$dp" || bad_daemons+=" $dp"
  done
  if [[ -z $(daemon_pids) ]]; then
    warn "当前没有 app-server daemon 在跑（运行一次 codex 后再自检更有意义）"
  elif [[ -z $bad_daemons ]]; then
    ok "app-server daemon 已指向转发器"
  else
    bad "app-server daemon 未指向转发器（pid${bad_daemons}），它会直连 OpenAI 域名"
    bad "  修复：$SELF guard  （结束它，下次运行 codex 会带代理重建）"
    failed=1
  fi

  echo "3. 监控 ${secs} 秒（期间可正常使用 codex，发几条消息）"
  local tmp
  tmp=$(mktemp -d)
  local end=$((SECONDS + secs)) pids
  while (( SECONDS < end )); do
    pids=$(codex_pids | tr '\n' '|' | sed 's/|$//')
    if [[ -n $pids ]]; then
      # ss 的 Process 列紧跟 Peer 列，按 users:(( 定位，兼容有无 State 列两种输出
      ss -tnp state established 2>/dev/null | awk -v want="^(${pids})\$" '
        {
          peer=""; pid=""
          for (i = 1; i <= NF; i++) {
            if ($i ~ /^users:\(\(/) {
              peer = $(i-1)
              if (match($i, /pid=[0-9]+/)) pid = substr($i, RSTART+4, RLENGTH-4)
            }
          }
          if (peer != "" && pid != "" && pid ~ want) print pid "\t" peer
        }' >> "$tmp/sock" || true
    fi
    curl -s -m 3 -H "Authorization: Bearer $secret" "http://127.0.0.1:$API_PORT/connections" |
      jq -r '.connections[]? | [(.metadata.host // .metadata.destinationIP), (.chains | join(" < "))] | @tsv' >> "$tmp/fwd" 2>/dev/null || true
    sleep 0.5
  done
  local leaks total
  leaks=$(sort -u "$tmp/sock" 2>/dev/null | awk -F'\t' '{
      h = $2; sub(/:[0-9]+$/, "", h); gsub(/[\[\]]/, "", h)
      if (h ~ /^(127\.|::1$|10\.|192\.168\.|172\.(1[6-9]|2[0-9]|3[01])\.)/) next
      print $1 "\t" $2 }' | sort | uniq -c || true)
  total=$(sort -u "$tmp/sock" 2>/dev/null | wc -l | tr -d ' ' || true)
  if [[ -z $leaks ]]; then
    ok "codex 相关进程共 ${total} 条连接，全部经过本机转发器或访问内网"
  else
    bad "发现绕过转发器直连外网的连接（pid / 对端）："
    echo "$leaks" | sed 's/^/      /'
    failed=1
  fi
  if [[ -s $tmp/fwd ]]; then
    echo "  经代理 IP 访问的域名："
    sort -u "$tmp/fwd" | awk -F'\t' '$2 == "codex-egress" {printf "      %s\n", $1}'
    echo "  经转发器但按规则直连的域名（非 OpenAI 域名属正常；若其中有 OpenAI 相关域名，才需补进脚本的 PROXY_DOMAINS）："
    sort -u "$tmp/fwd" | awk -F'\t' '$2 != "codex-egress" {printf "      %s\n", $1}'
  fi
  rm -rf "$tmp"

  echo
  if (( failed == 0 )); then
    printf '\033[32m通过：codex 访问 OpenAI 的请求只从 %s 出网\033[0m\n' "$expect"
  else
    printf '\033[31m未通过，请按上面的提示处理\033[0m\n'
  fi
  return $failed
}

# ------------------------------------------------------------------ uninstall
cmd_uninstall() {
  if have systemctl && [[ -n ${XDG_RUNTIME_DIR:-} ]]; then
    uctl disable --now "$GUARD_UNIT.timer"   >/dev/null 2>&1 || true
    uctl disable --now "$FWD_UNIT.service"   >/dev/null 2>&1 || true
    rm -f "$UNIT_DIR/$GUARD_UNIT.timer" "$UNIT_DIR/$GUARD_UNIT.service" "$UNIT_DIR/$FWD_UNIT.service"
    uctl daemon-reload >/dev/null 2>&1 || true
  else
    warn "systemd 用户总线不可用，未能卸载 unit；稍后手动执行：systemctl --user disable --now $FWD_UNIT $GUARD_UNIT.timer"
  fi
  remove_profile_block
  # 常驻 daemon 仍带着指向转发器的环境变量，必须一并结束，否则卸载后它会连不上网。
  if [[ -n $(daemon_pids) ]]; then
    kill_daemons
    ok "已结束 app-server daemon，下次运行 codex 会以无代理方式重建"
  fi
  rm -rf "$BASE"
  ok "已卸载：转发器、守护、shim、${PROFILE/#$HOME/\~} 中的 PATH 前置均已移除"
  warn "当前 shell 的 PATH 仍含 shim 目录，请重开一个 shell"
}

case "${1:-}" in
  install)      shift; cmd_install "$@" ;;
  guard)        cmd_guard ;;
  check)        shift; cmd_check "$@" ;;
  uninstall)    detect_profile; cmd_uninstall ;;
  *) sed -n '2,13p' "$0"; exit 1 ;;
esac
