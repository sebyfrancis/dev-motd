# Disable IPv6 on CentOS (per http://wiki.centos.org/FAQ/CentOS6#head-d47139912868bcb9d754441ecb6a8a10d41781df)

class profiles::disableipv6 {
  sysctl { "net.ipv6.conf.all.disable_ipv6":
    ensure  => present,
    value   => "1",
    comment => "Disable IPv6",
  }

  sysctl { "net.ipv6.conf.default.disable_ipv6":
    ensure  => present,
    value   => "1",
    comment => "Disable IPv6",
  }

  # fix Postfix conf:
  file_line { 'postfix-conf-ipv6':
    path  => '/etc/postfix/main.cf',
    match => '^inet_interfaces',
    line  => "inet_interfaces = 127.0.0.1",
  }

}
