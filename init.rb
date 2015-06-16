require_dependency 'standin/hooks'
require_dependency 'standin/controller_issues_edit_after_save_hook'
require_dependency 'standin/controller_issues_new_after_save_hook'


Redmine::Plugin.register :standin do
  name 'Stand-in Plugin'
  author 'Robin Schmidtke'
  description 'Choose and notify stand-ins for single users'
  version '0.0.2'

  settings :default => {'empty' => true}, :partial => 'settings/standin_settings'
end


