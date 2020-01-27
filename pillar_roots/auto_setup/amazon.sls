{% import "auto_setup/auto_base_map.jinja" as base_cfg %}

# comment
build_dest: '/srv/amazon/{{base_cfg.build_dest_dir}}/pkgs'
build_version: '{{base_cfg.build_version}}'
build_runas: 'builder'
build_release: 'amzn1'
