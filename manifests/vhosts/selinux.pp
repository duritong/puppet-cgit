# selinux related things
class cgit::vhosts::selinux {
  include gitolite::daemon::selinux::web

  if versioncmp($facts['os']['release']['major'],'7') >= 0 {
    $fc_source = 'puppet:///modules/cgit/selinux/gitolite/cgit_gitolite.fc'
  } else {
    $fc_source = 'puppet:///modules/cgit/selinux/gitolite.CentOS.6/cgit_gitolite.fc'
  }
  selinux::policy{
    'cgit_gitolite':
      te_source => 'puppet:///modules/cgit/selinux/gitolite/cgit_gitolite.te',
      fc_source => $fc_source,
      fc_file   => true,
      require   => Package['cgit'],
      before    => Service['apache'],
  }
}
