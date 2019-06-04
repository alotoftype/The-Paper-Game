class Notifier < ActionMailer::Base
  default from: 'thepapergame@wcwedin.com'
  helper :application

  def login_reminder(user)
    @login = user.login
    mail(
        :subject => 'The Paper Game Login Reminder',
        :to => "#{user.login} <#{user.email}>"
    )
  end

  def password_reset_instructions(user)
    @password_reset_url = edit_account_password_reset_url(user.perishable_token)
    mail(
        :subject => 'The Paper Game Password Reset',
        :to => "#{user.login} <#{user.email}>"
    )
  end

  def password_changed_notification(user)
    mail(
        :subject => 'The Paper Game Password Changed',
        :to => "#{user.login} <#{user.email}>"
    )
  end

  def email_confirmation_instructions(user)
    @account_activation_url = confirm_account_url(user.perishable_token)
    mail(
      :subject => 'The Paper Game Email Confirmation',
      :to => "#{user.login} <#{user.email}>"
    )
  end

  def welcome(user)
    @root_url = root_url
    mail(
        :subject => 'Welcome to The Paper Game!',
        :to => "#{user.login} <#{user.email}>"
    )
  end

  def daily_digest(user)
    @games = user['games']
    @login = user['login']
    mail(
      :subject => 'The Paper Game Daily Digest',
      :to => "#{user['login']} <#{user['email']}>"
    )
  end

  def game_complete(game, user)
    @game = game
    mail(
      :subject => 'The Paper Game: A Game Has Just Finished!',
      :to => "#{user.login} <#{user.email}>"
    )
  end
end