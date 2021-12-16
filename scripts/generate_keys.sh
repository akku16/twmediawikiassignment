#!/bin/bash
echo "====> Creation of key"
ssh-keygen -q -t rsa -N '' <<< $'\ny' >/dev/null 2>&1
chmod 755 ~/.ssh
touch ~/.ssh/authorized_keys
chmod 644 ~/.ssh/authorized_keys
