{% import "auto_setup/auto_base_map.jinja" as base_cfg %}

## comment for highlighting

{% set build_branch = base_cfg.build_year ~ '_' ~ base_cfg.build_major_ver %}
{% set apt_date = pillar.get('build_apt_date') %}

{% set build_py3 = pillar.get('build_py3', False) %}
{% if build_py3 %}
{% set py_ver = 'py3' %}
{% set changelog_text_py_ver = ' for Python 2 and Python 3' %}
{% set debian_supported = ['debian9'] %}
{% else %}
{% set py_ver = 'py2' %}
{% set changelog_text_py_ver = ' for Python 2' %}
{% set debian_supported = ['debian9', 'debian8'] %}
{% endif %}


{% if base_cfg.build_specific_tag %}
{% set default_branch_version = build_branch ~'.0' %}
{% set default_branch_version_dotted = base_cfg.build_year ~ '.' ~ base_cfg.build_major_ver ~'.0' %}

{% if base_cfg.release_level is defined %}
{% set release_level = pillar.get(base_cfg.release_level, '1') %}
{% else %}
{% set release_level = '1' %}
{% endif %}

{% set pattern_text_date = 'tobereplaced_date' %}
{% set replacement_text_date = '' %}
{% set pattern_text_ver = 'tobereplaced_ver' %}
{% set replacement_text_ver = base_cfg.build_dsig %}
{% else %}
{% set pattern_text_date = 'tobereplaced_date' %}
{% set replacement_text_date = base_cfg.build_dsig %}
{% set pattern_text_ver = 'tobereplaced_ver' %}
{% set replacement_text_ver = base_cfg.build_version_full_dotted %}
{% endif %}

{% set specific_user = pillar.get( 'specific_name_user', 'saltstack') %}
{% set spec_file_tarball = 'salt_debian.tar.xz' %}


{% for debian_ver in debian_supported %}

{% set dir_debian_base = base_cfg.build_salt_pack_dir ~ '/file_roots/pkg/salt/' ~ base_cfg.build_version ~ '/' ~ debian_ver %}

build_cp_salt_targz_{{debian_ver}}_sources:
  file.copy:
{% if base_cfg.build_specific_tag %}
    - name: {{dir_debian_base}}/sources/salt-{{base_cfg.build_dsig}}.tar.gz
    - source: {{base_cfg.build_salt_dir}}/dist/salt-{{base_cfg.build_dsig}}.tar.gz
{% else %}
    - name: {{dir_debian_base}}/sources/salt-{{base_cfg.build_version_full_dotted}}{{base_cfg.build_dsig}}.tar.gz
    - source: {{base_cfg.build_salt_dir}}/dist/salt-{{base_cfg.build_version_full_dotted}}{{base_cfg.build_dsig}}.tar.gz
{% endif %}
    - force: True
    - makedirs: True
    - preserve: True
    - user: {{base_cfg.build_runas}}
    - subdir: True


adjust_branch_curr_salt_pack_version_{{debian_ver}}_init_date:
  file.replace:
    - name: {{dir_debian_base}}/init.sls
    - pattern: '{{pattern_text_date}}'
    - repl: '{{replacement_text_date}}'
    - show_changes: True


adjust_branch_curr_salt_pack_version_{{debian_ver}}_init_ver:
  file.replace:
    - name: {{dir_debian_base}}/init.sls
    - pattern: '{{pattern_text_ver}}'
    - repl: '{{replacement_text_ver}}'
    - show_changes: True
    - require:
      - file: adjust_branch_curr_salt_pack_version_{{debian_ver}}_init_date


{% if base_cfg.build_specific_tag %}

adjust_branch_curr_salt_pack_version_{{debian_ver}}_init_release_ver:
  file.replace:
    - name: {{dir_debian_base}}/init.sls
    - pattern: "release_ver = '0'"
    - repl: "release_ver = '{{release_level}}'"
    - show_changes: True
    - require:
      - file: adjust_branch_curr_salt_pack_version_{{debian_ver}}_init_ver

{% endif %}


adjust_branch_curr_salt_pack_version_{{debian_ver}}_directory:
  file.directory:
    - name: {{dir_debian_base}}
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


unpack_branch_curr_salt_pack_version_{{debian_ver}}_spec:
  module.run:
    - name: archive.tar
    - tarfile: {{dir_debian_base}}/spec//{{spec_file_tarball}}
    - dest: {{dir_debian_base}}/spec
    - cwd: {{dir_debian_base}}/spec
    - runas: {{base_cfg.build_runas}}
    - options: -xvJf


remove_branch_curr_salt_pack_version_{{debian_ver}}_changelog:
  file.absent:
    - name: {{dir_debian_base}}/spec//debian/changelog


touch_branch_curr_salt_pack_version_{{debian_ver}}_changelog:
  file.touch:
    - name: {{dir_debian_base}}/spec//debian/changelog


update_branch_curr_salt_pack_version_{{debian_ver}}_changelog:
  file.append:
    - name: {{dir_debian_base}}/spec//debian/changelog
    - ignore_whitespace: False
    - text: |
{%- if base_cfg.build_specific_tag %}
        salt ({{base_cfg.build_dsig}}+ds-{{release_level}}) stable; urgency=medium

          * Build of Salt {{base_cfg.build_dsig}} {{changelog_text_py_ver}}

         -- Salt Stack Packaging <packaging@{{specific_user}}.com>  {{apt_date}}
{%- else %}
        salt ({{base_cfg.build_version_full_dotted}}{{base_cfg.build_dsig}}+ds-0) stable; urgency=medium

          * Build of Salt {{base_cfg.build_version_full_dotted}}{{base_cfg.build_dsig}} {{changelog_text_py_ver}}

         -- Salt Stack Packaging <packaging@{{specific_user}}.com>  {{apt_date}}
{%- endif %}
    - require:
      - file: remove_branch_curr_salt_pack_version_{{debian_ver}}_changelog


pack_branch_curr_salt_pack_version_{{debian_ver}}_spec:
   module.run:
     - name: archive.tar
     - tarfile: {{spec_file_tarball}}
     - dest: {{dir_debian_base}}/spec
     - sources: debian
     - cwd: {{dir_debian_base}}/spec
     - runas: {{base_cfg.build_runas}}
     - options: -cvJf


cleanup_pack_branch_curr_salt_pack_version_{{debian_ver}}_spec:
  file.absent:
    - name: {{dir_debian_base}}/spec/debian

{% endfor %}


{% if base_cfg.build_specific_tag %}

update_versions_debian_{{base_cfg.build_version}}:
 file.replace:
    - name: {{base_cfg.build_salt_pack_dir}}/file_roots/versions/{{base_cfg.build_version}}/debian_pkg.sls
    - pattern: '{{build_branch}}'
    - repl: '{{base_cfg.build_version}}'
    - show_changes: True

{% endif %}

