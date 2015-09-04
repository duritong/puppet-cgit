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
    '/etc/httpd/conf.d/cgit.conf':
      ensure  => absent,
      require => Package['cgit'];
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
      ensure        => 'directory',
      require       => Package['apache'],
      purge         => true,
      recurse       => true,
      force         => true,
      owner         => root,
      group         => 0,
      mode          => '0644';
  }

  if str2bool($::selinux) {
    File['/var/www/git_suexec']{
      seltype => 'httpd_git_script_exec_t'
    }
    include ::cgit::vhosts::selinux
  }
}
