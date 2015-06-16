class AddProxyUser < ActiveRecord::Migration
  def self.up
    add_column :user_preferences, :proxy_user_id, :integer, :default => 0
  end

  def self.down
    remove_column :user_preferences, :proxy_user_id
  end

end
