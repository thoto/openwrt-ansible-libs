from pprint import pformat
from ansible.plugins.action import ActionBase
from ansible import constants as C

class ActionModule(ActionBase):
    def _install_lua_json(self):
        ''' checks if json4lua package is present or install it otherwise '''
        lua_json=self._low_level_execute_command("lua -e \"require('json')\"")
        if lua_json["rc"]==0:
            return {}

        self._display.vv("Installing json4lua ...")
        opkg_version=self._low_level_execute_command("opkg --version")
        if opkg_version["rc"]!=0:
            return {"failed": True,
                    "msg": "no opkg binary found, cannot install json4lua"}

        opkg_find=self._low_level_execute_command("opkg find json4lua")
        if opkg_find["stdout"]=="":
            self._display.vv("json4lua package not found: update cache ...")
            self._low_level_execute_command("opkg update") # fire and forget

        opkg_inst=self._low_level_execute_command(
                "opkg install json4lua||exit 1")
        if opkg_inst["rc"]==1:
            return {"failed": True, "msg": "cannot install json4lua package:\n"+                    "\tinstall failed with:\n"+opkg_inst["stdout"]}
        self._display.vv("... done.")
        return {}

    def run(self, tmp=None, task_vars=None, **kwargs):
        ''' runs standard setup module or custom setup-openwrt if no python
        is present on this system '''
        if task_vars is None:
            task_vars = dict()

        result = super(ActionModule, self).run(tmp, task_vars)

        py_version=self._low_level_execute_command("python -V")

        # run lua module if either python is not installed or
        # ansible_distribution hostvar is set on host
        if py_version["rc"]!=0 or \
                ("ansible_distribution" in task_vars \
                    and task_vars["ansible_distribution"]=='OpenWRT'):
            # check for json4lua package required for module
            lua_install=self._install_lua_json()
            if "failed" in lua_install and lua_install["failed"]:
                result.update(lua_install)
            else:
                # use scp on OpenWRT. FIXME: does change constant!
                orig_sftp=C.DEFAULT_SCP_IF_SSH
                C.DEFAULT_SCP_IF_SSH=True
                result.update(self._execute_module(module_name='setup-openwrt',
                    module_args=self._task.args, task_vars=task_vars))
                C.DEFAULT_SCP_IF_SSH=orig_sftp
        else:
            # this is an standard host with python installed
            result.update(self._execute_module(module_name='setup',
                module_args=self._task.args, task_vars=task_vars))

        return result
