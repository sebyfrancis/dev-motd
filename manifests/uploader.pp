# For Uploader server(s). Recordings primarily.

class profiles::uploader {
  group { 'resin': ensure => present, }

  user { 'resin':
    ensure  => present,
    comment => 'for convenience',
    home    => '/mnt/primary/',
    shell   => '/bin/bash',
    groups  => 'resin',
    require => Group['resin'],
  }

  # This is the poor man's way to modify the fstab line (until we have Hiera)
  file_line { 'remove-s3fs-cache':
    path  => '/etc/fstab',
    match => '^s3fs',
    line  => "s3fs#p28-main-storage /mnt/primary  fuse  allow_other,uid=resin,gid=resin 0 0",
  } ->
  exec { 'restart-s3fs':
    path    => ['/usr/bin', '/usr/sbin', '/bin', '/sbin', '/usr/local/bin'],
    command => "/usr/local/bin/fusermount -uz /mnt/primary && service fuse restart && mount -a",
  }

}
