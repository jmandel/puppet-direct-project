class direct::certificate(
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
