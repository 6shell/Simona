echo "删除旧进程"
old_ids=$(ps -ef | grep /opt/serverstatus/client-linux.py | grep -v grep | awk '{print $2}')
echo $old_ids
kill $old_ids
echo "删除成功"
echo "后台启动新进程"
nohup python3 /opt/serverstatus/client-linux.py >/dev/null 2>&1 &
