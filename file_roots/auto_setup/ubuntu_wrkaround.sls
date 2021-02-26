tmux:
  pkg.installed

tmux new-session -d:
  cmd.run:
  - runas: ubuntu
