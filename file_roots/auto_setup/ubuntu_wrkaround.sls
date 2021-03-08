tmux:
  pkg.installed

tmux new-session -d /bin/bash:
  cmd.run:
  - runas: ubuntu
