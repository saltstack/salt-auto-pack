{% import "auto_setup/auto_base_map.jinja" as base_cfg %}

## create rsa keys, run on Master by Master's minion

check_rsa_key_file_exists:
  file.exists:
    - name: {{base_cfg.rsa_pub_key_absfile}}

generate_rsa_keys:
  cmd.run:
    - name: |
        ssh-keygen -b 2048 -t rsa -N '' -f {{base_cfg.rsa_priv_key_absfile}}
    - runas: {{base_cfg.build_runas}}
    - onfail:
      - file: check_rsa_key_file_exists


