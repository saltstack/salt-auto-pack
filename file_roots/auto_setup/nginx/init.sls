nginx_install:
  pkg.installed:
    - name: nginx
    - failhard: True


ensure_cert:
  file.managed:
    - name: /etc/ssl/certs/c7.saltstack.net.crt
    - source: salt://auto_setup/nginx/c7.saltstack.net.crt
    - show_changes: True
    - user: root
    - group: root
    - mode: 644
    - makedirs: True


ensure_key:
  file.managed:
    - name: /etc/ssl/private/c7.saltstack.net.key
    - source: salt://auto_setup/nginx/c7.saltstack.net.key
    - show_changes: True
    - user: root
    - group: root
    - mode: 644
    - makedirs: True


nginx_service:
  service.running:
    - name: nginx
    - require:
      - pkg: nginx_install
    - watch:
      - file: /etc/nginx/nginx.conf
      - file: /etc/nginx/sites-available/default


nginx_conf:
  file.managed:
    - source: salt://auto_setup/nginx/nginx.conf
    - name: /etc/nginx/nginx.conf
    - user: root
    - group: root
    - mode: 644
    - makedirs: True


nginx_default_conf:
  file.managed:
    - source: salt://auto_setup/nginx/default
    - name: /etc/nginx/sites-available/default
    - user: root
    - group: root
    - mode: 644
    - makedirs: True

