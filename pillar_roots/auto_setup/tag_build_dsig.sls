## # build_dsig (designation) is YYYYMMDDhhmmnnnn
## # branch_tag is either branch 2017.7 or tag v2017.7.1
{% import "auto_setup/tag_build_dsig.jinja" as bd_cfg %}

build_dsig: '{{bd_cfg.build_dsig }}'
build_local_minion: '{{bd_cfg.build_local_minion}}'
branch_tag: '{{bd_cfg.branch_tag}}'
nfs_minion: '{{bd_cfg.nfs_minion}}'
nfs_host: '{{bd_cfg.nfs_host}}'
nfs_absdir: '{{bd_cfg.nfs_absdir}}'
build_apt_date: "{{bd_cfg.build_apt_date}}"
build_rpm_date: "{{bd_cfg.build_rpm_date}}"
build_py3: {{bd_cfg.build_py3}}
keyid: 4DD70950

{% if bd_cfg.build_clean is defined %}
build_clean: '{{bd_cfg.build_clean}}'
{% endif %}

{% if bd_cfg.code_named_branch_tag is defined %}
code_named_branch_tag: '{{bd_cfg.code_named_branch_tag}}'
{% endif %}

{% if bd_cfg.specific_name_user is defined %}
specific_name_user: '{{bd_cfg.specific_name_user}}'
{% endif %}

{% if bd_cfg.specific_pack_branch is defined %}
specific_pack_branch: '{{bd_cfg.specific_pack_branch}}'
{% endif %}

{% if bd_cfg.user_nfs_server is defined %}
user_nfs_server: '{{bd_cfg.user_nfs_server}}'
{% endif %}

{% if bd_cfg.build_cloud_map is defined %}
build_cloud_map: '{{bd_cfg.build_cloud_map}}'
{% endif %}

