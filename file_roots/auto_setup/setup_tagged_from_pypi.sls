{% import "auto_setup/auto_base_map.jinja" as base_cfg %}

## comment for highlighting

{% if base_cfg.build_specific_tag %}

## attempt to retrieve tag from PyPI
build_create_salt_code_dest_dir_for_pypi:
  file.directory:
    - name: {{base_cfg.build_salt_pypi_dir}}
    - user: {{base_cfg.build_runas}}
    - dir_mode: 755
    - file_mode: 644
    - makedirs: True


build_create_salt_code_dest_dir:
  file.directory:
    - name: {{base_cfg.build_salt_dir}}
    - user: {{base_cfg.build_runas}}
    - dir_mode: 755
    - file_mode: 644
    - makedirs: True


retrieve_tag_from_pypi:
  cmd.run:
    - name: |
        wget -q https://pypi.io/packages/source/s/salt/salt-{{base_cfg.build_version_full_dotted}}.tar.gz
    - cwd: {{base_cfg.build_salt_pypi_dir}}
    - ignore_retcode: True


delay_to_ensure_download_completes:
  cmd.run:
    - name: 'ls -al {{base_cfg.build_salt_pypi_dir}}/salt-{{base_cfg.build_version_full_dotted}}.tar.gz'
    - ignore_retcode: True
    - use_vt: True
    - require:
      - cmd: retrieve_tag_from_pypi

{% endif %}

