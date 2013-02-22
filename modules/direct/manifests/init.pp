class direct_pre($java_home=hiera('java_home')) {

    package {
        ["ant",
	 "unzip", 
	 "openjdk-7-jdk",
	 "nmap", 
	 "python-pip",
	 "netcat",
	 "openssl",
	 "libssl-dev"]:
        ensure => latest
    }

    include ufw

    exec {"pip install suds": 
	unless => "pip freeze | grep suds=="
    }

    exec {"pip install pyopenssl": 
	unless => "pip freeze | grep pyopenssl=="
    }

    exec {"pip install dnspython": 
	unless => "pip freeze | grep dnspython=="
    }

    ufw::allow { "allow-ssh-from-all":
      port => 22,
    }

    ufw::allow { "allow-dns-from-all-tcp":
      port => 53,
      proto => "tcp"
    }

    ufw::allow { "allow-dns-from-all-udp":
      port => 53,
      proto => "udp"
    }

    ufw::allow { "allow-smtp-from-all":
      port => 25,
    }

    ufw::allow { "allow-spop3-from-all":
      port => 995,
    }

    ufw::allow { "allow-ssmtp-from-all":
      port => 465,
    }

    file {"/tmp/puppet":
	ensure => directory,
	mode => "0744"
    }

    file { "$java_home/jre/lib/security/US_export_policy.jar":
	require => Package["openjdk-7-jdk"],
        source => "puppet:///modules/direct/UnlimitedJCEPolicy/US_export_policy.jar",
	ensure => file,
	backup => puppet
    }	

    #TODO: Add bouncycastle to security.providers 
    # security.provider.5=org.bouncycastle.jce.provider.BouncyCastleProvider

	require => Package["openjdk-7-jdk"],
        source => "puppet:///modules/direct/UnlimitedJCEPolicy/local_policy.jar",
	ensure => file,
	backup => puppet
    }	

    include wget

    wget::fetch { "get direct-bare-metal":
	require => Package["openjdk-7-jdk"],
	source => "https://oss.sonatype.org/content/repositories/snapshots/org/nhind/direct-project-stock/2.1-SNAPSHOT/direct-project-stock-2.1-SNAPSHOT.tar.gz",
	destination => "/tmp/direct-stock.tgz"
    }
}


class direct(
  $direct_domain_name=hiera('direct_domain_name'),
  $email_users=hiera('email_users'), 
  $trust_bundles=hiera('trust_bundles'),
  $postmaster=hiera('postmaster'), 
  $java_home=hiera('java_home')) {

    class{'direct_pre':}
    class{'certificate':}
    create_resources(email_user, $email_users)
    create_resources(trust_bundle, $trust_bundles)

    Class['direct_pre'] -> Class['direct']
    Class['direct'] -> Class['certificate']


    exec {"extract direct-bare-metal":
	cwd => "/opt",
	command => "tar -xzvf /tmp/direct-stock.tgz",
	notify => [
		Service["direct-dns"],
		Service["direct-tomcat"],
		Service["direct-james"]
	]
    }

    exec {"generate james-ssl-key":
	require => Exec["extract direct-bare-metal"],
	cwd => "/opt/direct/james-2.3.2/apps/james/conf/",
	unless => "test -f keystore",
	command => "keytool  -genkey  -alias james -keyalg RSA -keystore keystore -storepass direct  -keypass direct -dname 'CN=James Server SSL'"
    }

    # http://projects.puppetlabs.com/issues/7680 -- can't copy symlink from java_home :-(
    file {"/opt/direct/james-2.3.2/lib/sunjce_provider.jar":
	require => [
		Exec["extract direct-bare-metal"]
	],
	ensure => file,
	links => follow,
	source => "puppet:///modules/direct/sunjce_provider.jar"
    }
 
    file {"/opt/direct/james-2.3.2/apps/james/SAR-INF/config.xml":
	require => Exec["extract direct-bare-metal"],
	ensure => file,
	content => template("direct/james-config.xml.erb"),
	owner => "root",
	group => "root",
	mode => "0644"
    }

    file {"/opt/direct/james-2.3.2/apps/james/SAR-INF/environment.xml":
	require => Exec["extract direct-bare-metal"],
	ensure => file,
	content => template("direct/james-environment.xml.erb"),
	owner => "root",
	group => "root",
	mode => "0644"
    }

    file {"/opt/direct/james-2.3.2/apps/james/SAR-INF/assembly.xml":
	require => Exec["extract direct-bare-metal"],
	ensure => file,
	content => template("direct/james-assembly.xml.erb"),
	owner => "root",
	group => "root",
	mode => "0644"
    }

    file {"/etc/init/direct-dns.conf":
	ensure => file,
	content => template("direct/init/direct-dns.conf.erb"),
	owner => "root",
	group => "root",
	mode => "0644"
    }

    file {"/etc/init/direct-james.conf":
	ensure => file,
	content => template("direct/init/direct-james.conf.erb"),
	owner => "root",
	group => "root",
	mode => "0644"
    }

    file {"/etc/init/direct-tomcat.conf":
	ensure => file,
	content => template("direct/init/direct-tomcat.conf.erb"),
	owner => "root",
	group => "root",
	mode => "0644"
    }

    service {"direct-dns":
	ensure=> running,
	enable=> true,
	require => [
		File["/etc/init/direct-dns.conf"],
		Exec["extract direct-bare-metal"]
	]
    }

    service {"direct-tomcat":
	ensure=> running,
	enable=> true,
	require => [
		File["/etc/init/direct-tomcat.conf"],
		Exec["extract direct-bare-metal"]
	]
    }


    file {"/tmp/puppet/wait_for_tomcat.sh":
	ensure => file,
	source => "puppet:///modules/direct/wait_for_tomcat.sh",
	mode => "0744"
    }

    exec {"wait-for-tomcat":
	cwd => "/tmp/puppet",
	command => "sh wait_for_tomcat.sh",
	require => [
		Service["direct-tomcat"],
		File["/tmp/puppet/wait_for_tomcat.sh"]
	],
	timeout => 600
    }

    file {"/tmp/puppet/config_client_py":
	ensure => directory,
	recurse => true,
	source => "puppet:///modules/direct/config_client_py",
	mode => "0755",
    }

    exec {"add-domain":
	cwd => "/tmp/puppet/config_client_py",
	command => "python add_domain.py $direct_domain_name $postmaster",
	require => [
		Exec["pip install suds"],	
		Exec["wait-for-tomcat"]
	]
    }

    service {"direct-james":
	ensure=> running,
	enable=> true,
	require => [
		File["/etc/init/direct-james.conf"],
		File["/opt/direct/james-2.3.2/apps/james/SAR-INF/config.xml"],
		File["/opt/direct/james-2.3.2/apps/james/SAR-INF/environment.xml"],
		File["/opt/direct/james-2.3.2/apps/james/SAR-INF/assembly.xml"],
		Exec["add-domain"]
	]
    }

    exec {"wait-for-james":
	command => "nc -z localhost 4555",
	tries => 30,
	try_sleep => 5,
	timeout => 1,
	require => Service["direct-james"]
    }

    file {"/tmp/puppet/add_email_user.expect":
	ensure => file,
	source => "puppet:///modules/direct/add_email_user.expect",
    }

}

define trust_bundle($url) {
  
    exec {"add-trust-bundle-$name":
	cwd => "/tmp/puppet/config_client_py",
	command => "python add_trust_bundle.py \"$name\" \"$url\" ",
	require => Exec["add-domain"]
    }

}

define email_user($password) {
  
    exec {"add-user-$title":
	cwd => "/tmp/puppet",
	command => "expect add_email_user.expect $title $password",
	require => [
		Exec["wait-for-james"],
		File["/tmp/puppet/add_email_user.expect"]
	]
    }
}

class certificate(
  $certificate=hiera("certificate"),
  $direct_domain_name=hiera('direct_domain_name'),
) {

    file {"/tmp/puppet/gencert.sh":
	ensure => file,
	source => "puppet:///modules/direct/gencert.sh",
    }

    file {"/tmp/puppet/req-config":
	ensure => file,
	content => template("direct/certificates/req-config.erb"),
    }

    file {"/tmp/puppet/sign-config":
	ensure => file,
	content => template("direct/certificates/sign-config.erb"),
    }

    exec {"gen-cert":
	cwd => "/tmp/puppet",
	command => "sh gencert.sh",
	require => [
		File["/tmp/puppet/req-config"],
		File["/tmp/puppet/sign-config"],
		File["/tmp/puppet/gencert.sh"],
	]
    }

    exec {"add-cert":
	command => "python add_certificate.py /tmp/puppet/cert-with-key-package.p12",
	cwd => "/tmp/puppet/config_client_py",
	require => Exec["gen-cert"]
    }

    exec {"add-dns-mx":
	command => "python add_dns.py MX $direct_domain_name $ipaddress ",
	cwd => "/tmp/puppet/config_client_py",
	require => File["/tmp/puppet/config_client_py"]
    }

    exec {"add-dns-a":
	command => "python add_dns.py A $direct_domain_name $ipaddress ",
	cwd => "/tmp/puppet/config_client_py",
	require => File["/tmp/puppet/config_client_py"]
    }
}

