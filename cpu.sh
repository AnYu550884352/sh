#!/bin/sh
#CPU时间计算公式：CPU_TIME=user+system+nice+idle+iowait+irq+softirq
#CPU使用率计算公式：cpu_usage=(idle2-idle1)/(cpu2-cpu1)*100
#默认时间间隔
TIME_INTERVAL=5
time=$(date "+%Y-%m-%d %H:%M:%S")
LAST_CPU_INFO=$(cat /proc/stat | grep -w cpu | awk '{print $2,$3,$4,$5,$6,$7,$8}')
LAST_SYS_IDLE=$(echo $LAST_CPU_INFO | awk '{print $4}')
LAST_TOTAL_CPU_T=$(echo $LAST_CPU_INFO | awk '{print $1+$2+$3+$4+$5+$6+$7}')
sleep ${TIME_INTERVAL}
NEXT_CPU_INFO=$(cat /proc/stat | grep -w cpu | awk '{print $2,$3,$4,$5,$6,$7,$8}')
NEXT_SYS_IDLE=$(echo $NEXT_CPU_INFO | awk '{print $4}')
NEXT_TOTAL_CPU_T=$(echo $NEXT_CPU_INFO | awk '{print $1+$2+$3+$4+$5+$6+$7}')
#系统空闲时间
SYSTEM_IDLE=`echo ${NEXT_SYS_IDLE} ${LAST_SYS_IDLE} | awk '{print $1-$2}'`
#CPU总时间
TOTAL_TIME=`echo ${NEXT_TOTAL_CPU_T} ${LAST_TOTAL_CPU_T} | awk '{print $1-$2}'`
CPU_USAGE=`echo ${SYSTEM_IDLE} ${TOTAL_TIME} | awk '{printf "%.2f", 100-$1/$2*100}'`
#echo "CPU Usage:${CPU_USAGE}%"$time >> /www/wwwroot/sh/cpu.log
#判断
WARNING=85
if [ $(echo "$CPU_USAGE > $WARNING"|bc) -eq 1 ]
then
        #发送
        webhook=""
        cluster="正式服务器"
        curl $webhook -H "Content-Type: application/json" -d "
    {
        "msgtype": "text",
        "text": {
            "content": "服务器名称：$cluster\nCPU报警信息：CPU超过百分之85，请注意\n"
        }
    }"
        echo "CPU Usage:${CPU_USAGE}%"$time >> /www/wwwroot/sh/cpu.log
else
        echo "CPU Usage:${CPU_USAGE}%"$time >> /www/wwwroot/sh/cpu.log
fi
##磁盘报警
ALERT=85
DF=$(df | grep '/$'| awk '{print $(NF-1)}' | awk -F'%' '{print $1}')
if [ $DF -gt $ALERT ]
then
        #发送
        webhook=""
        cluster="正式服务器"
        curl $webhook -H "Content-Type: application/json" -d "
    {
        "msgtype": "text",
        "text": {
            "content": "服务器名称：$cluster\nDF报警信息：DF超过百分之85，请及时清理\n"
        }
    }"
        echo "DF usage:${DF}%"$time >> /www/wwwroot/sh/df.log
else
        echo "DF usage:${DF}%"$time >> /www/wwwroot/sh/df.log
fi
##内存报警
#总内存大小
mem_total=`free -m | sed -n '2p' |awk '{print $2}'`
#已使用内存
mem_used=`free -m | sed -n '2p' |awk '{print $3}'`
#剩余内存
mem_free=`free -m |sed -n '2p' |awk '{print $4}'`
#使用内存百分比
Percent_mem_used=`echo "scale=2; $mem_used / $mem_total *100" | bc`
#剩余内存百分比
#Percent_mem_free=`echo "scale=2; $mem_free / $mem_total *100" | bc `
#echo $Percent_mem_used
#echo $Percent_mem_free
if [ $(echo "$Percent_mem_used > $WARNING"|bc) -eq 1 ]
then
        #发送
        webhook=""
        cluster="正式服务器"
        curl $webhook -H "Content-Type: application/json" -d "
    {
        "msgtype": "text",
        "text": {
            "content": "服务器名称：$cluster\nFREE报警信息：REFF内存超过百分之85，请注意\n"
        }
    }"
        echo "FREE Usage:${Percent_mem_used}%"$time >> /www/wwwroot/sh/free.log
else
        echo "FREE Usage:${Percent_mem_used}%"$time >> /www/wwwroot/sh/free.log
fi
