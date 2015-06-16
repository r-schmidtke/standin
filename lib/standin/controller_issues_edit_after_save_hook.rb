module StandIn
  class ControllerIssuesEditAfterSaveHook < Redmine::Hook::ViewListener

    
    def controller_issues_edit_after_save(context={ })
      relevant_users = []
      if(Setting.plugin_standin['notify_watchers'] == "true")
        relevant_users.concat(context[:issue].watchers.collect(&:user))
      end
      if(Setting.plugin_standin['notify_author'] == "true")
        relevant_users << User.find_by_id(context[:issue].author_id) unless context[:issue].author_id == nil
      end
      if(Setting.plugin_standin['notify_assignee'] == "true")
        #this part checks if the assignee is a group
        if(User.find_by_id(context[:issue].assigned_to_id) != nil)
          relevant_users << User.find_by_id(context[:issue].assigned_to_id) unless context[:issue].assigned_to_id == nil
        else (Group.find_by_id(context[:issue].assigned_to_id) != nil)
          relevant_users.concat(Group.find_by_id(context[:issue].assigned_to_id).users)
        end
      end
      
      notify_these_ids = []

      relevant_users.uniq.each do |user|
        if user.pref[:proxy_user_id] != 0
          notify_these_ids << user.pref[:proxy_user_id]
        end
      end
      
      #trim all users that are going to be notified anyways
      relevant_users.uniq.each do |user|
        notify_these_ids.delete(user.id)
      end

      notify_these_ids.uniq.each do |id|
        tempmail = Mailer.issue_edit( context[:journal], [User.find_by_id(id)] , [] )
        tempmail.subject << l("holidays.mail_subject_append")
        tempmail.deliver
      end

    end
  
  end
end