{% import "auto_setup/auto_base_map.jinja" as base_cfg %}

# comment for highlighting

{% set nfs_host = pillar.get('nfs_host', 'UKNOWN-HOST')%}
{% set build_local_id = pillar.get('build_local_minion', 'm7m') %}

umount_{{build_local_id}}:
  cmd.run:
    - name: umount {{nfs_host}}:{{base_cfg.minion_nfsabsdir}}
    - onlyif:
      - mount | grep '{{nfs_host}}'

