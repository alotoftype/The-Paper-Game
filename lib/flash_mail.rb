# By Henrik Nyh <http://henrik.nyh.se> 2007-06-29
# http://henrik.nyh.se/2007/06/flash-outgoing-mail-in-ruby-on-rails-development
# Free to modify and redistribute with due credit.

module FlashMail
  module ControllerTracking
    def self.included(action_controller)
      action_controller.instance_eval do
        before_filter  :set_current_controller
        cattr_accessor :current_controller
      end
    end

    protected

    def set_current_controller
      ApplicationController.current_controller = self
    end
  end

  module Delivery

    def self.included(mail_message)
      mail_message.instance_eval do
        alias_method_chain :deliver, :flash
      end
    end

    def deliver_with_flash(*args)
      deliver_without_flash(*args)
      if controller = ApplicationController.current_controller
        controller.instance_eval { flash.now[:mail] = ActionMailer::Base.deliveries.last.body.to_s.html_safe }
      end
    end

  end
end

Mail::Message.send :include, FlashMail::Delivery
ActionController::Base.send :include, FlashMail::ControllerTracking