{% import "auto_setup/auto_base_map.jinja" as base_cfg %}

## comment for highlighting

{% set my_id = grains.get('id') %}

{% set password = 'kAdLNTDt*ku7R9Y' %}
{% set vault_address = 'http://10.1.50.149:8200' %}

{% set vault_conf_abspath = '/etc/salt/master.d/vault.conf' %}

## {# {%- set vault_info_dict = salt.cmd.run("curl -s --request POST --data '{\"password\": \"kAdLNTDt*ku7R9Y\"}' http://10.1.50.149:8200/v1/auth/userpass/login/svc-builder") | load_json %} #}
#
{%- set vault_info_dict = salt.cmd.run("curl -s --request POST --data '{\"password\": \"" ~ password ~ "\"}' " ~ vault_address ~ "/v1/auth/userpass/login/svc-builder") | load_json %}

## {# {%- set vault_token = salt.cmd.run("echo " ~ vault_info_dict ~ " | jq .auth.client.token") %} #}
{%- set vault_token =  vault_info_dict['auth']['client_token'] %}

dgm_debug:
  cmd.run:
    - name: "echo vault info {{vault_info_dict}}"

dgm_debug2:
  cmd.run:
    - name: "echo vault token {{vault_token}}"


vault_conf_rm:
  file.absent:
    - name: {{vault_conf_abspath}}


vautl_conf_write_file:
  file.managed:
    - name: {{vault_conf_abspath}}
    - dir_mode: 755
    - mode: 755
    - show_changes: False
    - user: {{base_cfg.build_runas}}
    - group: {{base_cfg.build_runas}}
    - makedirs: True
    - contents: |
         vault:
           url: {{vault_address}}
           auth:
             method: token
             token: {{vault_token}}
         policies:
           - saltstack-dev-policy

