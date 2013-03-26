# selinux related things
class cgit::vhosts::selinux {
  include gitolite::daemon::selinux::web

  selinux::policy{
    'cgit_gitolite':
      te_source => 'puppet:///modules/cgit/selinux/gitolite/cgit_gitolite.te',
      fc_source => 'puppet:///modules/cgit/selinux/gitolite/cgit_gitolite.fc',
      require   => Package['cgit'],
      before    => Service['apache'],
  }
}
