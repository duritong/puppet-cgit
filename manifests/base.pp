# basic things for cgit
class cgit::base {
  package{['cgit','highlight']:
    ensure => present,
  } -> File['config_dir']
  # the pkg also manages this dir

  file{
    '/etc/cgitrc':
      source       => [
        "puppet:///modules/site_cgit/config/${::fqdn}/cgitrc",
        'puppet:///modules/site_cgit/config/cgitrc',
        'puppet:///modules/cgit/config/cgitrc',
      ],
      require      => Package['cgit'],
      before       => Service['apache'],
      owner        => root,
      group        => 0,
      mode         => '0644';
    '/var/cache/cgit':
      ensure       => 'directory',
      require      => Package['cgit'],
      purge        => true,
      recurse      => true,
      force        => true,
      recurselimit => 1,
      ignore       => 'lost+found',
      owner        => apache,
      group        => apache,
      mode         => '0644';
  }
  if versioncmp($facts['os']['release']['major'],'7') >= 0 {
    apache::config::global{
      'cgit.conf':
        source => 'puppet:///modules/cgit/config/httpd',
    }
  }
}
