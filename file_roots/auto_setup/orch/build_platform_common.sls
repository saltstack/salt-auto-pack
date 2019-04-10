{% import "auto_setup/auto_base_map.jinja" as base_cfg %}

## determine if build Python 3
{% set build_py3 = pillar.get('build_py3', False) %}
{% if build_py3 %}
{% set build_py_ver = 'py3' %}
{% else %}
{% set build_py_ver = 'py2' %}
{% endif %}


# get minion target, local minion and nfs host from pillar data
{% set minion_tgt = pillar.get('minion_tgt', 'UKNOWN-MINION') %}
{% set build_local_id = pillar.get('build_local_minion', 'm7m') %}
{% set nfs_host = pillar.get('nfs_host', 'UKNOWN-MINION') %}
{% set nfs_opts = pillar.get('nfs_opts', '') %}

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
{% if build_py3 %}
## only build Amazon Linux 2 for Py3, Amazon Linux 1 for Py2
{% set tgt_build_os_version = '2' %}
{% set tgt_build_release = 'amzn' ~ tgt_build_os_version %}
{% else %}
{% set tgt_build_os_version = 'latest' %}
{% set tgt_build_release = 'amzn' %}
{% endif %}
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

{% set nfs_server_base_dir = base_cfg.minion_mount_nfsbasedir ~ '/' ~ specific_user ~ '/' ~ repo_dsig ~ '/' ~ os_name ~ '/' ~ os_version ~ '/' ~ build_arch %}
{% set nfs_server_archive_dir = nfs_server_base_dir ~ '/archive/' ~ nb_destdir %}
{% set nfs_server_branch_symlink = nfs_server_base_dir ~ '/' ~ base_cfg.build_version_dotted %}

{% set my_tgt_link_dict = salt.cmd.run('salt ' ~ build_local_id ~ ' file.is_link ' ~ nfs_server_branch_symlink ~ ' -l quiet --out=json') | load_json  %}
{% if my_tgt_link_dict[build_local_id] == True %}
{% set my_tgt_link = true %}
{% else %}
{% set my_tgt_link = false %}
{% endif %}

{% if my_tgt_link %}
{% set branch_symlink_dict = salt.cmd.run("salt " ~ build_local_id ~ " file.path_exists_glob " ~ nfs_server_branch_symlink ~ "/* -l quiet --out=json") | load_json %}
{% if branch_symlink_dict[build_local_id] == True %}
{% set my_tgt_link_has_files = true %}
{% else %}
{% set my_tgt_link_has_files = false %}
{% endif %}
{% endif %}

## check use of vault and passphrase
{% set vault_user = 'svc-builder' %}
{% set vault_user_password = 'kAdLNTDt*ku7R9Y' %}
{% set vault_address = 'http://vault.aws.saltstack.net:8200' %}

{%- set vault_info_dict = salt.cmd.run("vault login -address='" ~ vault_address ~ "' -method=userpass -format=JSON username=" ~ vault_user ~ " password=" ~ vault_user_password ~ " ") | load_json %}
{%- set vault_token =  vault_info_dict['auth']['client_token'] %}

{% set secret_path = 'secret/saltstack/automation' %}

{% set vault_active_dict = salt.cmd.run("vault read -address='" ~ vault_address ~ "' -format=JSON '" ~ secret_path ~ "'") | load_json %}
{% if vault_active_dict %}
{% set vault_active = true %}
{% else %}
{% set vault_active = false %}
{% endif %}

{% set pphrase_flag = false %}

{% if vault_active %}

## retrive relevant key information from vault
{% set bld_test_pphrase = 'bld_test_pphrase' %}
{% set bld_release_pphrase = 'bld_release_pphrase' %}

{% if base_cfg.build_specific_tag %}
{% set pphrase = vault_active_dict['data'][bld_release_pphrase] %}
{% else %}
{% set pphrase = vault_active_dict['data'][bld_test_pphrase] %}
{% endif %}

{% if pphrase|length >= 5 %}
{% set pphrase_errchk_value = pphrase|truncate(5, True, '') %}
{% if pphrase_errchk_value != 'ERROR' %}
{% set pphrase_flag = True %}
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


ensure_nfs_dir_exists_{{minion_platform}}:
  salt.function:
    - name: file.makedirs
    - tgt: {{minion_tgt}}
    - arg:
      - {{base_cfg.minion_mount_nfsrootdir}}/
    - kwarg:
        user: nobody
        group: nogroup
        mode: 775

umount_any_previous_mount_nfs_{{minion_platform}}:
  salt.function:
    - name: cmd.run
    - tgt: {{minion_tgt}}
    - arg:
      - umount {{nfs_host}}:{{base_cfg.minion_nfsabsdir}}


mount_nfs_{{minion_platform}}:
  salt.state:
    - tgt: {{minion_tgt}}
    - queue: True
    - sls:
      - auto_setup.setup_local_mount
    - require:
      - salt: ensure_nfs_dir_exists_{{minion_platform}}


ensure_dest_dir_exists_{{minion_platform}}:
  salt.function:
    - name: file.makedirs
    - tgt: {{minion_tgt}}
    - arg:
      - {{nfs_server_archive_dir}}/
    - kwarg:
        user: nobody
        group: nogroup
        mode: 775
    - require:
      - salt: mount_nfs_{{minion_platform}}


copy_pub_keys_for_packages_{{base_cfg.build_version}}_{{minion_platform}}:
  salt.state:
    - tgt: {{minion_tgt}}
    - queue: True
    - sls:
      - auto_setup.copy_pub_keys
    - require:
      - salt: ensure_dest_dir_exists_{{minion_platform}}


{% if base_cfg.build_clean == 0 and my_tgt_link and my_tgt_link_has_files %}
copy_deps_packages_{{base_cfg.build_version}}_{{minion_platform}}:
  salt.state:
    - tgt: {{minion_tgt}}
    - queue: True
    - sls:
      - auto_setup.copy_build_deps
    - require:
      - salt: ensure_dest_dir_exists_{{minion_platform}}
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
      - salt: ensure_dest_dir_exists_{{minion_platform}}
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
    - tgt: {{minion_tgt}}
    - arg:
      - {{nfs_server_base_dir}}/{{base_cfg.build_version_dotted}}
    - require:
      - salt: sign_packages_{{base_cfg.build_version}}_{{minion_platform}}


update_current_{{base_cfg.build_version}}_{{minion_platform}}:
  salt.function:
    - name: file.symlink
    - tgt: {{minion_tgt}}
    - arg:
      - {{nfs_server_archive_dir}}
      - {{nfs_server_branch_symlink}}


copy_signed_packages_{{base_cfg.build_version}}_{{minion_platform}}:
  salt.state:
    - tgt: {{minion_tgt}}
    - queue: True
    - sls:
      - auto_setup.copy_build_product
    - require:
      - salt: sign_packages_{{base_cfg.build_version}}_{{minion_platform}}
      - salt: update_current_{{base_cfg.build_version}}_{{minion_platform}}


cleanup_mount_nfs_{{minion_platform}}:
  salt.state:
    - tgt: {{minion_tgt}}
    - queue: True
    - sls:
      - auto_setup.setup_local_umount
    - require:
      - salt: copy_signed_packages_{{base_cfg.build_version}}_{{minion_platform}}


## allow for umount to complete (90sec - give 120 for safety)
cleanup_tgt_settle_{{minion_platform}}:
  salt.function:
    - name: cmd.run
    - tgt: {{minion_tgt}}
    - arg:
      - sleep 120 
    - require:
      - salt: cleanup_mount_nfs_{{minion_platform}}


publish_event_finished_build_{{minion_platform}}:
  salt.state:
    - tgt: {{minion_tgt}}
    - queue: True
    - sls:
      - auto_setup.event_build_finished
    - require:
      - salt: cleanup_tgt_settle_{{minion_platform}}

