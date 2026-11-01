#!/bin/bash
# <xbar.title>USB 5G 通信壳状态</xbar.title>
# <swiftbar.type>streamable</swiftbar.type>
#
# SwiftBar 常驻插件：在状态栏显示通信壳的连接状态和重连进度。
# 平时每 SLOW 秒刷新；唤醒或重连后 WINDOW 秒内每 FAST 秒刷新。
source "$HOME/.usbnet/config"
D="$HOME/.usbnet"
STATE="$D/state"
LOG="$HOME/.usb-wake.log"
FAST=${FAST:-0.1}; SLOW=${SLOW:-10}; WINDOW=${WINDOW:-10}
WEBUI=${WEBUI:-http://192.168.66.1}

echo $$ > "$D/plugin.pid"   # 让其他脚本知道该通知谁
trap ':' USR1               # 收到 USR1 只用来打断等待、立即进入下一轮

# 生成一帧菜单内容（依赖循环里算好的 $present）
render() {
  info=$(/sbin/ifconfig $IF 2>/dev/null)
  ip=$(echo "$info" | awk '/inet /{print $2}')
  active=0
  echo "$info" | grep -q "status: active" && [ -n "$ip" ] && active=1
  now=$(date +%s)
  start=$(cat "$STATE" 2>/dev/null)
  age=$(( now - ${start:-$now} ))

  if [ -n "$start" ] && { [ $age -lt 6 ] || { [ $active = 0 ] && [ $age -lt 45 ]; }; }; then
    echo "🟡 5G"; echo "---"; echo "重连中…（${age} 秒）"
  elif [ $active = 1 ]; then
    [ -n "$start" ] && { echo "$(date '+%F %T') 网络已恢复（用时 ${age} 秒）" >> "$LOG"; rm -f "$STATE"; }
    echo "🟢 5G"; echo "---"; echo "已连接  $ip"
  elif [ $present = 1 ]; then
    [ -n "$start" ] && { echo "$(date '+%F %T') 重连超时" >> "$LOG"; rm -f "$STATE"; }
    echo "🔴 5G"; echo "---"; echo "已断开（设备在线，可重连）"
  else
    rm -f "$STATE"
    echo "⚪ 5G"; echo "---"; echo "未插入设备"
  fi
  [ $present = 1 ] && echo "立即重连 | bash=$D/reconnect.sh param1=手动 terminal=false"
  echo "---"
  echo "最近记录"
  tail -n 5 "$LOG" 2>/dev/null | while read -r line; do echo "--$line"; done
  echo "打开后台 | href=$WEBUI"
}

prev=""
last=$(date +%s)
while true; do
  present=0
  /usr/sbin/ioreg -p IOUSB -l -w0 | grep -q "$SERIAL" && present=1

  # 先在内存里拼好整帧，内容有变化才一次性输出，避免图标闪烁
  out=$(render)
  if [ "$out" != "$prev" ]; then
    printf '~~~\n%s\n' "$out"
    prev=$out
  fi

  now=$(date +%s)
  # 兜底：两轮之间隔得太久，说明 Mac 刚睡醒过
  [ $present = 1 ] && [ $((now - last)) -gt $((SLOW + 5)) ] && echo $((now + WINDOW)) > "$D/fast_until"
  last=$now

  fu=$(cat "$D/fast_until" 2>/dev/null)
  if [ "${fu:-0}" -gt "$now" ]; then iv=$FAST; else iv=$SLOW; fi
  sleep $iv & wait $!   # wait 可被 USR1 打断，sleep 不行
  kill $! 2>/dev/null
done
