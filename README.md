# openwrt-ansible-libs
Ansible libraries written in lua for use with OpenWRT

The reason of these modules is to use ansible to manage an OpenWRT router
without installing python or using the raw module.

Be careful and do not be afraid to patch things. This is my first lua code
so do not expect to see any kind of "good code".

See TODO.md for missing features, incompatibilities and bugs.

## modules and plugins
The `setup-openwrt` module is aimed to be a clone of the python setup module
included in the ansible core modules but written in lua. It does not accept
any parameters yet and misses some functionality.

The `setup.py` action plugin calls either the `setup` or the `setup-openwrt`
module when python is installed on target host or hostvar
`ansible_distribution` is set to `OpenWRT`. This makes
`gather_facts=True` work when executing on an OpenWRT host.
