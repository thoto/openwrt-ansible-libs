from ansible.plugins.action import ActionBase

class ActionModule(ActionBase):

    def __init__(self, task, connection, play_context, loader, templar,\
            shared_loader_obj):
        super(ActionModule, self).__init__(task, connection, play_context,\
                loader, templar, shared_loader_obj)

    def run(self, tmp=None, task_vars=None, **kwargs):
        ''' runs standard copy module or custom copy.lua/copy.sh if 
        ansible_distribution is set OpenWRT '''
        if task_vars is None:
            task_vars = dict()

        result = super(ActionModule, self).run(tmp, task_vars)

        old_pref=self._connection.module_implementation_preferences
        if "ansible_distribution" in task_vars \
                and task_vars["ansible_distribution"]=='OpenWRT':
            self._connection.module_implementation_preferences=(".lua",".sh","")
        else:
            self._connection.module_implementation_preferences=(".py","")

        self._copyplugin=self._shared_loader_obj.action_loader.get("copy",\
                self._task, self._connection, self._play_context,\
                self._loader, self._templar, self._shared_loader_obj)
        
        result.update(self._copyplugin.run(tmp,task_vars))

        self._connection.module_implementation_preferences=old_pref

        return result
