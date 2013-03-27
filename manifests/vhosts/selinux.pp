# selinux related things
class cgit::vhosts::selinux {
  include gitolite::daemon::selinux::web

  selinux::policy{
    'cgit_gitolite':
      te_source => 'puppet:///modules/cgit/selinux/gitolite/cgit_gitolite.te',
      fc_source => 'puppet:///modules/cgit/selinux/gitolite/cgit_gitolite.fc',
      fc_file   => true,
      require   => Package['cgit'],
      before    => Service['apache'],
  }
  selboolean{
    'git_cgit_read_gitosis_content':
      value       => 'on',
      persistent  => true;
  }
}
