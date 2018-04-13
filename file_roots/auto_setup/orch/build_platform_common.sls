{% import "auto_setup/auto_base_map.jinja" as base_cfg %}

# get minion target from pillar data
{% set minion_tgt = pillar.get('minion_tgt', 'UKNOWN-MINION') %}

{% set null_dict = dict() %}
{% set tgt_build_repo_dsig = 'UNKNOWN' %}
{% set tgt_build_os_name = 'UNKNOWN' %}
{% set tgt_build_os_version = 'UNKNOWN' %}
{% set tgt_build_release = 'UNKNOWN' %}
{% set tgt_build_arch = 'UNKNOWN' %}

{% set my_tgt_grains = salt.cmd.run('salt-run cache.grains ' ~ minion_tgt ~ ' -l quiet --out=json') | load_json  %}

{% set my_tgt_os = my_tgt_grains[minion_tgt]['os'] | lower %}
{% set my_tgt_os_family = my_tgt_grains[minion_tgt]['os_family'] | lower %}
{% set my_tgt_osarch = my_tgt_grains[minion_tgt]['osarch'] %}
{% set my_tgt_osmajorrelease = my_tgt_grains[minion_tgt]['osmajorrelease'] %}
{% set my_tgt_osrelease = my_tgt_grains[minion_tgt]['osrelease'] %}

## generate release, platform name, os version, arch, repo_dsig, etc.
{% if my_tgt_os_family == 'redhat' %}

{% set tgt_build_repo_dsig = 'yum' %}

{% if my_tgt_os == 'amazon' %}
    {% set tgt_build_os_name = my_tgt_os %}
    {% set tgt_build_os_version = 'latest' %}
    {% set tgt_build_release = 'amzn' %}
    {% set tgt_build_arch = my_tgt_osarch %}
{% else %}
    {% set tgt_build_os_name = my_tgt_os_family %}
    {% set tgt_build_os_version = my_tgt_osmajorrelease %}
    {% set tgt_build_release = 'rhel' ~ my_tgt_osmajorrelease  %}
    {% set tgt_build_arch = my_tgt_osarch %}
{% endif %}

{% elif my_tgt_os_family == 'debian' and my_tgt_os == 'debian' %}

{% set tgt_build_repo_dsig = 'apt' %}
{% set tgt_build_os_name = my_tgt_os_family %}
{% set tgt_build_os_version = my_tgt_osmajorrelease %}
{% set tgt_build_release = my_tgt_os_family ~ my_tgt_osmajorrelease  %}
{% set tgt_build_arch = my_tgt_osarch %}

{% elif my_tgt_os_family == 'debian' and my_tgt_os == 'ubuntu' %}

{% set tgt_build_repo_dsig = 'apt' %}
{% set tgt_build_os_name = my_tgt_os %}

{% if my_tgt_os == 'ubuntu' %}
{% set tgt_build_os_version = my_tgt_osrelease %}
{% set tgt_build_release = my_tgt_os ~ tgt_build_os_version.replace('.','') %}
{% else %}
{% set tgt_build_os_version = my_tgt_osmajorrelease %}
{% set tgt_build_release = my_tgt_os ~ my_tgt_osmajorrelease  %}
{% endif %}

{% set tgt_build_arch = my_tgt_osarch %}

{% endif %}


## determine if build Python 3
{% set build_py3 = pillar.get('build_py3', False) %}
{% if build_py3 %}
{% set build_py_ver = 'py3' %}
{% else %}
{% set build_py_ver = 'py2' %}
{% endif %}


# get pillar data
## {# {% set minion_platform = pillar.get('build_release', tgt_build_release) %} #}
{% set minion_platform = tgt_build_release %}

{% set build_arch = pillar.get('build_arch', tgt_build_arch) %}
{% set repo_dsig = pillar.get('build_repo_dsig', tgt_build_repo_dsig) %}
{% set os_version = pillar.get('build_os_version', tgt_build_os_version) %}
{% set os_name = pillar.get('build_os_name', tgt_build_os_name) %}
{% set specific_user = pillar.get('specific_name_user', 'saltstack') %}

{% set nb_srcdir = pillar.get('build_dest') ~ '/' ~ build_py_ver ~ '/' ~ minion_platform ~ '/' ~ build_arch %}

{% set minion_specific = os_name ~ '.' ~ minion_platform %}


{% if base_cfg.build_specific_tag %}
{% set nb_destdir = base_cfg.build_dsig %}
{% else %}
{% set nb_destdir = base_cfg.build_version ~ base_cfg.build_dsig %}
{% endif %}

## if Python 3 then override yum or apt
{% if build_py3 %}
{% set repo_dsig = 'py3' %}
{% endif %}

{% set web_server_base_dir = base_cfg.minion_bldressrv_rootdir ~ '/' ~ specific_user ~ '/' ~ repo_dsig ~ '/' ~ os_name ~ '/' ~ os_version ~ '/' ~ build_arch %}
{% set web_server_archive_dir = web_server_base_dir ~ '/archive/' ~ nb_destdir %}
{% set web_server_branch_symlink = web_server_base_dir ~ '/' ~ base_cfg.build_version_dotted %}

{% set my_tgt_link_dict = salt.cmd.run('salt ' ~ base_cfg.minion_bldressrv ~ ' file.is_link ' ~ web_server_branch_symlink ~ ' -l quiet --out=json') | load_json  %}
{% if my_tgt_link_dict[base_cfg.minion_bldressrv] == True %}
{% set my_tgt_link = true %} 
{% else %}
{% set my_tgt_link = false %}
{% endif %}

{% if my_tgt_link %}
{% set branch_symlink_dict = salt.cmd.run("salt " ~ base_cfg.minion_bldressrv  ~ " file.path_exists_glob " ~ web_server_branch_symlink ~ "/* -l quiet --out=json") | load_json %}
{% if branch_symlink_dict[base_cfg.minion_bldressrv] == True %}
{% set my_tgt_link_has_files = true %} 
{% else %}
{% set my_tgt_link_has_files = false %}
{% endif %}
{% endif %}

## check use of vault and passphrase
{% set secret_path = 'secret/saltstack/automation' %}

{% set bld_test_public_key = 'bld_test_public_key' %}
{% set bld_test_private_key = 'bld_test_private_key' %}
{% set bld_test_pphrase = 'bld_test_pphrase' %}
{% set bld_release_private_key = 'bld_release_private_key' %}
{% set bld_release_public_key = 'bld_release_public_key' %}
{% set bld_release_pphrase = 'bld_release_pphrase' %}

{% set build_local_id = pillar.get('build_local_minion', 'm7m') %}
{% set vault_active_dict = salt.cmd.run("salt " ~ build_local_id  ~ " file.file_exists /etc/salt/master.d/vault.conf -l quiet --out=json") | load_json %}
{% if vault_active_dict[build_local_id] == True %}
{% set vault_active = true %} 
{% else %}
{% set vault_active = false %}
{% endif %}

{% set pphrase_flag = false %}

{% if vault_active %}

## retrive relevant key information from vault
## flag doing test builds for now
{% set release_tag = true %}

{% if release_tag %}
{% set pphrase_dict = salt.cmd.run("salt " ~ build_local_id ~ " vault.read_secret '" ~ secret_path ~ "' '" ~ bld_release_pphrase ~ "' -l quiet --out=json") | load_json %}
{% else %}
{% set pphrase_dict = salt.cmd.run("salt " ~ build_local_id ~ " vault.read_secret '" ~ secret_path ~ "' '" ~ bld_test_pphrase ~ "' -l quiet --out=json") | load_json %}
{% endif %}

{% set pphrase = pphrase_dict[build_local_id] %} 
{% set pphrase_flag = true %}

{% if pphrase|length >= 5 %}
{% set pphrase_value = pphrase|truncate(5, True, '') %}
{% if pphrase_value == 'ERROR' %}
{% set pphrase_flag = false %}
{% endif %}
{% endif %}

{% endif %}


refresh_pillars_{{minion_platform}}:
  salt.function:
    - name: saltutil.refresh_pillar
    - tgt: {{minion_tgt}}


build_init_{{minion_platform}}:
  salt.state:
    - tgt: {{minion_tgt}}
    - queue: True
    - sls:
      - setup.{{minion_specific}}
    - pillar: 
        build_release: {{tgt_build_release}}
        build_arch: {{tgt_build_arch}}
    - require:
      - salt: refresh_pillars_{{minion_platform}}


{% if minion_platform == 'rhel7' %}
copy_redhat_7_base_subdir:
  salt.function:
    - name: cp.get_dir
    - tgt: {{minion_tgt}}
    - arg:
      - salt://auto_setup/rh7_base/base/
      - {{nb_srcdir}}
    - kwarg:
        makedirs: True
    - require:
      - salt: build_init_{{minion_platform}}
{% endif %}


ensure_bldresrv_nfs_dir_exists_{{minion_platform}}:
  salt.function:
    - name: file.makedirs
    - tgt: {{minion_tgt}}/
    - arg:
      - {{base_cfg.minion_bldressrv_nfsrootdir}}
    - kwarg:
        user: nobody
        group: nogroup
        mode: 775


## TBD ipaddr for bld-res-server should be pulled from grains
mount_bldressrv_nfs_{{minion_platform}}:
  salt.function:
    - name: cmd.run
    - tgt: {{minion_tgt}}
    - arg:
      - mount 10.1.50.77:{{base_cfg.minion_bldressrv_nfsrootdir}} {{base_cfg.minion_bldressrv_nfsrootdir}}


{% if base_cfg.build_clean == 0 and my_tgt_link and my_tgt_link_has_files %}
copy_deps_packages_{{base_cfg.build_version}}_{{minion_platform}}:
  salt.state:
    - tgt: {{minion_tgt}}
    - queue: True
    - sls:
      - auto_setup.copy_build_deps
    - require:
      - salt: build_bldressrv_basedir_exists_{{minion_platform}}
{% endif %}


cleanup_any_build_products_{{base_cfg.build_version}}_{{minion_platform}}:
  salt.state:
    - tgt: {{minion_tgt}}
    - queue: True
    - sls:
      - auto_setup.cleanup_build_product
    - require:
{% if base_cfg.build_clean == 0 and my_tgt_link and my_tgt_link_has_files %}
      - salt: copy_deps_packages_{{base_cfg.build_version}}_{{minion_platform}}
{% else %}
      - salt: mount_bldressrv_nfs_{{minion_platform}}
{% endif %}


build_highstate_{{base_cfg.build_version}}_{{minion_platform}}:
  salt.state:
    - tgt: {{minion_tgt}}
    - queue: True
    - highstate: True
    - pillar: 
        build_release: {{tgt_build_release}}
        build_arch: {{tgt_build_arch}}


sign_packages_{{base_cfg.build_version}}_{{minion_platform}}:
  salt.state:
    - tgt: {{minion_tgt}}
    - queue: True
    - sls:
      - repo.{{minion_specific}}
    - pillar: 
        build_release: {{tgt_build_release}}
        build_arch: {{tgt_build_arch}}
{%- if pphrase_flag %}
        gpg_passphrase: {{pphrase}}
{%- endif %}
    - require:
      - salt: build_highstate_{{base_cfg.build_version}}_{{minion_platform}}


remove_current_{{base_cfg.build_version}}_{{minion_platform}}:
  salt.function:
    - name: file.remove
    - tgt: {{base_cfg.minion_bldressrv}}
    - arg:
      - {{web_server_base_dir}}/{{base_cfg.build_version_dotted}}
    - require:
      - salt: sign_packages_{{base_cfg.build_version}}_{{minion_platform}}


update_current_{{base_cfg.build_version}}_{{minion_platform}}:
  salt.function:
    - name: file.symlink
    - tgt: {{base_cfg.minion_bldressrv}}
    - arg:
      - {{web_server_archive_dir}}
      - {{web_server_branch_symlink}}


update_current_{{base_cfg.build_version}}_mode_{{minion_platform}}:
  salt.function:
    - name: file.lchown
    - tgt: {{base_cfg.minion_bldressrv}}
    - arg:
      - {{web_server_base_dir}}/{{base_cfg.build_version_dotted}}
      - {{base_cfg.minion_bldressrv_username}}
      - www-data


copy_signed_packages_{{base_cfg.build_version}}_{{minion_platform}}:
  salt.state:
    - tgt: {{minion_tgt}}
    - queue: True
    - sls:
      - auto_setup.copy_build_product
    - require:
      - salt: sign_packages_{{base_cfg.build_version}}_{{minion_platform}}
      - salt: update_current_{{base_cfg.build_version}}_mode_{{minion_platform}}


