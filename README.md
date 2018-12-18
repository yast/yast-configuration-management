# YaST Configuration Management

[![Build Status](https://travis-ci.org/yast/yast-configuration-management.svg?branch=master)](
  https://travis-ci.org/yast/yast-configuration-management)
[![Coverage Status](https://coveralls.io/repos/github/yast/yast-configuration-management/badge.svg?branch=master)](
  https://coveralls.io/github/yast/yast-configuration-management?branch=master)
[![Code Climate](https://codeclimate.com/github/yast/yast-configuration-management/badges/gpa.svg)](
  https://codeclimate.com/github/yast/yast-configuration-management)
[![Issue Count](https://codeclimate.com/github/yast/yast-configuration-management/badges/issue_count.svg)](
  https://codeclimate.com/github/yast/yast-configuration-management/issues)

This module allows AutoYaST2 and Firstboot to delegate part of the configuration to a [Software
Configuration Management](https://en.wikipedia.org/wiki/Software_configuration_management) system.
Salt and Puppet are supported.

## How It Works

Basically, this module takes care of setting up the selected configuration management system (Salt
or Puppet) and running it in order to update the system's configuration. It supports working on
client/master or masterless modes and it can be combined with AutoYaST and Yast Firstboot. Even a
standalone mode is available.

Depending on the module's configuration, it will take care of:

* Installing the required packages.
* Retrieving authentication keys (when running in client/server mode).
* Fetching any additional data which may be needed (Salt states, pillars or formulas or Puppet
  modules).
* Updating Salt/Puppet configuration and running them.

## Example

YaST Configuration Management needs some configuration in order to know how to proceed. The snippets
below can be embedded into an AutoYaST profile or in the Firstboot configuration.

### Client/Server

When running in client/server mode, the configuration management system will need to connect to a
master server. For authentication, the client must use a pair of public/private keys which can be
stored on a server, a hard drive or even on an USB stick. Alternatively, the user might prefer to
let the client generate a new pair of keys and authorize them on the fly.

```xml
<configuration_management>
  <type>salt</type> <!-- you can use "puppet" too -->
  <master>my-salt-server.example.net</master>
  <auth_attempts config:type="integer">5</auth_attempts>
  <auth_time_out config:type="integer">10</auth_time_out>
  <keys_url>usb:/</keys_url> <!-- you can use HTTP, FTP... -->
</configuration_management>
```

### Masterless Mode

The good thing about running on masterless mode is that you do not need to set up a master server.
In that case, you can instruct YaST Configuration Management to retrieve the required data from
elsewhere.

```xml
<configuration_management>
  <type>salt</type> <!-- you can use "puppet" -->
  <states_url>http://myserver.example.net/states.tgz</states_url>
  <pillar_url>http://myserver.example.net/pillar.tgz</pillar_url> <!-- optional -->
</configuration_management>
```

## Firstboot Integration

The Firstboot module offers integration with YaST Configuration Management through a client called
`firstboot_configuration_management`. So in order to use this module in firstboot you need to write
a `<configuration_management/>` section containing the configuration options and add the client to
the required workflow. In the example below, only the relevant parts are shown:

*WARNING: During firstboot, only Salt is supported.*

```
<?xml version="1.0"?>
<productDefines xmlns="http://www.suse.com/1.0/yast2ns" 
  xmlns:config="http://www.suse.com/1.0/configns">

  <configuration_management>
      <type>salt</type>
      <!-- Default Salt Formulas root directories -->
      <formulas_roots config:type="list">
        <formula_root>/usr/share/susemanager/formulas/metadata</formula_root>
        <formula_root>/srv/formula_metadata</formula_root>
      </formulas_roots>
      <!-- Default Salt Formulas state directories -->
      <states_roots config:type="list">
        <state_root>/usr/share/susemanager/formulas/states</state_root>
      </states_roots>
      <!-- Default Salt Formulas pillar data directory  -->
      <pillar_root>/srv/susemanager/formula_data</pillar_root>
  </configuration_management>

  <!-- more stuff -->

  <workflows  config:type="list">
    <workflow>
      <stage>firstboot</stage>
      <label>Configuration</label>
      <mode>installation</mode>
      <modules  config:type="list">
        <!-- other modules -->
        <module>
          <label>Finish Setup</label>
          <name>firstboot_configuration_management</name>
        </module>
      </modules>
      <!-- and more modules -->
    </workflow>
  </workflows>
</productDefines>
```

## Supported Systems

### Salt

In this case, `salt-minion` package will be installed. If a `master`
is set in the AutoYaST profile, `/etc/salt/minion` will be
updated. Finally, `salt-call` will be used to apply the configuration.

### Puppet

In this case, `puppet` package will be installed. If a `master`
is set in the AutoYaST profile, `/etc/puppet/puppet.conf` will be
updated. Finally, `puppet agent` will be used to apply the configuration.

## Options Reference

Name           | Type         | Mode       | Description
---            | ---          | ---        | ---
type           | string       | all        | Configuration Management System. Only `salt` is supported
master         | string       | client     | Master server
auth_attempts  | integer      | client     | Number of attempts when connecting to the master server
auth_time_out  | integer      | client     | Time between attempts to connect to the master server
keys_url       | string       | masterless | URL to get authentication keys from
formulas_roots | list(string) | all        | List of directories to search for Salt formulas
states_roots   | list(string) | all        | List of directories to search for Salt states
pillar_root    | string       | all        | Path to write the Salt Pillar content
pillar_url     | string       | masterless | URL to get Pillar content from
states_url     | string       | masterless | URL to get the Salt states from
enabled_states | list(string) | masterless | List of states/formulas to apply
enable_service | boolean      | client     | Enable the configuration management service at the end
