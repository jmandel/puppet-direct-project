define direct::trust_bundle($url) {
  
    exec {"add-trust-bundle-$name":
	cwd => "/tmp/puppet/config_client_py",
	command => "python add_trust_bundle.py \"$name\" \"$url\" ",
	require => Exec["add-domain"]
    }

}


