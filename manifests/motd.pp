file { '/etc/motd':
    ensure  => present,
    content => template("motd/motd.erb"),
}