## Draft: Puppet installer for Direct J-RI
Java Reference Implementation for Direct Project

Targets: Version 2.1 RC1

On a fresh Ubuntu 12.10 machine:

Install Puppet 3.x:
```
#!/bin/bash
# upgrade all packages
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get -y upgrade

# install PuppetLabs repo
wget http://apt.puppetlabs.com/puppetlabs-release-quantal.deb
dpkg -i puppetlabs-release-quantal.deb
apt-get update

# Install puppet
apt-get -y install puppet-common git

# Clean up
export DEBIAN_FRONTEND=dialog
```


Then apply the site manifest to load Direct J-RI:
```
$ git clone https://github.com/jmandel/puppet-direct-project.git /etc/puppet
# (edit /etc/puppet/hieradata/common.json with your settings)
$ puppet apply  /etc/puppet/manifests/site.pp  -d
```

---
### TODO for automated config:

[x] 1.  Within config-service, create new domain w/ postmaster, ENABLED status

[x] 2.  Create a set of mail users in common.json

[x] ... and ensure each one is auto-created via telnet/expect

[x] 3.  Generate site certificate
[x] 4.  Generate domain certificate
[x] 5.  Within config-service, add the domain certificate.

6.  Within config-service, create MX  entry for MX
7.  Within config-service, create A entry for direct_host
8.  Within config-service, add authorized trust bundles to installation
9.  Within config-service, add authorized trust bundles to domain

