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
        svc-builder-debian9:
          provider: opennebula
          template: debian90-base-template
          image: debian90-base-image-v2
          script_args: stable 2017.7.5
        svc-builder-u1604:
          provider: opennebula
          template: dgm_ubuntu1604_base_packer_template
          image: dgm_ubuntu1604_base_template-disk-2
          script_args: stable 2017.7.5
        svc-builder-cent7:
          provider: opennebula
          template: svc-builder-centos7_base_packer_template
          image: centos7-base-packer-2017103110031509465834
          script_args: stable 2017.7.5
        svc-builder-debian8:
          provider: opennebula
          template: svc-builder-debian8_base_packer_template
          image: svc-bld-debian8_base_template-disk-0
          script_args: stable 2017.7.5
        svc-builder-u1404:
          provider: opennebula
          template: svc-builder-ubuntu1404_base_packer_template
          image: ubuntu1404-base-packer-2017103110011509465699
          script_args: stable 2017.7.5
        ##  script_args: stable 2016.11.8
        ## svc-builder-cent6:
        ##   provider: opennebula
        ##   template: svc-builder-centos6_base_packer_template
        ##   image: centos6-base-packer-2017111414131510694006
        ##   script_args: stable 2016.11.8
        ## svc-builder-amazon:
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
        svc-builder-cent7:
          - svc-builder-autotest-c7m
        svc-builder-debian9:
          - svc-builder-autotest-d9m
        svc-builder-u1604:
          - svc-builder-autotest-u16m
{%- if build_py3 == False %}
        svc-builder-debian8:
          - svc-builder-autotest-d8m
        svc-builder-u1404:
          - svc-builder-autotest-u14m
{% endif %}
##        svc-builder-cent6:
##          - svc-builder-autotest-c6m
##        svc-builder-amazon:
##          - svc-builder-autotest-amzn

{% endif %}


## startup build minions specified in cloud map 

launch_cloud_map:
  cmd.run:
    - name: "salt-cloud -l quiet -y -P -m {{build_cloud_map}}"

