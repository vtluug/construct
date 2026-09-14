# Magma (ws-c3750g-48ts)

Magma serves as the north/south traffic switch for bastille. By convention, the top half is for management interfaces, and the bottom half is for host frontend connections.

## Management

There is a serial console.

Configured, you can also manage it over SSH using the command 

```
ssh \
    -o KexAlgorithms=+diffie-hellman-group1-sha1 \
    -o HostKeyAlgorithms=+ssh-rsa \
    -o Ciphers=+aes128-cbc \
    papatux@10.98.0.192
```
or over HTTP at the same address.

# TODO

It currently has one VLAN. Ideally the top and bottom halves would be split into MGMT/LAN.