# IADT Project #

This is to get your application up and running.

### How to Use it ###

``` bash
packer build -var-file=var ami-test.json
```

```bash
terraform apply -var 'access_key=< access key >' -var 'secret_key=< secret_key >' -var 'db_master_password=< password >'

```
