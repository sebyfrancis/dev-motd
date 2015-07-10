class profiles::hosts {
  host { 'sip.east1.platform28.com':
    ensure => 'present',
    ip     => '54.236.115.203',
  }

  host { 'sip.west1.platform28.com':
    ensure => 'present',
    ip     => '54.236.115.203',
  }

  host { 'openswan.aws1.platform28.com':
    ensure => 'present',
    ip     => '10.0.2.150',
  }

  host { 'logi.aws1.platform28.com':
    ensure => 'present',
    ip     => '10.0.2.170',
  }

  host { 'loadtester.aws1.platform28.com':
    ensure => 'present',
    ip     => '10.0.1.56',
  }

  host { 'kafka1.aws1.platform28.com':
    ensure       => 'present',
    ip           => '10.0.102.222',
    host_aliases => ['zk1.aws1.platform28.com', 'AE1-kafka-C6-P-001.aws1.platform28.com',],
  }

  host { 'kafka2.aws1.platform28.com':
    ensure       => 'present',
    ip           => '10.0.102.223',
    host_aliases => ['zk2.aws1.platform28.com', 'AE1-kafka-C6-P-002.aws1.platform28.com',],
  }

  host { 'kafka3.aws1.platform28.com':
    ensure       => 'present',
    ip           => '10.0.102.224',
    host_aliases => ['zk3.aws1.platform28.com', 'AE1-kafka-C6-P-003.aws1.platform28.com',],
  }

  host { 'acd1.aws1.platform28.com':
    ensure       => 'present',
    ip           => '10.0.102.84',
    host_aliases => ['AE1-acd-C6-P-001.aws1.platform28.com', 'grid-bootstrap1-east.platform28.com',],
  }

  host { 'acd2.aws1.platform28.com':
    ensure       => 'present',
    ip           => '10.0.102.85',
    host_aliases => ['AE1-acd-C6-P-002.aws1.platform28.com', 'grid-bootstrap2-east.platform28.com',],
  }

  host { 'fs1.aws1.platform28.com':
    ensure       => 'present',
    ip           => '10.0.2.47',
    host_aliases => ['AE1-freeswitch-C6-P-001.aws1.platform28.com',],
  }

  host { 'fs2.aws1.platform28.com':
    ensure       => 'present',
    ip           => '10.0.2.48',
    host_aliases => ['AE1-freeswitch-C6-P-002.aws1.platform28.com',],
  }

  host { 'fs3.aws1.platform28.com':
    ensure       => 'present',
    ip           => '10.0.2.138',
    host_aliases => ['AE1-freeswitch-C6-P-003.aws1.platform28.com',],
  }

  host { 'fs4.aws1.platform28.com':
    ensure       => 'present',
    ip           => '10.0.2.139',
    host_aliases => ['AE1-freeswitch-C6-P-004.aws1.platform28.com',],
  }

  host { 'fs5.aws1.platform28.com':
    ensure       => 'present',
    ip           => '10.0.2.242',
    host_aliases => ['AE1-freeswitch-C6-P-005.aws1.platform28.com',],
  }

  host { 'fs6.aws1.platform28.com':
    ensure       => 'present',
    ip           => '10.0.2.243',
    host_aliases => ['AE1-freeswitch-C6-P-006.aws1.platform28.com',],
  }

  host { 'fs7.aws1.platform28.com':
    ensure       => 'present',
    ip           => '10.0.2.244',
    host_aliases => ['AE1-freeswitch-C6-P-007.aws1.platform28.com',],
  }

  host { 'fs8.aws1.platform28.com':
    ensure       => 'present',
    ip           => '10.0.2.245',
    host_aliases => ['AE1-freeswitch-C6-P-008.aws1.platform28.com',],
  }

  host { 'fs9.aws1.platform28.com':
    ensure       => 'present',
    ip           => '10.0.2.49',
    host_aliases => ['AE1-freeswitch-C6-P-009.aws1.platform28.com',],
  }

  host { 'fs10.aws1.platform28.com':
    ensure       => 'present',
    ip           => '10.0.2.50',
    host_aliases => ['AE1-freeswitch-C6-P-010.aws1.platform28.com',],
  }

  host { 'fs11.aws1.platform28.com':
    ensure       => 'present',
    ip           => '10.0.2.51',
    host_aliases => ['AE1-freeswitch-C6-P-011.aws1.platform28.com',],
  }

  host { 'fs12.aws1.platform28.com':
    ensure       => 'present',
    ip           => '10.0.2.52',
    host_aliases => ['AE1-freeswitch-C6-P-012.aws1.platform28.com',],
  }

  host { 'fs13.aws1.platform28.com':
    ensure       => 'present',
    ip           => '10.0.2.53',
    host_aliases => ['AE1-freeswitch-C6-P-013.aws1.platform28.com',],
  }

  host { 'fs14.aws1.platform28.com':
    ensure       => 'present',
    ip           => '10.0.2.54',
    host_aliases => ['AE1-freeswitch-C6-P-014.aws1.platform28.com',],
  }

  host { 'fs15.aws1.platform28.com':
    ensure       => 'present',
    ip           => '10.0.2.55',
    host_aliases => ['AE1-freeswitch-C6-P-015.aws1.platform28.com',],
  }

  host { 'fs25.aws1.platform28.com':
    ensure       => 'present',
    ip           => '10.0.2.135',
    host_aliases => ['AE1-freeswitch-C6-P-025.aws1.platform28.com',],
  }

  host { 'logi1.aws1.platform28.com':
    ensure       => 'present',
    ip           => '10.0.2.170',
    host_aliases => ['AE1-logi-C6-P-001.aws1.platform28.com',],
  }

  host { 'logi2.aws1.platform28.com':
    ensure       => 'present',
    ip           => '10.0.2.78',
    host_aliases => ['AE1-logi-C6-P-002.aws1.platform28.com', 'analytics.aws1.platform28.com',],
  }

  host { 'opensips.aws1.platform28.com':
    ensure => 'present',
    ip     => '10.0.2.10',
  }

  host { 'opensips1.aws1.platform28.com':
    ensure       => 'present',
    ip           => '10.0.2.134',
    host_aliases => ['AE1-opensips-C6-P-001.aws1.platform28.com',],
  }

  host { 'opensips2.aws1.platform28.com':
    ensure       => 'present',
    ip           => '10.0.2.147',
    host_aliases => ['AE1-opensips-C6-P-002.aws1.platform28.com',],
  }

  host { 'rest1.aws1.platform28.com':
    ensure       => 'present',
    ip           => '10.0.102.202',
    host_aliases => ['AE1-rest-C6-P-001.aws1.platform28.com', 'grid-bootstrap3-east.platform28.com',],
  }

  host { 'rest2.aws1.platform28.com':
    ensure       => 'present',
    ip           => '10.0.102.203',
    host_aliases => ['AE1-rest-C6-P-002.aws1.platform28.com', 'grid-bootstrap4-east.platform28.com',],
  }

  host { 'rest3.aws1.platform28.com':
    ensure       => 'present',
    ip           => '10.0.102.27',
    host_aliases => ['AE1-rest-C6-P-003.aws1.platform28.com', 'grid-bootstrap5-east.platform28.com',],
  }

  host { 'rest4.aws1.platform28.com':
    ensure       => 'present',
    ip           => '10.0.102.28',
    host_aliases => ['AE1-rest-C6-P-004.aws1.platform28.com', 'grid-bootstrap6-east.platform28.com',],
  }

  host { 'statsgen1.aws1.platform28.com':
    ensure       => 'present',
    ip           => '10.0.102.252',
    host_aliases => ['AE1-statsgen-C6-P-001.aws1.platform28.com',],
  }

  host { 'statsgen2.aws1.platform28.com':
    ensure       => 'present',
    ip           => '10.0.1.238',
    host_aliases => ['AE1-statsgen-C6-P-002.aws1.platform28.com',],
  }

  host { 'web1.aws1.platform28.com':
    ensure       => 'present',
    ip           => '10.0.2.65',
    host_aliases => ['AE1-web-C6-P-001.aws1.platform28.com',],
  }

  host { 'web2.aws1.platform28.com':
    ensure       => 'present',
    ip           => '10.0.2.66',
    host_aliases => ['AE1-web-C6-P-002.aws1.platform28.com',],
  }

  host { 'metrics1.aws1.platform28.com':
    ensure       => 'present',
    ip           => '10.0.102.209',
    host_aliases => ['AE1-metrics-C6-P-001.aws1.platform28.com',],
  }

  host { 'tts1.aws1.platform28.com':
    ensure       => 'present',
    ip           => '10.0.102.165',
    host_aliases => ['AE1-tts-C6-P-001.aws1.platform28.com',],
  }

  host { 'monitor1.aws1.platform28.com':
    ensure       => 'present',
    ip           => '10.0.2.24',
    host_aliases => ['AE1-monitor-C6-P-001.aws1.platform28.com', 'monitor.aws1.platform28.com'],
  }

  host { 'emailgw1.aws1.platform28.com':
    ensure       => 'present',
    ip           => '10.0.102.79',
    host_aliases => ['AE1-monitor-C6-P-001.aws1.platform28.com',],
  }

  host { 'emailgw2.aws1.platform28.com':
    ensure       => 'present',
    ip           => '10.0.2.251',
    host_aliases => ['AE1-monitor-C6-P-002.aws1.platform28.com',],
  }

  host { 'uploader1.aws1.platform28.com':
    ensure       => 'present',
    ip           => '10.0.2.151',
    host_aliases => ['AE1-uploader-C6-P-001.aws1.platform28.com', 'uploader.aws1.platform28.com'],
  }

  host { 'natdoas.aws1.platform28.com':
    ensure       => 'present',
    ip           => '10.0.2.62',
    host_aliases => ['AE1-natdoas-C6-P-001.aws1.platform28.com',],
  }

  host { 'natstars.aws1.platform28.com':
    ensure       => 'present',
    ip           => '10.0.2.217',
    host_aliases => ['AE1-monitor-C6-P-001.aws1.platform28.com',],
  }

  host { 'es2.aws1.platform28.com':
    ensure       => 'present',
    ip           => '10.0.102.141',
    host_aliases => ['AE1-elasticsearch-C6-P-002.aws1.platform28.com',],
  }

  host { 'es3.aws1.platform28.com':
    ensure       => 'present',
    ip           => '10.0.102.140',
    host_aliases => ['AE1-elasticsearch-C6-P-003.aws1.platform28.com',],
  }

  host { 'es4.aws1.platform28.com':
    ensure       => 'present',
    ip           => '10.0.102.157',
    host_aliases => ['AE1-elasticsearch-C6-P-004.aws1.platform28.com',],
  }

  host { 'logstash1.aws1.platform28.com':
    ensure => 'present',
    ip     => '10.0.102.104',
  }

  host { 'logstash2.aws1.platform28.com': ensure => 'absent', }

  host { 'logstash3.aws1.platform28.com': ensure => 'absent', }

  host { 'logstash4.aws1.platform28.com': ensure => 'absent', }

  host { 'logstash5.aws1.platform28.com': ensure => 'absent', }

  host { 'logstash6.aws1.platform28.com':
    ensure => 'present',
    ip     => '10.0.102.214',
  }

  host { 'redis1.aws1.platform28.com': ensure => 'absent', }

  host { 'redis2.aws1.platform28.com':
    ensure => 'present',
    ip     => '10.0.102.15',
  }

  host { 'redis6.aws1.platform28.com':
    ensure => 'present',
    ip     => '10.0.102.214',
  }

  host { 'starsgw.aws1.platform28.com':
    ensure       => 'present',
    ip           => '10.0.102.78',
    host_aliases => ['AE1-starsgw-C6-P-001.aws1.platform28.com',],
  }

  host { 'agentstats1.aws1.platform28.com':
    ensure       => 'present',
    ip           => '10.0.2.38',
    host_aliases => ['AE1-agentstats-C6-P-001.aws1.platform28.com', 'agentstats.aws1.platform28.com'],
  }
}
