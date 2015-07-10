# For installing and configuring the mounts to the AWS S3 bucket
# for content like voicemail, prompts, recordings, reports, etc.

class profiles::s3 {
  $s3bucketname = 'p28-main-storage'
  $mountpoint   = '/mnt/primary'

  package { 'fuse-s3': ensure => present, }

  file { '/etc/passwd-s3fs':
    mode    => '600',
    require => Package['fuse-s3'],
    source  => 'puppet:///modules/profiles/passwd-s3fs',
  }

  exec { 'tmp-s3fscache':
    path    => ['/usr/bin', '/usr/sbin', '/bin', '/sbin'],
    command => 'mkdir -p /tmp/s3fscache; chgrp resin /tmp/s3fscache; chmod g+w /tmp/s3fscache',
    creates => '/tmp/s3fscache',
  } ->
  exec { 'mnt-primary':
    path    => ['/usr/bin', '/usr/sbin', '/bin', '/sbin'],
    command => 'mkdir -p /mnt/primary; chgrp resin /mnt/primary; chmod g+rwxs,o+rx /mnt/primary',
    creates => '/mnt/primary',
  } ->
  exec { 'mounts3':
    path    => ['/usr/bin', '/usr/sbin', '/bin', '/sbin'],
    command => "/bin/grep -qw $mountpoint /proc/mounts || /usr/local/bin/s3fs -o allow_other,use_cache=/tmp/s3fscache $s3bucketname $mountpoint; echo 0",
    require => Package['fuse-s3'],
  }

  file { '/etc/cron.daily/delete-old-s3-cache.sh':
    ensure  => file,
    mode    => '755',
    require => Package['fuse-s3'],
    source  => 'puppet:///modules/profiles/delete-old-s3-cache.sh',
  }

  fstab { 'fstab-s3fs':
    source => "s3fs#$s3bucketname",
    dest   => $mountpoint,
    type   => 'fuse',
    opts   => 'use_cache=/tmp/s3fscache,allow_other,uid=resin,gid=resin',
    dump   => 0,
    passno => 0,
  }

  # Add MRPE check for S3:
  file_line { 'is-s3-connected':
    path  => '/etc/check_mk/mrpe.cfg',
    match => '^is_s3_connected',
    line  => "is_s3_connected /usr/lib64/nagios/plugins/check_file_exists /mnt/primary/s3-detection-test-file",
  }

  # Fix permissions on uploaded templates
  # 2014.12.08 - Moving this as a standalone script to a single server, since it's operating against an S3 bucket.


  # The mounts via s3fs can be flaky and need to be remounted.
  # This script checks and remounts:
  file { '/usr/local/bin/check-s3fs-restart-fuse.sh':
    ensure => file,
    mode   => '755',
    source => 'puppet:///modules/profiles/check-s3fs-restart-fuse.sh',
  }

  cron { 'check-s3fs-restart-fuse':
    command => '/usr/local/bin/check-s3fs-restart-fuse.sh 2>&1 > /dev/null',
    user    => root,
    minute  => '*/2',
    require => File['/usr/local/bin/check-s3fs-restart-fuse.sh'],
  }

}
