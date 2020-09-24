# ssh

Manages ssh keys and ssh client configuration.

## ssh-keygen

We prefer Ed25519 keys when possible, but use 4096 bit RSA keys if the service
in question does not support the newer key type.

Generate Ed25519 keys:

```shell
ssh-keygen -t ed25519 -o -a 128 -C username -f ./file
```

Generate older RSA keys:

```shell
ssh-keygen -t rsa -b 4096 -o -a 128 -C username -f ./file
```

Note if you'd like to regenerate the public key using the private key material:

```shell
ssh-keygen -f ~/file -y > ./file.pub
```

And finally, if you'd like to see the randomart again:

```shell
ssh-keygen -lv -f ./file
```
