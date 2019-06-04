class UserSession < Authlogic::Session::Base
  include ActiveModel::Conversion
  
  consecutive_failed_logins_limit 15
  failed_login_ban_for 2.hours
end