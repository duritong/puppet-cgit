# selinux related things
class cgit::vhosts::selinux {
  include ::gitolite::daemon::selinux::web

  if versioncmp($facts['os']['release']['major'],'7') >= 0 {
    $source = 'puppet:///modules/cgit/selinux/gitolite'
  } else {
    $source = 'puppet:///modules/cgit/selinux/gitolite.CentOS.6'
  }
  selinux::policy{
    'cgit_gitolite':
      te_source => "${source}/cgit_gitolite.te",
      fc_source => "${source}/cgit_gitolite.fc",
      fc_file   => true,
      require   => Package['cgit'],
      before    => Service['apache'],
  }
}
