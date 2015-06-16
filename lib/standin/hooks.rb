module StandIn
  class Hooks < Redmine::Hook::ViewListener
    
    render_on :view_my_account_preferences,
              :partial => 'issues/view_my_account_preferences'
  end
end
