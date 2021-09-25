#!/bin/sh
rm /var/log/alternatives.log.* -f
rm /var/log/auth.log.* -f
rm /var/log/debug.* -f
rm /var/log/daemon.log.* -f
rm /var/log/dpkg.log.* -f
rm /var/log/kern.log.* -f
rm /var/log/messages.* -f
rm /var/log/syslog.* -f
rm /var/log/user.log.* -f
for i in `find /var/log -name "*.log"`; do cat /dev/null >$i; done
