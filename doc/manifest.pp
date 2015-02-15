include site_hadoop

# if to enable autoupdates
class{'site_hadoop::autoupdate':
  email => 'email@example.com',
  time  => '0 5 * * *',
}
