include:
  - common
  - solana.user
  - solana.rust

# Deploy the data disk setup script
/usr/local/bin/setup_data_disk.sh:
  file.managed:
    - source: salt://common/files/setup_data_disk.sh
    - mode: '0755'
    - user: root
    - group: root

# Run the data disk setup script
setup_data_directory:
  cmd.run:
    - name: /usr/local/bin/setup_data_disk.sh --owner solana --group solana
    - unless: mountpoint -q /mnt/solana
    - require:
      - file: /usr/local/bin/setup_data_disk.sh
      - user: solana_user

# Ensure solana owns data directory
/mnt/solana:
  file.directory:
    - user: solana
    - group: solana
    - recurse:
        - user
        - group
    - require:
        - cmd: setup_data_directory

set_system_limits:
  file.managed:
    - name: /etc/sysctl.d/99-solana-validator.conf
    - contents: |
        # Increase UDP buffer sizes
        net.core.rmem_default = 134217728
        net.core.rmem_max = 134217728
        net.core.wmem_default = 134217728
        net.core.wmem_max = 134217728
        # Increase memory mapped files limit
        vm.max_map_count = 1000000
        # Increase number of allowed open file descriptors
        fs.nr_open = 1000000
        vm.swappiness=0
        kernel.hung_task_timeout_secs=600

# Set systemd file limits
systemd_limits:
  file.managed:
    - name: /etc/systemd/system.conf.d/99-solana-limits.conf
    - makedirs: True
    - contents: |
        [Manager]
        DefaultLimitNOFILE=1000000

# Set security limits for all users
security_limits:
  file.managed:
    - name: /etc/security/limits.d/90-solana-nofiles.conf
    - contents: |
        # Increase process file descriptor count limit
        * - nofile 1000000

reload_systemd:
  cmd.run:
    - name: systemctl daemon-reload
    - onchanges:
      - file: systemd_limits

install_solana:
  cmd.run:
    - name: sh -c "$(curl -sSfL https://release.anza.xyz/v2.1.5/install)"
    - runas: solana
    - env:
        - HOME: /home/solana
        - USER: solana
    - unless: test -f /home/solana/.local/share/solana/install/active_release/bin/solana
    - require:
      - user: solana_user

# Add Solana to PATH in .profile if not already present
setup_solana_path:
  file.managed:
    - name: /home/solana/.profile
    - contents: |
        # ~/.profile: executed by the command interpreter for login shells.
        # Source Rust environment
        if [ -f "$HOME/.cargo/env" ]; then
            . "$HOME/.cargo/env"
        fi

        # include .bashrc if it exists
        if [ -f "$HOME/.bashrc" ]; then
            . "$HOME/.bashrc"
        fi

        # set PATH so it includes Rust binaries if they exist
        if [ -d "$HOME/.cargo/bin" ] ; then
            PATH="$HOME/.cargo/bin:$PATH"
        fi

        # set PATH so it includes Solana binaries if they exist
        if [ -d "$HOME/.local/share/solana/install/active_release/bin" ] ; then
            PATH="$HOME/.local/share/solana/install/active_release/bin:$PATH"
        fi
    - user: solana
    - group: solana
    - mode: '0644'
    - require:
      - cmd: install_solana

