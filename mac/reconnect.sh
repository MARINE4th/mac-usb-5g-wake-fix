#!/bin/bash
# 通过 USB ADB 让通信壳执行一次软件插拔。安装到 ~/.usbnet/reconnect.sh
# 由 ~/.wakeup 自动调用，也可由状态栏菜单“立即重连”手动调用。
source "$HOME/.usbnet/config"
D="$HOME/.usbnet"
LOG="$HOME/.usb-wake.log"
DEVICE_SCRIPT="${DEVICE_SCRIPT:-/mnt/userdata/usbwd/rebind.sh}"

now=$(date +%s)
echo "$now" > "$D/state"                         # 状态栏据此显示“重连中”
echo $((now + ${WINDOW:-10})) > "$D/fast_until"  # 打开高速刷新窗口
kill -USR1 "$(cat "$D/plugin.pid" 2>/dev/null)" 2>/dev/null   # 通知状态栏立即刷新
echo "$(date '+%F %T') 开始重连（${1:-手动}）" >> "$LOG"

# 唤醒后 adb 可能需要片刻才认到设备，最多等 10 秒
for i in 1 2 3 4 5; do
  "$ADB" -s "$SERIAL" get-state >/dev/null 2>&1 && break
  sleep 2
done
( "$ADB" -s "$SERIAL" shell "$DEVICE_SCRIPT" >/dev/null 2>&1 & )
echo "$(date '+%F %T') 已发送重连命令" >> "$LOG"
