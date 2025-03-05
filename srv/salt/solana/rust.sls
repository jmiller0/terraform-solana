include:
  - solana.user


# Download rustup installer
download_rustup:
  cmd.run:
    - name: curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs -o /tmp/rustup-init.sh
    - creates: /tmp/rustup-init.sh
    - unless: test -f /tmp/rustup-init.sh

# Set proper permissions on the installer
rustup_init_permissions:
  file.managed:
    - name: /tmp/rustup-init.sh
    - mode: 755
    - replace: False
    - require:
      - cmd: download_rustup
    - unless: test -f /home/solana/.cargo/bin/cargo

# Install Rust 1.81.0 as solana user
install_rust:
  cmd.run:
    - name: |
        /tmp/rustup-init.sh -y --default-toolchain 1.81.0 --no-modify-path
        source $HOME/.cargo/env
        rustup component add rustfmt clippy
    - runas: solana
    - shell: /bin/bash
    - env:
        - HOME: /home/solana
        - USER: solana
    - unless: |
        test -f /home/solana/.cargo/bin/cargo && /home/solana/.cargo/bin/cargo --version 2>/dev/null
    - require:
      - file: rustup_init_permissions
      - user: solana_user

# Verify Rust installation
# verify_rust_installation:
#   cmd.run:
#     - name: |
#         source $HOME/.cargo/env
#         rustc --version
#         cargo --version
#     - runas: solana
#     - shell: /bin/bash
#     - env:
#         - HOME: /home/solana
#         - USER: solana
#     - require:
#       - cmd: install_rust

# Add Rust to PATH in solana's .profile
add_rust_to_profile:
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
    - mode: 644
    - require:
      - cmd: install_rust
    - unless: grep -q "PATH=\"\$HOME/.cargo/bin:\$PATH\"" /home/solana/.profile



