{% import "auto_setup/auto_base_map.jinja" as base_cfg %}

## highlight syntax

build_ssh_rm:
  file.absent:
    - name: '/srv/salt/auto_setup/ubuntu1804_wrkaround.sh'


write_script:
  file.managed:
    - name: '/srv/salt/auto_setup/ubuntu1804_wrkaround.sh'
    - makedirs: True
    - dir_mode: 0755
    - mode: 0775
    - user: {{base_cfg.build_runas}}
    - group: {{base_cfg.build_runas}}
    - contents: |
        #!/usr/bin/bash
        # param $1 minion_id
        fqdn_minion=$(salt $1 grains.get fqdn -l quiet --out=json |  jq  '.[]' | sed  's/,//' | sed 's/"//g')
        SERVER_LIST="ubuntu@$fqdn_minion"
        for h in $SERVER_LIST;
        do
           (ssh -i /srv/salt/auto_setup/{{base_cfg.aws_access_priv_key_name}} -o StrictHostKeyChecking=no -o RequestTTY=yes -t $h &)
        done

