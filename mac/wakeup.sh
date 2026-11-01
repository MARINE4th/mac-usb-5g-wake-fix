#!/bin/bash
# Mac 唤醒时由 sleepwatcher 执行。安装到 ~/.wakeup
source "$HOME/.usbnet/config"
D="$HOME/.usbnet"
LOG="$HOME/.usb-wake.log"

# 日志超过 2000 行时只保留最近 1000 行
if [ -f "$LOG" ] && [ "$(wc -l < "$LOG")" -gt 2000 ]; then
  tail -n 1000 "$LOG" > "$LOG.tmp" && mv "$LOG.tmp" "$LOG"
fi

# 通信壳没插着（比如出差拔掉了）就什么都不做
/usr/sbin/ioreg -p IOUSB -l -w0 | grep -q "$SERIAL" || exit 0

# 打开高速刷新窗口，并让状态栏立即刷新
echo $(( $(date +%s) + ${WINDOW:-10} )) > "$D/fast_until"
kill -USR1 "$(cat "$D/plugin.pid" 2>/dev/null)" 2>/dev/null

# 每 0.5 秒检查一次网卡，一发现断开就重连；连续 5 秒正常才跳过
for i in 1 2 3 4 5 6 7 8 9 10; do
  if ! /sbin/ifconfig "$IF" 2>/dev/null | grep -q "status: active" \
     || ! /sbin/ifconfig "$IF" | grep -q "inet "; then
    echo "$(date '+%F %T') 网络断开" >> "$LOG"
    "$D/reconnect.sh" 自动
    exit 0
  fi
  sleep 0.5
done
echo "$(date '+%F %T') 网络正常，跳过" >> "$LOG"
