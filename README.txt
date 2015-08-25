# standin
Installation: 
    1. Place this plugin into the plugin folder of your redmine installation
    2. Run "rake redmine:plugins:migrate RAILS_ENV=production"
    3. Restart your websever
    
Configuration:
    Configure the Plugin under Administration>Plugins to choose who will get Stand-In notifications
    
Usage:
    Users can choose a stand-in under My_account>Preferences>Stand-i
    
Testing:
    Run "RAILS_ENV=test db:drop db:create db:migrate redmine:plugins:migrate" to  prepare the database for testing
    
    
