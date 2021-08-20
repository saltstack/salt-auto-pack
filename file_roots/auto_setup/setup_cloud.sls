{% import "auto_setup/auto_base_map.jinja" as base_cfg %}

## get if cloud map is default

{% set dflt_cloud_providers = '/etc/salt/cloud.providers' %}
{% set dflt_cloud_profiles = '/etc/salt/cloud.profiles' %}
{% set dflt_cloud_map = '/etc/salt/cloud.map' %}

{% set build_cloud_map = pillar.get('build_cloud_map', dflt_cloud_map) %}
{% set build_py3 = pillar.get('build_py3', False) %}
{% set master_fqdn = grains.get('fqdn') %}
{% set use_existing_cloud_map = false %}

## disable for now since hand build till 2019.2.1 release
{%- if build_py3 %}
{% set debian10_available = true %}
{% set rhel8_available = true %}
{% set amzn2_available = true %}
{%- else %}
{% set debian10_available = false %}
{% set rhel8_available = false %}
{% set amzn2_available = false %}
{%- endif %}


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
          size: c4.xlarge
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
{%- if build_py3 %}
          script_args: -x python3 stable
{%- else %}
          script_args: stable
{%- endif %}
        svc-builder-debian9{{unique_postfix}}:
          provider: production-ec2-us-west-2-private-ips
          image: ami-0f73b3e4b0b0a67ac
          size: c5.xlarge
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
          script_args: -x python3 stable
        svc-builder-u2004arm64{{unique_postfix}}:
          provider: production-ec2-us-west-2-private-ips
          image: ami-0515006d8fd69b0a3
          size: c6g.xlarge
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
          script_args: -x python3 stable
        svc-builder-u2004{{unique_postfix}}:
          provider: production-ec2-us-west-2-private-ips
          image: ami-0adf3a90b056c3b35
          size: c5.xlarge
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
          script_args: -x python3 stable
        svc-builder-u1804{{unique_postfix}}:
          provider: production-ec2-us-west-2-private-ips
          image: ami-0d5f916f52836397d
          size: c5.xlarge
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
          script_args: -x python3 stable
        svc-builder-u1604{{unique_postfix}}:
          provider: production-ec2-us-west-2-private-ips
          image: ami-0f7157f751a882a04
          size: c5.xlarge
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
          script_args: -x python3 stable
{%- if build_py3 %}
{%- if rhel8_available %}
        svc-builder-cent8{{unique_postfix}}:
          provider: production-ec2-us-west-2-private-ips
          image: ami-02b343d2e3ea1980c
          size: c5.xlarge
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
          script_args: -x python3 stable
{%- endif %}
{%- if debian10_available %}
        svc-builder-debian10{{unique_postfix}}:
          provider: production-ec2-us-west-2-private-ips
          image: ami-07aa4b8d0915e6f17
          size: c5a.xlarge
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
          script_args: -x python3 stable
{%- endif %}
{%- if amzn2_available %}
        svc-builder-amzn2{{unique_postfix}}:
          provider: production-ec2-us-west-2-private-ips
          image: ami-0033222265d04439f
          size: c5.xlarge
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
          script_args: -x python3 stable
{%- endif %}
{% else %}
        svc-builder-amzn1{{unique_postfix}}:
          provider: production-ec2-us-west-2-private-ips
          image: ami-06878170589c3321a
          size: c5.xlarge
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
          script_args: stable
        svc-builder-debian8{{unique_postfix}}:
          provider: production-ec2-us-west-2-private-ips
          image: ami-0853e07df32d2cd50
          size: c5.xlarge
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
          script_args: stable
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
        svc-builder-u2004{{unique_postfix}}:
          - svc-builder-autotest-u2004m{{unique_postfix}}
{%- if not "3001" in base_cfg.build_version and not "3002" in base_cfg.build_version and not "3003" in base_cfg.build_version %}
        svc-builder-u2004arm64{{unique_postfix}}:
          - svc-builder-autotest-u2004arm64m{{unique_postfix}}
{%- endif %}
        svc-builder-u1804{{unique_postfix}}:
          - svc-builder-autotest-u1804m{{unique_postfix}}
{%- if "3001" in base_cfg.build_version or "3002" in base_cfg.build_version %}
        svc-builder-u1604{{unique_postfix}}:
          - svc-builder-autotest-u1604m{{unique_postfix}}
{%- endif %}
{%- if build_py3 %}
{%- if debian10_available %}
        svc-builder-debian10{{unique_postfix}}:
          - svc-builder-autotest-d10m{{unique_postfix}}
{%- endif %}
{%- if rhel8_available %}
        svc-builder-cent8{{unique_postfix}}:
          - svc-builder-autotest-c8m{{unique_postfix}}
{%- endif %}
{%- if amzn2_available %}
        svc-builder-amzn2{{unique_postfix}}:
          - svc-builder-autotest-amzn2{{unique_postfix}}
{%- endif %}
{%- endif %}
{%- endif %}

## endif for if use_existing_cloud_map == false

## waiting for bootstrap to support Amazon Linux 2
##         svc-builder-amzn2{{unique_postfix}}:
##           - svc-builder-autotest-amzn2{{unique_postfix}}

## startup build minions specified in cloud map
update_cloud_bootstrap_latest:
  cmd.run:
    - name: "salt-cloud -u"

## temporary workaround until upstream bootstrap works
#update_cloud_bootstrap_latest_p1:
#  cmd.run:
#    - name: "cp -f /home/centos/test/bootstrap-salt.sh /etc/salt/cloud.deploy.d/bootstrap-salt.sh"
#
#update_cloud_bootstrap_latest_p2:
#  cmd.run:
#    - name: "cp -f /home/centos/test/bootstrap-salt.sh /usr/lib/python2.7/site-packages/salt/cloud/deploy/bootstrap-salt.sh"


launch_cloud_map:
  cmd.run:
    - name: "salt-cloud -l quiet -y -P -m {{build_cloud_map}}"
