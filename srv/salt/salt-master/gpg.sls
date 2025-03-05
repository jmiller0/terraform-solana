# Ensure GPG directory exists
gpg_config_dir:
  file.directory:
    - name: /etc/salt/gpgkeys
    - user: root
    - group: root
    - mode: 700
    - makedirs: True

# Configure GPG for Salt master
gpg_config:
  file.managed:
    - name: /etc/salt/master.d/gpg.conf
    - contents: |
        # GPG configuration for Salt master
        gpg_keydir: /etc/salt/gpgkeys
    - user: root
    - group: root
    - mode: 644
    - require:
      - file: gpg_config_dir

# Configure GPG renderer for pillar decryption
gpg_renderer_config:
  file.managed:
    - name: /etc/salt/master.d/gpg_renderer.conf
    - contents: |
        # Enable GPG renderer for pillar decryption
        decrypt_pillar_default: gpg
        decrypt_pillar_renderers:
          - gpg
    - user: root
    - group: root
    - mode: 644
    - require:
      - file: gpg_config_dir

