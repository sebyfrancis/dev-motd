# For installing and configuring MCollective servers

class profiles::mcollective {
  file { "/etc/mcollective/facts.yaml":
    owner    => root,
    group    => root,
    mode     => 400,
    loglevel => debug, # reduce noise in Puppet reports
    # exclude rapidly changing facts:
    content  => inline_template("<%= scope.to_hash.reject { |k,v| k.to_s =~ /(uptime_seconds|timestamp|free)/ }.to_yaml %>"),
  }

  file { "/etc/mcollective/server.cfg":
    owner   => root,
    group   => root,
    mode    => 640,
    content => template("profiles/mcollective-server.erb"),
    notify  => Service['mcollective']
  }

  service { 'mcollective':
    ensure => running,
    enable => true,
  }
}
