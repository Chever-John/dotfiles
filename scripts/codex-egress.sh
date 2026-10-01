#!/bin/bash
# codex-egress：让 Codex（ChatGPT 桌面版 + codex CLI）的全部请求只从指定代理 IP 出网，不影响其他应用。
#
#   安装:  bash codex-egress.sh install 'http://用户名:密码@IP:端口'
#   启动:  打开「应用程序 → Codex Proxy」（或 ~/.codex-egress/codex-egress.sh launch）
#   自检:  ~/.codex-egress/codex-egress.sh check [秒数]
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
ZPROFILE="$HOME/.zprofile"
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
forwarder_up() { nc -z 127.0.0.1 "$PORT" >/dev/null 2>&1; }

wait_exit() {
  local pid=$1 i
  for i in $(seq 40); do kill -0 "$pid" 2>/dev/null || return 0; sleep 0.5; done
  return 1
}

remove_zprofile_block() {
  [[ -f $ZPROFILE ]] || return 0
  awk '/^# >>> codex-proxy/{s=1;next} /^# <<< codex-proxy/{s=0;next} !s && !/desktop-proxy\.zsh/' "$ZPROFILE" > "$ZPROFILE.codex-egress.tmp"
  cat "$ZPROFILE.codex-egress.tmp" > "$ZPROFILE"
  rm -f "$ZPROFILE.codex-egress.tmp"
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
  [[ -n $ip ]] || die "代理连不上，请检查地址和账号密码（本次未做任何修改）"
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
  cat >> "$ZPROFILE" <<'EOF'
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
  ok "配置写入 ~/.codex-egress，并在 ~/.zprofile 加入 codex 命令包装"

  echo "4/6 启动转发器（开机自启）"
  EXTRA_KEYS='<key>KeepAlive</key><true/>' write_plist "$FWD_LABEL" "$BASE/bin/mihomo" -d "$BASE"
  local i
  for i in $(seq 20); do forwarder_up && break; sleep 0.5; done
  forwarder_up || die "转发器启动失败，查看 $BASE/logs/$FWD_LABEL.log"
  local via
  via=$(trace_ip "$FWD")
  [[ $via == "$ip" ]] || die "经转发器的出口 IP 为 ${via:-空}，与代理 IP $ip 不一致"
  ok "转发器运行中，出口 IP：$via"

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
    local via
    via=$(trace_ip "$FWD")
    [[ $via == "$expect" ]] && ok "运行中，出口 IP $via" || { bad "出口 IP 为 ${via:-空}，期望 $expect"; failed=1; }
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
  ok "已卸载：转发器、守护、启动器、~/.zprofile 中的 codex 包装均已移除"
}

case "${1:-}" in
  install)      shift; cmd_install "$@" ;;
  launch)       cmd_launch ;;
  guard)        cmd_guard ;;
  check)        shift; cmd_check "$@" ;;
  uninstall)    cmd_uninstall ;;
  *) sed -n '2,11p' "$0"; exit 1 ;;
esac
