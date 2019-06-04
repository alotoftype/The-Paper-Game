class NotificationsController < ApplicationController
  def send_daily_digest
    send_time = Time.now

    Sequence.bleeding.each { |s| s.bleed!(send_time) }

    @users = Array.new
    User.notifications.each do |notification|
        Notifier.daily_digest(notification[1]).deliver

        user_id = notification[0]
        user = User.find(user_id)
        user.daily_digest_last_sent = send_time
        user.save
        @users.push user_id
    end
  end
end