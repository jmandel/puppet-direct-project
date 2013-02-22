define direct::email_user($password) {
  
    exec {"add-user-$title":
	cwd => "/tmp/puppet",
	command => "expect add_email_user.expect $title $password",
	require => [
		Exec["wait-for-james"],
		File["/tmp/puppet/add_email_user.expect"]
	]
    }
}
