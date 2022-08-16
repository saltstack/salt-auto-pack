remove_redhat_8_mock_cfg:
  file.absent:
    - name:  /etc/mock/epel-8-x86_64.cfg

