## Puppet installer for Direct J-RI
Java Reference Implementation for Direct Project

## From 0 to Direct Java-RI
These scripts take a fresh Ubuntu 12.10 machine, and install 
the Direct Java Reference Implementation 2.1 RC1 with all dependencies.

### Configurable through a [single JSON file](hieradata/common.json)
 * Certificate Generation
 * Default e-mail account names + passwords
 * DNS hostname for MX and A records
 * Trust Bundles to install

### Total system configuration
 * Firewall allows access only to mail servers + ssh
 * upstart services launch on boot

### Unattended install in the cloud

Just provision an Ubuntu 12.10 stock VM.  Then

*Install Puppet 3.x:*
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

*Apply the site manifest to load Direct J-RI:*
```
$ git clone https://github.com/jmandel/puppet-direct-project.git /etc/puppet
# (edit /etc/puppet/hieradata/common.json with your settings)
$ puppet apply  /etc/puppet/manifests/site.pp  -d
```

---
### TODO for automated config:

1. [x]   Within config-service, create new domain w/ postmaster, ENABLED status
2.  [x] Create a set of mail users in common.json
3. [x] ...and ensure each one is auto-created via telnet/expect
4. [x] Generate site certificate
5. [x] Generate domain certificate
6. [x] Within config-service, add the domain certificate.
7. [x] Within config-service, create MX  entry for MX
7. [x] Within config-service, create A entry for direct_host
8. [x] Within config-service, add authorized trust bundles to installation
9. [x]   Within config-service, add authorized trust bundles to domain

* Run `config-service` tomcat as unprivileged user
