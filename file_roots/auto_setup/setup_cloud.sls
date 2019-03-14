{% import "auto_setup/auto_base_map.jinja" as base_cfg %}

## get if cloud map is default

{% set dflt_cloud_providers = '/etc/salt/cloud.providers' %}
{% set dflt_cloud_profiles = '/etc/salt/cloud.profiles' %}
{% set dflt_cloud_map = '/etc/salt/cloud.map' %}

{% set build_cloud_map = pillar.get('build_cloud_map', dflt_cloud_map) %}
{% set build_py3 = pillar.get('build_py3', False) %}
{% set master_fqdn = grains.get('fqdn') %}
{% set use_existing_cloud_map = false %}


{% if base_cfg.build_cloud_hold %}

{% if build_cloud_map == dflt_cloud_map %}
{% set my_id = grains.get('id') %}
{% set use_existing_cloud_map_dict = salt.cmd.run("salt " ~ my_id ~ " file.file_exists '" ~ dflt_cloud_map ~ "' -l quiet --out=json") | load_json %}
{% if use_existing_cloud_map_dict[my_id] == True %}
{% set use_existing_cloud_map = true %}
{% endif %}
{% endif %}

{% endif %}


{% set uniqueval = base_cfg.uniqueval %}
{% if uniqueval != '' %}
{% set unique_postfix = '-' ~ uniqueval %}
{% else %}
{% set unique_postfix = '' %}
{% endif %}


{% if use_existing_cloud_map == false %}

remove_curr_providers:
  file.absent:
    - name: {{dflt_cloud_providers}}


create_dflt_providers:
  file.append:
    - name: {{dflt_cloud_providers}}
    - ignore_whitespace: False
    - text: |
        production-ec2-us-west-2-private-ips:
          location: us-west-2
          minion:
            master: {{master_fqdn}}
          grains:
            role_type: auto-pack
          id: 'use-instance-role-credentials'
          key: 'use-instance-role-credentials'
          private_key: /srv/salt/auto_setup/{{base_cfg.aws_access_priv_key_name}}
          keyname: {{base_cfg.aws_access_pub_key_name}}
          driver: ec2


remove_curr_profiles:
  file.absent:
    - name: {{dflt_cloud_profiles}}


create_dflt_profiles:
  file.append:
    - name: {{dflt_cloud_profiles}}
    - ignore_whitespace: False
    - text: |
        svc-builder-cent7{{unique_postfix}}:
          provider: production-ec2-us-west-2-private-ips
          image: ami-0bf2c7f0df2c22ce0
          size: t2.medium
          private_key: /srv/salt/auto_setup/{{base_cfg.aws_access_priv_key_name}}
          ssh_interface: private_ips
          network_interfaces:
            - DeviceIndex: 0
              PrivateIpAddresses:
                - Primary: True
              AssociatePublicIpAddress: True
              SubnetId: {{base_cfg.subnet_id}}
              SecurityGroupId:
                - {{base_cfg.sec_group_id}}
          del_root_vol_on_destroy: True
          del_all_vol_on_destroy: True
          tag: {'environment': 'production', 'role_type': 'auto-pack', 'created-by': 'auto-pack'}
          sync_after_install: grains
          script_args: stable 2019.2.0
        svc-builder-amzn2{{unique_postfix}}:
          provider: production-ec2-us-west-2-private-ips
          image: ami-0de21f348ed67b2f6
          size: t2.medium
          private_key: /srv/salt/auto_setup/{{base_cfg.aws_access_priv_key_name}}
          ssh_interface: private_ips
          network_interfaces:
            - DeviceIndex: 0
              PrivateIpAddresses:
                - Primary: True
              AssociatePublicIpAddress: True
              SubnetId: {{base_cfg.subnet_id}}
              SecurityGroupId:
                - {{base_cfg.sec_group_id}}
          del_root_vol_on_destroy: True
          del_all_vol_on_destroy: True
          tag: {'environment': 'production', 'role_type': 'auto-pack', 'created-by': 'auto-pack'}
          sync_after_install: grains
          script_args: stable 2019.2.0
        svc-builder-debian9{{unique_postfix}}:
          provider: production-ec2-us-west-2-private-ips
          image: ami-0f73b3e4b0b0a67ac
          size: t2.medium
          private_key: /srv/salt/auto_setup/{{base_cfg.aws_access_priv_key_name}}
          ssh_interface: private_ips
          network_interfaces:
            - DeviceIndex: 0
              PrivateIpAddresses:
                - Primary: True
              AssociatePublicIpAddress: True
              SubnetId: {{base_cfg.subnet_id}}
              SecurityGroupId:
                - {{base_cfg.sec_group_id}}
          del_root_vol_on_destroy: True
          del_all_vol_on_destroy: True
          tag: {'environment': 'production', 'role_type': 'auto-pack', 'created-by': 'auto-pack'}
          sync_after_install: grains
          script_args: stable 2019.2.0
        svc-builder-u1804{{unique_postfix}}:
          provider: production-ec2-us-west-2-private-ips
          image: ami-0772a3ab3adde716a
          size: t2.medium
          private_key: /srv/salt/auto_setup/{{base_cfg.aws_access_priv_key_name}}
          ssh_interface: private_ips
          network_interfaces:
            - DeviceIndex: 0
              PrivateIpAddresses:
                - Primary: True
              AssociatePublicIpAddress: True
              SubnetId: {{base_cfg.subnet_id}}
              SecurityGroupId:
                - {{base_cfg.sec_group_id}}
          del_root_vol_on_destroy: True
          del_all_vol_on_destroy: True
          tag: {'environment': 'production', 'role_type': 'auto-pack', 'created-by': 'auto-pack'}
          sync_after_install: grains
          script_args: stable 2019.2.0
        svc-builder-u1604{{unique_postfix}}:
          provider: production-ec2-us-west-2-private-ips
          image: ami-0a48da1bc7a80c2f2
          size: t2.medium
          private_key: /srv/salt/auto_setup/{{base_cfg.aws_access_priv_key_name}}
          ssh_interface: private_ips
          network_interfaces:
            - DeviceIndex: 0
              PrivateIpAddresses:
                - Primary: True
              AssociatePublicIpAddress: True
              SubnetId: {{base_cfg.subnet_id}}
              SecurityGroupId:
                - {{base_cfg.sec_group_id}}
          del_root_vol_on_destroy: True
          del_all_vol_on_destroy: True
          tag: {'environment': 'production', 'role_type': 'auto-pack', 'created-by': 'auto-pack'}
          sync_after_install: grains
          script_args: stable 2019.2.0
{%- if build_py3 == False %}
        svc-builder-amzn1{{unique_postfix}}:
          provider: production-ec2-us-west-2-private-ips
          image: ami-06878170589c3321a
          size: t2.medium
          private_key: /srv/salt/auto_setup/{{base_cfg.aws_access_priv_key_name}}
          ssh_interface: private_ips
          network_interfaces:
            - DeviceIndex: 0
              PrivateIpAddresses:
                - Primary: True
              AssociatePublicIpAddress: True
              SubnetId: {{base_cfg.subnet_id}}
              SecurityGroupId:
                - {{base_cfg.sec_group_id}}
          del_root_vol_on_destroy: True
          del_all_vol_on_destroy: True
          tag: {'environment': 'production', 'role_type': 'auto-pack', 'created-by': 'auto-pack'}
          sync_after_install: grains
          script_args: stable 2016.11
        svc-builder-debian8{{unique_postfix}}:
          provider: production-ec2-us-west-2-private-ips
          image: ami-0f91bd607d6192cd9
          size: t2.medium
          private_key: /srv/salt/auto_setup/{{base_cfg.aws_access_priv_key_name}}
          ssh_interface: private_ips
          network_interfaces:
            - DeviceIndex: 0
              PrivateIpAddresses:
                - Primary: True
              AssociatePublicIpAddress: True
              SubnetId: {{base_cfg.subnet_id}}
              SecurityGroupId:
                - {{base_cfg.sec_group_id}}
          del_root_vol_on_destroy: True
          del_all_vol_on_destroy: True
          tag: {'environment': 'production', 'role_type': 'auto-pack', 'created-by': 'auto-pack'}
          sync_after_install: grains
          script_args: stable 2019.2.0
        svc-builder-u1404{{unique_postfix}}:
          provider: production-ec2-us-west-2-private-ips
          image: ami-01999a491d50246b4
          size: t2.medium
          private_key: /srv/salt/auto_setup/{{base_cfg.aws_access_priv_key_name}}
          ssh_interface: private_ips
          network_interfaces:
            - DeviceIndex: 0
              PrivateIpAddresses:
                - Primary: True
              AssociatePublicIpAddress: True
              SubnetId: {{base_cfg.subnet_id}}
              SecurityGroupId:
                - {{base_cfg.sec_group_id}}
          del_root_vol_on_destroy: True
          del_all_vol_on_destroy: True
          tag: {'environment': 'production', 'role_type': 'auto-pack', 'created-by': 'auto-pack'}
          sync_after_install: grains
          script_args: stable 2019.2.0
{%- endif %}


remove_curr_map:
  file.absent:
    - name: {{dflt_cloud_map}}


create_dflt_map:
  file.append:
    - name: {{dflt_cloud_map}}
    - ignore_whitespace: False
    - text: |
        svc-builder-cent7{{unique_postfix}}:
          - svc-builder-autotest-c7m{{unique_postfix}}
        svc-builder-debian9{{unique_postfix}}:
          - svc-builder-autotest-d9m{{unique_postfix}}
        svc-builder-u1804{{unique_postfix}}:
          - svc-builder-autotest-u18m{{unique_postfix}}
        svc-builder-u1604{{unique_postfix}}:
          - svc-builder-autotest-u16m{{unique_postfix}}
{%- if build_py3 %}
        svc-builder-amzn2{{unique_postfix}}:
          - svc-builder-autotest-amzn2{{unique_postfix}}
{%- else %}
        svc-builder-amzn1{{unique_postfix}}:
          - svc-builder-autotest-amzn1{{unique_postfix}}
        svc-builder-debian8{{unique_postfix}}:
          - svc-builder-autotest-d8m{{unique_postfix}}
        svc-builder-u1404{{unique_postfix}}:
          - svc-builder-autotest-u14m{{unique_postfix}}
{%- endif %}

{%- endif %}
## endif for if use_existing_cloud_map == false

## waiting for bootstrap to support Amazon Linux 2
##         svc-builder-amzn2{{unique_postfix}}:
##           - svc-builder-autotest-amzn2{{unique_postfix}}


## startup build minions specified in cloud map


launch_cloud_map:
  cmd.run:
    - name: "salt-cloud -l quiet -y -P -m {{build_cloud_map}}"
