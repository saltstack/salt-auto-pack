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
{% set nb_destdir = base_cfg.build_number_dotted %}
{% else %}
{% set nb_destdir = base_cfg.build_number_dotted ~ base_cfg.build_dsig %}
{% endif %}

## if Python 3 then override yum or apt
{% if build_py3 %}
{% set platform_pkg = 'py3' %}
{% endif %}

{% set nfs_server_base_dir = base_cfg.minion_mount_nfsbasedir ~ '/' ~ specific_user ~ '/' ~ platform_pkg ~ '/' ~ platform_name ~ '/' ~ os_version ~ '/' ~ build_arch %}
{% set nfs_server_archive_dir = nfs_server_base_dir ~ '/archive/' ~ nb_destdir %}


copy_signed_packages:
  cmd.run:
    - name: |
        cp -p -R {{nb_srcdir}}/* {{nfs_server_archive_dir}}/


copy_signed_packages_done:
 cmd.run:
    - name: echo "copied to {{nfs_server_archive_dir}}/"
    - require:
      - cmd: copy_signed_packages

