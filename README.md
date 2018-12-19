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
* Retrieving authentication keys (when running in client/master mode).
* Fetching any additional data which may be needed (Salt states, pillars or formulas or Puppet
  modules).
* Updating Salt/Puppet configuration and running them.

## Module Configuration

YaST Configuration Management needs some configuration in order to know how to proceed. The snippets
below can be embedded into an AutoYaST profile or in the Firstboot configuration
(`/etc/YaST2/firstboot.xml`).

### Client/Master

When running in client/master mode, the configuration management system will need to connect to a
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

If you do not want to set up a master server, you can instruct YaST Configuration Management to run
in *masterless* mode retrieving the required data from elsewhere.

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

**WARNING: Only Salt is supported in firstboot.**

```xml
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

## Salt Formulas Forms Support

**WARNING: Under development.**

The support for Salt Formulas Forms is still under development. Currently, the module is able to
render the corresponding UI to get user's input, store the information and run Salt accordingly.
However, some stuff is still missing:

* Some basic widgets are not implemented yet (passwords, numbers, etc.).
* Support for nested collections, although simple collections are already working.
* Better integration with Firstboot (supporting stuff like going back or running Salt at the end).
* Good documentation.

## Options Reference

Name            | Type         | Mode       | Description
---             | ---          | ---        | ---
type            | string       | all        | Configuration Management System (`salt` or `puppet`)
master          | string       | client     | Master server (if not set, it will run as masterless
auth_attempts   | integer      | client     | Number of attempts when connecting to the master server
auth_time_out   | integer      | client     | Time between attempts to connect to the master server
enable_services | boolean      | client     | Enable the configuration management service at the end
formulas_roots  | list(string) | all        | List of directories to search for Salt formulas
states_roots    | list(string) | all        | List of directories to search for Salt states
pillar_root     | string       | all        | Path to write the Salt Pillar content
pillar_url      | string       | masterless | URL to get Pillar content from
keys_url        | string       | masterless | URL to get authentication keys from
states_url      | string       | masterless | URL to get the Salt states from
enabled_states  | list(string) | masterless | List of states/formulas to apply
