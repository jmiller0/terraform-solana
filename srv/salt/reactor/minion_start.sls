# Reactor to handle minion connections
# This will run highstate on minions when they connect
# and log the results to a file

highstate_on_connect:
  local.state.highstate:
    - tgt: {{ data['id'] }}
    - kwarg:
        state_output: full
        pillar:
          reactor: true
    - require:
      - local: sync_modules
    - onfail:
      - local: sync_modules

# Sync modules and states to ensure we have latest
sync_modules:
  local.saltutil.sync_all:
    - tgt: {{ data['id'] }} 