tmux:
  pkg.installed

su - admin -c 'LANG=en_US.UTF-8 tmux new-session -d /bin/bash':
  cmd.run
