# everything needed for a vhost based setup
class cgit::vhosts::base inherits cgit::base {
  File['/etc/cgitrc']{
    source  => [
      "puppet:///modules/site_cgit/config/${::fqdn}/cgitrc",
      'puppet:///modules/site_cgit/config/cgitrc',
      'puppet:///modules/cgit/config/cgitrc.vhosts',
    ],
  }

  file{
    '/etc/cgitrc.d':
      ensure  => directory,
      recurse => true,
      purge   => true,
      force   => true,
      owner   => root,
      group   => 0,
      mode    => '0644';
    [ '/var/www/git_suexec',
      '/var/www/git_htpasswds', ]:
      ensure  => 'directory',
      require => Package['apache'],
      purge   => true,
      recurse => true,
      force   => true,
      owner   => root,
      group   => 0,
      mode    => '0644',
      seltype => 'httpd_sys_content_t';
  }
  apache::config::global{'cgit.conf': }
  if versioncmp($facts['os']['release']['major'],'7') >= 0 {
    Apache::Config::Global['cgit.conf']{
      source => 'puppet:///modules/cgit/config/httpd',
    }
  } else {
    Apache::Config::Global['cgit.conf']{
      ensure  => absent,
    }
  }

  if str2bool($::selinux) {
    include ::cgit::vhosts::selinux
  }
}
