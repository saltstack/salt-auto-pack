{% import "auto_setup/auto_base_map.jinja" as base_cfg %}

## comment for highlighting

{% set build_branch = base_cfg.build_branch %}
{% set default_branch_version_number_dotted  = base_cfg.build_number_dotted %}

{% set apt_date = pillar.get('build_apt_date') %}

{% set build_py3 = pillar.get('build_py3', False) %}
{% if build_py3 %}
{% set py_ver = 'py3' %}
{% set changelog_text_py_ver = ' for Python 3' %}
{% set ubuntu_supported = ['ubuntu2004', 'ubuntu1804', 'ubuntu1604'] %}
{% else %}
{% set py_ver = 'py2' %}
{% set changelog_text_py_ver = ' for Python 2' %}
{% set ubuntu_supported = ['ubuntu2004', 'ubuntu1804', 'ubuntu1604'] %}
{% endif %}


{% if base_cfg.build_specific_tag %}

{% if base_cfg.release_level is defined %}
{% set release_level = pillar.get(base_cfg.release_level, '1') %}
{% else %}
{% set release_level = '1' %}
{% endif %}

{% set pattern_text_date = 'tobereplaced_date' %}
{% set replacement_text_date = '' %}
{% set pattern_text_ver = 'tobereplaced_ver' %}
{% set replacement_text_ver = default_branch_version_number_dotted %}

{% else %}

{% set pattern_text_date = 'tobereplaced_date' %}
{% set replacement_text_date = base_cfg.build_dsig %}
{% set pattern_text_ver = 'tobereplaced_ver' %}
{% set replacement_text_ver = default_branch_version_number_dotted %}

{% endif %}


{% set specific_user = pillar.get( 'specific_name_user', 'saltstack') %}
{% set spec_file_tarball = 'salt_ubuntu.tar.xz' %}


{% for platform_release in ubuntu_supported %}

{% set dir_platform_base = base_cfg.build_salt_pack_dir ~ '/file_roots/pkg/salt/' ~ base_cfg.build_number_uscore ~ '/' ~ platform_release %}

build_cp_salt_targz_{{platform_release}}_sources:
  file.copy:
{% if base_cfg.build_specific_tag %}
    - name: {{dir_platform_base}}/sources/salt-{{default_branch_version_number_dotted}}.tar.gz
    - source: {{base_cfg.build_salt_dir}}/dist/salt-{{default_branch_version_number_dotted}}.tar.gz
{% else %}
    - name: {{dir_platform_base}}/sources/salt-{{default_branch_version_number_dotted}}{{base_cfg.build_dsig}}.tar.gz
    - source: {{base_cfg.build_salt_dir}}/dist/salt-{{default_branch_version_number_dotted}}{{base_cfg.build_dsig}}.tar.gz
{% endif %}
    - force: True
    - makedirs: True
    - dir_mode: 755
    - file_mode: 644
    - user: {{base_cfg.build_runas}}
    - subdir: True


adjust_branch_curr_salt_pack_version_{{platform_release}}_init_date:
  file.replace:
    - name: {{dir_platform_base}}/init.sls
    - pattern: '{{pattern_text_date}}'
    - repl: '{{replacement_text_date}}'
    - show_changes: True


adjust_branch_curr_salt_pack_version_{{platform_release}}_init_ver:
  file.replace:
    - name: {{dir_platform_base}}/init.sls
    - pattern: '{{pattern_text_ver}}'
    - repl: '{{replacement_text_ver}}'
    - show_changes: True
    - require:
      - file: adjust_branch_curr_salt_pack_version_{{platform_release}}_init_date


{% if base_cfg.build_specific_tag %}

adjust_branch_curr_salt_pack_version_{{platform_release}}_init_release_ver:
  file.replace:
    - name: {{dir_platform_base}}/init.sls
    - pattern: "release_ver = '0'"
    - repl: "release_ver = '{{release_level}}'"
    - show_changes: True
    - require:
      - file: adjust_branch_curr_salt_pack_version_{{platform_release}}_init_ver

{% endif %}


adjust_branch_curr_salt_pack_version_{{platform_release}}_directory:
  file.directory:
    - name: {{dir_platform_base}}
    - force: True
    - makedirs: True
    - group: {{base_cfg.build_runas}}
    - user: {{base_cfg.build_runas}}
    - dir_mode: 755
    - file_mode: 644
    - recurse:
      - user
      - group
      - mode


unpack_branch_curr_salt_pack_version_{{platform_release}}_spec:
  module.run:
    - name: archive.tar
    - tarfile: {{dir_platform_base}}/spec/{{spec_file_tarball}}
    - dest: {{dir_platform_base}}/spec/
    - cwd: {{dir_platform_base}}/spec/
    - runas: {{base_cfg.build_runas}}
    - options: -xvJf


remove_branch_curr_salt_pack_version_{{platform_release}}_changelog:
  file.absent:
    - name: {{dir_platform_base}}/spec/debian/changelog


touch_branch_curr_salt_pack_version_{{platform_release}}_changelog:
  file.touch:
    - name: {{dir_platform_base}}/spec/debian/changelog


update_branch_curr_salt_pack_version_{{platform_release}}_changelog:
  file.append:
    - name: {{dir_platform_base}}/spec/debian/changelog
    - ignore_whitespace: False
    - text: |
{%- if base_cfg.build_specific_tag %}
        salt ({{default_branch_version_number_dotted}}+ds-{{release_level}}) stable; urgency=medium

          * Build of Salt {{default_branch_version_number_dotted}}{{changelog_text_py_ver}}

         -- Salt Stack Packaging <packaging@{{specific_user}}.com>  {{apt_date}}
{%- else %}
        salt ({{default_branch_version_number_dotted}}{{base_cfg.build_dsig}}+ds-0) stable; urgency=medium

          * Build of Salt {{default_branch_version_number_dotted}}{{base_cfg.build_dsig}} {{changelog_text_py_ver}}

         -- Salt Stack Packaging <packaging@{{specific_user}}.com>  {{apt_date}}
{%- endif %}
    - require:
      - file: remove_branch_curr_salt_pack_version_{{platform_release}}_changelog


pack_branch_curr_salt_pack_version_{{platform_release}}_spec:
   module.run:
     - name: archive.tar
     - tarfile: {{spec_file_tarball}}
     - dest: {{dir_platform_base}}/spec
     - sources: debian
     - cwd: {{dir_platform_base}}/spec
     - runas: {{base_cfg.build_runas}}
     - options: -cvJf


cleanup_pack_branch_curr_salt_pack_version_{{platform_release}}_spec:
  file.absent:
    - name: {{dir_platform_base}}/spec/debian

{% endfor %}


update_versions_ubuntu_{{base_cfg.build_number_uscore}}:
 file.replace:
    - name: {{base_cfg.build_salt_pack_dir}}/file_roots/versions/{{base_cfg.build_number_uscore}}/ubuntu_pkg.sls
    - pattern: '{{build_branch}}'
    - repl: '{{base_cfg.build_number_uscore}}'
    - show_changes: True

