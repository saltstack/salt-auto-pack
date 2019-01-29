{% import "auto_setup/auto_base_map.jinja" as base_cfg %}

## comment for highlighting

{% set my_id = grains.get('id') %}
{% set my_gpg_tmpfile = '/tmp/tmp_copy_of_pub_gpg_file' %}  ## needs to match that used in setup_keyid.sls

{% set vault_user = 'svc-builder' %}
{% set vault_user_password = 'kAdLNTDt*ku7R9Y' %}
{% set vault_address = 'http://vault.aws.saltstack.net:8200' %}

{%- set vault_info_dict = salt.cmd.run("vault login -address='" ~ vault_address ~ "' -method=userpass -format=JSON username=" ~ vault_user ~ " password=" ~ vault_user_password ~ " ") | load_json %}
{%- set vault_token =  vault_info_dict['auth']['client_token'] %}

{% set secret_path = 'secret/saltstack/automation' %}

{% set bld_release_private_key = 'bld_release_private_key' %}
{% set bld_release_public_key = 'bld_release_public_key' %}
{% set bld_release_pphrase = 'bld_release_pphrase' %}

{% set bld_test_public_key = 'bld_test_public_key' %}
{% set bld_test_private_key = 'bld_test_private_key' %}
{% set bld_test_pphrase = 'bld_test_pphrase' %}

{% set vault_active_dict = salt.cmd.run("vault read -address='" ~ vault_address ~ "' -format=JSON '" ~ secret_path ~ "'") | load_json %}
{% if vault_active_dict %}
{% set vault_active = true %}
{% else %}
{% set vault_active = false %}
{% endif %}

{% set pphrase_flag = false %}

{% if vault_active %}

## retrive relevant key information from vault
{% if base_cfg.build_specific_tag %}
{% set pub_key_b64 = vault_active_dict['data'][bld_release_public_key] %}
{% set priv_key_b64 = vault_active_dict['data'][bld_release_public_key ] %}
{% set pphrase = vault_active_dict['data'][bld_release_pphrase] %}
{% else %}
{% set pub_key_b64 = vault_active_dict['data'][bld_test_public_key ] %}
{% set priv_key_b64 = vault_active_dict['data'][bld_test_private_key ] %}
{% set pphrase = vault_active_dict['data'][bld_test_pphrase ] %}
{% endif %}

{% if pphrase|length >= 5 %}
{% set pphrase_value = pphrase|truncate(5, True, '') %}
{% if pphrase_value != 'ERROR' %}
{% set pphrase_flag = True %}
{% endif %}
{% endif %}


# retrieve AWS credentials from Vault
{% set aws_access_priv_key = vault_active_dict['data']['aws_access_priv_key'] %} 
{% set subnet_id =  vault_active_dict['data']['subnet_id'] %}
{% set sec_group_id = vault_active_dict['data']['sec_group_id'] %}
{% set aws_access_priv_key_name = vault_active_dict['data']['aws_access_priv_key_name'] %}
{% set aws_access_priv_key_filename = "/srv/salt/auto_setup/" ~ aws_access_priv_key_name %}


{% set test_file = '/srv/pillar/auto_setup/gpg_keys_do_not_commit.sls' %}
{% set test_file_priv = '/srv/pillar/auto_setup/gpg_keys_do_not_commit_a.sls' %}
{% set test_file_pub = '/srv/pillar/auto_setup/gpg_keys_do_not_commit_b.sls' %}

{% set base_map_jinja_file = '/srv/salt/setup/base_map.jinja' %}
{% set tag_build_dsig_jinja_file = '/srv/pillar/auto_setup/tag_build_dsig.jinja' %}


remove_gpg_keys_pillar_file:
  file.absent:
    - name: {{test_file}}


write_gpg_keys_to_pillar_file:
  file.append:
    - name: {{test_file}}
    - text: |
        gpg_pkg_pub_key: |


write_gpg_pub_keys_to_file:
  file.decode:
    - name: {{test_file_pub}}
    - encoded_data: |
        {{pub_key_b64}}
    - encoding_type: 'base64'
    - require:
      - file: write_gpg_keys_to_pillar_file


shift_blanks2_write_gpg_pub_keys_to_pillar_file:
  cmd.run:
    - name: |
        sed 's/^/  /' {{test_file_pub}} >> {{test_file}}
    - kwargs:
        python_shell: True
    - require:
      - file: write_gpg_pub_keys_to_file


append_blanks2_write_gpg_pub_keys_to_pillar_file:
  cmd.run:
    - name: |
        echo -e "\n" >> {{test_file}}


append_write_gpg_pub_keys_to_pillar_file:
  file.append:
    - name: {{test_file}}
    - text: |
        gpg_pkg_pub_keyname: gpg_pkg_key.pub


append_blanks3_write_gpg_to_pillar_file:
  cmd.run:
    - name: |
        echo -e "\n" >> {{test_file}}


## get key id from public key in another state file
generate_tmp_copy_of_pub_file:
  cmd.run:
    - name: |
        cp {{test_file_pub}} {{my_gpg_tmpfile}}


append_write_gpg_priv_keys_in_pillar:
  file.append:
    - name: {{test_file}}
    - text: |
        gpg_pkg_priv_key: |


write_gpg_priv_keys_in_file:
  file.decode:
    - name: {{test_file_priv}}
    - encoded_data: |
        {{priv_key_b64}}
    - encoding_type: 'base64'


shift_blanks2_write_gpg_priv_keys_to_pillar_file:
  cmd.run:
    - name: |
        sed 's/^/  /' {{test_file_priv}} >> {{test_file}}
    - kwargs:
        python_shell: True
    - require:
      - file: write_gpg_priv_keys_in_file


append_blanks_write_gpg_keys_pillar_file:
  cmd.run:
    - name: |
        echo -e "\n" >> {{test_file}}
    - require:
      - cmd: shift_blanks2_write_gpg_pub_keys_to_pillar_file


append_blanks2_write_gpg_priv_keys_in_pillar:
  cmd.run:
    - name: |
        echo -e "\ngpg_pkg_priv_keyname: gpg_pkg_key.pem\n" >> {{test_file}}


remove_aws_priv_keys_file:
  file.absent:
    - name: {{aws_access_priv_key_filename}}


remove_aws_priv_keys_tmp_file:
  file.absent:
    - name: {{aws_access_priv_key_filename}}_tmp


write_aws_priv_keys_to_file:
  file.decode:
    - name: {{aws_access_priv_key_filename}}_tmp
    - encoded_data: |
        {{aws_access_priv_key}}
    - encoding_type: 'base64'
    - require:
      - file: write_aws_priv_keys_begin_to_file


write_aws_priv_keys_end_to_file:
  file.append:
    - name: {{aws_access_priv_key_filename}}_tmp
    - text: |
        -----END RSA PRIVATE KEY-----
    - require:
      - file: write_aws_priv_keys_to_file


write_aws_priv_keys_begin_to_file:
  file.append:
    - name: {{aws_access_priv_key_filename}}
    - text: |
        -----BEGIN RSA PRIVATE KEY-----


write_aws_priv_keys_contents_to_file:
  file.append:
    - name: {{aws_access_priv_key_filename}}
    - source:  {{aws_access_priv_key_filename}}_tmp


cleanup_aws_priv_keys_tmp_file:
  file.absent:
    - name: {{aws_access_priv_key_filename}}_tmp


ensure_mode_aws_priv_keys_file:
  module.run:
    - name: file.set_mode
    - path: {{aws_access_priv_key_filename}}
    - mode: 0600


{% if pphrase_flag ==  false %}
disable_use_of_passphrases:
  file.replace:
    - name: {{base_map_jinja_file}}
    - pattern: |
{%- raw %}
        {% set repo_use_passphrase = True %}
{%- endraw %}
    - repl: |
{%- raw %}
        {% set repo_use_passphrase = False %}
{%- endraw %}
    - show_changes: True
    - append_if_not_found: True
    - not_found_content: |
{%- raw %}
        {% set repo_use_passphrase = False %}
{%- endraw %}
{% endif %}


update_pillar_subnet_id:
  file.replace:
    - name: {{tag_build_dsig_jinja_file}}
    - pattern: 'subnet-to-be-determined'
    - repl: '{{subnet_id}}'
    - show_changes: True


update_pillar_sec_group_id:
  file.replace:
    - name: {{tag_build_dsig_jinja_file}}
    - pattern: 'sec-group-to-be-determined'
    - repl: '{{sec_group_id}}'
    - show_changes: True


update_pillar_aws_access_priv_key_name:
  file.replace:
    - name: {{tag_build_dsig_jinja_file}}
    - pattern: 'aws-file-key-name-to-be-determined'
    - repl: '{{aws_access_priv_key_name}}'
    - show_changes: True


cleanup_gpg_pub_keys_pillar_file:
  file.absent:
    - name: {{test_file_pub}}


cleanup_gpg_priv_keys_pillar_file:
  file.absent:
    - name: {{test_file_priv}}

{% endif %}  ## vault active

