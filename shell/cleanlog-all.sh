#!/bin/sh
ls | egrep 'auth.log..*|debug..*|daemon.log..*|dpkg.log..*|kern.log..*|messages..*|syslog..*|user.log..*' | xargs rm -rf
for i in `find /var/log -name "*.log"`; do cat /dev/null >$i; done
for i in `find /var/log -name "*tmp"`; do cat /dev/null >$i; done
for i in `find /var/lib/docker/containers/ -name "*-json.log"`; do cat /dev/null >$i; done
