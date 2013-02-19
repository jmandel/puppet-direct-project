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
