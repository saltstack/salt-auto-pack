{% import "auto_setup/auto_base_map.jinja" as base_cfg %}
#
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
{% set os_version = 'latest' %}
{% set platform = grains.get('os')|lower -%}
{% set tgt_build_release = 'amzn' %}
{% else %}
{% set os_version = grains.get('osmajorrelease') %}
{% set platform = grains.get('os_family')|lower -%}
{% set tgt_build_release = 'rhel' ~ grains.get('osmajorrelease') %}
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

{% if base_cfg.build_specific_tag %}
{% set nb_destdir = base_cfg.build_dsig %}
{% else %}
{% set nb_destdir = base_cfg.build_version ~ base_cfg.build_dsig %}
{% endif %}

## if Python 3 then override yum or apt
{% if build_py3 %}
{% set platform_pkg = 'py3' %}
{% endif %}

{% set web_server_base_dir = base_cfg.minion_bldressrv_rootdir ~ '/' ~ specific_user ~ '/' ~ platform_pkg ~ '/' ~ platform_name ~ '/' ~ os_version ~ '/' ~ build_arch %}
{% set web_server_archive_dir = web_server_base_dir ~ '/archive/' ~ nb_destdir %}


copy_signed_packages:
  cmd.run:
    - name: |
        scp -i {{base_cfg.build_homedir}}/.ssh/{{base_cfg.rsa_priv_key_file}} -o StrictHostKeyChecking='no' -p -r {{nb_srcdir}}/* {{base_cfg.minion_bldressrv_username}}@{{base_cfg.minion_bldressrv_hostname}}:{{web_server_archive_dir}}/
    - runas: {{base_cfg.build_runas}}

