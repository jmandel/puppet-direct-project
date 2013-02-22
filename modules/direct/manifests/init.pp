class direct(
  $direct_domain_name=hiera('direct_domain_name'),
  $email_users=hiera('email_users'), 
  $trust_bundles=hiera('trust_bundles'),
  $postmaster=hiera('postmaster'), 
  $java_home=hiera('java_home')
) {

    class{'direct::prerequisites':}
    class{'direct::certificate':}
    create_resources(direct::email_user, $email_users)
    create_resources(direct::trust_bundle, $trust_bundles)

    Class['direct::prerequisites'] -> Class['direct']
    Class['direct'] -> Class['direct::certificate']


    exec {"generate james-ssl-key":
	cwd => "/opt/direct/james-2.3.2/apps/james/conf/",
	unless => "test -f keystore",
	command => "keytool  \
                    -genkey  \
                    -alias james \
                    -keyalg RSA \
                    -keystore keystore \
                    -storepass direct  \
                    -keypass direct \
                    -dname 'CN=James Server SSL'"
    }

    # http://projects.puppetlabs.com/issues/7680
    # can't copy symlink from java_home :-(
    file {"/opt/direct/james-2.3.2/lib/sunjce_provider.jar":
	ensure => file,
	links => follow,
	source => "puppet:///modules/direct/java/sunjce_provider.jar"
    }
 
    file {"/opt/direct/james-2.3.2/apps/james/SAR-INF/config.xml":
	ensure => file,
	content => template("direct/james/config.xml.erb"),
	owner => "root",
	group => "root",
	mode => "0644"
    }

    file {"/opt/direct/james-2.3.2/apps/james/SAR-INF/environment.xml":
	ensure => file,
	content => template("direct/james/environment.xml.erb"),
	owner => "root",
	group => "root",
	mode => "0644"
    }

    file {"/opt/direct/james-2.3.2/apps/james/SAR-INF/assembly.xml":
	ensure => file,
	content => template("direct/james/assembly.xml.erb"),
	owner => "root",
	group => "root",
	mode => "0644"
    }

    file {"/etc/init/direct-dns.conf":
	ensure => file,
	content => template("direct/upstart/direct-dns.conf.erb"),
	owner => "root",
	group => "root",
	mode => "0644"
    }

    file {"/etc/init/direct-james.conf":
	ensure => file,
	content => template("direct/upstart/direct-james.conf.erb"),
	owner => "root",
	group => "root",
	mode => "0644"
    }

    file {"/etc/init/direct-tomcat.conf":
	ensure => file,
	content => template("direct/upstart/direct-tomcat.conf.erb"),
	owner => "root",
	group => "root",
	mode => "0644"
    }

    service {"direct-dns":
	ensure=> running,
	enable=> true,
	require =>  File["/etc/init/direct-dns.conf"]
    }

    service {"direct-tomcat":
	ensure=> running,
	enable=> true,
	require => File["/etc/init/direct-tomcat.conf"]
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
