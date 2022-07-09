# Test kerberos server

Docker image for the test kerberos server (see https://ubuntu.com/server/docs/service-kerberos).


## Configuration

Docker image is configured with the following environment variables:

`TEST_USER_PASSWORD` - password for test user. No default value (must be set).

`REALM` - realm name (must be in upper case). Default value: `CONCEPTICA.LOCAL`

`DOMAIN` - domain name. Default value is lower case realm (`conceptica.local` for default REALM).

## Usage

```shell
docker run -it -v /tmp/keytab:/app/keytab -p 88:88 -p 750:750 -e TEST_USER_PASSWORD=TestPassword42 conceptica/test_kerberos_server
```

Also see the example `docker-compose.yml` file.


## Principals

After running the docker image, those principals are created:

- user `test`
- service principal `HTTP/ipharm.conceptica.local`
- service principal `HTTP/izadanky.conceptica.local`

## Using keytab file

The keytab file is generated for the principals `HTTP/ipharm.conceptica.local` and `HTTP/izadanky.conceptica.local`
The file is stored as `/app/keytab/apache2.keytab` directory.

## Setup kerberos client

Also see https://ubuntu.com/server/docs/service-kerberos-workstation-auth

### Add KDC to hosts file

You have to add the KDC domain name (default is `kdc.conceptica.local`) to the hosts file.

```
127.0.0.1 kdc.conceptica.local
``` 

Note: 127.0.0.1 works for KDC, but when you have to use local IP address for the services (`ipharm.conceptica.local` ect).

### Install kerberos client libraries

```shell
sudo apt install krb5-user
```

You will be prompted for the addresses of your KDCs and admin server. Default is `kdc.conceptica.local`.

### Authenticate with KDC

```shell
kinit test
```

Enter password for `test` user.