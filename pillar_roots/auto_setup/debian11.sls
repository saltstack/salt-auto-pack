{% import "auto_setup/auto_base_map.jinja" as base_cfg %}

# comment
build_dest: '/srv/debian/{{base_cfg.build_dest_dir}}/pkgs'
build_version: '{{base_cfg.build_version}}'
build_runas: 'admin'
build_release: 'debian11'
