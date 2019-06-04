ENV["RAILS_ENV"] = "test"
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'
require 'factory_girl'

class ActiveSupport::TestCase
  Factory.sequence :login do |n|
    "guy#{n}"
  end

  Factory.sequence :email do |n|
    "guy#{n}@guy.com"
  end

  Factory.define :user do |f|
    f.login { Factory.next(:email) }
    f.email { Factory.next(:email) }
    f.password 'password'
    f.password_confirmation 'password'
  end

  Factory.define :game do |f|
    f.creator { |c| c.association(:user) }
    f.is_open_invitation false
    f.is_private false
    f.player_limit 1
    f.round_limit 1
  end

  Factory.define :player do |f|
    f.association :user
    f.association :game
    f.position
    f.color
  end

  Factory.define :sentence, :class => Play do |f|
    f.player
    f.add_attribute :sequence
    f.position
    f.sentence 'This is a test sentence.'
  end

  Factory.define :drawing, :class => Play do |f|
    f.player
    f.add_attribute :sequence
    f.position
    f.picture { |p| p.association(:picture) }
  end

  Factory.define :play do |f|
    f.player
    f.add_attribute :sequence
    f.position
    f.sentence
    f.picture
  end
  
  Factory.define :picture, :class => Picture do |f|
    f.image_file_name 'C:\no-image.jpg'
    f.image_content_type 'image/jpeg'
    f.image_file_size 200
    f.image_height 50
    f.image_width 50
  end
end
