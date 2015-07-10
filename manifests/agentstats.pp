# For Agent Statistics (AgentStats) server(s).

class profiles::agentstats {
  # Rotate job for Tomcat's catalina.out:
  file { '/etc/logrotate.d/tomcat':
    ensure => present,
    mode   => '755',
    source => 'puppet:///modules/profiles/agentstats-tomcat-logrotate',
  }

  # ensure there's a symlink to the latest tomcat dir so that the
  # logrotate and other jobs work without modification
  file { '/home/dashboard/apache-tomcat':
    ensure => present,
    owner  => 'dashboard',
    group  => 'dashboard',
    target => '/home/dashboard/apache-tomcat-7.0.59',
  }

}
