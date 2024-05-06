#!/bin/bash
CurCore="linux-image-`uname -r`"
CurCoreExtra="linux-image-extra-`uname -r`"
echo "清理无用的内核"
echo "当前内核是：$CurCore"
for i in `dpkg --get-selections|grep linux-image`
do
if [ "$i" != "install" ] && [ "$i" != "$CurCore" ]  && [ "$i" != "$CurCoreExtra" ] && [ "$i" != 'linux-image-generic' ];then
echo "删除无用的内核：$i"
apt-get remove --purge $i
fi
done
echo "更新启动菜单"
update-grub
apt-get autoremove
apt-get autoclean
