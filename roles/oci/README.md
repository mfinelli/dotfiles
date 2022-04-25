# oci

Setup configuration for oci.

## generate api key

```shell
cd roles/oci/files
openssl genrsa -out ./oci.pem 4096
cd ../../../
./vault roles/oci/files/oci.pem
```

## get the public key to paste into the console

```shell
openssl rsa -pubout -in ~/.oci/oci.pem -out ~/.oci/oci_public.pem
```
