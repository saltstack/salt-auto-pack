{% import "auto_setup/auto_base_map.jinja" as base_cfg %}

## comment high-lighting

{% set build_py3 = pillar.get('build_py3', False) %}
{% if build_py3 %}
{% set build_py_ver = 'py3' %}
{% else %}
{% set build_py_ver = 'py2' %}
{% endif %}

{% set build_arch = grains.get('osarch') %}

## set platform
{% if grains.get('os_family') == 'Debian' -%}
{% set platform_pkg = 'apt' %}

{% if grains.get('os') == 'Ubuntu' -%}
{% set platform = grains.get('os')|lower -%}
{% set os_version = grains.get('osrelease') %}
{% set tgt_build_release = platform ~ os_version.replace('.', '') %}
{% else %}
{% set platform = grains.get('os_family')|lower -%}
{% set os_version = grains.get('osmajorrelease') %}
{% set tgt_build_release = platform ~ grains.get('osmajorrelease') %}
{% endif %}

{% elif grains.get('os_family') == 'RedHat' -%}
{% set platform_pkg = 'yum' %}

{% if grains.get('os') == 'Amazon' -%}
{% set platform = grains.get('os')|lower -%}
{% if build_py3 %}
## only build Amazon Linux 2 for Py3, Amazon Linux 1 for Py2
{% set os_version = '2' %}
{% set tgt_build_release = 'amzn' ~ os_version %}
{% else %}
{% set os_version = 'latest' %}
{% set tgt_build_release = 'amzn' %}
{% endif %}
{% else %}
{% set platform = grains.get('os_family')|lower -%}
{% set tgt_build_release = 'rhel' ~ grains.get('osmajorrelease') %}
{% set os_version = grains.get('osmajorrelease') %}
{% endif %}

{% else %}
{% set platform_pkg = 'Unsupported-platform-packager' -%}
{% set platform = 'Unsupported-platform' -%}
{% set tgt_build_release = 'Unsupported-platform' -%}
{% endif %}

{% set minion_platform = pillar.get('build_release', tgt_build_release) %}
{% set specific_user = pillar.get('specific_name_user', 'saltstack') %}
{% set build_dest = pillar.get('build_dest') %}
{% set platform_name = platform|lower %}
{% set nb_srcdir = build_dest ~ '/' ~ build_py_ver ~ '/' ~ minion_platform ~ '/' ~ build_arch %}

{% if base_cfg.build_specific_tag %}
{% set nb_destdir = base_cfg.build_number_dotted %}
{% else %}
{% set nb_destdir = base_cfg.build_number_dotted ~ base_cfg.build_dsig %}
{% endif %}

## if Python 3 then override yum or apt
{% if build_py3 %}
{% set platform_pkg = 'py3' %}
{% endif %}

{% set repo_url = 'https://s3.repo.saltstack.com' %}
{% set web_compatible_dir = platform_pkg ~ '/' ~ platform_name ~ '/' ~ os_version ~ '/' ~ build_arch %}

{% set nfs_server_base_dir = base_cfg.minion_mount_nfsbasedir ~ '/' ~ specific_user ~ '/' ~ web_compatible_dir %}

{% set copy_repo_check_script_file = base_cfg.build_homedir ~ '/copy_deps_repo_check.sh' %}

{% if platform == 'debian' or platform == 'ubuntu' %}
## only need to perform this check for Debian or Ubuntu families

{% set repo_version = 'latest' %}

cleanup_deps_tmpdir:
  file.absent:
    - name: {{base_cfg.build_salt_tmp_dir}}

mkdir_deps_tmpdir:
  file.directory:
    - name: {{base_cfg.build_salt_tmp_dir}}
    - user: {{base_cfg.build_runas}}
    - group: {{base_cfg.build_runas}}
    - dir_mode: 775
    - file_mode: 644
    - makedirs: True
    - recurse:
        - user
        - group
        - mode

{%- if platform == 'redhat' and os_version == 8 %}
install_s3_sync_tool:
  pkg.installed:
    - name: rclone
{%- else %}
install_s3_sync_tool:
  pkg.installed:
    - name: awscli
{%- endif %}
copy_repo_latest_deps:
  cmd.run:
    - name: |
{%- if platform == 'redhat' and os_version == 8 %}
        RCLONE_CONFIG_S3_TYPE=s3 RCLONE_CONFIG_S3_PROVIDER=Other RCLONE_CONFIG_S3_ENV_AUTH=false RCLONE_CONFIG_S3_ENDPOINT={{repo_url}} rclone copy -c -v s3:s3/{{web_compatible_dir}}/{{repo_version}}/ ./
{%- else %}
        aws --no-sign-request --endpoint-url {{repo_url}} s3 sync --exact-timestamps s3://s3/{{web_compatible_dir}}/{{repo_version}}/ ./
{%- endif %}
    - cwd: {{base_cfg.build_salt_tmp_dir}}/
    - runas: {{base_cfg.build_runas}}
    - use_vt: True
    - require:
      - file: mkdir_deps_tmpdir

remove_salt_tmp_dirs_packages:
  cmd.run:
    - name: |
        rm -fR {{base_cfg.build_salt_tmp_dir}}/conf {{base_cfg.build_salt_tmp_dir}}/db {{base_cfg.build_salt_tmp_dir}}/dists {{base_cfg.build_salt_tmp_dir}}/pool


## now we have a copy of the latest on repo.saltstack.com
## we need to compare to see if same in tmp dir as just built, need to give pref.
## to version from tmp dir, but cannot do straight name replace since abc.orig.tar.gz will
## match new abc.orig.tar.gz, hence need to check debian.tar.[gz|xz] versions first and then if no difference
## copy all with 'abc' in name.

remove_copy_script:
  file.absent:
    - name: {{copy_repo_check_script_file}}


generate_copy_script:
  file.managed:
    - name: {{copy_repo_check_script_file}}
    - dir_mode: 755
    - mode: 755
    - show_changes: False
    - user: {{base_cfg.build_runas}}
    - group: {{base_cfg.build_runas}}
    - makedirs: True
    - contents: |
        #!/bin/sh

        ## script to update built packages with originally released packages
        ## only if they are essentially unchanged, by checking sha256sum of ABC.debian.tar.[x|g]z
        ## since contents of ABC.debian.tar.xz only change if real changes have occured.

        repo_dir=$1
        built_dir=$2

        curr_dir=$(pwd)
        # get list of*.debian.tar.?z for repo
        cd $repo_dir
        repo_debtar_list=$(find . -name "*.debian.tar.?z" | cut -d '/' -f 2 | sort| uniq)
        cd $curr_dir

        cd $built_dir
        # get list of*.debian.tar.?z for built
        built_debtar_list=$(find . -name "*.debian.tar.?z" | cut -d '/' -f 2 | sort | uniq)
        cd $curr_dir

        ## loop thru repo list and copy repo contents if sums match
        for idx in $repo_debtar_list
        do
            for bdx in $built_debtar_list
            do
                if [ "$idx" = "$bdx" ]; then
                    repo_sum=$(sha256sum $repo_dir/$idx | cut -d ' ' -f 1)
                    built_sum=$(sha256sum $built_dir/$bdx | cut -d ' ' -f 1)
                    if [ "$repo_sum" = "$built_sum" ]; then
                        item=$(echo $idx | cut -d '_' -f 1)
                        copy_list=$(find $repo_dir -name "*$item*")
                        for cpx in $copy_list
                        do
                            cp -f -v $cpx $built_dir/
                        done
                        break
                    fi
                fi
            done
        done


execute_copy_script:
  cmd.run:
    - name: {{copy_repo_check_script_file}} {{base_cfg.build_salt_tmp_dir}} {{nb_srcdir}}
    - runas: 'root'
    - require:
      - file: generate_copy_script


copy_repo_deps_done:
 cmd.run:
    - name: echo "copied to {{nb_srcdir}} those repo products that are unchanged"
    - require:
      - cmd: execute_copy_script

{% else %}

copy_repo_deps_done:
 cmd.run:
    - name: echo "non Debian or Ubuntu platform those repo products that are unused"

{% endif %}

