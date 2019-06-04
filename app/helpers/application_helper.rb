module ApplicationHelper
  include ActionView::Helpers::JavaScriptHelper
  def title(page_title)
    content_for(:title) { page_title }
  end

  def back_or_default_path(default)
    if UserSession.find
      return session[:return_to_logged_in] || session[:return_to] || default
    else
      return session[:return_to_logged_out] || session[:return_to] || default
    end
  end

  def broadcast(server, channel, value = nil, &block)
    client = Faye::Client.new(server)
    client.add_extension(FayeClientAuth.new)
    value ||= capture(&block)
    client.publish(channel, value)
  end

  def update_payer_lists(game)
    game.players.each { |player|
      broadcast events_url, player_events_path(player.id),
        '$("#players").html("'+ escape_javascript( render_to_string :partial => 'games/players', :locals => { :game => game, :user => player.user } ) + '");
        var stylesheet = $("#game_stylesheet")[0];
        var h = stylesheet.href.replace(/(&|\\?)forceReload=d /,"");
        stylesheet.href = h + (h.indexOf("?") >= 0 ? "&" : "?") + "forceReload=" + (new Date().valueOf());'
    }
  end

  def image_url(image)
    "https://thepapergame.herokuapp.com#{image_path(image)}"
  end

  def semantic_search_form_for(*args, &block)
    opts = args.extract_options!
    opts[:builder] = Formtastic::FormBuilder

    # add the default form class
    # (works whether existing class is a String like
    # "foo bar" or an Array like ["foo", "bar"])
    opts[:html] ||= {}
    opts[:html][:class] ||= []
    opts[:html][:class] << ' ' if opts[:html][:class].is_a? String
    opts[:html][:class] << Formtastic::Helpers::FormHelper.default_form_class

    search_form_for(*args, opts, &block)
  end
end