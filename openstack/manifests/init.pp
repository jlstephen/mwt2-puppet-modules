## Config files for openstack deployment

class openstack::base ( $version = '3.2.1-1.el7') {
  file { '/etc/yum.repos.d/rdo-release.repo':
    source  => "puppet:///modules/openstack/rdo-release.repo",
    owner   => root,
    group   => root,
    require => File['/etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-SIG-Cloud'],
  }
  file { '/etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-SIG-Cloud':
    source  => "puppet:///modules/openstack/RPM-GPG-KEY-CentOS-SIG-Cloud",
    owner   => root,
    group   => root,
  }
  package { 'python-openstackclient':
    ensure  => $version,
    require => File['/etc/yum.repos.d/rdo-release.repo'],
  }

}

class openstack::memcache ( $controller_ip = '10.1.20.0') {
  package { 'memcached': ensure => present }
  package { 'python-memcached': ensure => present }

  service { 'memcached':
    ensure   => true,
    enable   => true,
    require  => Package['memcached'],
  }

  file { '/etc/sysconfig/memcached':
    content  => template('openstack/memcached'),
    owner    => root,
    group    => root,
  }
}

class openstack::controller (
  $controller_mgt_ip = '10.1.20.0',
  $controller_pub_ip = '192.170.227.13',
  $local_ip          = "${::ipaddress}",
  $interfaces        = 'provider:br1',
  $interfaces_flat   = 'provider',
  $interfaces_mtu    = 'provider:9000',
  $rabbitmq,
  $keystone_db,
  $glance_db,
  $nova_db,
  $neutron_db,
  $cinder_db,
  $barbican_db,
  $heat_db,
  $ec2api_db,
  $nova_user,
  $neutron_user,
  $cinder_user,
  $glance_user,
  $metadata_secret,
  $placement_user,
  $barbican_user,
  $heat_user,
  $heat_admin,
  $ec2api_user,
) {

  package { 'openstack-keystone': ensure => present }
  package { 'openstack-glance': ensure => present }
  package { 'openstack-nova-common': ensure => present }
  package { 'openstack-nova-api': ensure => present }
  package { 'openstack-nova-conductor': ensure => present }
  package { 'openstack-nova-console': ensure => present }
  package { 'openstack-nova-novncproxy': ensure => present }
  package { 'openstack-nova-scheduler': ensure => present }
  package { 'openstack-neutron': ensure => present }
  package { 'openstack-neutron-ml2': ensure => present }
  package { 'openstack-neutron-linuxbridge': ensure => present }
  package { 'openstack-cinder': ensure => present }
  package { 'httpd': ensure => present }
  package { 'mod_wsgi': ensure => present }
  package { 'ebtables': ensure => present }
  package { 'openstack-heat-api': ensure => present }
  package { 'openstack-heat-api-cfn': ensure => present }
  package { 'openstack-heat-engine': ensure => present }
  package { 'openstack-ec2-api': ensure => present }

  service { 'httpd':
    ensure    => true,
    enable    => true,
    require   => [ Package['openstack-keystone'], Package['httpd'] ],
  }

  service { 'openstack-glance-api':
    ensure    => true,
    enable    => true,
    require   => [ Package['openstack-glance'],
                   File['/etc/glance/glance-api.conf'],
                   File['/etc/glance/glance-registry.conf'], ],
  }
  service { 'openstack-glance-registry':
    ensure    => true,
    enable    => true,
    require   => [ Package['openstack-glance'],
                   File['/etc/glance/glance-api.conf'],
                   File['/etc/glance/glance-registry.conf'], ],
  }
  service { 'openstack-nova-api':
    ensure    => true,
    enable    => true,
    require   => [ Package['openstack-nova-api'],
                   File['/etc/nova/nova.conf'], ],
  }
  service { 'openstack-nova-consoleauth':
    ensure    => true,
    enable    => true,
    require   => [ Package['openstack-nova-console'],
                   File['/etc/nova/nova.conf'], ],
  }
  service { 'openstack-nova-scheduler':
    ensure    => true,
    enable    => true,
    require   => [ Package['openstack-nova-scheduler'],
                   File['/etc/nova/nova.conf'], ],
  }
  service { 'openstack-nova-conductor':
    ensure    => true,
    enable    => true,
    require   => [ Package['openstack-nova-conductor'],
                   File['/etc/nova/nova.conf'], ],
  }
  service { 'openstack-nova-novncproxy':
    ensure    => true,
    enable    => true,
    require   => [ Package['openstack-nova-novncproxy'],
                   File['/etc/nova/nova.conf'], ],
  }
  service { 'neutron-server':
    ensure    => true,
    enable    => true,
    require   => [ Package['openstack-neutron'],
                   File['/etc/neutron/neutron.conf'], 
                   File['/etc/neutron/plugins/ml2/ml2_conf.ini'], ],
  }
  service { 'neutron-linuxbridge-agent':
    ensure    => true,
    enable    => true,
    require   => [ Package['openstack-neutron-linuxbridge'],
                   File['/etc/neutron/plugins/ml2/linuxbridge_agent.ini'], ],
  }
  service { 'neutron-dhcp-agent':
    ensure    => true,
    enable    => true,
    require   => [ Package['openstack-neutron'],
                   File['/etc/neutron/l3_agent.ini'], ],
  }
  service { 'neutron-metadata-agent':
    ensure    => true,
    enable    => true,
    require   => [ Package['openstack-neutron'],
                   File['/etc/neutron/metadata_agent.ini'], ],
  }
  service { 'neutron-l3-agent':
    ensure    => false,
    enable    => false,
    require   => [ Package['openstack-neutron'],
                   File['/etc/neutron/l3_agent.ini'], ],
  }
  service { 'openstack-cinder-api':
    ensure    => true,
    enable    => true,
    require   => [ Package['openstack-cinder'],
                   File['/etc/cinder/cinder.conf'], ],
  }
  service { 'openstack-cinder-scheduler':
    ensure    => true,
    enable    => true,
    require   => [ Package['openstack-cinder'],
                   File['/etc/cinder/cinder.conf'], ],
  }
  service { 'openstack-heat-api':
    ensure    => true,
    enable    => true,
    require   => [ Package['openstack-heat-api'],
                   File['/etc/heat/heat.conf'], ],
  }
  service { 'openstack-heat-api-cfn':
    ensure    => true,
    enable    => true,
    require   => [ Package['openstack-heat-api-cfn'],
                   File['/etc/heat/heat.conf'], ],
  }
  service { 'openstack-heat-engine':
    ensure    => true,
    enable    => true,
    require   => [ Package['openstack-heat-engine'],
                   File['/etc/heat/heat.conf'], ],
  }
  service { 'openstack-ec2-api':
    ensure    => true,
    enable    => true,
    require   => [ Package['openstack-ec2-api'],
                   File['/etc/ec2api/ec2api.conf'], ],
  }
  service { 'openstack-ec2-api-metadata':
    ensure    => true,
    enable    => true,
    require   => [ Package['openstack-ec2-api'],
                   File['/etc/ec2api/ec2api.conf'], ],
  }

  file { '/etc/neutron/plugin.ini':
    ensure => link,
    target => '/etc/neutron/plugins/ml2/ml2_conf.ini',
  }
  file { '/etc/httpd/conf.d/wsgi-keystone.conf':
    ensure => link,
    target => '/usr/share/keystone/wsgi-keystone.conf',
  }
  file { '/etc/glance/glance-api.conf':
    content => template('openstack/controller/glance-api.conf.erb'),
    owner   => 'root',
    group   => 'glance',
    mode    => '640',
    require => Package['openstack-glance'],
    notify  => [ Service['openstack-glance-api'],
                 Service['openstack-glance-registry'], ],
  }
  file { '/etc/glance/glance-registry.conf':
    content => template('openstack/controller/glance-registry.conf.erb'),
    owner   => 'root',
    group   => 'glance',
    mode    => '640',
    require => Package['openstack-glance'],
    notify  => [ Service['openstack-glance-api'],
                 Service['openstack-glance-registry'], ],
  }
  file { '/etc/nova/nova.conf':
    content => template('openstack/controller/nova.conf.erb'),
    owner   => 'root',
    group   => 'nova',
    mode    => '640',
    require => Package['openstack-nova-common'],
    notify  => [ Service['openstack-nova-api'],
                 Service['openstack-nova-consoleauth'],
                 Service['openstack-nova-scheduler'],
                 Service['openstack-nova-conductor'],
                 Service['openstack-nova-novncproxy'], ],
  }
  file { '/etc/neutron/neutron.conf':
    content => template('openstack/controller/neutron.conf.erb'),
    owner   => 'root',
    group   => 'neutron',
    mode    => '640',
    require => Package['openstack-neutron'],
    notify  => Service['neutron-server'],
  }
  file { '/etc/neutron/plugins/ml2/ml2_conf.ini':
    content => template('openstack/controller/ml2_conf.ini.erb'),
    owner   => 'root',
    group   => 'neutron',
    mode    => '640',
    require => Package['openstack-neutron-ml2'],
    notify  => Service['neutron-server'],
  }
  file { '/etc/neutron/plugins/ml2/linuxbridge_agent.ini':
    content => template('openstack/controller/linuxbridge_agent.ini.erb'),
    owner   => 'root',
    group   => 'neutron',
    mode    => '640',
    require => Package['openstack-neutron-linuxbridge'],
    notify  => Service['neutron-linuxbridge-agent'],
  }
  file { '/etc/neutron/l3_agent.ini':
    content => template('openstack/controller/l3_agent.ini.erb'),
    owner   => 'root',
    group   => 'neutron',
    mode    => '640',
    require => Package['openstack-neutron'],
    notify  => Service['neutron-l3-agent'],
  }
  file { '/etc/neutron/metadata_agent.ini':
    content => template('openstack/controller/metadata_agent.ini.erb'),
    owner   => 'root',
    group   => 'neutron',
    mode    => '640',
    require => Package['openstack-neutron'],
    notify  => Service['neutron-metadata-agent'],
  }
  file { '/etc/cinder/cinder.conf':
    content => template('openstack/controller/cinder.conf.erb'),
    owner   => 'root',
    group   => 'cinder',
    mode    => '640',
    require => Package['openstack-cinder'],
    notify  => [ Service['openstack-cinder-api'],
                 Service['openstack-cinder-scheduler'], ],
  }
  file { '/etc/keystone/keystone.conf':
    content => template('openstack/controller/keystone.conf.erb'),
    owner   => 'root',
    group   => 'keystone',
    mode    => '640',
    require => Package['openstack-keystone'],
  }
  file { '/etc/heat/heat.conf':
    content => template('openstack/controller/heat.conf.erb'),
    owner   => 'root',
    group   => 'heat',
    mode    => '640',
    require => [ Package['openstack-heat-api'],
                 Package['openstack-heat-api-cfn'],
                 Package['openstack-heat-engine'], ],
    notify  => [ Service['openstack-heat-api'],
                 Service['openstack-heat-api-cfn'],
                 Service['openstack-heat-engine'], ],
  }
  file { '/etc/ec2api/ec2api.conf':
    content => template('openstack/controller/ec2api.conf.erb'),
    owner   => 'root',
    group   => 'ec2api',
    mode    => '640',
    require => Package['openstack-ec2-api'],
    notify  => [ Service['openstack-ec2-api'],
                 Service['openstack-ec2-api-metadata'], ],
  }

}

class openstack::compute (
  $controller_mgt_ip = '10.1.20.0',
  $controller_pub_ip = '192.170.227.13',
  $local_ip          = "${::ipaddress}",
  $interfaces        = 'provider:br1',
  $rabbitmq,
  $nova_db,
  $neutron_db,
  $cinder_db,
  $barbican_db,
  $nova_user,
  $neutron_user,
  $cinder_user,
  $metadata_secret,
  $placement_user,
  $barbican_user,
) {

  package { 'openstack-nova-compute': ensure => present }
  package { 'openstack-neutron-linuxbridge': ensure => present }
  package { 'openstack-cinder': ensure => present }
  package { 'libvirt': ensure => present }
  package { 'ebtables' : ensure => present }
  package { 'ipset' : ensure => present }
  package { 'targetcli': ensure => present }
  package { 'python-keystone': ensure => present }
  package { 'lvm2': ensure => present }

  service { 'openstack-nova-compute':
    ensure  => true,
    enable  => true,
    require => [ Package['openstack-nova-compute'],
                 File['/etc/nova/nova.conf'] ],
  }
  service { 'neutron-linuxbridge-agent':
    ensure  => true,
    enable  => true,
    require => [ Package['openstack-neutron-linuxbridge'],
                 File['/etc/neutron/neutron.conf'],
                 File['/etc/neutron/plugins/ml2/linuxbridge_agent.ini'] ],
  }
  service { 'openstack-cinder-volume':
    ensure  => true,
    enable  => true,
    require => [ Package['openstack-cinder'],
                 File['/etc/cinder/cinder.conf'] ],
  }
  service { 'libvirtd':
    ensure  => true,
    enable  => true,
    require => Package['libvirt'],
  }
  service { 'lvm2-lvmetad':
    ensure  => true,
    enable  => true,
    require => Package['lvm2'],
  }
  service { 'target':
    ensure  => true,
    enable  => true,
    require => Package['targetcli'],
  }

  file { '/etc/nova/nova.conf':
    content => template('openstack/compute/nova.conf.erb'),
    owner   => 'root',
    group   => 'nova',
    mode    => '640',
    notify  => Service['openstack-nova-compute'],
  }
  file { '/etc/neutron/neutron.conf':
    content => template('openstack/compute/neutron.conf.erb'),
    owner   => 'root',
    group   => 'neutron',
    mode    => '640',
    notify  => Service['neutron-linuxbridge-agent'],
  }
  file { '/etc/neutron/plugins/ml2/linuxbridge_agent.ini':
    content => template('openstack/compute/linuxbridge_agent.ini.erb'),
    owner   => 'root',
    group   => 'neutron',
    mode    => '640',
    notify  => Service['neutron-linuxbridge-agent'],
  }
  file { '/etc/cinder/cinder.conf':
    content => template('openstack/compute/cinder.conf.erb'),
    owner   => 'root',
    group   => 'cinder',
    mode    => '640',
    notify  => Service['openstack-cinder-volume'],
  }

}
