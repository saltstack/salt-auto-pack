{% import "auto_setup/auto_base_map.jinja" as base_cfg %}

## comment for highlighting

{% set my_id = grains.get('id') %}

{% set secret_path = 'secret/saltstack/automation' %}

{% set bld_test_public_key = 'bld_test_public_key' %}
{% set bld_test_private_key = 'bld_test_private_key' %}
{% set bld_test_pphrase = 'bld_test_pphrase' %}

{% set bld_release_private_key = 'bld_release_private_key' %}
{% set bld_release_public_key = 'bld_release_public_key' %}
{% set bld_release_pphrase = 'bld_release_pphrase' %}


{% set vault_active_dict = salt.cmd.run("salt " ~ my_id  ~ " file.file_exists /etc/salt/master.d/vault.conf -l quiet --out=json") | load_json %}
{% if vault_active_dict[my_id] == True %}
{% set vault_active = true %} 
{% else %}
{% set vault_active = false %}
{% endif %}

{% set pphrase_flag = false %}

{% if vault_active %}

## retrive relevant key information from vault
{% if base_cfg.build_specific_tag %}

{% set pub_key_b64 = salt['vault'].read_secret(secret_path, bld_release_public_key) %}
{% set priv_key_b64 = salt['vault'].read_secret(secret_path, bld_release_private_key) %}
{% set pphrase_dict = salt.cmd.run("salt " ~ my_id ~ " vault.read_secret '" ~ secret_path ~ "' '" ~ bld_release_pphrase ~ "' -l quiet --out=json") | load_json %}

{% else %}

{% set pub_key_b64 = salt['vault'].read_secret(secret_path, bld_test_public_key) %}
{% set priv_key_b64 = salt['vault'].read_secret(secret_path, bld_test_private_key) %}
{% set pphrase_dict = salt.cmd.run("salt " ~ my_id ~ " vault.read_secret '" ~ secret_path ~ "' '" ~ bld_test_pphrase ~ "' -l quiet --out=json") | load_json %}

{% endif %}

{% set pphrase = pphrase_dict[my_id] %} 

{% if pphrase|length >= 5 %}
{% set pphrase_value = pphrase|truncate(5, True, '') %}

{% if pphrase_value != 'ERROR' %}
{% set pphrase_flag = True %}
{% endif %}

{% endif %}


{% set test_file = '/srv/pillar/auto_setup/gpg_keys_do_not_commit.sls' %}
{% set test_file_priv = '/srv/pillar/auto_setup/gpg_keys_do_not_commit_a.sls' %}
{% set test_file_pub = '/srv/pillar/auto_setup/gpg_keys_do_not_commit_b.sls' %}

{% set base_map_jinja_file = '/srv/salt/setup/base_map.jinja' %}
{% set tag_build_dsig_sls_file = '/srv/pillar/auto_setup/tag_build_dsig.sls' %}


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
        cp {{test_file_pub}} /tmp/tmp_copy_of_pub_gpg_file


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


{% if pphrase_flag ==  false %}
disable_use_of_passphrases:
  file.replace:
    - name: {{base_map_jinja_file}}
    - pattern: |
{% raw %}
        {% set repo_use_passphrase = True %}
{% endraw %}
    - repl: |
{% raw %}
        {% set repo_use_passphrase = False %}
{% endraw %}
    - show_changes: True
    - append_if_not_found: True
    - not_found_content: |
{% raw %}
        {% set repo_use_passphrase = False %}
{% endraw %}
{% endif %}


cleanup_gpg_pub_keys_pillar_file:
  file.absent:
    - name: {{test_file_pub}}


cleanup_gpg_priv_keys_pillar_file:
  file.absent:
    - name: {{test_file_priv}}

{% endif %}

