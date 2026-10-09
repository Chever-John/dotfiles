#!/bin/bash
# codex-egress：让 Codex（ChatGPT 桌面版 + codex CLI）的全部请求只从指定代理 IP 出网，不影响其他应用。
#
#   安装:  bash codex-egress.sh install 'http://用户名:密码@IP:端口'
#   启动:  打开「应用程序 → Codex Proxy」（或 ~/.codex-egress/codex-egress.sh launch）
#   自检:  ~/.codex-egress/codex-egress.sh check [秒数]
#   质量:  ~/.codex-egress/codex-egress.sh quality [小时数=24]   （请求链路质量报告）
#          ~/.codex-egress/codex-egress.sh quality live          （实时看每一次失败）
#   卸载:  ~/.codex-egress/codex-egress.sh uninstall
#
# 原理：本机起一个只供 Codex 使用的转发器（127.0.0.1:7899，OpenAI 相关域名走代理、其余直连），
# 用启动参数和进程级环境变量把 Codex 的界面层、后台进程和 CLI 指向它；系统代理、DNS、路由与其他应用均不改动。
set -euo pipefail

BASE="$HOME/.codex-egress"
SELF="$BASE/codex-egress.sh"
APP=/Applications/ChatGPT.app
LAUNCHER="$HOME/Applications/Codex Proxy.app"
AGENTS="$HOME/Library/LaunchAgents"
FWD_LABEL=com.codex-egress.forwarder
GUARD_LABEL=com.codex-egress.guard
PORT=7899
API_PORT=9099
FWD="http://127.0.0.1:$PORT"
NO_PROXY_LIST='localhost,127.0.0.1,::1,10.0.0.0/8,172.16.0.0/12,192.168.0.0/16'
# codex 包装函数写进 .zshrc 而不是 .zprofile：.zprofile 只有登录 shell 读，
# 在终端里再敲一次 zsh / tmux / IDE 内置终端起的非登录 shell 拿不到包装函数，
# codex 会裸启动（无代理环境变量），带起的 app-server-daemon 直连 OpenAI，
# 守护随即每 120 秒重启一次 Codex，表现为「Codex 一直在重启」。
ZSHRC="$HOME/.zshrc"
ZPROFILE="$HOME/.zprofile"   # 旧版本写入位置，仅用于清理
# 经代理出网的域名（含子域名）：OpenAI 自有域名及其登录、错误上报、统计、实验开关服务商。
# 未列出的域名一律直连；OpenAI 若启用新域名，需补到这里后重新执行 install。
PROXY_DOMAINS=(
  openai.com openai.org chatgpt.com oaistatic.com oaiusercontent.com sora.com
  auth0.com sentry.io segment.io segment.com statsig.com statsigapi.net featuregates.org
)
MIHOMO_VER=v1.19.31
MIHOMO_SHA_ARM64=d131f44b3deb2a8356f7ac75048ad67a10d53243323951c4f3cda7b672922963
MIHOMO_SHA_AMD64=fb6fca0e105b4310a21eaacd3a8d3853d3d8b87fa4c69737bea52a30a435aac7
PROC_RE='^/Applications/ChatGPT\.app/|/\.codex/|/node_modules/@openai/codex'
# app-server-daemon 是 Codex 的常驻后台进程（PPID=1，自管理，不随 ChatGPT 主进程退出）。
# 它不读 --proxy-server，只认环境变量；若启动时没带上代理环境变量，就会直连 OpenAI 域名。
DAEMON_RE='/\.codex/packages/app-server-daemon/.*/bin/codex( |$)'
GUARD_STAMP="$BASE/.guard-daemon-stamp"
GUI="gui/$(id -u)"

ok()   { printf '  \033[32m✔\033[0m %s\n' "$*"; }
warn() { printf '  \033[33m!\033[0m %s\n' "$*"; }
bad()  { printf '  \033[31m✘\033[0m %s\n' "$*"; }
die()  { printf '\033[31m✘ %s\033[0m\n' "$*" >&2; exit 1; }
notify() { osascript -e "display notification \"$1\" with title \"Codex Proxy\"" >/dev/null 2>&1 || true; }

main_pid() { pgrep -f "^$APP/Contents/MacOS/ChatGPT( |\$)" | head -1 || true; }
is_proxied() { [[ $(ps -o command= -p "$1" 2>/dev/null) == *"--proxy-server=$FWD"* ]]; }
env_proxied() { [[ " $(ps eww -o command= -p "$1" 2>/dev/null) " == *" HTTPS_PROXY=$FWD "* ]]; }
daemon_pids() { pgrep -f "$DAEMON_RE" 2>/dev/null || true; }

# 存在「未指向转发器」的 app-server-daemon 时返回 0；没有 daemon 在跑也算正常。
daemon_leaking() {
  local dp
  for dp in $(daemon_pids); do
    env_proxied "$dp" || return 0
  done
  return 1
}

# 结束常驻 daemon，使其随下一次带代理环境变量的 Codex 启动重建。
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

trace_ip() { curl -s -m 20 --noproxy '' -x "$1" https://chatgpt.com/cdn-cgi/trace 2>/dev/null | sed -n 's/^ip=//p' || true; }

# 经指定代理探测 ChatGPT 看到的出口 IP。成功返回 0 并把 IP 放进 PROBE_IP；
# 失败时保留 curl 退出码 / HTTP 状态 / 错误文本（PROBE_RC / PROBE_HTTP / PROBE_ERR）供 egress_diag 解释，不再一律显示成「空」。
PROBE_RC=0 PROBE_HTTP="" PROBE_ERR="" PROBE_IP=""
egress_probe() {
  local proxy=$1 body code
  body=$(mktemp); code=$(mktemp)
  PROBE_RC=0 PROBE_HTTP="" PROBE_ERR="" PROBE_IP=""
  PROBE_ERR=$(curl -sS -m 20 --noproxy '' -x "$proxy" -o "$body" -w '%{http_code}' https://chatgpt.com/cdn-cgi/trace 2>&1 >"$code") || PROBE_RC=$?
  PROBE_HTTP=$(cat "$code" 2>/dev/null || true)
  PROBE_IP=$(sed -n 's/^ip=//p' "$body" 2>/dev/null || true)
  rm -f "$body" "$code"
  [[ -n $PROBE_IP ]]
}

upstream_addr() { awk '/^    server:/{s=$2} /^    port:/{p=$2} END{print s ":" p}' "$BASE/config.yaml" 2>/dev/null || true; }

# 把「探测不到出口 IP」翻译成：坏在哪一段（本机转发器 / 上游代理链路 / 目标站点）、依据是什么。
# 依据 = curl 退出码 + 转发器日志里最近一次向上游代理拨号的错误。
egress_diag() {
  local upstream where why
  upstream=$(upstream_addr)
  case $PROBE_RC in
    0)
      if [[ $PROBE_HTTP == 200 ]]; then
        where="目标站点"; why="chatgpt.com 返回 200，但内容里没有 ip= 字段（trace 页面格式变了？）"
      else
        where="目标站点 / 代理出口"; why="chatgpt.com 返回 HTTP ${PROBE_HTTP:-?} 而不是 trace 内容（403/503 多为 Cloudflare 拦截了代理出口 IP）"
      fi ;;
    7)  where="本机转发器"; why="连不上 127.0.0.1:$PORT（转发器刚退出或端口被占）" ;;
    28) where="上游代理链路"; why="20 秒内没有任何回应——转发器把请求交给上游代理 ${upstream} 后一直等不到数据" ;;
    35|52|56) where="上游代理链路"; why="转发器接受了 CONNECT 但随即关闭连接——这是 mihomo 向上游代理 ${upstream} 拨号失败时的表现" ;;
    *)  where="未知"; why="curl 退出码 $PROBE_RC" ;;
  esac
  bad "探测不到出口 IP：经本机转发器访问 chatgpt.com 失败"
  printf '      故障段：%s\n      原因：%s\n' "$where" "$why"
  [[ -n $PROBE_ERR ]] && printf '      curl 原始错误：%s\n' "$PROBE_ERR"
  local log=$BASE/logs/$FWD_LABEL.log line when err
  [[ -r $log ]] || return 0
  # 本机断网时会刷大量 network is unreachable，和代理无关，排除掉再找最近一条
  line=$(tail -n 2000 "$log" | grep 'dial codex-egress' | grep -v 'network is unreachable' | tail -1 || true)
  if [[ -z $line ]]; then
    printf '      转发器日志最近 2000 行没有上游拨号错误，问题更可能在本机转发器或目标站点\n'
    return 0
  fi
  when=$(sed -E 's/^time="([^"]+)".*/\1/; s/T/ /; s/\.[0-9]+\+.*//' <<<"$line")
  err=$(sed -E 's/.*error: //; s/"$//' <<<"$line")
  printf '      转发器最近一次上游错误（%s）：%s\n' "$when" "$err"
  case $err in
    *"i/o timeout"*|*"context deadline"*|*"operation timed out"*)
      printf '      → 到上游代理 %s 的建连/握手超时，属于本机→代理之间的链路问题，不是账号或脚本配置问题。\n' "$upstream"
      printf '        注意：若本机到该 IP 走的是隧道/VPN（如云枢，route -n get %s 显示 utun），nc/telnet 显示「可连」并不代表代理真的可达，以 SOCKS 握手为准\n' "${upstream%%:*}" ;;
    *EOF*)
      printf '      → 上游代理在握手后主动断开：多见于来源 IP 不在代理白名单（经隧道时来源是网关出口 IP）、账号并发超限或代理服务重启\n' ;;
    *"connection refused"*)
      printf '      → 上游代理端口拒绝连接：代理服务没在监听\n' ;;
    *"no route to host"*|*"network is unreachable"*)
      printf '      → 本机没有到上游代理的路由：检查 VPN/隧道是否在线\n' ;;
  esac
}

# 代理不通时把 curl 的真实错误和排查方向打出来，避免只留一句「连不上」
proxy_diag() {
  local proxy=$1 out rc=0 host port
  host=${proxy##*@}; port=${host##*:}; host=${host%%:*}
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
  local via_if
  via_if=$(route -n get "$host" 2>/dev/null | awk '/interface:/{print $2}' || true)
  if nc -z -G 5 -w 5 "$host" "$port" >/dev/null 2>&1; then
    if [[ $via_if == utun* ]]; then
      echo "  代理端口 TCP：可连，但本机到 $host 走的是隧道接口 $via_if（VPN/云枢），隧道会在本地替对端应答 TCP，「可连」不代表代理真的可达；以上面 curl 的结果为准"
    else
      echo "  代理端口 TCP：可连（说明是认证/策略层被拒，不是网络不通）"
    fi
  else
    echo "  代理端口 TCP：连不上（网络层就被挡住了，先查防火墙/出网策略）"
  fi
  echo "  本机公网出口 IP：$(curl -s -m 10 https://ifconfig.me 2>/dev/null || echo '取不到，本机可能完全不能直连外网')"
}
forwarder_up() { nc -z 127.0.0.1 "$PORT" >/dev/null 2>&1; }

wait_exit() {
  local pid=$1 i
  for i in $(seq 40); do kill -0 "$pid" 2>/dev/null || return 0; sleep 0.5; done
  return 1
}

# 同时清理 .zshrc（当前写入位置）和 .zprofile（旧版本写入位置）里的 codex-proxy 块。
remove_zprofile_block() {
  local f
  for f in "$ZSHRC" "$ZPROFILE"; do
    [[ -f $f ]] || continue
    awk '/^# >>> codex-proxy/{s=1;next} /^# <<< codex-proxy/{s=0;next} !s && !/desktop-proxy\.zsh/' "$f" > "$f.codex-egress.tmp"
    cat "$f.codex-egress.tmp" > "$f"
    rm -f "$f.codex-egress.tmp"
  done
}

write_plist() {
  local label=$1 file="$AGENTS/$1.plist"; shift
  local args="" a
  for a in "$@"; do args+="<string>$a</string>"; done
  cat > "$file" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>Label</key><string>$label</string>
  <key>ProgramArguments</key><array>$args</array>
  <key>RunAtLoad</key><true/>
  $EXTRA_KEYS
  <key>StandardOutPath</key><string>$BASE/logs/$label.log</string>
  <key>StandardErrorPath</key><string>$BASE/logs/$label.log</string>
</dict></plist>
EOF
  launchctl bootout "$GUI/$label" >/dev/null 2>&1 || true
  local i
  for i in $(seq 20); do
    launchctl print "$GUI/$label" >/dev/null 2>&1 || break
    sleep 0.25
  done
  for i in 1 2 3 4 5; do
    launchctl bootstrap "$GUI" "$file" 2>/dev/null && return 0
    sleep 1
  done
  die "加载 $label 失败"
}

cmd_install() {
  local proxy="${1:-}"
  [[ $(uname) == Darwin ]] || die "仅支持 macOS"
  [[ -d $APP ]] || die "未找到 ${APP}，请先安装 Codex 桌面版"
  [[ -f ${BASH_SOURCE[0]} ]] || die "请先把脚本保存成文件再运行：bash codex-egress.sh install '代理地址'"
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
    pid=$(lsof -nP -t -iTCP:"$p" -sTCP:LISTEN 2>/dev/null | head -1 || true)
    if [[ -n $pid && $(ps -o comm= -p "$pid") != "$BASE/bin/mihomo" ]]; then
      die "本机端口 ${p} 已被其他程序占用（pid ${pid}），无法安装"
    fi
  done

  echo "2/6 准备转发器 mihomo $MIHOMO_VER"
  mkdir -p "$BASE/bin" "$BASE/logs" "$AGENTS" "$HOME/Applications"
  chmod 700 "$BASE"
  if [[ -x $BASE/bin/mihomo ]] && "$BASE/bin/mihomo" -v 2>/dev/null | grep -q "$MIHOMO_VER"; then
    ok "已安装，跳过下载"
  else
    local asset sha tmp
    case $(uname -m) in
      arm64)  asset=mihomo-darwin-arm64-$MIHOMO_VER.gz;            sha=$MIHOMO_SHA_ARM64 ;;
      x86_64) asset=mihomo-darwin-amd64-compatible-$MIHOMO_VER.gz; sha=$MIHOMO_SHA_AMD64 ;;
      *) die "不支持的 CPU 架构：$(uname -m)" ;;
    esac
    tmp=$(mktemp -d)
    local url="https://github.com/MetaCubeX/mihomo/releases/download/$MIHOMO_VER/$asset"
    curl -fsSL -m 600 --noproxy '' -x "$curl_proxy" -o "$tmp/$asset" "$url" \
      || curl -fsSL -m 600 -o "$tmp/$asset" "$url" \
      || die "下载 mihomo 失败"
    [[ $(shasum -a 256 "$tmp/$asset" | cut -d' ' -f1) == "$sha" ]] || die "mihomo 校验失败，已中止"
    gunzip -c "$tmp/$asset" > "$BASE/bin/mihomo.new"
    chmod 755 "$BASE/bin/mihomo.new"
    mv "$BASE/bin/mihomo.new" "$BASE/bin/mihomo"
    rm -rf "$tmp"
    ok "下载并校验通过"
  fi
  cp "${BASH_SOURCE[0]}" "$SELF.new" && chmod 755 "$SELF.new" && mv "$SELF.new" "$SELF"

  echo "3/6 写入配置"
  local secret
  secret=$(openssl rand -hex 16)
  # YAML 单引号标量里 ' 要写成 ''；必须在 heredoc 之外算好，heredoc 内的 \' 不会被当成转义。
  local user_esc=${user//"'"/"''"} pass_esc=${pass//"'"/"''"}
  (
    umask 077
    cat > "$BASE/config.yaml" <<EOF
# 由 codex-egress.sh 生成：仅供 Codex 使用的本地转发器
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
    cat > "$BASE/env.zsh" <<EOF
export HTTP_PROXY=$FWD HTTPS_PROXY=$FWD ALL_PROXY=$FWD NO_PROXY=$NO_PROXY_LIST
export http_proxy=$FWD https_proxy=$FWD all_proxy=$FWD no_proxy=$NO_PROXY_LIST
EOF
  )
  "$BASE/bin/mihomo" -d "$BASE" -t >/dev/null || die "转发器配置校验失败"
  if [[ -f $HOME/.codex/desktop-proxy.zsh ]]; then
    rm -f "$HOME/.codex/desktop-proxy.zsh"
    ok "已移除旧方案的 ~/.codex/desktop-proxy.zsh"
  fi
  remove_zprofile_block
  cat >> "$ZSHRC" <<'EOF'
# >>> codex-proxy >>>
[[ "${CODEX_SHELL:-}" == 1 && -r ~/.codex-egress/env.zsh ]] && source ~/.codex-egress/env.zsh
codex() {
  if ! nc -z 127.0.0.1 7899 >/dev/null 2>&1; then
    echo "codex-egress 转发器未运行，已阻止 codex 直连；运行 ~/.codex-egress/codex-egress.sh check 排查" >&2
    return 1
  fi
  ( source ~/.codex-egress/env.zsh; command codex "$@" )
}
# <<< codex-proxy <<<
EOF
  ok "配置写入 ~/.codex-egress，并在 ~/.zshrc 加入 codex 命令包装"

  echo "4/6 启动转发器（开机自启）"
  EXTRA_KEYS='<key>KeepAlive</key><true/>' write_plist "$FWD_LABEL" "$BASE/bin/mihomo" -d "$BASE"
  local i
  for i in $(seq 20); do forwarder_up && break; sleep 0.5; done
  forwarder_up || die "转发器启动失败，查看 $BASE/logs/$FWD_LABEL.log"
  if egress_probe "$FWD"; then
    [[ $PROBE_IP == "$ip" ]] || die "经转发器看到的出口 IP 是 $PROBE_IP，与直连代理时的 $ip 不一致（转发器规则或代理出口有变）"
  else
    egress_diag
    die "转发器已启动，但经它访问 chatgpt.com 失败（见上）"
  fi
  ok "转发器运行中，出口 IP：$PROBE_IP"

  echo "5/6 创建启动器并以代理方式启动 Codex"
  rm -rf "$LAUNCHER"
  osacompile -o "$LAUNCHER" -e 'do shell script "/bin/bash \"$HOME/.codex-egress/codex-egress.sh\" launch >/dev/null 2>&1 &"' >/dev/null 2>&1
  cp "$APP/Contents/Resources/app.icns" "$LAUNCHER/Contents/Resources/applet.icns" 2>/dev/null || true
  codesign --force --deep -s - "$LAUNCHER" >/dev/null 2>&1 || true
  touch "$LAUNCHER"
  ok "启动器：$LAUNCHER"
  cmd_launch
  ok "Codex 已以代理方式启动"

  echo "6/6 启用守护"
  EXTRA_KEYS='<key>StartInterval</key><integer>5</integer>' write_plist "$GUARD_LABEL" /bin/bash "$SELF" guard
  ok "发现 Codex 未经代理启动（如用了原图标、自动更新后重启）时，几秒内自动切换为代理模式"

  echo
  echo "✅ 安装完成。以后请用「应用程序 → Codex Proxy」打开 Codex（可拖到 Dock 替换原图标）。"
  echo "   自检：~/.codex-egress/codex-egress.sh check"
}

cmd_launch() {
  if ! forwarder_up; then
    launchctl kickstart -k "$GUI/$FWD_LABEL" >/dev/null 2>&1 || true
    local i
    for i in $(seq 20); do forwarder_up && break; sleep 0.5; done
  fi
  if ! forwarder_up; then
    notify "转发器未运行，已取消启动 Codex"
    exit 1
  fi
  local pid
  pid=$(main_pid)
  if [[ -n $pid ]] && is_proxied "$pid" && ! daemon_leaking; then
    open -a "$APP"
    return 0
  fi
  if [[ -n $pid ]]; then
    kill -TERM "$pid" 2>/dev/null || true
    if ! wait_exit "$pid"; then
      notify "请手动退出 ChatGPT，再用 Codex Proxy 打开"
      exit 1
    fi
  fi
  # 必须在 open 之前结束：daemon 不随主进程退出，留着它会被新进程复用旧 socket，
  # 下面注入的 --env 永远到不了它身上，导致它继续直连 OpenAI 域名。
  kill_daemons
  open -a "$APP" \
    --env "CODEX_APP_SERVER_FORCE_CLI=1" \
    --env "HTTPS_PROXY=$FWD" --env "HTTP_PROXY=$FWD" --env "ALL_PROXY=$FWD" --env "NO_PROXY=$NO_PROXY_LIST" \
    --env "https_proxy=$FWD" --env "http_proxy=$FWD" --env "all_proxy=$FWD" --env "no_proxy=$NO_PROXY_LIST" \
    --args "--proxy-server=$FWD"
}

cmd_guard() {
  local pid
  pid=$(main_pid)
  [[ -z $pid ]] && return 0
  if ! is_proxied "$pid"; then
    echo "$(date '+%F %T') 检测到 Codex 未经代理启动（pid ${pid}），自动切换"
    notify "检测到 Codex 未经代理启动，正在切换为代理模式"
    cmd_launch
    return 0
  fi
  daemon_leaking || return 0
  # daemon 泄漏需要重启整个 Codex 才能修，加 120 秒冷却，避免修不好时 5 秒一次反复重启。
  local now last
  now=$(date +%s)
  last=$(cat "$GUARD_STAMP" 2>/dev/null || echo 0)
  if (( now - last < 120 )); then return 0; fi
  echo "$now" > "$GUARD_STAMP"
  echo "$(date '+%F %T') 检测到后台 app-server-daemon 未经转发器（pid $(daemon_pids | tr '\n' ' ')），重启 Codex 重建"
  notify "后台进程未经代理，正在重启 Codex 修复"
  cmd_launch
}

cmd_check() {
  local secs=${1:-60} failed=0
  [[ -f $BASE/config.yaml ]] || die "未安装 codex-egress"
  local expect secret
  expect=$(cat "$BASE/proxy-ip")
  secret=$(awk '/^secret:/{print $2}' "$BASE/config.yaml")

  echo "1. 转发器"
  if forwarder_up; then
    if egress_probe "$FWD"; then
      if [[ $PROBE_IP == "$expect" ]]; then
        ok "运行中，出口 IP $PROBE_IP"
      else
        bad "出口 IP 不符：ChatGPT 实际看到 $PROBE_IP，期望 $expect（代理出口变了？确认后重新 install 以更新期望值）"; failed=1
      fi
    else
      egress_diag; failed=1
    fi
  else
    bad "转发器未运行"; failed=1
  fi
  launchctl print "$GUI/$GUARD_LABEL" >/dev/null 2>&1 && ok "守护已启用" || { bad "守护未启用"; failed=1; }

  echo "2. Codex 进程"
  local pid
  pid=$(main_pid)
  if [[ -z $pid ]]; then
    warn "Codex 未运行，正在以代理方式启动"
    cmd_launch
    sleep 10
    pid=$(main_pid)
  fi
  if [[ -n $pid ]] && is_proxied "$pid"; then ok "Codex 以代理方式运行（pid ${pid}）"; else bad "Codex 未以代理方式运行"; failed=1; fi
  local server_pid
  server_pid=$(pgrep -f "^$APP/Contents/Resources/codex-cli/" | head -1 || true)
  if [[ -n $server_pid ]] && env_proxied "$server_pid"; then
    ok "应用内 codex-cli 已指向转发器"
  else
    bad "应用内 codex-cli 未指向转发器"; failed=1
  fi
  local dp bad_daemons=""
  for dp in $(daemon_pids); do
    env_proxied "$dp" || bad_daemons+=" $dp"
  done
  if [[ -z $(daemon_pids) ]]; then
    warn "未发现常驻 app-server-daemon（Codex 可能尚未完全启动）"
  elif [[ -z $bad_daemons ]]; then
    ok "常驻 app-server-daemon 已指向转发器"
  else
    bad "常驻 app-server-daemon 未指向转发器（pid${bad_daemons}），它会直连 OpenAI 域名"
    bad "  修复：~/.codex-egress/codex-egress.sh launch （会重启 Codex 以重建该进程）"
    failed=1
  fi

  echo "3. 监控 ${secs} 秒（期间可正常使用 Codex，发几条消息）"
  local tmp
  tmp=$(mktemp -d)
  local end=$((SECONDS + secs)) pids
  while (( SECONDS < end )); do
    pids=$(ps -axo pid=,comm= | while read -r p path; do [[ $path =~ $PROC_RE ]] && printf '%s,' "$p"; done || true)
    if [[ -n $pids ]]; then
      lsof -nP -a -p "${pids%,}" -iTCP -F pcn 2>/dev/null |
        awk '/^c/{c=substr($0,2)} /^n/ && /->/{print c "\t" substr($0,2)}' >> "$tmp/sock" || true
    fi
    curl -s -m 3 -H "Authorization: Bearer $secret" "http://127.0.0.1:$API_PORT/connections" |
      jq -r '.connections[]? | [(.metadata.host // .metadata.destinationIP), (.chains | join(" < "))] | @tsv' >> "$tmp/fwd" 2>/dev/null || true
    sleep 0.5
  done
  local leaks
  leaks=$(sort -u "$tmp/sock" 2>/dev/null | awk -F'\t' '{
      split($2, ep, "->"); r = ep[2]; h = r; sub(/:[0-9]+$/, "", h); gsub(/[\[\]]/, "", h)
      if (h ~ /^(127\.|::1$|10\.|192\.168\.|172\.(1[6-9]|2[0-9]|3[01])\.)/) next
      print $1 "\t" r }' | sort | uniq -c || true)
  local total known others
  total=$(sort -u "$tmp/sock" 2>/dev/null | wc -l | tr -d ' ' || true)
  known=$(grep -F 'SkyComputerUse' <<<"$leaks" || true)
  others=$(grep -vF 'SkyComputerUse' <<<"$leaks" | grep -v '^$' || true)
  if [[ -z $others && -n $known ]]; then
    ok "Codex 相关进程共 ${total} 条连接，除下面的已知例外外，全部经过本机转发器或访问内网"
  elif [[ -z $others ]]; then
    ok "Codex 相关进程共 ${total} 条连接，全部经过本机转发器或访问内网"
  else
    bad "发现绕过转发器直连外网的连接："
    echo "$others" | sed 's/^/      /'
    failed=1
  fi
  if [[ -n $known ]]; then
    warn "已知例外：Computer Use 功能（SkyComputerUseService、SkyComputerUseClient）是原生程序，不遵守代理设置，以下连接直连："
    echo "$known" | sed 's/^/      /'
  fi
  if [[ -s $tmp/fwd ]]; then
    echo "  经代理 IP 访问的域名："
    sort -u "$tmp/fwd" | awk -F'\t' '$2 == "codex-egress" {printf "      %s\n", $1}'
    echo "  经转发器但按规则直连的域名（非 OpenAI 域名属正常；若其中有 OpenAI 相关域名，才需补进脚本的 PROXY_DOMAINS）："
    sort -u "$tmp/fwd" | awk -F'\t' '$2 != "codex-egress" {printf "      %s\n", $1}'
  fi
  rm -rf "$tmp"

  echo "4. 请求质量（精简版：5 次探测 + 最近 1 小时日志；完整报告见 codex-egress.sh quality）"
  q_probe 5 || warn "链路质量不佳不影响「出网只走代理 IP」的结论，但会表现为 Codex 卡顿 / reconnecting"
  q_log 1 || true

  echo
  if (( failed == 0 )) && [[ -n $known ]]; then
    printf '\033[32m通过（有已知例外）：除 Computer Use 功能外，Codex 访问 OpenAI 的请求只从 %s 出网\033[0m\n' "$expect"
  elif (( failed == 0 )); then
    printf '\033[32m通过：Codex 访问 OpenAI 的请求只从 %s 出网\033[0m\n' "$expect"
  else
    printf '\033[31m未通过，请按上面的提示处理\033[0m\n'
  fi
  return $failed
}

# ============================== 请求质量 ==============================
# 四个数据源拼出「整条链路」的质量：
#   A. 主动探测      本机 → 转发器 → 上游代理 → chatgpt.com，和「本机 → 上游代理 → chatgpt.com」直连对照，
#                   区分出慢/失败在转发器还是上游
#   B. 转发器实时连接 mihomo API /connections：Codex 当前挂着哪些长连接、活了多久、流量多少
#   C. 转发器日志    mihomo 只记失败（log-level: warning），按「本机无网 / 上游超时 / 上游断开」分类并逐小时画出来，
#                   叠加系统睡眠/唤醒记录，一眼看出是合盖导致还是代理本身抖
#   D. Codex 侧      app-server-daemon 的 stderr：模型列表刷新超时、WebSocket 连不上、MCP 断流——这些就是 TUI 里 reconnecting 的直接来源
Q_URL=https://chatgpt.com/cdn-cgi/trace

api_secret() { awk '/^secret:/{print $2}' "$BASE/config.yaml"; }
api() { curl -s -m "${2:-3}" -H "Authorization: Bearer $(api_secret)" "http://127.0.0.1:$API_PORT$1"; }

# 从 config.yaml 读上游代理，供直连对照探测；凭据只进 curl 参数，不打印
UP_SCHEME="" UP_HOST="" UP_PORT="" UP_USER="" UP_PASS=""
load_upstream() {
  eval "$(awk -F': ' '
    /^    type:/ {t=$2} /^    server:/ {s=$2} /^    port:/ {p=$2}
    /^    username:/ {u=$2} /^    password:/ {w=$2}
    END {
      gsub(/^\047|\047$/, "", u); gsub(/^\047|\047$/, "", w); gsub(/\047\047/, "\047", u); gsub(/\047\047/, "\047", w)
      gsub(/\047/, "\047\\\047\047", u); gsub(/\047/, "\047\\\047\047", w)
      printf "UP_SCHEME=%s UP_HOST=%s UP_PORT=%s UP_USER=\047%s\047 UP_PASS=\047%s\047\n", t, s, p, u, w
    }' "$BASE/config.yaml")"
}

# 跑 n 次 curl，每行输出：http码 建链+TLS秒 首字节秒 总秒
q_probe_run() {
  local n=$1 i; shift
  for i in $(seq "$n"); do
    curl -s -m 15 --noproxy '' -o /dev/null \
      -w '%{http_code} %{time_appconnect} %{time_starttransfer} %{time_total}\n' "$@" "$Q_URL" 2>/dev/null \
      || echo "000 0 0 0"
  done
}
# 读 q_probe_run 的输出，打一行汇总；返回值 0 良好 / 1 一般 / 2 差
q_probe_summary() {
  awk -v label="$1" '
    function pct(arr, n, p,   i, j, tmp, idx) {
      for (i = 2; i <= n; i++) { tmp = arr[i]; j = i - 1; while (j > 0 && arr[j] > tmp) { arr[j+1] = arr[j]; j-- } arr[j+1] = tmp }
      idx = int((n - 1) * p / 100 + 0.5) + 1; return arr[idx]
    }
    { n++; if ($1 == "200") { ok++; a[ok] = $2 * 1000; t[ok] = $4 * 1000 } else { fail[$1]++ } }
    END {
      if (n == 0) { printf "  %s：没有样本\n", label; exit 2 }
      fails = ""; for (c in fail) fails = fails sprintf(" http=%s×%d", c, fail[c])
      if (ok == 0) { printf "  \033[31m✘\033[0m %s：%d 次全部失败%s\n", label, n, fails; exit 2 }
      p50 = pct(t, ok, 50); p95 = pct(t, ok, 95); mx = pct(t, ok, 100)
      tls50 = pct(a, ok, 50); tlsmx = pct(a, ok, 100)
      grade = (ok < n) ? 2 : (p50 < 600 && p95 < 1500) ? 0 : (p50 < 1500 && p95 < 4000) ? 1 : 2
      mark = (grade == 0) ? "\033[32m✔\033[0m" : (grade == 1) ? "\033[33m!\033[0m" : "\033[31m✘\033[0m"
      printf "  %s %s：成功 %d/%d  建链+TLS p50 %.0fms(最差 %.0fms)  整请求 p50 %.0fms / p95 %.0fms / 最差 %.0fms%s\n",
        mark, label, ok, n, tls50, tlsmx, p50, p95, mx, fails
      exit grade
    }'
}

# A. 主动探测
q_probe() {
  local n=${1:-10} rc_fwd=0 rc_up=0 out
  echo "A. 主动探测 ${n} 次 ${Q_URL}（建链+TLS = CONNECT 穿过代理并完成 TLS 握手；整请求 = 到拿完响应）"
  if forwarder_up; then
    out=$(q_probe_run "$n" -x "$FWD")
    q_probe_summary "经转发器 127.0.0.1:$PORT" <<<"$out" || rc_fwd=$?
  else
    bad "转发器未运行，跳过"; rc_fwd=2
  fi
  load_upstream
  if [[ -n $UP_HOST ]]; then
    local scheme=$UP_SCHEME; [[ $scheme == socks5 ]] && scheme=socks5h
    out=$(q_probe_run "$n" -x "$scheme://$UP_HOST:$UP_PORT" --proxy-user "$UP_USER:$UP_PASS")
    q_probe_summary "直连上游 $UP_HOST:$UP_PORT" <<<"$out" || rc_up=$?
    local via_if
    via_if=$(route -n get "$UP_HOST" 2>/dev/null | awk '/interface:/{print $2}' || true)
    [[ $via_if == utun* ]] && printf '      本机到上游走的是隧道接口 %s（VPN/云枢），耗时包含隧道那一跳\n' "$via_if"
  fi
  local d i ds=""
  for i in 1 2 3; do
    d=$(api "/proxies/codex-egress/delay?timeout=5000&url=$(printf '%s' "$Q_URL" | sed 's/:/%3A/g; s/\//%2F/g')" 8 \
        | jq -r 'if .delay then "\(.delay)ms" else "失败" end' 2>/dev/null || echo "失败")
    ds+="$d "
  done
  printf '  转发器自测上游延迟（mihomo 内部计时，3 次）：%s\n' "$ds"
  if (( rc_fwd == 0 )); then
    ok "链路通畅"
  elif (( rc_up >= rc_fwd )); then
    warn "慢/失败在「上游代理 → OpenAI」这一段（直连上游同样差），本机转发器没有拖后腿"
  else
    warn "经转发器比直连上游明显更差，怀疑本机转发器（mihomo）本身：launchctl kickstart -k $GUI/$FWD_LABEL 重启它试试"
  fi
  return $rc_fwd
}

# B. 转发器当前连接
q_conns() {
  echo "B. 转发器当前经代理 IP 的连接（长连接 = Codex 挂着的 WebSocket / MCP 流；它们一断 TUI 就会 reconnecting）"
  local json
  json=$(api /connections) || true
  if [[ -z $json ]]; then bad "转发器 API 不可达"; return 1; fi
  local now; now=$(date +%s)
  local rows
  rows=$(jq -r '.connections[]? | select(.chains | index("codex-egress"))
           | [ .metadata.host // .metadata.destinationIP, (.start | sub("\\.[0-9]+"; "")), .upload, .download ] | @tsv' <<<"$json" 2>/dev/null \
    | while IFS=$'\t' read -r host start up down; do
        local st age
        st=$(date -j -f "%Y-%m-%dT%H:%M:%S%z" "$(sed -E 's/([+-][0-9]{2}):([0-9]{2})$/\1\2/; s/Z$/+0000/' <<<"$start")" +%s 2>/dev/null || echo "$now")
        age=$(( now - st ))
        printf '%s\t%d\t%d\t%d\n' "$host" "$age" "$up" "$down"
      done | sort -t$'\t' -k2,2nr)
  if [[ -z $rows ]]; then
    warn "此刻没有经代理 IP 的连接（Codex 空闲或还没启动）"
  else
    printf '      %-44s %10s %10s %10s\n' 域名 已存活 上传 下载
    awk -F'\t' 'function hb(b){ if(b>1048576) return sprintf("%.1fMB",b/1048576); if(b>1024) return sprintf("%.0fKB",b/1024); return b "B" }
                function hd(s){ if(s>=3600) return sprintf("%dh%02dm",s/3600,(s%3600)/60); if(s>=60) return sprintf("%dm%02ds",s/60,s%60); return s "s" }
                { printf "      %-44s %10s %10s %10s\n", $1, hd($2), hb($3), hb($4) }' <<<"$rows"
  fi
  jq -r '"      转发器自启动以来累计：上传 \(.uploadTotal/1048576|floor)MB，下载 \(.downloadTotal/1048576|floor)MB，当前连接 \(.connections|length) 条"' <<<"$json" 2>/dev/null || true
}

# C. 转发器日志：按类分、逐小时画
q_log() {
  local hours=${1:-24} log=$BASE/logs/$FWD_LABEL.log
  echo "C. 转发器日志最近 ${hours} 小时（只记失败；成功的请求不在这里）"
  [[ -r $log ]] || { warn "没有日志文件"; return 0; }
  local since; since=$(date -v-"${hours}"H +%Y-%m-%dT%H:%M:%S)
  local tmp; tmp=$(mktemp)
  # 分类：L 本机无网  T 上游超时  E 上游断开  O 其它；输出：类别 小时 目标域名
  grep -a '^time="' "$log" | awk -v since="$since" '
    { ts = substr($0, 7, 19); if (ts < since) next
      h = substr(ts, 1, 13)
      host = ""; if (match($0, /--> [^ :]+:[0-9]+/)) { host = substr($0, RSTART + 4, RLENGTH - 4); sub(/:[0-9]+$/, "", host) }
      if ($0 ~ /network is unreachable|no route to host/) c = "L"
      else if ($0 ~ /i\/o timeout|context deadline exceeded|operation timed out/) c = "T"
      else if ($0 ~ /error: EOF|connection reset|connection refused/) c = "E"
      else c = "O"
      print c "\t" h "\t" host }' > "$tmp"
  local total; total=$(wc -l < "$tmp" | tr -d ' ')
  if (( total == 0 )); then ok "这 ${hours} 小时转发器没有记录任何失败"; rm -f "$tmp"; return 0; fi
  local nL nT nE nO
  nL=$(grep -c '^L' "$tmp" || true); nT=$(grep -c '^T' "$tmp" || true); nE=$(grep -c '^E' "$tmp" || true); nO=$(grep -c '^O' "$tmp" || true)
  printf '  共 %d 次失败：本机无网 %d（合盖/唤醒/切网时，与代理无关） | 上游超时 %d | 上游断开 %d | 其它 %d\n' "$total" "$nL" "$nT" "$nE" "$nO"
  # 睡眠/唤醒事件所在的小时
  local sleep_hours
  sleep_hours=$(pmset -g log 2>/dev/null | grep -E 'Entering Sleep|Wake from|DarkWake from' | awk '{print substr($1,1,10) "T" substr($2,1,2)}' | sort -u | tr '\n' ' ' || true)
  echo "  逐小时（每格 █ ≈ 10 次；L=本机无网 T=上游超时 E=上游断开；💤 = 该小时有睡眠/唤醒）："
  awk -F'\t' '{print $2 "\t" $1}' "$tmp" | sort | uniq -c | awk -v sh=" $sleep_hours " '
    function flush() {
      if (h == "") return
      bar = ""; for (k = 0; k < int((T + E + O + 9) / 10) && k < 40; k++) bar = bar "█"
      lbar = ""; for (k = 0; k < int((L + 9) / 10) && k < 40; k++) lbar = lbar "░"
      z = (index(sh, " " h " ") > 0) ? "💤" : "  "
      printf "    %s:00 %s L%-5d T%-5d E%-4d O%-3d %s%s\n", substr(h, 6), z, L, T, E, O, bar, lbar
      L = T = E = O = 0
    }
    { if ($2 != h) { flush(); h = $2 }
      if ($3 == "L") L = $1; else if ($3 == "T") T = $1; else if ($3 == "E") E = $1; else O = $1 }
    END { flush() }'
  echo "    （█ 上游问题  ░ 本机无网）"
  if (( nT + nE > 0 )); then
    echo "  上游失败最多的目标："
    awk -F'\t' '$1=="T"||$1=="E"{print $3}' "$tmp" | sort | uniq -c | sort -rn | head -5 | awk '{printf "      %6d  %s\n", $1, $2}'
    local last
    last=$(grep -a 'dial codex-egress' "$log" | grep -avE 'network is unreachable|no route to host' | tail -1 | sed -E 's/^time="([^"]+)".*error: (.*)"$/\1  \2/; s/T/ /; s/\.[0-9]+\+[0-9:]+//')
    [[ -n $last ]] && printf '  最近一次上游失败：%s\n' "$last"
  fi
  rm -f "$tmp"
  # 评级只看上游问题，排除本机无网
  local per_hour=$(( (nT + nE) / (hours > 0 ? hours : 1) ))
  if (( nT + nE == 0 )); then ok "上游代理在这 ${hours} 小时没有失败记录"
  elif (( per_hour < 5 )); then ok "上游代理平均每小时失败 ${per_hour} 次，属正常抖动"
  elif (( per_hour < 30 )); then warn "上游代理平均每小时失败 ${per_hour} 次，偏多；Codex 会时不时 reconnecting"
  else bad "上游代理平均每小时失败 ${per_hour} 次，质量差：建议换节点或加备用节点"; return 1; fi
}

# D. Codex daemon 侧
q_daemon() {
  local hours=${1:-24} d=$HOME/.codex/app-server-daemon
  echo "D. Codex app-server-daemon 最近 ${hours} 小时的网络类错误（这是 TUI 里 reconnecting 的直接来源）"
  [[ -d $d ]] || { warn "没有 $d"; return 0; }
  local since; since=$(date -u -v-"${hours}"H +%Y-%m-%dT%H:%M:%S)
  local lines
  lines=$(cat "$d/daemon.stderr.log.previous" "$d/daemon.stderr.log" 2>/dev/null | sed 's/\x1b\[[0-9;]*m//g' | awk -v s="$since" 'substr($1,1,19) >= s' || true)
  if [[ -z $lines ]]; then ok "没有错误记录"; return 0; fi
  local n_models n_ws n_mcp n_tls
  n_models=$(grep -c 'failed to refresh available models' <<<"$lines" || true)
  n_ws=$(grep -c 'failed to connect to websocket' <<<"$lines" || true)
  n_tls=$(grep -c 'tls handshake eof' <<<"$lines" || true)
  n_mcp=$(grep -cE 'worker quit with fatal|Transport channel closed' <<<"$lines" || true)
  printf '  模型列表刷新超时 %d  |  模型流 WebSocket 连不上 %d（其中 TLS 被掐 %d）  |  MCP 连接断开 %d\n' "$n_models" "$n_ws" "$n_tls" "$n_mcp"
  local last
  last=$(grep -E 'websocket|Transport channel closed|refresh available models' <<<"$lines" | tail -3 | sed -E 's/^([0-9T:-]+)\.[0-9]+Z +ERROR +[^ ]+ +/\1Z  /' | cut -c1-150)
  [[ -n $last ]] && { echo "  最近 3 条（UTC 时间）："; sed 's/^/      /' <<<"$last"; }
  local up; up=$(jq -r '.processStartTime // empty' "$d/daemon.pid" 2>/dev/null || true)
  [[ -n $up ]] && printf '  daemon 当前进程启动于：%s（自动更新/被守护重建都会导致一次 reconnecting）\n' "$up"
  local restarts
  restarts=$(grep -c '"event":"restart_requested"' "$d/daemon-updater.stderr.log" 2>/dev/null || true)
  (( restarts > 0 )) && printf '  updater 日志里累计 %d 次自动更新重启\n' "$restarts"
  if (( n_ws + n_mcp > 0 )); then warn "有 WebSocket/MCP 断连记录，和上面 C 的上游失败对照时间即可定位"; fi
  return 0
}

cmd_quality() {
  [[ -f $BASE/config.yaml ]] || die "未安装 codex-egress"
  if [[ ${1:-} == live ]]; then
    echo "实时跟踪转发器失败（Ctrl+C 退出）；[本机无网] 可忽略，[上游超时]/[上游断开] 才是代理质量问题"
    tail -n 0 -F "$BASE/logs/$FWD_LABEL.log" | awk '
      { ts = substr($0, 7, 19); sub(/T/, " ", ts)
        host = ""; if (match($0, /--> [^ ]+/)) host = substr($0, RSTART + 4, RLENGTH - 4)
        err = $0; sub(/.*error: /, "", err); sub(/"$/, "", err)
        if ($0 ~ /network is unreachable|no route to host/) tag = "\033[2m[本机无网]\033[0m"
        else if ($0 ~ /i\/o timeout|context deadline exceeded/) tag = "\033[33m[上游超时]\033[0m"
        else if ($0 ~ /error: EOF|connection reset|refused/) tag = "\033[31m[上游断开]\033[0m"
        else tag = "[其它]"
        printf "%s %s %-40s %s\n", ts, tag, host, err; fflush() }'
    return 0
  fi
  local hours=${1:-24} rc=0
  [[ $hours =~ ^[0-9]+$ ]] || die "用法：quality [小时数] | quality live"
  q_probe 10 || rc=1; echo
  q_conns || true; echo
  q_log "$hours" || rc=1; echo
  q_daemon "$hours" || true
  echo
  if (( rc == 0 )); then printf '\033[32m链路质量正常\033[0m\n'; else printf '\033[33m链路质量有问题，见上面标 ! / ✘ 的项\033[0m\n'; fi
  return $rc
}

cmd_uninstall() {
  launchctl bootout "$GUI/$GUARD_LABEL" >/dev/null 2>&1 || true
  launchctl bootout "$GUI/$FWD_LABEL" >/dev/null 2>&1 || true
  rm -f "$AGENTS/$GUARD_LABEL.plist" "$AGENTS/$FWD_LABEL.plist"
  rm -rf "$LAUNCHER"
  remove_zprofile_block
  local pid
  pid=$(main_pid)
  if [[ -n $pid ]] && is_proxied "$pid"; then
    kill -TERM "$pid" 2>/dev/null || true
    wait_exit "$pid" || true
    ok "已退出以代理方式运行的 Codex，之后正常打开即可"
  fi
  # 常驻 daemon 仍带着指向转发器的环境变量，必须一并结束，否则卸载后它会连不上网。
  if [[ -n $(daemon_pids) ]]; then
    kill_daemons
    ok "已结束常驻 app-server-daemon，下次打开 Codex 会以无代理方式重建"
  fi
  rm -rf "$BASE"
  ok "已卸载：转发器、守护、启动器、~/.zshrc 中的 codex 包装均已移除"
}

case "${1:-}" in
  install)      shift; cmd_install "$@" ;;
  launch)       cmd_launch ;;
  guard)        cmd_guard ;;
  check)        shift; cmd_check "$@" ;;
  quality)      shift; cmd_quality "$@" ;;
  uninstall)    cmd_uninstall ;;
  *) sed -n '2,12p' "$0"; exit 1 ;;
esac
