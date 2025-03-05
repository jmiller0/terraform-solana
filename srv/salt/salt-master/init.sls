# Set hostname for Salt master
set_salt_master_hostname:
  host.present:
    - name: salt-master
    - ip: 127.0.1.1

# Set grain for Salt master
set_salt_master_grain:
  grains.present:
    - name: host
    - value: salt-master

# Install required packages for Salt master
salt_master_packages:
  pkg.installed:
    - pkgs:
      - python3-gnupg  # Required for GPG-encrypted pillar files
      - python3-pip    # Required for pip packages

# Ensure Salt master configuration directory exists
salt_master_config_dir:
  file.directory:
    - name: /etc/salt/master.d
    - user: root
    - group: root
    - mode: 755
    - makedirs: True

# Configure basic Salt master settings
salt_master_config:
  file.managed:
    - name: /etc/salt/master
    - contents: |
        interface: 0.0.0.0
        auto_accept: True
        open_mode: True
        file_roots:
          base:
            - /srv/salt
        pillar_roots:
          base:
            - /srv/salt/pillar
        log_level: info
        log_level_logfile: info
        hash_type: sha256
        worker_threads: 5
        timeout: 60
        job_cache: True
        keep_jobs: 24
        reactor:
          - 'salt/minion/*/start':
            - /srv/salt/reactor/minion_start.sls
    - user: root
    - group: root
    - mode: 644
    - require:
      - file: salt_master_config_dir

# Configure Vault integration for Salt master
vault_integration_config:
  file.managed:
    - name: /etc/salt/master.d/vault.conf
    - contents: |
        vault:
          auth:
            method: token
            token: {{ pillar['vault']['token'] }}
          server:
            url: https://salt-master.{{ grains['aws_root_zone'] }}:8200
            verify: /opt/vault/tls/tls.crt
          cache:
            backend: disk
          issue:
            type: approle
            approle:
              mount: approle
              params:
                token_ttl: 24h
                token_max_ttl: 48h
                token_explicit_max_ttl: 0
                token_num_uses: 0
                secret_id_ttl: 0
                secret_id_num_uses: 0
          policies:
            assign:
              # Test minions get test-minion-policy
              - test-minion-policy
              - salt_minion_base
              # Validators get validator-policy
              - validator-policy
              # Default policy for all other minions
              - salt_minion_base
          minion_policies:
            # Test minions
            'aws-test-minion':
              - test-minion-policy
              - salt_minion_base
            'gcp-test-minion':
              - test-minion-policy
              - salt_minion_base
            # Validators
            'aws-validator-gcp-0*':
              - validator-policy
              - salt_minion_base
            'solana-validator-gcp-0*':
              - validator-policy
              - salt_minion_base
            # Default for all other minions
            '*':
              - salt_minion_base
    - template: jinja
    - user: root
    - group: root
    - mode: 640
    - require:
      - file: salt_master_config_dir

# Configure peer runner for Vault token generation and AppRole
vault_peer_run_config:
  file.managed:
    - name: /etc/salt/master.d/peer_run.conf
    - contents: |
        # Configure peer runner for Vault token generation and AppRole
        peer_run:
          .*:
            - vault.generate_token
            - vault.get_config
            - vault.generate_secret_id
            - vault.generate_new_token
            - vault.get_role_id
    - user: root
    - group: root
    - mode: 644
    - require:
      - file: salt_master_config_dir

# Add Vault environment variables to root's .bashrc
vault_env_vars:
  file.append:
    - name: /root/.bashrc
    - text: |
        export VAULT_ADDR="https://127.0.0.1:8200"
        export VAULT_SKIP_VERIFY=true
        export VAULT_TOKEN=$(cat /etc/salt/vault_token)
        alias logs='journalctl -u salt-master.service -u vault.service -f'
        alias pingall='salt "*" test.ping  -t 1'
        alias keys='salt-key -L'
        alias reloadbash='source ~/.bashrc'
        alias allhs='salt "*" state.highstate --state-output=changes'
        alias lhs='salt-call state.highstate --state-output=changes'

        # List all historical jobs
        alias salt-jobs='salt-run jobs.list_jobs --out=json | jq'

        # List only the last 10 jobs
        alias salt-jobs-last10='salt-run jobs.list_jobs --out=json | jq "to_entries | sort_by(.key) | reverse | .[:10]"'

        # Show details of a specific job (requires job ID)
        alias salt-job-detail='salt-run jobs.lookup_jid'

        # Show all currently running jobs
        alias salt-jobs-running='salt "*" saltutil.running --out=json | jq'

        # Show running jobs for a specific minion (requires minion ID)
        alias salt-jobs-running-minion='salt $1 saltutil.running --out=json | jq'

        # Show job results for a specific job ID (requires job ID)
        alias salt-job-results='salt-run jobs.lookup_jid $1'

        # Show the last job for a specific minion (requires minion ID)
        alias salt-job-last='salt-run jobs.list_jobs search_target=$1 --out=json | jq "to_entries | sort_by(.key) | reverse | .[0]"'

        # Kill a running job (requires job ID and minion ID)
        alias salt-job-kill='salt $1 saltutil.kill_job $2'

        # Retry a failed job (requires job ID)
        alias salt-job-retry='salt-run state.orchestrate jobs.retry_job jid=$1'

        # Show failed jobs in the last 24 hours
        alias salt-jobs-failed='salt-run jobs.list_jobs --out=json | jq "to_entries | map(select(.value.Result == false))"'

        # Show highstate job history for a specific minion (requires minion ID)
        alias salt-jobs-highstate='salt-run jobs.list_jobs search_function=state.highstate search_target=$1 --out=json | jq'

        # Show job status (pending, running, completed) for a given job ID
        alias salt-job-status='salt-run jobs.list_job $1 --out=json | jq'

        # Show all jobs started by a specific user (requires username)
        alias salt-jobs-user='salt-run jobs.list_jobs search_user=$1 --out=json | jq'

        # Show the most recent job that affected a given minion
        alias salt-job-latest='salt-run jobs.list_jobs search_target=$1 --out=json | jq "to_entries | sort_by(.key) | reverse | .[0]"'

        # Show when the last highstate ran for a minion (requires minion ID)
        alias salt-last-highstate='salt-run jobs.list_jobs search_function=state.highstate search_target=$1 --out=json | jq "to_entries | sort_by(.key) | reverse | .[0]"'

        # Show jobs executed within the last hour
        alias salt-jobs-last-hour='salt-run jobs.list_jobs search_time_range=3600 --out=json | jq'

        # Show all jobs for a specific function (e.g., state.apply)
        alias salt-jobs-function='salt-run jobs.list_jobs search_function=$1 --out=json | jq'
        


# Restart Salt master to apply changes
salt_master_service:
  service.running:
    - name: salt-master
    - enable: True
    - watch:
      - file: salt_master_config
      - file: vault_integration_config
      - file: vault_peer_run_config

# Include GPG configuration
include:
  - salt-master.gpg 