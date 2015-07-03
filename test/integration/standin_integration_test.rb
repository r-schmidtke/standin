require File.expand_path('../../test_helper', __FILE__)

class StandinIntegrationTest < Redmine::IntegrationTest
  fixtures :projects, :users, :email_addresses, :members, :member_roles, :roles,
           :groups_users,
           :trackers, :projects_trackers,
           :enabled_modules,
           :versions,
           :issue_statuses, :issue_categories, :issue_relations, :workflows,
           :enumerations,
           :issues, :journals, :journal_details,
           :custom_fields, :custom_fields_projects, :custom_fields_trackers, :custom_values,
           :time_entries
  
  #log in as admin and enable plugin settings
  def setup
    log_user('admin', 'admin')
    post "/settings/plugin/standin" , 
         "settings"=>{"notify_watchers"=>"true", 
    	 "notify_author"=>"true", 
    	 "notify_assignee"=>"true"}, 
    	 "commit"=>"Apply"
  end

  #see if the plugin settings page loads
  def test_load_settings_page
  	get "/settings/plugin/standin"
   	assert_response :success
  end

  #set some settings for the plugin and check if they are saved
  def test_save_settings
    post "/settings/plugin/standin" , "settings"=>{"notify_watchers"=>"false", "notify_author"=>"false", "notify_assignee"=>"false"}, "commit"=>"Apply"
    assert_not_equal( Setting.plugin_standin['notify_watchers'], "true" , failure_message = "watchers not saved" )
    assert_not_equal( Setting.plugin_standin['notify_author'], "true" , failure_message = "author not saved" )
    assert_not_equal( Setting.plugin_standin['notify_assignee'], "true" , failure_message = "assignee not saved" )

    post "/settings/plugin/standin" , 
         "settings"=>{"notify_watchers"=>"true", 
    	 "notify_author"=>"true", 
    	 "notify_assignee"=>"true"}, 
    	 "commit"=>"Apply"
    assert_equal( Setting.plugin_standin['notify_watchers'], "true" , failure_message = "watchers not saved" )
    assert_equal( Setting.plugin_standin['notify_author'], "true" , failure_message = "author not saved" )
    assert_equal( Setting.plugin_standin['notify_assignee'], "true" , failure_message = "assignee not saved" )
  end

  #check if proxy_user_id is saved
  def test_save_proxy
  	#send notifications to all
  	post "/settings/plugin/standin" , 
         "settings"=>{"notify_watchers"=>"true", 
    	 "notify_author"=>"true", 
    	 "notify_assignee"=>"true"}, 
    	 "commit"=>"Apply"

    post "/my/account", 
         "commit"=>"Save", 
         "pref"=>{
           "proxy_user_id"=>"3"
         }
    assert_equal(User.find(1).pref[:proxy_user_id], 3, failure_message = "proxy_user_id not saved")
  end

  #check if mailer will send the correct number of additional notifications  
  def test_edit_issue_single    
    #set a stand-in for user 1
    user3pref = User.find(2).pref
    user3pref.proxy_user_id = 1
    assert user3pref.save

    ActionMailer::Base.deliveries.clear

    patch "/issues/1",
    	  "issue"=>{"notes"=>"testaenderung"},
    	  "commit"=>"Sumbit",
    	  "id"=>"1"
    sleep(1)
    #1 normal notification to author + 1 mail to authors stand-in
    assert_equal 2, ActionMailer::Base.deliveries.size
  end

  def test_edit_issue_single
    #create cain of stand-ins
    user3pref = User.find(2).pref
    user3pref.proxy_user_id = 1
    assert user3pref.save

    user3pref = User.find(1).pref
    user3pref.proxy_user_id = 3
    assert user3pref.save

    user3pref = User.find(3).pref
    user3pref.proxy_user_id = 4
    assert user3pref.save   

    ActionMailer::Base.deliveries.clear

    patch "/issues/1",
    	  "issue"=>{"notes"=>"testaenderung2"},
    	  "commit"=>"Sumbit",
    	  "id"=>"1"    
    sleep(1)

    assert_equal 4, ActionMailer::Base.deliveries.size
  end


  def test_setting_no_mail_to_author
  	post "/settings/plugin/standin" , 
         "settings"=>{"notify_watchers"=>"true", 
    	 "notify_author"=>"false", 
    	 "notify_assignee"=>"true"}, 
    	 "commit"=>"Apply"

    #create cain of stand-ins
    user3pref = User.find(2).pref
    user3pref.proxy_user_id = 1
    assert user3pref.save

    user3pref = User.find(1).pref
    user3pref.proxy_user_id = 3
    assert user3pref.save

    user3pref = User.find(3).pref
    user3pref.proxy_user_id = 4
    assert user3pref.save   

    ActionMailer::Base.deliveries.clear

    patch "/issues/1",
    	  "issue"=>{"notes"=>"testaenderung2"},
    	  "commit"=>"Sumbit",
    	  "id"=>"1"
    sleep(1)

    assert_equal 1, ActionMailer::Base.deliveries.size
  end


end