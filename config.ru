# This file is used by Rack-based servers to start the application.

require ::File.expand_path('../config/environment',  __FILE__)

require 'faye'
use Faye::RackAdapter, :mount => '/events', :timeout => 25, :extensions => [FayeServerAuth.new, FayeNoWildcards.new, FayeFilterSubscribe.new]

run Paper::Application