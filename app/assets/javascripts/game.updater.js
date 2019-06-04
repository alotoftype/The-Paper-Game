var SubscribeToGameUpdates = function (game_id, events_url, game_events_path) {
  "use strict";
  var faye = new Faye.Client(events_url);
  faye.disable('websocket');
  faye.disable('eventsource');
  faye.addExtension({
    outgoing: function (message, callback) {
      if (message.channel === '/meta/subscribe') {
        message.ext = message.ext || {};
        $.ajax({
          url: Routes.game_user_token_path(game_id, { "format": "json" }),
          cache: false,
          success: function (data) {
            message.ext.user_id = data.user_id;
            message.ext.user_token = data.user_token;
            callback(message);
          }
        });
      } else {
        callback(message);
      }
    }
  });

  faye.subscribe(game_events_path, function (data) {
    eval(data);
  });
};

var SubscribeToPlayerUpdates = function (player_id, events_url, player_events_path) {
	"use strict";
	var faye = new Faye.Client(events_url);
	faye.disable('websocket');
	faye.disable('eventsource');
	faye.addExtension({
		outgoing: function (message, callback) {
			if (message.channel === '/meta/subscribe') {
				message.ext = message.ext || {};
				$.ajax({
					url: Routes.player_user_token_path(player_id, { "format": "json" }),
					cache: false,
					success: function (data) {
						message.ext.user_id = data.user_id;
						message.ext.user_token = data.user_token;
						callback(message);
					}
				});
			} else {
				callback(message);
			}
		}
	});

	faye.subscribe(player_events_path, function (data) {
		eval(data);
	});
};