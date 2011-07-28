import "base.pp"

class app inherits base {

	package { "tomcat6":
		ensure => "present",	
	}
	
	$prevayler_path = "/var/db/prevayler"
	
	file { "${prevayler_path}" :
		ensure => "directory",
		owner => "tomcat",
		require => Package["tomcat6"],
	}
	
	file { "/etc/tomcat6/tomcat6.conf" :
		ensure => "present",
		content => template("tomcat6.conf.erb"),
		require => [Package["tomcat6"],File["${prevayler_path}"]],
		notify => Service["tomcat6"]	
	}
	
	service { "tomcat6":
		ensure => "running",
		require => Package["tomcat6"],
		hasstatus => true,
		hasrestart => true,
	}
	

}

include app
