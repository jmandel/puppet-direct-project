class direct::prerequisites($java_home=hiera('java_home')) {

    package {
        ["ant",
	 "unzip", 
         "expect",
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
        source => "puppet:///modules/direct/java/US_export_policy.jar",
	ensure => file,
	backup => puppet
    }	

    file { "$java_home/jre/lib/security/local_policy.jar":
	require => Package["openjdk-7-jdk"],
        source => "puppet:///modules/direct/java/local_policy.jar",
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
	cwd => "/opt",
	command => "tar -xzvf /tmp/direct-stock.tgz",
	require => Wget::Fetch["get direct-bare-metal"],
	notify => [
		Service["direct-dns"],
		Service["direct-tomcat"],
		Service["direct-james"]
	]
    }


}
