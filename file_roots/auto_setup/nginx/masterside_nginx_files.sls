{% import "auto_setup/auto_base_map.jinja" as base_cfg %}

## TBD it would be nice to be able to write to salt://<named-file>

nginx_rm_default_conf:
  file.absent:
    - name: /srv/salt/auto_setup/nginx/default
##    - name: salt://auto_setup/nginx/default


nginx_create_default_conf:
  file.append:
#    - name: salt://auto_setup/nginx/default
    - name: /srv/salt/auto_setup/nginx/default
    - makedirs: True
    - text: |
        # HTTPS server
        #
        server {
            listen 443 ssl;
            server_name nightly.c7.saltstack.net;

            index index.html index.htm;

            ssl on;
            ssl_certificate /etc/ssl/certs/c7.saltstack.net.crt;
            ssl_certificate_key /etc/ssl/private/c7.saltstack.net.key;

            ssl_session_timeout 5m;

            ssl_protocols SSLv3 TLSv1 TLSv1.1 TLSv1.2;
            ssl_ciphers "HIGH:!aNULL:!MD5 or HIGH:!aNULL:!MD5:!3DES";
            ssl_prefer_server_ciphers on;

                location / {
                root {{base_cfg.minion_bldressrv_rootdir}};
                        autoindex on;
                try_files $uri $uri/ =404;
                } 
        }
    - require:
      - file: nginx_rm_default_conf



