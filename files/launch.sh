#! /bin/bash

#
# Skript will copy Kerberos credentials to prevent cleaning credentials for
# background jobs. Clean them up after finish.
#

krbcc=`klist 2>/dev/null | grep '^\(Credentials cache\|Ticket cache\)'`
if test $? -ne 0; then
        echo 'Credentials not available:'
        klist
        exit -1
fi
krbcc=`echo "${krbcc}" | head -n 1 | sed -e 's,.*FILE:,,'`

export KRB5CCNAME="FILE:${krbcc}_long"

trap 'ret=$?; kdestroy; exit "${ret}"' INT TERM EXIT
cp -p "${krbcc}" "${krbcc}_long"

"$@"
