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


