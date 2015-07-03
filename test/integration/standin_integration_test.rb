require File.expand_path('../../test_helper', __FILE__)

class StandinIntegrationTest < Redmine::IntegrationTest
  fixtures :projects, :users, :email_addresses, :members, :member_roles, :roles, :watchers,
           :groups_users,
           :versions,
           :enumerations,
           :issues, :journals, :journal_details

  #log in as admin and enable plugin settings
  def setup
    log_user('admin', 'admin')
    post "/settings/plugin/standin" , 
         "settings"=>{"notify_watchers"=>"true", 
    	 "notify_author"=>"true", 
    	 "notify_assignee"=>"true"}, 
    	 "commit"=>"Apply"
    
    6.times do |i|
      userpref = User.find(i+1).pref
      userpref.proxy_user_id = 0
      assert userpref.save
      usernotifications = User.find(i+1)
      usernotifications.mail_notification = "only_my_events"
      assert usernotifications.save
    end
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
    userpref = User.find(2).pref
    userpref.proxy_user_id = 1
    assert userpref.save

    ActionMailer::Base.deliveries.clear

    patch "/issues/1", 
    	  "issue"=>{"notes"=>"test_edit_issue_single"},
    	  "commit"=>"Sumbit",
    	  "id"=>"1"
    sleep(1)
    #1 normal notification mail + 1 mail to authors stand-in
    assert_equal 2, ActionMailer::Base.deliveries.size
                     
  end



  def test_edit_issue_chain
    #create cain of stand-ins
    userpref = User.find(2).pref
    userpref.proxy_user_id = 1
    assert userpref.save

    userpref = User.find(1).pref
    userpref.proxy_user_id = 4
    assert userpref.save

    userpref = User.find(4).pref
    userpref.proxy_user_id = 5
    assert userpref.save   

    ActionMailer::Base.deliveries.clear

    patch "/issues/1",
    	  "issue"=>{"notes"=>"test_edit_issue_chain"},
    	  "commit"=>"Sumbit",
    	  "id"=>"1"    
    sleep(1)

    assert_equal 4, ActionMailer::Base.deliveries.size
  end

  def test_edit_issue_single_assignee
    #create cain of stand-ins
    userpref = User.find(4).pref
    userpref.proxy_user_id = 5
    assert userpref.save
    tempissue = Issue.find(1)
    tempissue.assigned_to_id = 4
    tempissue.save


    ActionMailer::Base.deliveries.clear

    patch "/issues/1",
    	  "issue"=>{
    	  	"notes"=>"test_edit_issue_single_assignee"},
    	  "commit"=>"Sumbit"
    	      
    sleep(1)

    assert_equal 2, ActionMailer::Base.deliveries.size
  end


  def test_edit_issue_two_watchers
    #create cain of stand-ins
    userpref = User.find(1).pref
    userpref.proxy_user_id = 5
    assert userpref.save
    userpref = User.find(3).pref
    userpref.proxy_user_id = 7
    assert userpref.save
    tempissue = Issue.find(2)
    tempissue.assigned_to_id = ""
    tempissue.author_id = ""
    tempissue.save

    ActionMailer::Base.deliveries.clear

    patch "/issues/2",
    	  "issue"=>{
    	  	"notes"=>"test_edit_issue_two_watchers"},
    	  "commit"=>"Sumbit"
    	      
    sleep(1)

    
    assert_equal 3, ActionMailer::Base.deliveries.size
  end


  def test_setting_no_mail_to_author
  	post "/settings/plugin/standin" , 
         "settings"=>{"notify_watchers"=>"true", 
    	 "notify_author"=>"false", 
    	 "notify_assignee"=>"true"}, 
    	 "commit"=>"Apply"

    #create cain of stand-ins
    userpref = User.find(2).pref
    userpref.proxy_user_id = 1
    assert userpref.save

    userpref = User.find(1).pref
    userpref.proxy_user_id = 3
    assert userpref.save

    userpref = User.find(3).pref
    userpref.proxy_user_id = 4
    assert userpref.save   

    ActionMailer::Base.deliveries.clear

    patch "/issues/1",
    	  "issue"=>{"notes"=>"test_setting_no_mail_to_author"},
    	  "commit"=>"Sumbit",
    	  "id"=>"1"
    sleep(1)

    assert_equal 1, ActionMailer::Base.deliveries.size
  end


  def test_new_issue_multi
    ActionMailer::Base.deliveries.clear

    userpref = User.find(1).pref
    userpref.proxy_user_id = 4
    userpref.save

    userpref = User.find(2).pref
    userpref.proxy_user_id = 3
    userpref.save

    post "/projects/ecookbook/issues",
         "issue"=>{
         	"subject"=>"new test subject",
         	"description"=>"test_new_issue_multi",
         	"status_id"=>"1", 
         	"priority_id"=>"4",
         	"assigned_to_id"=>"2"},
         "commit"=>"Create"
 
    sleep(1)
    #1 mail to author (user 1) + 1 mail to authors stand-in (user 4) + 1 mail to assignees stand-in (user 3)
    assert_equal 3, ActionMailer::Base.deliveries.size
  end
  
end