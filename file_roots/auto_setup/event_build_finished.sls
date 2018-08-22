
send_event_build_finished:
  event.send:
    - name: 'salt/auto-pack/build/finished'
    - data:
        build_transfer: 'completed'
