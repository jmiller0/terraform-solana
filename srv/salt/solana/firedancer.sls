include:
  - solana.validator
  - solana.rust

# Create sudoers file for solana user first to avoid password prompts
/etc/sudoers.d/solana-nopasswd:
  file.managed:
    - contents: |
        solana ALL=(ALL) NOPASSWD: ALL
    - mode: '0440'
    - user: root
    - group: root
    - check_cmd: visudo -c -f
    - require:
      - user: solana_user

# Get the latest tag from the Firedancer repository
get_latest_firedancer_tag:
  cmd.run:
    - name: |
        git ls-remote --tags --sort="-v:refname" \
          https://github.com/firedancer-io/firedancer.git | \
          grep -v '{}' | \
          head -n1 | \
          sed 's/.*refs\/tags\///' > /tmp/firedancer_latest_tag
    - creates: /tmp/firedancer_latest_tag
    - unless: test -f /opt/firedancer/build/native/gcc/bin/fdctl

# Clone as root
clone_firedancer:
  git.latest:
    - name: https://github.com/firedancer-io/firedancer.git
    - target: /opt/firedancer
    - branch: main
    - force_reset: True
    - unless: test -d /opt/firedancer/.git
    - require:
      - pkg: system_packages

# Set ownership after clone
set_firedancer_ownership:
  file.directory:
    - name: /opt/firedancer
    - user: solana
    - group: solana
    - recurse:
        - user
        - group
    - require:
        - git: clone_firedancer

# Build Firedancer - only if CPU cores > 32
build_firedancer:
  cmd.run:
    - name: |
        source $HOME/.cargo/env
        cd /opt/firedancer
        LATEST_TAG=$(cat /tmp/firedancer_latest_tag)
        echo "Building Firedancer version: $LATEST_TAG"
        git checkout $LATEST_TAG
        yes | ./deps.sh

        # Only build fdctl and solana if we have enough CPU cores
        if [ $(nproc) -gt 32 ]; then
            echo "System has $(nproc) cores, building Firedancer..."
            make -j fdctl solana
        else
            echo "System has only $(nproc) cores, skipping Firedancer build to avoid overloading the system."
            # Create a marker file so Salt knows we've run this step
            touch /opt/firedancer/build_skipped_low_cpu
        fi
    - runas: solana
    - shell: /bin/bash
    - env:
        - HOME: /home/solana
        - USER: solana
        - PATH: /home/solana/.cargo/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
    - unless: test -f /opt/firedancer/build/native/gcc/bin/fdctl || test -f /opt/firedancer/build_skipped_low_cpu
    - require:
      - file: set_firedancer_ownership
      - file: /etc/sudoers.d/solana-nopasswd
      - cmd: install_rust
      - cmd: get_latest_firedancer_tag

# Create symlink for fdctl
/usr/local/bin/fdctl:
  file.symlink:
    - target: /opt/firedancer/build/native/gcc/bin/fdctl
    - force: True
    - onlyif: test -f /opt/firedancer/build/native/gcc/bin/fdctl
    - require:
      - cmd: build_firedancer

# Create fdctl directory
/home/solana/fdctl:
  file.directory:
    - user: solana
    - group: solana
    - mode: '0755'
    - makedirs: True

# Deploy testnet.toml configuration
/home/solana/fdctl/testnet.toml:
  file.managed:
    - source: salt://solana/files/testnet.toml.jinja
    - template: jinja
    - user: solana
    - group: solana
    - mode: '0644'
    - require:
      - file: /home/solana/fdctl

# Install Firedancer service
/etc/systemd/system/firedancer.service:
  file.managed:
    - source: salt://solana/files/firedancer.service
    - mode: '0644'
    - user: root
    - group: root
    - onlyif: test -f /opt/firedancer/build/native/gcc/bin/fdctl
    - require:
      - file: /usr/local/bin/fdctl

# Enable and start Firedancer service
firedancer:
  service.enabled:
    - onlyif: test -f /opt/firedancer/build/native/gcc/bin/fdctl
    - require:
      - file: /etc/systemd/system/firedancer.service

# Add sudo permissions for fdctl
/etc/sudoers.d/solana-fdctl:
  file.managed:
    - contents: |
        solana ALL=(ALL) NOPASSWD: /usr/local/bin/fdctl
    - mode: '0440'
    - user: root
    - group: root
    - check_cmd: visudo -c -f
    - onlyif: test -f /opt/firedancer/build/native/gcc/bin/fdctl