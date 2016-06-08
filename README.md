# YaST SCM

This module allows AutoYaST2 to delegate part of the configuration to a
[Configuration Management System](https://en.wikipedia.org/wiki/Software_configuration_management)
(SCM). At this time, only Salt is supported, but it should be pretty
easy to extend it to support Chef or Puppet.

At this time, the module is only a simple proof of concept and is not
ready for prime time.

## How it works

The module will take care of:

* Installing needed packages.
* Retrieving authentication keys (not implemented yet).
* Updating configuration if needed.
* Applying configuration during AutoYaST 2nd stage.

## Example

```xml
<scm>
  <type>salt</type>
  <master>my-salt-server.example.net</master>
  <auth_retries config:type="integer">5</auth_retries>
  <auth_timeout config:type="integer">10</auth_timeout>
</scm>
```

## Supported systems

### Salt

In this case, `salt-minion` package will be installed. If a `master`
is set in the AutoYaST profile, `/etc/salt/minion` will be
updated. Finally, `salt-call` will be used to apply the configuration.

To set up other options in `/etc/salt/minion`, the
[AutoYaST file element](https://www.suse.com/documentation/sles-12/singlehtml/book_autoyast/book_autoyast.html#createprofile.completeconf)
should be used.
