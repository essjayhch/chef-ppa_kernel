# ppa_kernel Cookbook

This cookbook installs and maintains upstream kernel debians maintained on the ppa kernel website.

These are not installable via the usual aptitude modules.

## Requirements


e.g.
### Platforms

- Debian
- Ubuntu

### Chef

- Chef 12.0 or later


## Syntax
A **ppa_kernel_version** resource block manages the kernel on a node, typically by installing it. The simplest use of the `dpkg_package` resource is:

```ruby
ppa_kernel_version 'version'
```
which will install the named version of the kernel from the ppa repository using all of the default options and the default action (`:add`).

The full syntax for all of the properties that are available to the **ppa_kernel_version** resource is:

```ruby
ppa_kernel_version 'kernel_version' do
  version           String # defaults to 'kernel_version' if not specified
  type              String # defaults to 'generic' if not specified
  headers           Boolean # defaults to 'true' if not specified
  reboot_on_install Boolean # defaults to 'false' if not specified
  action            Symbol # defaults to :add if not specified
end
```
where
* `ppa_kernel_version` tells the chef-client to manage a kernel version
* `'kernel_version'` is the major.minor.increment version of the kernel release tree
* `action` identifies which steps the chef-client will take to bring the node into the desired state
* `type`, `headers` and `reboot_on_install` are properties of this resource, with the Ruby type shown. See "Properties" section below for more information about all the properties that may be used with this resource.

## Actions
This resource has the following actions:

`:add`
    Default. Installs a kernel verion.

## Properties
This resource has the following properties:

`type`

**Ruby Type:** String

Specifies the type of kernel to be installed (typically included are 'generic' and 'lowlatency')

`headers`

**Ruby Types:** TrueClass, FalseClass

Optionally install the associated Kernel Headers package for this kernel version. Default value: `true`

`reboot_on_install`

**Ruby Types:** TrueClass, FalseClass

Optionally reboot the system immediately on install or update of kernel verion. Default value: `false`

## Examples

**Install a given kernel version without headers**
```ruby
ppa_kernel_version '4.1.2' do
  action :add
  headers false
end
```

**Install a give kernel version and trigger a reboot**
```ruby
ppa_kernel_version '4.4.2' do
  action :add
  reboot_on_install true
end
```

## Contributing

1. Fork the repository on Github
2. Create a named feature branch (like `add_component_x`)
3. Write your change
4. Write tests for your change (if applicable)
5. Run the tests, ensuring they all pass
6. Submit a Pull Request using Github

## License and Authors

Authors: Stuart Harland essjayhch@gmail.com, Livelink Technology ltd infra@livelinktechnology.net

