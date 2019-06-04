FAYE_TOKEN = SecureRandom.base64(2048)

def events_url
  "#{request.protocol}#{request.host_with_port}/events"
end

def game_events_path(game_id)
  '/games/' + game_id.to_s
  end

def player_events_path(player_id)
  '/players/' + player_id.to_s
end

class FayeFilterSubscribe
  def incoming(message, callback)
    if message['channel'] == '/meta/subscribe'
      subscription = message['subscription']
      user_id = message['ext'] && message['ext']['user_id'] || ''
      user_token = message['ext'] && message['ext']['user_token'] || ''
      if user_token != FayeFilterSubscribe.user_token(subscription, user_id)
        puts 'Invalid user token: ' + user_token + ' for user_id ' + user_id.to_s + ' and subscription ' + message['subscription']
        message['error'] = 'Invalid user token.'
      end
    end
    callback.call(message);
  end

  def self.user_token(subscription, user_id)
    OpenSSL::HMAC.hexdigest(OpenSSL::Digest::Digest.new('sha256'), FAYE_TOKEN, subscription.to_s + '-' + user_id.to_s)
  end
end

class FayeClientAuth
  def outgoing(message, callback)
    message['ext'] ||= {}
    message['ext']['server_token'] = FAYE_TOKEN
    callback.call(message)
  end
end

class FayeServerAuth
  def incoming(message, callback)
    if message['channel'] !~ %r{^/meta/}
      token = message['ext'] && message['ext']['server_token'] || ''
      if token != FAYE_TOKEN
        puts 'Invalid server token: ' + token
        message['error'] = 'Invalid server token.'
      end
    end
    callback.call(message)
  end

  def outgoing(message, callback)
    if message['ext']
      message['ext'].delete('server_token')
    end
    callback.call(message)
  end
end

class FayeNoWildcards
    def incoming(message, callback)
      if message['channel'] == '/meta/subscribe' && message['subscription'] =~ /\*/
        puts "Not allowing: " + message['subscription']
        message['error'] = 'Wildcard subscriptions not allowed'
      end
      callback.call(message);
  end
end