{% import "auto_setup/auto_base_map.jinja" as base_cfg %}

## comment for highlighting

{% set my_id = grains.get('id') %}
{% set my_gpg_tmpfile = '/tmp/tmp_copy_of_pub_gpg_file' %}  ## needs to match that used in setup_vault_user.sls

{% set vault_active_dict = salt.cmd.run("salt " ~ my_id  ~ " file.file_exists " ~ my_gpg_tmpfile ~ " -l quiet --out=json") | load_json %}
{% if vault_active_dict[my_id] == True %}
{% set vault_active = true %}
{% else %}
{% set vault_active = false %}
{% endif %}

{% if vault_active %}

## get key id from public key
## do this copy explicit file due to having jinja issues - revisit TBD

{% set tag_build_dsig_sls_file = '/srv/pillar/auto_setup/tag_build_dsig.sls' %}
{% set finger_test = salt.cmd.run("gpg --with-fingerprint " ~ my_gpg_tmpfile, use_vt=False)|truncate(20, True, '')|trim %}
{% set keysize, keyid = finger_test.split('/', 1) -%}

update_tag_build_dsig_with_keyid:
  file.replace:
    - name: {{tag_build_dsig_sls_file}}
    - pattern: |
        keyid: .*
    - repl: |
        keyid: {{keyid}}
    - show_changes: True
    - append_if_not_found: True
    - not_found_content: |
        keyid: {{keyid}}


cleanup_tmp_copy_of_pub_file:
  file.absent:
    - name: {{my_gpg_tmpfile}}
    - require:
      - file: update_tag_build_dsig_with_keyid

{% else %}

{% set old_key_file = '/srv/pillar/auto_setup/gpg_keys_test.sls' %}
{% set new_key_file = '/srv/pillar/auto_setup/gpg_keys_do_not_commit.sls' %}

remove_curr_gpg_keys_pillar_file:
  file.absent:
    - name: {{new_key_file}}


generate_gpg_keyfile_to_use:
  cmd.run:
    - name: |
        cp {{old_key_file}}  {{new_key_file}} 

{% endif %}

