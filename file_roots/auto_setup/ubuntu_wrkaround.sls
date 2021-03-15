tmux:
  pkg.installed

su - ubuntu -c 'LANG=en_US.UTF-8 tmux new-session -d /bin/bash':
  cmd.run
