# TODO: bugs, missing features and incompatible parts

## library/setup-openwrt

### Missing variables:
* `ansible_lsb`
* `ansible_selinux`
* `ansible_date_time`
* `ansible_memory_mb`
* `ansible_devices`
* `ansible_distribution_major_version`
* `ansible_os_family`
* `ansible_ssh_host_key_{dsa,ecdsa,rsa}_public`
* `ansible_system_vendor`
* `ansible_fips`
* `ansible_form_factor`
* `ansible_gather_subset`
* `ansible_processor`
* `ansible_processor_{cores,count,threads_per_core,vcpus}`
* `ansible_product_{name,serial,uuid,version}`
* `ansible_userspace_bits`
* `ansible_virtualization_{role,type}`
* bonding support for interfaces

### Missing functionality:
Implement module options `fact_path`, `filter`, `gather_subset`,
`gather_timeout`.

## action_plugins/setup.py
### Bugs:

* changes C.DEFAULT_SCP_IF_SSH which should be constant. Works but there 
should be a better way to do this.

## library/stat.lua
### Bugs:
* implement SHA2 and SHA3 sums (argument `checksum_algorithm`)
* check for `sha1sum` binary
* implement MIME checking, check for `file` binary
  `mime=dict(default=False, type='bool', aliases=['mime_type', 'mime-type']),`
* use `supports_check_mode`
* add nixio switch for MD5/SHA1:
```
    local fd=io.open(args['path'])
    local file_content=fd:read("*a")
    fd:close()
    local md5=nixio.crypto.hash(md5)
    CryptoHash.update(md5,file_content)
    print(CryptoHash.final(md5)
```
