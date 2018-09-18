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
            ec2_tags:
              aws:
                access_key: 'ABCDEFGHIJK'
                secret_key: '0123456789'
          grains:
            role_type: auto-pack
          id: 'ABCDEFGHIJK'
          key: '0123456789'
          private_key: /root/.ssh/jenkins-testing.pem
          keyname: jenkins-testing
          driver: ec2
          ssh_interface: private_ips
          block_device_mappings:
            - DeviceName: /dev/sda1
              Ebs.VolumeSize: 100
              Ebs.VolumeType: gp2

## {#                access_key: '{{ salt['pillar.get']('amazon_apikey') }}' #}
## {#                secret_key: '{{ salt['pillar.get']('amazon_password') }}' #}
## {#          id: '{{ salt['pillar.get']('amazon_apikey') }}' #}
## {#          key: '{{ salt['pillar.get']('amazon_password') }}' #}
##        opennebula:
##          minion:
## {#            master: {{master_fqdn}} #}
##          xml_rpc: http://one.c7.saltstack.net:2633/RPC2
##          driver: opennebula
##          user: svc-builder
##          password: VbJY6DjxJhHAauTXuRv8
##          ssh_username: root
##          ssh_password: salt
##          wait_for_passwd_maxtries: 40
##          fqdn_base: c7.saltstack.net
##          private_key: /root/.ssh/opennebula_key


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
          image: ami-0a0296f7f67824612
          size: t2.medium
          private_key: /root/.ssh/jenkins-testing.pem
          ssh_interface: private_ips
          network_interfaces:
            - DeviceIndex: 0
              PrivateIpAddresses:
                - Primary: True
              AssociatePublicIpAddress: True
              SubnetId: subnet-700cf53b
              SecurityGroupId:
                - sg-d6b08ea9
          del_root_vol_on_destroy: True
          del_all_vol_on_destroy: True
          tag: {'environment': 'production', 'role_type': 'auto-pack', 'created-by': 'auto-pack'}
          sync_after_install: grains
          script_args: stable 2017.7.5
        svc-builder-debian9{{unique_postfix}}:
          provider: production-ec2-us-west-2-private-ips
          image: ami-84439fe4
          size: t2.medium
          private_key: /root/.ssh/jenkins-testing.pem
          ssh_interface: private_ips
          network_interfaces:
            - DeviceIndex: 0
              PrivateIpAddresses:
                - Primary: True
              AssociatePublicIpAddress: True
              SubnetId: subnet-700cf53b
              SecurityGroupId:
                - sg-d6b08ea9
          del_root_vol_on_destroy: True
          del_all_vol_on_destroy: True
          tag: {'environment': 'production', 'role_type': 'auto-pack', 'created-by': 'auto-pack'}
          sync_after_install: grains
          script_args: stable 2017.7.5
        svc-builder-u1804{{unique_postfix}}:
          provider: production-ec2-us-west-2-private-ips
          image: ami-04f8bb7c
          image: ami-0a0296f7f67824612
          size: t2.medium
          private_key: /root/.ssh/jenkins-testing.pem
          ssh_interface: private_ips
          network_interfaces:
            - DeviceIndex: 0
              PrivateIpAddresses:
                - Primary: True
              AssociatePublicIpAddress: True
              SubnetId: subnet-700cf53b
              SecurityGroupId:
                - sg-d6b08ea9
          del_root_vol_on_destroy: True
          del_all_vol_on_destroy: True
          tag: {'environment': 'production', 'role_type': 'auto-pack', 'created-by': 'auto-pack'}
          sync_after_install: grains
          script_args: stable 2017.7.5
        svc-builder-u1604{{unique_postfix}}:
          provider: production-ec2-us-west-2-private-ips
          image: ami-51537029
          size: t2.medium
          private_key: /root/.ssh/jenkins-testing.pem
          ssh_interface: private_ips
          network_interfaces:
            - DeviceIndex: 0
              PrivateIpAddresses:
                - Primary: True
              AssociatePublicIpAddress: True
              SubnetId: subnet-700cf53b
              SecurityGroupId:
                - sg-d6b08ea9
          del_root_vol_on_destroy: True
          del_all_vol_on_destroy: True
          tag: {'environment': 'production', 'role_type': 'auto-pack', 'created-by': 'auto-pack'}
          sync_after_install: grains
          script_args: stable 2017.7.5
        ## svc-builder-amazon{{unique_postfix}}:
        ##   provider: production-ec2-us-west-2-private-ips
        ##  image: 
        ##  ssh_username: 
{%- if build_py3 == False %}
        svc-builder-debian8{{unique_postfix}}:
          provider: production-ec2-us-west-2-private-ips
          image: ami-0d5b6c3d
          size: t2.medium
          private_key: /root/.ssh/jenkins-testing.pem
          ssh_interface: private_ips
          network_interfaces:
            - DeviceIndex: 0
              PrivateIpAddresses:
                - Primary: True
              AssociatePublicIpAddress: True
              SubnetId: subnet-700cf53b
              SecurityGroupId:
                - sg-d6b08ea9
          del_root_vol_on_destroy: True
          del_all_vol_on_destroy: True
          tag: {'environment': 'production', 'role_type': 'auto-pack', 'created-by': 'auto-pack'}
          sync_after_install: grains
          script_args: stable 2017.7.5
        svc-builder-u1404{{unique_postfix}}:
          provider: production-ec2-us-west-2-private-ips
          image: ami-0d10b1979afc575ba
          size: t2.medium
          private_key: /root/.ssh/jenkins-testing.pem
          ssh_interface: private_ips
          network_interfaces:
            - DeviceIndex: 0
              PrivateIpAddresses:
                - Primary: True
              AssociatePublicIpAddress: True
              SubnetId: subnet-700cf53b
              SecurityGroupId:
                - sg-d6b08ea9
          del_root_vol_on_destroy: True
          del_all_vol_on_destroy: True
          tag: {'environment': 'production', 'role_type': 'auto-pack', 'created-by': 'auto-pack'}
          sync_after_install: grains
          script_args: stable 2017.7.5
{%- endif %}

##DGM         svc-builder-debian9{{unique_postfix}}:
##DGM           provider: opennebula
##DGM           template: debian90-base-template
##DGM           image: debian90-base-image-v2
##DGM {#        svc-builder-u1804{{unique_postfix}}: #}
##DGM           provider: opennebula
##DGM           template: ubuntu1804_base_packer_template
##DGM           image: ubuntu1804-base-packer-2018050911351525887332
##DGM {#        svc-builder-u1604{{unique_postfix}}: #}
##DGM           provider: opennebula
##DGM           template: dgm_ubuntu1604_base_packer_template
##DGM           image: dgm_ubuntu1604_base_template-disk-2
##DGM {#        svc-builder-cent7{{unique_postfix}}: #}
##DGM           provider: opennebula
##DGM           template: centos7.2_base_template
##DGM           image: centos7.2-base-image-v5
##DGM  {#{%- if build_py3 == False %} #}
##DGM         svc-builder-debian8{{unique_postfix}}: #}
##DGM           provider: opennebula
##DGM           template: svc-builder-debian8_base_packer_template
##DGM           image: svc-bld-debian8_base_template-disk-0
##DGM   {#       svc-builder-u1404{{unique_postfix}}: #}
##DGM           provider: opennebula
##DGM           template: svc-builder-ubuntu1404_base_packer_template
##DGM           image: ubuntu1404-base-packer-2017103110011509465699
##DGM {%- endif %}


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
{%- if build_py3 == False %}
        svc-builder-debian8{{unique_postfix}}:
          - svc-builder-autotest-d8m{{unique_postfix}}
        svc-builder-u1404{{unique_postfix}}:
          - svc-builder-autotest-u14m{{unique_postfix}}
{%- endif %}
##        svc-builder-cent6{{unique_postfix}}:
##          - svc-builder-autotest-c6m{{unique_postfix}}
##        svc-builder-amazon{{unique_postfix}}:
##          - svc-builder-autotest-amzn{{unique_postfix}}


## startup build minions specified in cloud map

launch_cloud_map:
  cmd.run:
    - name: "salt-cloud -l quiet -y -P -m {{build_cloud_map}}"

