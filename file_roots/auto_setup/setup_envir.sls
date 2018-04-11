{% import "auto_setup/auto_base_map.jinja" as base_cfg %}

## comment for highlighting

{% set top_file_location = '/srv/pillar/top.sls' %}

clean_salt_code_dir:
  file.absent:
    - name: {{base_cfg.build_salt_dir}}


clean_salt_code_pypi_dir:
  file.absent:
      - name: {{base_cfg.build_salt_pypi_dir}}


clean_salt_pack_dir:
  file.absent:
    - name: {{base_cfg.build_salt_pack_dir}}


## TBD need to utilize path from install environment for top.sls
remove_pillar_top_file:
  file.absent:
    - name: {{top_file_location}}


reinitialize_pillar_top_file:
  file.append:
    - name: {{top_file_location}}
    - text: |
        base:
          '*':
            - auto_setup.tag_build_dsig

