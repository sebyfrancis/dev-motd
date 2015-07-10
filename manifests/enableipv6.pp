# Enable IPv6 on CentOS (per http://wiki.centos.org/FAQ/CentOS6#head-d47139912868bcb9d754441ecb6a8a10d41781df)

class profiles::enableipv6 {
  sysctl { "net.ipv6.conf.all.disable_ipv6":
    ensure  => present,
    value   => "0",
    comment => "Enable IPv6",
  }

  sysctl { "net.ipv6.conf.default.disable_ipv6":
    ensure  => present,
    value   => "0",
    comment => "Enable IPv6",
  }

}
