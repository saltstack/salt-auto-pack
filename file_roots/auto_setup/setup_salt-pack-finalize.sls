{% import "auto_setup/auto_base_map.jinja" as base_cfg %}

remove_any_salt_target_platforms:
  file.absent:
    - name: /srv/salt/pkg/salt/{{base_cfg.build_number_uscore}}

## finally setup salt-pack files on master, noting auto_setup should not get overwritten
setup_salt_pack_master_base:
  cmd.run:
    - name: cp -f -R {{base_cfg.build_salt_pack_dir}}/file_roots/* /srv/salt/


setup_salt_pack_master_pillar:
  cmd.run:
    - name: cp -f -R {{base_cfg.build_salt_pack_dir}}/pillar_roots/* /srv/pillar/


adjust_salt_pack_master_pillar_top_keys:
  file.line:
    - name: /srv/pillar/top.sls
    - match: '- gpg_keys'
    - mode: delete
    - show_changes: True
    - backup: True


## fix issue of not having do_not_commit keys file yet on a clean system and top.sls needs file
{% set old_key_file = '/srv/pillar/auto_setup/gpg_keys_test.sls' %}
{% set new_key_file = '/srv/pillar/auto_setup/gpg_keys_do_not_commit.sls' %}
{% set build_local_minion = grains.get('id') %}
{% set do_not_commit_file_exists_dict = salt.cmd.run("salt " ~ build_local_minion  ~ " file.file_exists " ~ new_key_file ~ " -l quiet --out=json") | load_json %}
{% if do_not_commit_file_exists_dict[build_local_minion] == True %}
{% set do_not_commit_file_exists = true %}
{% else %}
{% set do_not_commit_file_exists = false %}
{% endif %}

{% if do_not_commit_file_exists == false %}

remove_curr_gpg_keys_pillar_file:
  file.absent:
    - name: {{new_key_file}}


generate_gpg_keyfile_to_use:
  cmd.run:
    - name: |
        cp {{old_key_file}}  {{new_key_file}}

{% endif %}


adjust_salt_pack_master_pillar_top_match:
  file.append:
    - name: /srv/pillar/top.sls
    - ignore_whitespace: False
    - text: |
          ##
              - auto_setup.gpg_keys_do_not_commit
              - auto_setup.tag_build_dsig

            'G@os_family:Redhat and G@os:Amazon and not G@osmajorrelease:2':
              - auto_setup.amazon

            'G@os_family:Redhat and G@os:Amazon and G@osmajorrelease:2':
              - auto_setup.amazon2

            'G@os_family:Redhat and G@osmajorrelease:8 and not G@os:Amazon':
              - auto_setup.redhat8

            'G@os_family:Redhat and G@osmajorrelease:7 and not G@os:Amazon':
              - auto_setup.redhat7

            'G@os_family:Redhat and G@osmajorrelease:6 and not G@os:Amazon':
              - auto_setup.redhat6

            'G@os_family:Debian and G@osmajorrelease:11 and not G@osfullname:Raspbian':
              - auto_setup.debian11

            'G@os_family:Debian and G@osmajorrelease:10 and not G@osfullname:Raspbian':
              - auto_setup.debian10

            'G@os_family:Debian and G@osmajorrelease:9 and not G@osfullname:Raspbian':
              - auto_setup.debian9

            'G@os_family:Debian and G@osmajorrelease:8 and not G@osfullname:Raspbian':
              - auto_setup.debian8

            'G@osfullname:Raspbian and G@osmajorrelease:11 and G@os_family:Debian':
              - auto_setup.raspbian11

            'G@osfullname:Raspbian and G@osmajorrelease:10 and G@os_family:Debian':
              - auto_setup.raspbian10

            'G@osfullname:Raspbian and G@osmajorrelease:9 and G@os_family:Debian':
              - auto_setup.raspbian9

            'G@osfullname:Raspbian and G@osmajorrelease:8 and G@os_family:Debian':
              - auto_setup.raspbian8

            'G@osfullname:Ubuntu and G@osmajorrelease:20':
              - auto_setup.ubuntu20

            'G@osfullname:Ubuntu and G@osmajorrelease:18':
              - auto_setup.ubuntu18

            'G@osfullname:Ubuntu and G@osmajorrelease:16':
              - auto_setup.ubuntu16

    - require:
      - file: adjust_salt_pack_master_pillar_top_keys


cleanup_pillar_bak:
  cmd.run:
    - name: |
        find /srv/pillar -name "*.bak" | xargs rm -f


cleanup_salt_bak:
  cmd.run:
    - name: |
        find /srv/salt -name "*.bak" | xargs rm -f

