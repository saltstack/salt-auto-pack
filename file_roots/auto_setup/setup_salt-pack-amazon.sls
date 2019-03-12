{% import "auto_setup/auto_base_map.jinja" as base_cfg %}

## comment for highlighting

## Python 3 support on Amazon only for Amazon Linux 2 (amzn2)
## Python 2 support on Amazon only for Amazon Linux (amzn), 
## Python 2 Amazon Linux 2 get redirected to use RHEL 7

{% set build_py3 = pillar.get('build_py3', False) %}
{% if build_py3 %}
{% set py_ver = 'py3' %}
{% set changelog_text_py_ver = ' for Python 3' %}
{% set platform_supported = ['amzn2'] %}
{% else %}
{% set py_ver = 'py2' %}
{% set changelog_text_py_ver = ' for Python 2' %}
{% set platform_supported = ['amzn'] %}
{% endif %}

## Amazon Latest, copies from Redhat 7 which should be run first

{% set build_branch = base_cfg.build_year ~ '_' ~ base_cfg.build_major_ver %}
{% set default_branch_version_dotted = base_cfg.build_year ~ '.' ~ base_cfg.build_major_ver ~'.0' %}
{% set rpm_date = pillar.get('build_rpm_date') %}

{% if base_cfg.build_specific_tag %}
{% set default_branch_version = build_branch ~'.0' %}

{% if base_cfg.release_level is defined %}
{% set release_level = pillar.get(base_cfg.release_level, '1') %}
{% else %}
{% set release_level = '1' %}
{% endif %}

{% set pattern_text_date = default_branch_version_dotted ~ 'tobereplaced_date-0' %}
{% set replacement_text_date = base_cfg.build_dsig ~ '-' ~ release_level %}
{% set changelog_text = base_cfg.build_dsig ~ '-' ~ release_level %}
{% else %}
{% set release_level = '0' %}
{% set pattern_text_date = 'tobereplaced_date' %}
{% set replacement_text_date = base_cfg.build_dsig %}
{% set changelog_text = default_branch_version_dotted ~ base_cfg.build_dsig ~ '-' ~ release_level %}
{% endif %}


{% set specific_user = pillar.get( 'specific_name_user', 'saltstack') %}


{% for platform_ver in platform_supported %}

{% set dir_platform_base = base_cfg.build_salt_pack_dir ~ '/file_roots/pkg/salt/' ~ base_cfg.build_version ~ '/' ~ platform_ver %}

build_cp_salt_targz_{{platform_ver}}_sources:
  file.copy:
{% if base_cfg.build_specific_tag %}
    - name: {{base_cfg.build_salt_pack_dir}}/file_roots/pkg/salt/{{base_cfg.build_version}}/{{platform_ver}}/sources
    - source: {{base_cfg.build_salt_dir}}/dist/salt-{{base_cfg.build_dsig}}.tar.gz
{% else %}
    - name: {{base_cfg.build_salt_pack_dir}}/file_roots/pkg/salt/{{base_cfg.build_version}}/{{platform_ver}}/sources
    - source: {{base_cfg.build_salt_dir}}/dist/salt-{{base_cfg.build_version_full_dotted}}{{base_cfg.build_dsig}}.tar.gz
{% endif %}
    - force: True
    - makedirs: True
    - preserve: True
    - user: {{base_cfg.build_runas}}
    - subdir: True

{% set rpmfiles = ['salt-api', 'salt-api.service', 'salt-master', 'salt-master.service', 'salt-minion', 'salt-minion.service', 'salt-syndic', 'salt-syndic.service', 'salt.bash' ] %}

{% for rpmfile in rpmfiles %}

build_cp_salt_targz_{{platform_ver}}_{{rpmfile.replace('.', '-')}}:
  file.copy:
    - name: {{base_cfg.build_salt_pack_dir}}/file_roots/pkg/salt/{{base_cfg.build_version}}/{{platform_ver}}/sources
    - source: {{base_cfg.build_salt_dir}}/pkg/rpm/{{rpmfile}}
    - force: True
    - makedirs: True
    - preserve: True
    - user: {{base_cfg.build_runas}}
    - subdir: True

{% endfor %}


## TODO does salt-proxy@.service need a symbolic link in pkg/rpm
build_cp_salt_targz_{{platform_ver}}_special_salt-proxy-service:
  file.copy:
    - name: {{base_cfg.build_salt_pack_dir}}/file_roots/pkg/salt/{{base_cfg.build_version}}/{{platform_ver}}/sources
    - source: {{base_cfg.build_salt_dir}}/pkg/salt-proxy@.service
    - force: True
    - makedirs: True
    - preserve: True
    - user: {{base_cfg.build_runas}}
    - subdir: True


build_cp_salt_targz_{{platform_ver}}_salt-fish-completions:
  cmd.run:
    - name: cp -R {{base_cfg.build_salt_dir}}/pkg/fish-completions {{base_cfg.build_salt_pack_dir}}/file_roots/pkg/salt/{{base_cfg.build_version}}/{{platform_ver}}/sources/
    - runas: {{base_cfg.build_runas}}


{% if base_cfg.build_specific_tag %}

adjust_branch_curr_salt_pack_{{platform_ver}}_spec:
  file.replace:
    - name: {{base_cfg.build_salt_pack_dir}}/file_roots/pkg/salt/{{base_cfg.build_version}}/{{platform_ver}}/spec/salt.spec
    - pattern: 'tobereplaced_date'
    - repl: '%{nil}'
    - show_changes: True
    - count: 1


adjust_branch_curr_salt_pack_{{platform_ver}}_spec_version:
  file.replace:
    - name: {{base_cfg.build_salt_pack_dir}}/file_roots/pkg/salt/{{base_cfg.build_version}}/{{platform_ver}}/spec/salt.spec
    - pattern: 'Version: {{default_branch_version_dotted}}'
    - repl: 'Version: {{base_cfg.build_dsig}}'
    - show_changes: True
    - count: 1
    - require:
      - file: adjust_branch_curr_salt_pack_{{platform_ver}}_spec


adjust_branch_curr_salt_pack_{{platform_ver}}_spec_release:
  file.replace:
    - name: {{base_cfg.build_salt_pack_dir}}/file_roots/pkg/salt/{{base_cfg.build_version}}/{{platform_ver}}/spec/salt.spec
    - pattern: 'Release: 0'
    - repl: 'Release: {{release_level}}'
    - show_changes: True
    - count: 1
    - require:
      - file: adjust_branch_curr_salt_pack_{{platform_ver}}_spec_version


adjust_branch_curr_salt_pack_{{platform_ver}}_spec_release_changelog:
  file.line:
    - name: {{base_cfg.build_salt_pack_dir}}/file_roots/pkg/salt/{{base_cfg.build_version}}/{{platform_ver}}/spec/salt.spec
    - mode: insert
    - after: "%changelog"
    - content: |
        * {{rpm_date}} SaltStack Packaging Team <packaging@{{specific_user}}.com> - {{changelog_text}}
        - Update to feature release {{changelog_text}}
        
        remove_this_line_after_insertion
    - show_changes: True
    - require:
      - file: adjust_branch_curr_salt_pack_{{platform_ver}}_spec_release


adjust_branch_curr_salt_pack_{{platform_ver}}_spec_release_changelog_cleanup:
  file.line:
    - name: {{base_cfg.build_salt_pack_dir}}/file_roots/pkg/salt/{{base_cfg.build_version}}/{{platform_ver}}/spec/salt.spec
    - mode: delete
    - match: 'remove_this_line_after_insertion'
    - show_changes: True
    - require:
      - file: adjust_branch_curr_salt_pack_{{platform_ver}}_spec_release_changelog

{% else %}

adjust_branch_curr_salt_pack_{{platform_ver}}_spec:
  file.replace:
    - name: {{base_cfg.build_salt_pack_dir}}/file_roots/pkg/salt/{{base_cfg.build_version}}/{{platform_ver}}/spec/salt.spec
    - pattern: '{{pattern_text_date}}'
    - repl: '{{replacement_text_date}}'
    - show_changes: True
    - count: 1


adjust_branch_curr_salt_pack_{{platform_ver}}_spec_release_changelog:
  file.line:
    - name: {{base_cfg.build_salt_pack_dir}}/file_roots/pkg/salt/{{base_cfg.build_version}}/{{platform_ver}}/spec/salt.spec
    - mode: insert
    - after: "%changelog"
    - content: |
        * {{rpm_date}} SaltStack Packaging Team <packaging@{{specific_user}}.com> - {{changelog_text}}
        - Update to feature release {{changelog_text}}
        
        remove_this_line_after_insertion
    - show_changes: True
    - require:
      - file: adjust_branch_curr_salt_pack_{{platform_ver}}_spec


adjust_branch_curr_salt_pack_{{platform_ver}}_spec_release_changelog_cleanup:
  file.line:
    - name: {{base_cfg.build_salt_pack_dir}}/file_roots/pkg/salt/{{base_cfg.build_version}}/{{platform_ver}}/spec/salt.spec
    - mode: delete
    - match: 'remove_this_line_after_insertion'
    - show_changes: True
    - require:
      - file: adjust_branch_curr_salt_pack_{{platform_ver}}_spec_release_changelog


{% endif %}


adjust_branch_curr_salt_pack_{{platform_ver}}_pkgbuild:
  file.replace:
    - name: {{base_cfg.build_salt_pack_dir}}/pillar_roots/pkgbuild.sls
    - pattern: '{{pattern_text_date}}'
    - repl: '{{replacement_text_date}}'
    - show_changes: True
    - count: 1


adjust_branch_curr_salt_pack_{{platform_ver}}_version_pkgbuild:
  file.replace:
    - name: {{base_cfg.build_salt_pack_dir}}/pillar_roots/versions/{{base_cfg.build_version}}/pkgbuild.sls
    - pattern: '{{pattern_text_date}}'
    - repl: '{{replacement_text_date}}'
    - show_changes: True

{% endfor %}


{% if base_cfg.build_specific_tag %}

update_versions_{{platform_ver}}_{{base_cfg.build_version}}:
 file.replace:
    - name: {{base_cfg.build_salt_pack_dir}}/file_roots/versions/{{base_cfg.build_version}}/amazon_pkg.sls
    - pattern: '{{build_branch}}'
    - repl: '{{base_cfg.build_version}}'
    - show_changes: True

{% endif %}

