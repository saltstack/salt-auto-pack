# Import base config
{% import "auto_setup/auto_base_map.jinja" as base_cfg %}

include:
  - auto_setup.setup_salt
  - auto_setup.setup_salt-pack
  - auto_setup.setup_salt-pack-redhat
  - auto_setup.setup_salt-pack-amazon
  - auto_setup.setup_salt-pack-debian
  - auto_setup.setup_salt-pack-ubuntu
  - auto_setup.setup_salt-pack-finalize

