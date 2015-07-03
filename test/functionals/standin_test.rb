require File.expand_path('../../test_helper', __FILE__)

class StandinTest < ActionController::TestCase
  fixtures :users, :projects, :issues
  
  def test_load_settings_page
  	get "/settings/plugin/standin"
  	assert_response :success
  end



end