{% import "auto_setup/auto_base_map.jinja" as base_cfg %}

# comment to induce highlighting

{% set default_user = 'saltstack' %}
{% set specific_user = pillar.get('specific_name_user', default_user) %}
{% set specific_user_salt_only = pillar.get('specific_name_user_salt_only', False) %}
{% set specific_pack_branch = pillar.get('specific_pack_branch', 'develop') %}
{% set build_branch = base_cfg.build_branch %}

{% set build_py3 = pillar.get('build_py3', False) %}
{% if build_py3 %}
{% set salt_pack_version = 'salt-pack-py3' %}
{% else %}
{% set salt_pack_version = 'salt-pack' %}
{% endif %}


build_pack_pkgs:
  pkg.installed:
   - pkgs:
     - git


build_pack_user:
  user.present:
    - name: {{base_cfg.build_runas}}
    - groups:
      - adm
    - require:
      - pkg: build_pack_pkgs


build_create_salt_pack_dir:
  file.directory:
    - name: {{base_cfg.build_salt_pack_dir}}
    - user: {{base_cfg.build_runas}}
    - dir_mode: 755
    - file_mode: 644


retrieve_desired_salt_pack:
  git.latest:
{% if specific_user_salt_only == True %}
    - name: https://github.com/{{default_user}}/{{salt_pack_version}}.git
{% else %}
    - name: https://github.com/{{specific_user}}/{{salt_pack_version}}.git
{% endif %}
    - rev: {{specific_pack_branch}}
    - target: {{base_cfg.build_salt_pack_dir}}
    - user: {{base_cfg.build_runas}}
    - force_clone: True
    - force_reset: True


build_clean_pkgbuild_file:
  file.absent:
    - name: {{base_cfg.build_salt_pack_dir}}/pillar_roots/pkgbuild.sls


write_build_pkgbuild_file:
  file.append:
    - name: {{base_cfg.build_salt_pack_dir}}/pillar_roots/pkgbuild.sls
    - makedirs: True
    - text: |
        # set version to build
        {{'{%'}} set build_version = '{{base_cfg.build_version}}' {{'%}'}}

        {% raw %}
        {% if build_version != '' %}
        include:
            - versions.{{build_version}}.pkgbuild
        {% endif %}
        {% endraw %}


{% if base_cfg.build_specific_tag %}
## ensure tagged directory exists and is updated
copy_working_branch_to_tagged_pillar_directory:
  file.copy:
    - name: {{base_cfg.build_salt_pack_dir}}/pillar_roots/versions/{{base_cfg.build_version}}/pkgbuild.sls
    - source: {{base_cfg.build_salt_pack_dir}}/pillar_roots/versions/{{build_branch}}/pkgbuild.sls
    - dir_mode: 755
    - file_mode: 644
    - user: {{base_cfg.build_runas}}
    - makedirs: True


ensure_versions_directory:
  file.directory:
    - name: {{base_cfg.build_salt_pack_dir}}/file_roots/versions/{{base_cfg.build_version}}
    - user: {{base_cfg.build_runas}}
    - dir_mode: 755
    - file_mode: 644
    - makedirs: True


ensure_salt_directory:
  file.directory:
    - name: {{base_cfg.build_salt_pack_dir}}/file_roots/pkg/salt/{{base_cfg.build_version}}
    - user: {{base_cfg.build_runas}}
    - dir_mode: 755
    - file_mode: 644
    - makedirs: True


copy_working_branch_to_tagged_file_salt_directory:
  cmd.run:
    - name: cp -f -R {{base_cfg.build_salt_pack_dir}}/file_roots/pkg/salt/{{build_branch}}/* {{base_cfg.build_salt_pack_dir}}/file_roots/pkg/salt/{{base_cfg.build_version}}/


copy_working_branch_to_tagged_file_directory:
  cmd.run:
    - name: cp -f -R {{base_cfg.build_salt_pack_dir}}/file_roots/versions/{{build_branch}}/* {{base_cfg.build_salt_pack_dir}}/file_roots/versions/{{base_cfg.build_version}}/
    - require:
      - cmd: copy_working_branch_to_tagged_file_salt_directory


ensure_dirs_copied:
  file.exists:
    - name: {{base_cfg.build_salt_pack_dir}}/file_roots/versions/{{base_cfg.build_version}}/ubuntu_pkg.sls
    - require:
      - cmd: copy_working_branch_to_tagged_file_directory

{% endif %}

