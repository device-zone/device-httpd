# device-httpd
Provides an Apache webserver appliance.

This appliance does the following:

- All parameters passed to the device commands are syntax checked and canonicalised, with bash completion.
- Creates webserver instances as required, running on individual ports.
- Allows creation of secure virtual hosts, binding securely to TLS (https).
- Autostarts on server restart.
- Zero Trust configuration.

## before

- Deploy the device-httpd package.

```
[root@server ~]# dnf install device-httpd
```

- Place certificates in files beneath the directory /etc/pki/tls/certs with extension
  pem. Place keys in files beneath the directory /etc/pki/tls/private. Place CA certificate
  bundles beneath the directory /etc/pki/tls/certs with extension crt. The names of the
  files are not important, all certificates and keys will be scanned and the matching
  certificates and keys selected, only file extensions are important.

```
[root@server ~]# ls -l /etc/pki/tls/certs /etc/pki/tls/private
/etc/pki/tls/certs:
total 48
drwxr-xr-x. 2 root root 4096 Oct  2 21:35 .
drwxr-xr-x. 5 root root  104 Sep 23 21:03 ..
lrwxrwxrwx. 1 root root   49 Jul 28 21:08 ca-bundle.crt -> /etc/pki/ca-trust/extracted/pem/tls-ca-bundle.pem
lrwxrwxrwx. 1 root root   55 Jul 28 21:08 ca-bundle.trust.crt -> /etc/pki/ca-trust/extracted/openssl/ca-bundle.trust.crt
-rw-r--r--. 1 root root 2278 Aug 20 12:50 seawitch.example.com-sectigo-2023-hostCert.pem
-rw-r--r--. 1 root root 4136 Aug 20 12:51 seawitch.example.com-sectigo-2023-hostChain.pem

/etc/pki/tls/private:
total 12
-rw-------. 1 root root 1705 Aug 20 12:44 seawitch.example.com-sectigo-2023-hostKey.pem
```

## define an mpm

Each instance is deployed based on a set of performance parameters. To add an mpm
defition that can be chosen by an instance, do this:

```
[root@server ~]# device services www mpm add name=event module=event max-request-workers=400 server-limit=16 thread-limit=64 threads-per-child=25 
```

## remove an mpm

To remove the mpm definition called "event" above, do this:

```
[root@server ~]# device services www mpm remove event
```

## add instance

To add an instance of a webserver called "seawitch", run this.

```
[root@server ~]# device services www instance add name=seawitch
```

The instance is not started until at least one listen address is defined for the
instance to bind to.

## remove instance

To remove an instance called "seawitch", run this.

```
[root@server ~]# device services www instance remove seawitch
```

## add listen

Before an instance becomes available, at least one listen address and port must
be specified, telling the server what to bind to.

```
[root@server ~]# device services www listen add name=secure instance=seawitch tls-port=443
```

Options include the following:

- address=[ip-address] : if left unset, defaults to binding to all addresses.
- instance=[instance] : the name of the instance that will listen to these ports.
- port=[port] : the port used for HTTP (clear) connections.
- tls-port=[port] : the port used for HTTPS (TLS) connections.

## remove listen

To remove a listen address called "secure", run this.

```
[root@server ~]# device services www listen remove secure
```

## add virtualhost

To add a virtualhost to respond at a given listen address / port, do this:

```
[root@server ~]# device services www virtualhost add name=seawitch listen=secure server-name=seawitch.example.com
```

The corresponding TLS certificate and key for server-name will be searched and located automatically
in files beneath /etc/pki/tls.

Options include:

- listen=[listen] : the name of the listen port to bind the virtualhost to.
- server-name=[fqdn] : the fully qualified domain name of the virtualhost. If secure, the certificate
  and key will be automatically picked up from the /etc/pki/tls directory.
- tls-ca-certs=[ca-cert-bundle] : if the virtualhost is to be protected with mutual TLS authentication,
  specify the certificate authority bundle here. The bundles are read from /etc/pki/tls/certs.
- tls-verify=[none|optional|require] : should mutual TLS authentication be optional, or required.

## remove virtualhost

To remove a virtualhost called "seawitch", run this.

```
[root@server ~]# device services www virtualhost remove seawitch
```

# device-httpd-auth
Provides an Apache webserver authentication extension, authenticated using TLS mutual authentication,
and backed by LDAP.

This appliance does the following:

- All parameters passed to the device commands are syntax checked and canonicalised, with bash completion.
- Integrates with the 389ds appliance.
- Defines authentication requirements based on TLS mutual authentication, where the certificate
  is required to be present and valid, or additionally the certificate mapped to an LDAP group.
- Zero Trust configuration.

Note: while the webserver is capable of supporting many types of authentication, this appliance
provides the safest option of all of them, and actively excludes the others. If you have different
requirements, it is expected that the device-httpd-auth appliance be swapped out for a more
specialised one.

With this appliance, the default behaviour is safe behaviour.

Once an authentication requirement is defined, it is referred to be other appliance extensions.

## before

- Deploy the device-httpd-auth package.

```
[root@server ~]# dnf install device-httpd-auth
```

## add auth

To add an authorisation definition called "administrators", run this.

```
[root@server ~]# device services www auth add name=administrators ldap-suffix=seawitch-example ldap-group="cn=admins,ou=Groups,dc=example,dc=com"
```

## remove auth

To remove an authorisation definition called "administrators", run this.

```
[root@server ~]# device services www auth remove administrators
```

# device-httpd-alias
Provides an Apache webserver alias extension, allowing directories to be mapped into the URL space.

This appliance does the following:

- All parameters passed to the device commands are syntax checked and canonicalised, with bash completion.
- Splits content definitions between "open" content, where authorisation is optional, to "safe" content, where authorisation is mandatory, protecting against misconfiguration.
- Zero Trust configuration.

Open content can be configured allow access without authentication.

Safe content forces the specification of an authentication scheme. Safe content attempts to protect against potential misconfiguration where sensitive content is accidentally stripped of authentication. Care must still be taken to ensure the authentication scheme is meaningful.

## before

- Deploy the device-httpd-alias package.

```
[root@server ~]# dnf install device-httpd-alias
```

## add safe alias

To add an alias called "accounts", containing sensitive data, run this.

```
[root@server ~]# device services www safe alias add name=accounts virtualhost=seawitch auth=accounts path=/accounts directory=accounts
```

The auth option is mandatory.

The directory is specified beneath /var/www/safe/alias, and can be a symbolic link to the real location on disk.

## remove safe alias

To remove a safe alias called "accounts", run this.

```
[root@server ~]# device services www safe alias remove accounts
```

## add open alias

To add an open alias called "docs", containing unprotected data, run this.

```
[root@server ~]# device services www open alias add name=docs virtualhost=seawitch path=/docs directory=docs
s
```

The auth option is optional.

The directory is specified beneath /var/www/open/alias, and can be a symbolic link to the real location on disk.

## remove open alias

To remove an open alias called "docs", run this.

```
[root@server ~]# device services www open alias remove docs
```

