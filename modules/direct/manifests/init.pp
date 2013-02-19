class direct {

    $direct_domain_name = hiera('direct_domain_name')

    package {
        ["ant", "unzip", "openjdk-7-jdk", "nmap"]:
        ensure => latest
    }

    include ufw

    ufw::allow { "allow-ssh-from-all":
      port => 22,
    }

    ufw::allow { "allow-dns-from-all":
      port => 53,
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

    notify {"set up basics; now ready to copy $java_home/jre/lib/ext/sunjce_provider.jar":
	require => [
	    Ufw::Allow["allow-ssmtp-from-all"]
	]
    }

    file { "$java_home/jre/lib/security/US_export_policy.jar":
	require => Package["openjdk-7-jdk"],
        source => "puppet:///modules/direct/UnlimitedJCEPolicy/US_export_policy.jar",
	ensure => file,
	backup => puppet
    }	

    file { "$java_home/jre/lib/security/local_policy.jar":
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

    exec {"extract direct-bare-metal":
	require => Wget::Fetch["get direct-bare-metal"],
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

    # http://projects.puppetlabs.com/issues/7680 -- can't copy symlink from $java_home :-(
    file {"/opt/direct/james-2.3.2/lib/sunjce_provider.jar":
	require => [
		Exec["extract direct-bare-metal"],
		Package["openjdk-7-jdk"]
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

    service {"direct-james":
	ensure=> running,
	enable=> true,
	require => [
		File["/etc/init/direct-james.conf"],
		File["/opt/direct/james-2.3.2/apps/james/SAR-INF/config.xml"],
		File["/opt/direct/james-2.3.2/apps/james/SAR-INF/environment.xml"],
		File["/opt/direct/james-2.3.2/apps/james/SAR-INF/assembly.xml"],
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

}
