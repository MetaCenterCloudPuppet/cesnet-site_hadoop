# == Class site_hadoop::devel::hadoop
# Local post-installation steps for Hadoop for testing in Vagrant.
class site_hadoop::devel::hadoop {
  hadoop::kinit{'vagrant-kinit':
    touchfile => 'vagrant-user-created',
  }
  ->
  hadoop::mkdir{'/user/vagrant':
    owner     => 'vagrant',
    group     => 'hadoop',
    mode      => '0750',
    touchfile => 'vagrant-user-created',
  }
  ->
  hadoop::kdestroy{'vagrant-kdestroy':
    touchfile => 'vagrant-user-created',
    touch     => true,
  }
}
