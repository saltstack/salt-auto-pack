{% import "auto_setup/auto_base_map.jinja" as base_cfg %}

# comment for highlighting

{% set nfs_host = pillar.get('nfs_host', 'UKNOWN-HOST')%}
{% set build_local_id = pillar.get('build_local_minion', 'm7m') %}


ensure_dir_{{build_local_id}}:
  file.directory:
    - name: {{base_cfg.minion_bldressrv_nfsrootdir}}
    - makedirs: True


mount_{{build_local_id}}:
  cmd.run:
    - name: mount {{nfs_host}}:{{base_cfg.minion_bldressrv_nfs_absdir}}{{base_cfg.minion_bldressrv_nfsrootdir}} {{base_cfg.minion_bldressrv_nfsrootdir}}

