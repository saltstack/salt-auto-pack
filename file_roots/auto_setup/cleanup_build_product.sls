{% import "auto_setup/auto_base_map.jinja" as base_cfg %}

## comment high-lighting

{% set build_py3 = pillar.get('build_py3', False) %}
{% if build_py3 %}
{% set build_py_ver = 'py3' %}
{% else %}
{% set build_py_ver = 'py2' %}
{% endif %}

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

{% set specific_user = pillar.get('specific_name_user', 'saltstack') %}
{% set platform_name = platform|lower %}

{% set build_arch = grains.get('osarch') %}
{% set minion_platform = pillar.get('build_release', tgt_build_release) %}
{% set build_dest = pillar.get('build_dest') %}
{% set nb_srcdir = build_dest ~ '/' ~ build_py_ver ~ '/' ~ minion_platform ~ '/' ~ build_arch %}


## ensure cleanup from any previous builds
remove_salt_packages:
  cmd.run:
    - name: |
        rm -f {{nb_srcdir}}/salt*

remove_salt_srpms_packages:
  cmd.run:
    - name: |
        rm -f {{nb_srcdir}}/SRPMS/salt*


remove_salt_dirs_packages:
  cmd.run:
    - name: |
        rm -fR {{nb_srcdir}}/repodata {{nb_srcdir}}/conf {{nb_srcdir}}/db {{nb_srcdir}}/dists {{nb_srcdir}}/pool



