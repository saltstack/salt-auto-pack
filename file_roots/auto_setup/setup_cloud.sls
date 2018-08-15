{% import "auto_setup/auto_base_map.jinja" as base_cfg %}

## get if cloud map is default

{% set dflt_cloud_providers = '/etc/salt/cloud.providers' %}
{% set dflt_cloud_profiles = '/etc/salt/cloud.profiles' %}
{% set dflt_cloud_map = '/etc/salt/cloud.map' %}

{% set build_cloud_map = pillar.get('build_cloud_map', dflt_cloud_map) %}

{% set master_fqdn = grains.get('fqdn') %}

{% set overwrite_cloud_map = false %}

{% if build_cloud_map == dflt_cloud_map %}
{% set my_id = grains.get('id') %}
{% set overwrite_cloud_map_dict = salt.cmd.run("salt " ~ my_id ~ " file.file_exists '" ~ dflt_cloud_map ~ "' -l quiet --out=json") | load_json %}

{% if overwrite_cloud_map_dict[my_id] == True %}
{% set overwrite_cloud_map = true %}
{% else %}
{% set overwrite_cloud_map = false %}
{% endif %}

{% endif %}

{% set build_py3 = pillar.get('build_py3', False) %}

{% set uniqueval = base_cfg.uniqueval %}

{% if overwrite_cloud_map == false %}

remove_curr_providers:
  file.absent:
    - name: {{dflt_cloud_providers}}


create_dflt_providers:
  file.append:
    - name: {{dflt_cloud_providers}}
    - ignore_whitespace: False
    - text: |
        opennebula:
          minion:
            master: {{master_fqdn}}
          xml_rpc: http://one.c7.saltstack.net:2633/RPC2
          driver: opennebula
          user: svc-builder
          password: VbJY6DjxJhHAauTXuRv8
          ssh_username: root
          ssh_password: salt
          wait_for_passwd_maxtries: 40
          fqdn_base: c7.saltstack.net
          private_key: /root/.ssh/opennebula_key


remove_curr_profiles:
  file.absent:
    - name: {{dflt_cloud_profiles}}


create_dflt_profiles:
  file.append:
    - name: {{dflt_cloud_profiles}}
    - ignore_whitespace: False
    - text: |
        svc-builder-debian9-{{uniqueval}}:
          provider: opennebula
          template: debian90-base-template
          image: debian90-base-image-v2
        svc-builder-u1804-{{uniqueval}}:
          provider: opennebula
          template: ubuntu1804_base_packer_template
          image: ubuntu1804-base-packer-2018050911351525887332
        svc-builder-u1604-{{uniqueval}}:
          provider: opennebula
          template: dgm_ubuntu1604_base_packer_template
          image: dgm_ubuntu1604_base_template-disk-2
        svc-builder-cent7-{{uniqueval}}:
          provider: opennebula
          template: svc-builder-centos7_base_packer_template
          image: centos7-base-packer-2017103110031509465834
        svc-builder-debian8-{{uniqueval}}:
          provider: opennebula
          template: svc-builder-debian8_base_packer_template
          image: svc-bld-debian8_base_template-disk-0
        svc-builder-u1404-{{uniqueval}}:
          provider: opennebula
          template: svc-builder-ubuntu1404_base_packer_template
          image: ubuntu1404-base-packer-2017103110011509465699
        ## svc-builder-cent6-{{uniqueval}}:
        ##   provider: opennebula
        ##   template: svc-builder-centos6_base_packer_template
        ##   image: centos6-base-packer-2017111414131510694006
        ##   script_args: stable 2016.11.8
        ## svc-builder-amazon-{{uniqueval}}:
        ##   provider: opennebula
        ##   template: svc-builder-amazon-linux_base_packer_template
        ##   image: svc-bld-amzn_base_template-disk-0



remove_curr_map:
  file.absent:
    - name: {{dflt_cloud_map}}


create_dflt_map:
  file.append:
    - name: {{dflt_cloud_map}}
    - ignore_whitespace: False
    - text: |
        svc-builder-cent7-{{uniqueval}}:
          - svc-builder-autotest-c7m-{{uniqueval}}
        svc-builder-debian9-{{uniqueval}}:
          - svc-builder-autotest-d9m-{{uniqueval}}
        svc-builder-u1804-{{uniqueval}}:
          - svc-builder-autotest-u18m-{{uniqueval}}
        svc-builder-u1604-{{uniqueval}}:
          - svc-builder-autotest-u16m-{{uniqueval}}
{%- if build_py3 == False %}
        svc-builder-debian8-{{uniqueval}}:
          - svc-builder-autotest-d8m-{{uniqueval}}
        svc-builder-u1404-{{uniqueval}}:
          - svc-builder-autotest-u14m-{{uniqueval}}
{% endif %}
##        svc-builder-cent6-{{uniqueval}}:
##          - svc-builder-autotest-c6m-{{uniqueval}}
##        svc-builder-amazon-{{uniqueval}}:
##          - svc-builder-autotest-amzn-{{uniqueval}}

{% endif %}


## startup build minions specified in cloud map

launch_cloud_map:
  cmd.run:
    - name: "salt-cloud -l quiet -y -P -m {{build_cloud_map}}"

