# Automation for Salt Package Builder (auto-pack)

Auto-pack is an open-source automation for building Salt packages and its dependencies, creating a repository and then delivering the built products to a results NFS server acting as a final receptical from which the build prodiuct can be obtained, leveraging salt-pack on various Operating Systems, most commonly used Linux platforms, for example: Redhat/CentOS and Debian/Ubuntu families, utilizing Salt states, execution modules and orchestration.

Auto-pack relies on SaltStack’s Master-Minion functionality to build the desired packages and repository, and can install the required tools to build the packages and repository for that platform.

Auto-pack is designed to overlay salt-pack and it's main functionality resides in pillar_roots/auto_setup and file_roots/auto_setup.  Auto-pack leverages orchestration to preform the setup, build and create repository functions which are typically done seperately with salt-pack.

For example: common usage of salt-pack
    salt minion_id state.sls setup.debian.debian9 pillar='{ "build_dest" : "/srv/debian/2017.7/pkgs" , "build_release" : "debian9" , "build_arch" : "armhf" }'

    salt minion_id state.highstate pillar='{ "build_dest" : "/srv/debian/2017.7/pkgs" , "build_release" : "debian9", "build_version" : "2017_7", "build_arch" : "armhf" }'

    salt minion_id state.sls repo.debian.debian9  pillar='{ "build_dest" : "/srv/debian/2017.7/pkgs", "keyid" : "ABCEDF12" , "build_release" : "debian9", "build_version" : "2017_7", "gpg_passphrase" : "fill-in here" , "build_arch" : "armhf" }'


Currently auto-pack is driven by a shell script, autobuild, located in file_roots/auto_setup.


# Overview

Auto-pack can check out a specific version of Salt, a specific version of salt-pack, build Salt and the dependencies using salt-pack on a desired operating system utilising a specified cloud.map, create the repository containing that repository and then deliver the built product to a specified results NFS server, laying out the repository and built product in a manner similar to repo.saltstack.com.

This allows a user to build their own version of Salt and its dependencies, creating a repository using their own keys and deliver the results to a NFS server of their own choosing.  This allows for a user to create new features or bug fixs for Salt with it's own versions of dependencies, create a repository and deliver them to a NFS server from which the build products can be installed and tested (web server utilizing NFS mounts).

Currently auto-pack has been enabled to leverage Hashicorp's Vault for the location of secret keys and passphrase with which to sign created repositories, however it does not have to be used and a specific user's keys can be used by replacing the contents of pillar_roots/auto_setup/gpg_keys.sls or the default Salt testing keys (no passphrase used) can be used to sign the created repositories. If the file /etc/salt/master.d/vault.conf is found then use of Vault is assummed.

Auto-pack is driven from the salt-master and assumes that a salt-minion is currently active on the salt-master (it is used to perfrom functions such as checking out and setting up build minions)

Currently supported Operating Systems

| Operating System(OS) | Description       |
|----------------------|-------------------|
| rhel7                | Redhat 7          |
| rhel6                | Redhat 6          |
| amazon               | Amazon Linux AMI  |
| debian9              | Debian 9 (stretch)|
| debian8              | Debian 8 (jessie) |
| ubuntu1604           | Ubuntu 16.04 LTS  |
| ubuntu1404           | Ubuntu 14.04 LTS  |


# Script

Currently auto-pack is driven from the shell script autobuild located in file_roots/auto_setup which takes a number of short or long switches to control it's functionality as follows:

usage: ${0}  [-h|--help] [-b|--branch <branch to build>] [-c|--clean] [-m|--minion <minion to use>]"
             [-n|--named_branch <code named branch to build>] [-r|--nfs_opts <NFS server's directories>]"
             [-p|--pack_branch <git named branch>] [-s|--specific_name <specific named version to produce>]"
             [-u|--user <username for git salt and salt-pack>] [-v|--verbose]"
             [-w|--mount_nfsdir <mount root NFS directory for minions>] [-y|--nfs_host <hostname of NFS server>]"
             [-z|--nfs_absdir <absolute NFS directory on NFS server for build product>]"


autobuild can be typically used to built a dated version of the current head of a Salt branch in Git as follows:

    cd /srv/salt/auto_setup
    ./autobuild

This will result in a dated packaged build of Salt and its dependencies, here for Redhat 7 on the results NFS server in the directory:

    /build_res/autobuild/saltstack/yum/redhat/7/x86_64/archive/2017_7nb201712112221239405613
        .
        .
        .
        -rw-r--r-- 1 root    root     230K Nov 14 12:00 python-timelib-0.2.4-1.el7.noarch.rpm
        -rw-r--r-- 1 root    root     161K Nov 14 12:00 PyYAML-3.11-1.el7.x86_64.rpm
        -rw-r--r-- 1 root    root     248K Nov 14 12:00 PyYAML-debuginfo-3.11-1.el7.x86_64.rpm
        drwxrwxr-x 4 builder www-data   80 Dec 11 17:11 ..
        drwxr-xr-x 2 root    root     4.0K Dec 11 17:22 SRPMS
        -rw-r--r-- 1 root    root     7.9M Dec 11 17:24 salt-2017.7.0nb201712112221239405613-0.el7.noarch.rpm
        -rw-r--r-- 1 root    root     1.6M Dec 11 17:24 salt-master-2017.7.0nb201712112221239405613-0.el7.noarch.rpm
        -rw-r--r-- 1 root    root      35K Dec 11 17:24 salt-minion-2017.7.0nb201712112221239405613-0.el7.noarch.rpm
        -rw-r--r-- 1 root    root      17K Dec 11 17:24 salt-syndic-2017.7.0nb201712112221239405613-0.el7.noarch.rpm
        -rw-r--r-- 1 root    root      17K Dec 11 17:24 salt-api-2017.7.0nb201712112221239405613-0.el7.noarch.rpm
        -rw-r--r-- 1 root    root      20K Dec 11 17:24 salt-cloud-2017.7.0nb201712112221239405613-0.el7.noarch.rpm
        -rw-r--r-- 1 root    root      18K Dec 11 17:24 salt-ssh-2017.7.0nb201712112221239405613-0.el7.noarch.rpm
        drwxr-xr-x 2 root    root     4.0K Dec 11 17:24 repodata
        .
        .
        .


# Details

| Short | Long          | Description                                                                                                               |
|-------|---------------|---------------------------------------------------------------------------------------------------------------------------|
|   b   | branch        | git HEAD of branch for intended or specified major version, default 2017.7                                                |
|       |               | if a specific_name user is not used then, salt-pack branch version is used (for example: nightly build)                   |
|   c   | clean         | clean build, do not not use any dependencies already built for the branch, default not clean                              |
|   g   | cloud-map     | cloud map to overwrite default build minions to use, default '/etc/salt/cloud.map'                                        |
|   h   | help          | this message                                                                                                              |
|   m   | minion        | salt-minion installed on salt-master node to use for code checkout, default id 'm7m'                                      |
|   n   | named_branch  | git named branch for example: nitrogen, my_user_branch1, no default                                                       |
|   p   | pack_branch   | name of salt-pack branch to use, default develop                                                                          |
|   r   | nfs_opts      | NFS options used to mount NFS server's directories                                                                        |
|   s   | specific_name | specifically named version to build, default date YYYYMMDDhhmmnnnn similar to salt's job id, for example: rc1             |
|   t   | tag           | build tagged release, for example: specific release version v2017.7.1, if PyPI doesn't contain tag, then utilizes git tag |
|   u   | user          | username for git's salt and salt-pack, and results NFS server , default saltstack                                  |
|       |               | Note: user's salt-pack changes should be against root for branch, for example: 2017.7                                     |
|   v   | verbose       | verbose output                                                                                                            |
|   w   | mount_nfsdir  | mount root NFS directory for minions as repository for build products                                                     |
|   y   | nfs_host      | using user's NFS server hostname for repository for build products                                                        |
|   z   | nfs_absdir    |absolute NFS directory on NFS server for mounting root NFS directory, for example: /volume3                                |


