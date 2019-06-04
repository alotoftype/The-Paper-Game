Rails.application.config.middleware.use OmniAuth::Builder do
    #provider :twitter, 'CONSUMER_KEY', 'CONSUMER_SECRET'
    
    if Rails.env == "development"
      provider :facebook, '429934500397022', 'fb8a52e87de21ba5071664ae72bd0177', { :client_options => { :ssl => { :verify => false } } }
    else
      provider :facebook, '429934500397022', 'fb8a52e87de21ba5071664ae72bd0177'
    end
end