{% import "auto_setup/auto_base_map.jinja" as base_cfg %}

## comment high-lighting

{% set build_py3 = pillar.get('build_py3', False) %}
{% if build_py3 %}
{% set build_py_ver = 'py3' %}
{% else %}
{% set build_py_ver = 'py2' %}
{% endif %}

{% set build_arch = grains.get('osarch') %}

## set platform
{% if grains.get('os_family') == 'Debian' -%}
{% set platform_pkg = 'apt' %}

{% if grains.get('os') == 'Ubuntu' -%}
{% set platform = grains.get('os')|lower -%}
{% set os_version = grains.get('osrelease') %}
{% set tgt_build_release = platform ~ os_version.replace('.', '') %}
{% else %}
{% set platform = grains.get('os_family')|lower -%}
{% set os_version = grains.get('osmajorrelease') %}
{% set tgt_build_release = platform ~ grains.get('osmajorrelease') %}
{% endif %}

{% elif grains.get('os_family') == 'RedHat' -%}
{% set platform_pkg = 'yum' %}

{% if grains.get('os') == 'Amazon' -%}
{% set platform = grains.get('os')|lower -%}
{% if build_py3 %}
## only build Amazon Linux 2 for Py3, Amazon Linux 1 for Py2
{% set os_version = '2' %}
{% set tgt_build_release = 'amzn' ~ os_version %}
{% else %}
{% set os_version = 'latest' %}
{% set tgt_build_release = 'amzn' %}
{% endif %}
{% else %}
{% set platform = grains.get('os_family')|lower -%}
{% set tgt_build_release = 'rhel' ~ grains.get('osmajorrelease') %}
{% set os_version = grains.get('osmajorrelease') %}
{% endif %}

{% else %}
{% set platform_pkg = 'Unsupported-platform-packager' -%}
{% set platform = 'Unsupported-platform' -%}
{% set tgt_build_release = 'Unsupported-platform' -%}
{% endif %}

{% set minion_platform = pillar.get('build_release', tgt_build_release) %}
{% set specific_user = pillar.get('specific_name_user', 'saltstack') %}
{% set build_dest = pillar.get('build_dest') %}
{% set platform_name = platform|lower %}
{% set nb_srcdir = build_dest ~ '/' ~ build_py_ver ~ '/' ~ minion_platform ~ '/' ~ build_arch %}

{% set build_branch = base_cfg.build_number_dotted %}

{% if base_cfg.build_specific_tag %}
{% set nb_destdir = base_cfg.build_number_dotted %}
{% else %}
{% set nb_destdir = base_cfg.build_number_dotted ~ base_cfg.build_dsig %}
{% endif %}

## if Python 3 then override yum or apt
{% if build_py3 %}
{% set platform_pkg = 'py3' %}
{% endif %}

{% set repo_url = 'https://s3.repo.saltstack.com' %}
{% set web_compatible_dir = platform_pkg ~ '/' ~ platform_name ~ '/' ~ os_version ~ '/' ~ build_arch %}

{% set nfs_server_base_dir = base_cfg.minion_mount_nfsbasedir ~ '/' ~ specific_user ~ '/' ~ web_compatible_dir %}

mkdir_deps_packages:
  file.directory:
    - name: {{nb_srcdir}}
    - user: {{base_cfg.build_runas}}
    - group: {{base_cfg.build_runas}}
    - dir_mode: 775
    - file_mode: 644
    - makedirs: True
    - recurse:
        - user
        - group
        - mode

{%- if platform == 'redhat' and os_version == 8 %}
install_s3_sync_tool:
  pkg.installed:
    - name: rclone
{%- else %}
install_s3_sync_tool:
  pkg.installed:
    - name: awscli
{%- endif %}
copy_repo_latest_deps:
  cmd.run:
    - name: |
{%- if platform == 'redhat' and os_version == 8 %}
        RCLONE_CONFIG_S3_TYPE=s3 RCLONE_CONFIG_S3_PROVIDER=Other RCLONE_CONFIG_S3_ENV_AUTH=false RCLONE_CONFIG_S3_ENDPOINT={{repo_url}} rclone copy -c -v s3:s3/{{web_compatible_dir}}/latest/ ./
{%- else %}
        aws --no-sign-request --endpoint-url {{repo_url}} s3 sync --exact-timestamps s3://s3/{{web_compatible_dir}}/latest/ ./
{%- endif %}
    - cwd: {{nb_srcdir}}/
    - runas: {{base_cfg.build_runas}}
    - use_vt: True
    - require:
      - file: mkdir_deps_packages

copy_signed_deps:
  cmd.run:
    - name: |
        cp -n -v -u -p -R {{nfs_server_base_dir}}/{{build_branch}}/* {{nb_srcdir}}/
    - runas: {{base_cfg.build_runas}}


copy_signed_deps_done:
 cmd.run:
    - name: echo "copied to {{nb_srcdir}}/"
    - require:
      - cmd: copy_signed_deps

