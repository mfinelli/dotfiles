# irssi

Configuration for `irssi`.

We use certificate authentication where possible:
https://wiki.archlinux.org/title/Irssi#TLS_Connection

- https://libera.chat/guides/certfp
- https://www.oftc.net/NickServ/CertFP/

## generating certificates

First, generate the (encrypted) private key (this will prompt for a password):

```shell
openssl genpkey -algorithm ed25519 -aes256 -out roles/irssi/files/supermario.key
```

Then, generate the self-signed certificate using the key just created:

```shell
openssl req -x509 -new -sha256 -days 730 -subj /OU=IRC/CN=SUPERMARIO \
  -key roles/irssi/files/supermario.key -out roles/irssi/files/supermario.crt
```

If desired the resulting certificate can be examined like so:

```shell
openssl x509 -text -noout -in roles/irssi/files/supermario.crt
```

Now, concatenate the resulting file and encrypt it:

```shell
cat roles/irssi/files/supermario.{crt,key} > roles/irssi/files/supermario.pem
```

```shell
./vault -w roles/irssi/files/supermario.pem
```
