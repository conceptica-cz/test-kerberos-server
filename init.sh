#!/usr/bin/env bash
# Based on https://github.com/ist-dsi/docker-kerberos/blob/master/kdc-kadmin/init-script.sh

export REALM=${REALM:=CONCEPTICA.LOCAL}
DEFAULT_DOMAIN=$(echo $REALM | awk '{print tolower($0)}')
DOMAIN=${DOMAIN:=$DEFAULT_DOMAIN}
export KDC_KADMIN_SERVER=${KDC_KADMIN_SERVER:=kdc.$DOMAIN}
PASSWORD=$(tr -cd '[:alnum:]' < /dev/urandom | fold -w30 | head -n1)
export TEST_USER_PASSWORD=${TEST_USER_PASSWORD:=$PASSWORD}

echo "REALM: $REALM"
echo "KDC_KADMIN_SERVER: $KDC_KADMIN_SERVER"
echo "TEST_USER_PASSWORD: $TEST_USER_PASSWORD"

echo "Creating /etc/krb5.conf"

cat > /etc/krb5.conf<< EOF
[libdefaults]
	default_realm = $REALM
[realms]
	$REALM = {
		kdc = $KDC_KADMIN_SERVER
		admin_server = $KDC_KADMIN_SERVER
	}
EOF

echo "Creating /etc/krb5kdc/kdc.conf"

cat > /etc/krb5kdc/kdc.conf<< EOF
[kdcdefaults]
    kdc_ports = 750,88

[realms]
    $REALM = {
        database_name = /var/lib/krb5kdc/principal
        admin_keytab = FILE:/etc/krb5kdc/kadm5.keytab
        acl_file = /etc/krb5kdc/kadm5.acl
        key_stash_file = /etc/krb5kdc/stash
        kdc_ports = 750,88
        max_life = 10h 0m 0s
        max_renewable_life = 7d 0h 0m 0s
        master_key_type = des3-hmac-sha1
        default_principal_flags = +preauth
    }
EOF

echo "Creating /etc/krb5kdc/kadm5.acl"
cat > /etc/krb5kdc/kadm5.acl<< EOF
 */admin *
EOF

echo "Creating realm"
MASTER_PASSWORD=$(tr -cd '[:alnum:]' < /dev/urandom | fold -w30 | head -n1)
krb5_newrealm <<EOF
$MASTER_PASSWORD
$MASTER_PASSWORD
EOF

echo "Creating test user principal"

kadmin.local -q "addprinc test" <<EOF
$TEST_USER_PASSWORD
$TEST_USER_PASSWORD
EOF

echo "Creating manager user principal"

kadmin.local -q "addprinc manager" <<EOF
$TEST_USER_PASSWORD
$TEST_USER_PASSWORD
EOF

echo "Creating services principals"

mkdir -p ./keytab
rm -f ./keytab/apache2.keytab

kadmin.local -q "addprinc -randkey HTTP/ipharm.${DOMAIN}"
kadmin.local -q "ktadd -k ./keytab/apache2.keytab HTTP/ipharm.${DOMAIN}"
kadmin.local -q "addprinc -randkey HTTP/ipharm-fe.${DOMAIN}"
kadmin.local -q "ktadd -k ./keytab/apache2.keytab HTTP/ipharm-fe.${DOMAIN}"
kadmin.local -q "addprinc -randkey HTTP/izadanky.${DOMAIN}"
kadmin.local -q "ktadd -k ./keytab/apache2.keytab HTTP/izadanky.${DOMAIN}"

chmod a+r ./keytab/apache2.keytab

krb5kdc
kadmind -nofork