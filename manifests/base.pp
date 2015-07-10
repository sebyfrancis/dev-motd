# Common things for all systems:

class profiles::base {
  include profiles::hosts

  # Set Puppet agent's run frequency to a very large # to effectively disable it.
  ini_setting { 'puppet-agent-runinterval':
    ensure  => present,
    path    => '/etc/puppet/puppet.conf',
    section => 'agent',
    setting => 'runinterval',
    value   => '32900900',
  }
  
  # Puppet's Logrotate job keeps restarting the Puppet agent. Disable by deleting the logrotate job.
   file { '/etc/logrotate.d/puppet':
    ensure  => absent,
   }
  

  ini_setting { 'puppet-agent-pluginsync':
    ensure  => present,
    path    => '/etc/puppet/puppet.conf',
    section => 'main',
    setting => 'pluginsync',
    value   => 'true',
  }

  ini_setting { 'yum-timeout':
    ensure  => present,
    path    => '/etc/yum.conf',
    section => 'main',
    setting => 'timeout',
    value   => '3',
  }

  class { '::ntp':
    servers       => ['0.amazon.pool.ntp.org', '1.amazon.pool.ntp.org', '2.amazon.pool.ntp.org', '3.amazon.pool.ntp.org'],
    iburst_enable => true,
  }

  # This is a workaround as the example42/timezone module does not have a template for Amazon Linux:
  if $::operatingsystem == "Amazon" {
    class { 'timezone':
      timezone => 'UTC',
      template => 'timezone/timezone-RedHat',
      hw_utc   => true,
    }
  } else {
    class { 'timezone':
      timezone => 'UTC',
      hw_utc   => true,
    }
  }

  yumrepo { 'p28-extras':
    baseurl  => 'http://repo.platform28.com/extra_x86_64_rpms',
    descr    => 'Platform28 CentOS 6 repository',
    enabled  => 1,
    gpgcheck => 0
  }

  package { 'rpmforge-release':
    ensure  => latest,
    require => Yumrepo['p28-extras'],
  }

  package { 'epel-release': ensure => latest, }

  $basepkgs = [
    'bc',
    'bind-utils',
    "crontabs",
    "curl",
    "vi",
    "vim-enhanced",
    "bzip2",
    "wget",
    "which",
    "htop",
    "iftop",
    "mlocate",
    "s3cmd",
    'strace',
    'sysstat',
    'telnet',
    "tmux",
    "yum-utils",
    "yum-plugin-priorities"]

  package { $basepkgs:
    ensure  => present,
    require => [Package['epel-release'], Package['rpmforge-release'],],
  }

  package { 'updatebash':
    ensure => latest,
    name   => 'bash',
  }

  # ensure we're not running OpenJDK:
  $openjdkpkgs = [ 'java-1.6.0-openjdk', 'java-1.7.0-openjdk', 'java-1.8.0-openjdk' ]
  package { $openjdkpkgs:
    ensure => absent,
  }
  
  service { 'crond': enable => true, }

  $monitoringpkgs = ['check_mk-agent', 'check_mk-agent-logwatch', 'nagios-common', 'nagios-plugins-all']

  package { $monitoringpkgs:
    ensure  => present,
    require => [Package['epel-release'], Package['rpmforge-release'],],
  }

  file { '/etc/motd':
    ensure  => present,
    content => template("profiles/motd.erb"),
  }
  
  file { '/etc/profile.d/aliases.sh':
    ensure  => present,
    source => 'puppet:///modules/profiles/aliases.sh',
  }

  file { "/etc/check_mk/mrpe.cfg":
    ensure => present,
    owner  => 'root',
    group  => 'root',
    mode   => '644',
    source => 'puppet:///modules/profiles/mrpe.cfg',
    ignore => '.git',
  }

  file { "/usr/lib64/nagios/plugins/check_file_exists":
    ensure => present,
    owner  => 'root',
    group  => 'root',
    mode   => '755',
    source => 'puppet:///modules/profiles/check_file_exists',
    ignore => '.git',
  }
  
  file { "/usr/lib64/nagios/plugins/check_proc_cpu.sh":
    ensure => present,
    owner  => 'root',
    group  => 'root',
    mode   => '755',
    source => 'puppet:///modules/profiles/check_proc_cpu.sh',
    ignore => '.git',
  }

  package { 'nuodb': ensure => absent, }
  
  # Logstash installation & shipper config
  
  $_redis_rr_dns_name  = hiera('redis_rr_dns_name')
  $_logstash_redis_key = hiera('logstash_redis_key')
  $_logs_common        = hiera('logs_common')
  
  # Currently easier to let Logstash run as root than remount filesystems with ACLs and add ACLs to logfiles.
  $logstash_init_conf = {
    'LS_USER' => 'root',
  }

  # The next line's specific config is needed to avoid a conflict between it and the Logstash module
  # which also tries to install the Logstash RPM:
  package { 'logstash-1.4.2-1_2c0f5a1_p28': ensure => present, }

  package { 'logstash-contrib': ensure => present, }

  class { '::logstash':
    require       => Package['logstash-1.4.2-1_2c0f5a1_p28'],
    init_defaults => $logstash_init_conf,
  # When Logstash 1.5 is released, we can delete the install of our customized package (above)
  # and re-enable the parameters below or perhaps use the LS RPM repo directly:
  # package_url         =>
  # 'https://download.elasticsearch.org/logstash/logstash/packages/centos/logstash-1.4.2-1_2c0f5a1.noarch.rpm',
  # install_contrib     => true,
  # contrib_package_url =>
  # 'https://download.elasticsearch.org/logstash/logstash/packages/centos/logstash-contrib-1.4.2-1_efd53ef.noarch.rpm',
  # manage_repo         => true,
  # repo_version        => '1.4',
  }

  logstash::configfile { 'shipper_core_config': content => template('profiles/logstash_shipper_core.conf.erb'), }

  logstash::patternfile { 'trade-kernel':
   source  => 'puppet:///modules/profiles/logstash-pattern-trade-kernel',
  }

  user { 'rundeck':
    ensure     => present,
    comment    => 'for connections from Rundeck',
    shell      => '/bin/bash',
    home       => '/home/rundeck',
    managehome => true,
  }

  ssh_authorized_key { 'rundeck@rundeck.aws1.platform28.com':
    user => 'rundeck',
    type => 'ssh-rsa',
    key  => 'AAAAB3NzaC1yc2EAAAABIwAAAQEAtFODUgCUtbnn40INlLwO5bBCiowS0nIrmNe5OrhEdM0jGMygYE6Y2Ysv5ZmmGRSO7zQ33y1MBURl+u2bhYwS0dQlga5OZvJajqs8I0jm+ammFmGzb/vMLpjanHeJbDtErmg1YQqpOvuC9/FghrW3QLN2yMptMPGxJ6fdNsFAMFuFK9N1/Ve+SKUuE5Pnqr7oTHHODpkNbN1zftblzoWYqWYkZbuJB/EnH57jSiT5uPEzgP2KJfYU7aZjjLqcxpSy4F1pLooIwhn35Z5n4XUWwVHZIuYnsOUzCE/q1pwy4xnMmjP1ugwWCGg9pGh72hAOoGNyJOc6xgC3Z+5f9VjoJw==',
  }
  
  file {'/etc/sudoers.d':
    ensure => directory,
  } ->
  file { '/etc/sudoers.d/rundeck':
    ensure  => file,
    content => "rundeck ALL = NOPASSWD: ALL",
  }
}
