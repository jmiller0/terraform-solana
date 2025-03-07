# Configure DNS search domain using systemd-resolved (persistent across reboots)
configure_dns_search_domain:
  file.managed:
    - name: /etc/systemd/resolved.conf
    - contents: |
        [Resolve]
        Domains={{ grains['aws_root_zone'] }}
    - user: root
    - group: root
    - mode: '0644'
  service.running:
    - name: systemd-resolved
    - enable: True
    - watch:
      - file: configure_dns_search_domain

# Ensure salt-minion package is installed
salt_minion_pkg:
  pkg.installed:
    - name: salt-minion
    - reload_modules: true

# Add Salt repository configuration
setup_salt_repo:
  file.managed:
    - name: /etc/apt/keyrings/salt-archive-keyring.pgp
    - source: https://packages.broadcom.com/artifactory/api/security/keypair/SaltProjectKey/public
    - skip_verify: True
    - makedirs: True
  cmd.run:
    - name: |
        curl -fsSL https://github.com/saltstack/salt-install-guide/releases/latest/download/salt.sources | tee /etc/apt/sources.list.d/salt.sources
    - unless: test -f /etc/apt/sources.list.d/salt.sources

# Basic minion configuration to ensure it can connect to master
basic_minion_config:
  file.managed:
    - name: /etc/salt/minion
    - contents: |
        master: salt-master
        id: {{ grains['host'] }}
        random_id: false
        hash_type: sha256
        log_level: debug
    - mode: '0644'
    - user: root
    - group: root
    - template: jinja
    - require:
      - pkg: salt_minion_pkg

# Set minion ID based on hostname
basic_minion_id:
  file.managed:
    - name: /etc/salt/minion_id
    - contents: {{ grains['host'] }}
    - mode: '0644'
    - user: root
    - group: root
    - require:
      - pkg: salt_minion_pkg

# Ensure minion.d directory exists
minion_d_dir:
  file.directory:
    - name: /etc/salt/minion.d
    - user: root
    - group: root
    - mode: '0755'
    - makedirs: True
    - require:
      - pkg: salt_minion_pkg

# Configure Vault settings
vault_config:
  file.managed:
    - name: /etc/salt/minion.d/vault.conf
    - source: salt://common/files/vault.conf
    - user: root
    - group: root
    - mode: '0644'
    - require:
      - file: minion_d_dir

# Configure Salt grains
configure_grains:
  file.managed:
    - name: /etc/salt/grains
    - contents: |
        aws_root_zone: {{ grains['aws_root_zone'] }}
    - user: root
    - group: root
    - mode: '0644'
    - require:
      - pkg: salt_minion_pkg

# Ensure salt-minion service is running before other states
salt_init_minion_service:
  service.running:
    - name: salt-minion
    - enable: True
    - require:
      - pkg: salt_minion_pkg
      - file: basic_minion_config
      - file: basic_minion_id
      - file: vault_config
      - file: configure_grains