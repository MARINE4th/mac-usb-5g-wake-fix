#!/bin/sh
# 运行在通信壳上：断开并重新连接 USB gadget，相当于一次“软件插拔”。
# 放到 /mnt/userdata/usbwd/rebind.sh，由 Mac 通过 USB ADB 调用。

# ADB 本身也走这条 USB，解绑时 adb 会话会断开并发来挂断信号。
# 忽略这些信号，保证“重新绑定”这一步一定执行。
trap "" HUP INT TERM

UDC=$(ls /sys/class/udc | head -n 1)
GADGET=/sys/kernel/config/usb_gadget/$(ls /sys/kernel/config/usb_gadget | head -n 1)
LOG="$(dirname "$0")/rebind.log"

# 日志超过 400 行时只保留最近 200 行，避免长期堆积
if [ -f "$LOG" ] && [ "$(wc -l < "$LOG")" -gt 400 ]; then
  tail -n 200 "$LOG" > "$LOG.tmp" && mv "$LOG.tmp" "$LOG"
fi

exec >> "$LOG" 2>&1 < /dev/null
echo "$(date '+%F %T') begin (udc=$UDC gadget=$GADGET)"
sleep 1                                       # 给 adb 一点时间返回
echo "" > "$GADGET/UDC" && echo "unbind ok"   # 断开：主机看到设备被拔出
sleep 2
echo "$UDC" > "$GADGET/UDC" && echo "bind ok" # 重连：主机看到设备被插入
echo "$(date '+%F %T') end, state=$(cat /sys/class/udc/$UDC/state)"
