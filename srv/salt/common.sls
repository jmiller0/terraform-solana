system_packages:
  pkg.installed:
    - pkgs:
      - htop
      - iotop
      - sysstat
      - net-tools
      - jq
      - awscli
      - emacs-nox
      # Development packages
      - build-essential
      - pkg-config
      - cmake
      - ninja-build
      - libssl-dev
      - python3
      - python3-pip
      - git
      - curl
      - locate
      - libhugetlbfs-dev
      - libhugetlbfs-bin
      # Additional packages from bootstrap
      - python3-gnupg
      - unzip
      - software-properties-common
      - openssl

# Base /opt directory setup
/opt:
  file.directory:
    - user: root
    - group: root
    - mode: 755

set_performance_governor:
  cmd.run:
    - name: |
        echo "never" > /sys/kernel/mm/transparent_hugepage/enabled
    - unless: grep -q '\[never\]' /sys/kernel/mm/transparent_hugepage/enabled

# Secure SSH configuration
sshd_config:
  file.managed:
    - name: /etc/ssh/sshd_config
    - contents: |
        # Package generated configuration file
        # See the sshd_config(5) manpage for details
        
        Port 22
        Protocol 2
        HostKey /etc/ssh/ssh_host_rsa_key
        HostKey /etc/ssh/ssh_host_ecdsa_key
        HostKey /etc/ssh/ssh_host_ed25519_key
        
        # Authentication
        PermitRootLogin no
        PubkeyAuthentication yes
        PasswordAuthentication yes
        PermitEmptyPasswords no
        ChallengeResponseAuthentication no
        UsePAM yes
        AuthorizedKeysFile .ssh/authorized_keys
        
        # Logging
        SyslogFacility AUTH
        LogLevel INFO
        
        # Other settings
        X11Forwarding no
        PrintMotd no
        AcceptEnv LANG LC_*
        Subsystem sftp /usr/lib/openssh/sftp-server

# Restart SSH service if config changes
sshd_service:
  service.running:
    - name: sshd
    - enable: True
    - reload: True
    - watch:
      - file: sshd_config 

# Deploy hostname setting script
/usr/local/bin/set_hostname.sh:
  file.managed:
    - source: salt://common/files/set_hostname.sh
    - mode: 755
    - user: root
    - group: root

# Set hostname based on instance tags
set_hostname:
  cmd.run:
    - name: /usr/local/bin/set_hostname.sh
    - unless: |
        CURRENT_HOSTNAME=$(hostname)
        /usr/local/bin/set_hostname.sh
        test "$CURRENT_HOSTNAME" = "$(hostname)"
    - require:
      - file: /usr/local/bin/set_hostname.sh

