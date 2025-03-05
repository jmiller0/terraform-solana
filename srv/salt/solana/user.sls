# Create solana group
solana_group:
  group.present:
    - name: solana
    - system: False

# Create solana user
solana_user:
  user.present:
    - name: solana
    - fullname: Solana Validator
    - shell: /bin/bash
    - home: /home/solana
    - createhome: True
    - password: firedancer
    - groups:
      - solana
      - sudo
    - require:
      - group: solana_group
    - unless: id -u solana > /dev/null 2>&1

