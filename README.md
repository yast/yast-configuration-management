# YaST Configuration Management

This module allows AutoYaST2 to delegate part of the configuration to a
[Software Configuration Management](https://en.wikipedia.org/wiki/Software_configuration_management)
system. Salt and Puppet are supported.

## How it works

The module will take care of:

* Installing needed packages.
* Retrieving authentication keys.
* Updating configuration if needed.
* Applying configuration during AutoYaST 2nd stage.

## Example

### Client/master

```xml
<configuration_management>
  <type>salt</type> <!-- you can use "puppet" -->
  <master>my-salt-server.example.net</master>
  <auth_attempts config:type="integer">5</auth_attempts>
  <auth_time_out config:type="integer">10</auth_time_out>
  <keys_url>usb:/</keys_url> <!-- you can use HTTP, FTP... -->
</configuration_management>
```

### Masterless mode

```xml
<configuration_management>
  <type>salt</type> <!-- you can use "puppet" -->
  <states_url>http://myserver.example.net/states.tgz</states_url>
  <pillar_url>http://myserver.example.net/pillar.tgz</pillar_url> <!-- optional -->
</configuration_management>
```

## Supported systems

### Salt

In this case, `salt-minion` package will be installed. If a `master`
is set in the AutoYaST profile, `/etc/salt/minion` will be
updated. Finally, `salt-call` will be used to apply the configuration.

### Puppet

In this case, `puppet` package will be installed. If a `master`
is set in the AutoYaST profile, `/etc/puppet/puppet.conf` will be
updated. Finally, `puppet agent` will be used to apply the configuration.

## Advanced options

To set up advanced options you can use the
[AutoYaST file element](https://www.suse.com/documentation/sles-12/singlehtml/book_autoyast/book_autoyast.html#createprofile.completeconf).
