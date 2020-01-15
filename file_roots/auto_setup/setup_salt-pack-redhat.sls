{% import "auto_setup/auto_base_map.jinja" as base_cfg %}

## comment for highlighting

## Redhat 7 & 6

{% set build_branch = base_cfg.build_year ~ '_' ~ base_cfg.build_major_ver %}
{% set default_branch_version_dotted = base_cfg.build_year ~ '.' ~ base_cfg.build_major_ver ~'.0' %}
{% set rpm_date = pillar.get('build_rpm_date') %}

# no support for Redhat 6 in Python3
{% set build_py3 = pillar.get('build_py3', False) %}
{% if build_py3 %}
{% set py_ver = 'py3' %}
{% set changelog_text_py_ver = ' for Python 3' %}
## {# {% set platform_supported = ['rhel8', 'rhel7', 'fedora'] %} #}
{% set platform_supported = ['rhel8', 'rhel7'] %}
{% else %}
{% set py_ver = 'py2' %}
{% set changelog_text_py_ver = ' for Python 2' %}
## {# {% set platform_supported = ['rhel7', 'rhel6', 'fedora'] %} #}
{% set platform_supported = ['rhel7', 'rhel6'] %}
{% endif %}

{% if base_cfg.build_specific_tag %}
{% set default_branch_version = build_branch ~'.0' %}

{% if base_cfg.release_level is defined %}
{% set release_level = pillar.get(base_cfg.release_level, '1') %}
{% else %}
{% set release_level = '1' %}
{% endif %}

{% set spec_pattern_text_date = 'tobereplaced_date' %}
{% set spec_replacement_text_date = '%{nil}' %}
{% set pattern_text_date = default_branch_version_dotted ~ 'tobereplaced_date-0' %}
{% set replacement_text_date = base_cfg.build_dsig ~ '-' ~ release_level %}
{% set changelog_text = base_cfg.build_dsig ~ '-' ~ release_level %}
{% else %}
{% set release_level = '0' %}
{% set spec_pattern_text_date = 'tobereplaced_date' %}
{% set spec_replacement_text_date = base_cfg.build_dsig %}
{% set pattern_text_date = spec_pattern_text_date ~ '-' ~ release_level %}
{% set replacement_text_date = spec_replacement_text_date ~ '-' ~ release_level %}
{% set changelog_text = default_branch_version_dotted ~ base_cfg.build_dsig ~ '-' ~ release_level %}
{% endif %}

{% set specific_user = pillar.get( 'specific_name_user', 'saltstack') %}


{% set rpmfiles = ['salt-api', 'salt-api.service', 'salt-master', 'salt-master.service', 'salt-minion', 'salt-minion.service', 'salt-syndic', 'salt-syndic.service', 'salt.bash' ] %}

{% for platform_release in platform_supported %}

build_cp_salt_targz_{{platform_release}}_sources:
  file.copy:
{% if base_cfg.build_specific_tag %}
    - name: {{base_cfg.build_salt_pack_dir}}/file_roots/pkg/salt/{{base_cfg.build_version}}/{{platform_release}}/sources
    - source: {{base_cfg.build_salt_dir}}/dist/salt-{{base_cfg.build_dsig}}.tar.gz
{% else %}
    - name: {{base_cfg.build_salt_pack_dir}}/file_roots/pkg/salt/{{base_cfg.build_version}}/{{platform_release}}/sources
    - source: {{base_cfg.build_salt_dir}}/dist/salt-{{base_cfg.build_version_full_dotted}}{{base_cfg.build_dsig}}.tar.gz
{% endif %}
    - force: True
    - makedirs: True
    - preserve: True
    - user: {{base_cfg.build_runas}}
    - subdir: True

{% for rpmfile in rpmfiles %}

build_cp_salt_targz_{{platform_release}}_{{rpmfile.replace('.', '-')}}:
  file.copy:
    - name: {{base_cfg.build_salt_pack_dir}}/file_roots/pkg/salt/{{base_cfg.build_version}}/{{platform_release}}/sources
    - source: {{base_cfg.build_salt_dir}}/pkg/rpm/{{rpmfile}}
    - force: True
    - makedirs: True
    - preserve: True
    - user: {{base_cfg.build_runas}}
    - subdir: True

{% endfor %}


## TODO does salt-proxy@.service need a symbolic link in pkg/rpm
build_cp_salt_targz_{{platform_release}}_special_salt-proxy-service:
  file.copy:
    - name: {{base_cfg.build_salt_pack_dir}}/file_roots/pkg/salt/{{base_cfg.build_version}}/{{platform_release}}/sources
    - source: {{base_cfg.build_salt_dir}}/pkg/salt-proxy@.service
    - force: True
    - makedirs: True
    - preserve: True
    - user: {{base_cfg.build_runas}}
    - subdir: True


build_cp_salt_targz_{{platform_release}}_salt-fish-completions:
  cmd.run:
    - name: cp -R {{base_cfg.build_salt_dir}}/pkg/fish-completions {{base_cfg.build_salt_pack_dir}}/file_roots/pkg/salt/{{base_cfg.build_version}}/{{platform_release}}/sources/
    - runas: {{base_cfg.build_runas}}


adjust_branch_curr_salt_pack_{{platform_release}}_spec:
  file.replace:
    - name: {{base_cfg.build_salt_pack_dir}}/file_roots/pkg/salt/{{base_cfg.build_version}}/{{platform_release}}/spec/salt.spec
    - pattern: '{{spec_pattern_text_date}}'
    - repl: '{{spec_replacement_text_date}}'
    - show_changes: True
    - count: 1


adjust_branch_curr_salt_pack_{{platform_release}}_spec_release_changelog:
  file.line:
    - name: {{base_cfg.build_salt_pack_dir}}/file_roots/pkg/salt/{{base_cfg.build_version}}/{{platform_release}}/spec/salt.spec
    - mode: insert
    - after: "%changelog"
    - content: |
        * {{rpm_date}} SaltStack Packaging Team <packaging@{{specific_user}}.com> - {{changelog_text}}
        - Update to feature release {{changelog_text}} {{changelog_text_py_ver}}
 
        remove_this_line_after_insertion
    - show_changes: True
    - require:
      - file: adjust_branch_curr_salt_pack_{{platform_release}}_spec


adjust_branch_curr_salt_pack_{{platform_release}}_spec_release_changelog_cleanup:
  file.line:
    - name: {{base_cfg.build_salt_pack_dir}}/file_roots/pkg/salt/{{base_cfg.build_version}}/{{platform_release}}/spec/salt.spec
    - mode: delete
    - match: 'remove_this_line_after_insertion'
    - show_changes: True
    - require:
      - file: adjust_branch_curr_salt_pack_{{platform_release}}_spec_release_changelog


adjust_branch_curr_salt_pack_{{platform_release}}_pkgbuild:
  file.replace:
    - name: {{base_cfg.build_salt_pack_dir}}/pillar_roots/pkgbuild.sls
    - pattern: '{{pattern_text_date}}'
    - repl: '{{replacement_text_date}}'
    - show_changes: True
    - count: 1


adjust_branch_curr_salt_pack_{{platform_release}}_version_pkgbuild:
  file.replace:
    - name: {{base_cfg.build_salt_pack_dir}}/pillar_roots/versions/{{base_cfg.build_version}}/pkgbuild.sls
    - pattern: '{{pattern_text_date}}'
    - repl: '{{replacement_text_date}}'
    - show_changes: True


{% if base_cfg.build_specific_tag %}

adjust_branch_curr_salt_pack_{{platform_release}}_spec_version:
  file.replace:
    - name: {{base_cfg.build_salt_pack_dir}}/file_roots/pkg/salt/{{base_cfg.build_version}}/{{platform_release}}/spec/salt.spec
    - pattern: '{{default_branch_version_dotted}}'
    - repl: '{{base_cfg.build_dsig}}'
    - show_changes: True
    - count: 1
    - require:
      - file: adjust_branch_curr_salt_pack_{{platform_release}}_spec


adjust_branch_curr_salt_pack_{{platform_release}}_spec_release:
  file.replace:
    - name: {{base_cfg.build_salt_pack_dir}}/file_roots/pkg/salt/{{base_cfg.build_version}}/{{platform_release}}/spec/salt.spec
    - pattern: 'Release: 0'
    - repl: 'Release: {{release_level}}'
    - show_changes: True
    - count: 1
    - require:
      - file: adjust_branch_curr_salt_pack_{{platform_release}}_spec_version

{% endif %}

{% endfor %}    ## platform_supported


{% if base_cfg.build_specific_tag %}

update_versions_redhat_{{base_cfg.build_version}}:
 file.replace:
    - name: {{base_cfg.build_salt_pack_dir}}/file_roots/versions/{{base_cfg.build_version}}/redhat_pkg.sls
    - pattern: '{{build_branch}}'
    - repl: '{{base_cfg.build_version}}'
    - show_changes: True

{% endif %}
