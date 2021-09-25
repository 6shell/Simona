#!/bin/sh
ls | egrep 'auth.log..*|debug..*|daemon.log..*|dpkg.log..*|kern.log..*|messages..*|syslog..*|user.log..*' | xargs rm
for i in `find /var/log -name "*.log"`; do cat /dev/null >$i; done
