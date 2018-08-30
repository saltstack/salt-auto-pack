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


clean_salt_reactor_conf:
   file.absent:
     - name: {{base_cfg.build_salt_reactor_conf}}


clean_salt_reactor_file:
   file.absent:
     - name: {{base_cfg.build_salt_reactor_file}}


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


reinitialize_reactor_conf:
  file.managed:
    - name: {{base_cfg.build_salt_reactor_conf}}
    - makedirs: True
    - contents: |
        reactor:
          - 'salt/auto-pack/build/finished':
              - /srv/reactor/auto_pack_event.sls


reinitialize_reactor_file:
  file.managed:
    - name: {{base_cfg.build_salt_reactor_file}}
    - makedirs: True
    - contents: |
        {% raw %}
        {% import "auto_setup/auto_base_map.jinja" as base_cfg %}
        {% if data.tag == 'salt/auto-pack/build/finished' and data.data.build_transfer == 'completed' %}
        test_auto_pack_event:
        {% if base_cfg.build_cloud_hold == 0 %}
          runner.cloud.destroy:
            - args:
                instances: {{data['id']}}
          wheel.key.delete:
            - args:
                match: {{data['id']}}
        {% endif %}
        {% endif %}
        {% endraw %}


