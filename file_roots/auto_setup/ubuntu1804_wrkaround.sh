#!/usr/bin/bash
# param $1 minion_id
fqdn_minion=$(salt $1 grains.get fqdn -l quiet --out=json |  jq  '.[]' | sed  's/,//' | sed 's/"//g')
SERVER_LIST="ubuntu@$fqdn_minion"
for h in $SERVER_LIST;
do
   (ssh -i /srv/salt/auto_setup/jenkins-testing.pem -o StrictHostKeyChecking=no -o RequestTTY=yes -t $h &)
done
