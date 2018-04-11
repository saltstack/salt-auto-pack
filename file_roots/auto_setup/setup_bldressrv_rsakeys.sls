{% import "auto_setup/auto_base_map.jinja" as base_cfg %}

rsa_set_auth_key:
  module.run:
    - name: ssh.set_auth_key_from_file
    - user: {{base_cfg.minion_bldressrv_username}}
    - source: salt://{{base_cfg.rsa_pub_key_file}}


