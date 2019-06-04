//= require jquery
//= require jquery_ujs
//= require jquery.form
//= require jquery.remotipart
//= require rails.validations
//= require js-routes
//= require jquery.autosize
//= require jquery.mousewheel
//= require jquery.jscrollpane
//= require array-tools
//= require math-tools
//= require complex
//= require spline
//= require wColorPicker
//= require drawing
//= require game.updater

// Scrolls to the provided element.
(function($) {
  "use strict";
  $.fn.goTo = function() {
      $('html, body').animate({
          scrollTop: $(this).offset().top + 'px'
      }, 'fast');
      return this; // for chaining...
  };
})(jQuery);


// Initialize chat scroll pane (after a short delay to allow assets to load.
$(function() {
  "use strict";
	var scrollPane = $('.scroll_pane').jScrollPane({
		stickToBottom: true,
		maintainPosition: true,
		contentWidth: '0px'
    }).data('jsp');

	window.setTimeout(function ()
	{
		if (scrollPane) {
			scrollPane.reinitialise();
			scrollPane.scrollToBottom(false);
		}
	}, 500);


	$(window).resize(function() {
      if (scrollPane) {
        scrollPane.reinitialise();
        scrollPane.scrollToBottom(false);
      }
	});
});

// Make enter submit chat messages.
$(function() {
  'use strict';
  $('#game_message_message').keydown(function(e) {
    if (e.keyCode === 13 && !e.shiftKey) {
      e.preventDefault();
      if ($('#new_game_message button[type="submit"][disabled]').length === 0)
      {
        $(this.form).trigger('submit.rails');
      }
    }
    return true;
  });
});

// Set up global mouse button tracking and initialize drawing pads.
$(function () {
  "use strict";
	trackLeftMouseButtonState();
	$(".drawing_pad").each(function () { new DrawingPad($(this)); });
});

// Automatic textarea resizing
$(function () {
	'use strict';
	$('#play_sentence, #game_message_message').autosize();
});

// Abandoned sentence warning
$(function() {
	"use strict";
	window.onbeforeunload = function()
	{
		if ($('#play_sentence').val() !== undefined && $('#play_sentence').val() !== '') {
			return "You were in the middle of something!";
		}
	};
});

// Upload image preview
function previewSelectedImageFile(e) {
	"use strict";
	var canvas = $('#play_upload_image_preview').get()[0];
	if (canvas === undefined) {
		return;
	}
	var ctx = canvas.getContext('2d');
	var img = new Image();
	img.onload = function() {
		var targetHeight = Math.min(canvas.height, img.height);
		var targetWidth = img.width  / img.height * targetHeight;
		canvas.width = targetWidth;
		ctx.clearRect(0, 0, canvas.width, canvas.height);
		ctx.drawImage(img, 0, 0, canvas.width, canvas.height);
		canvas.style.display = "block";
	};
	img.onerror = function() {
		canvas.style.display = "none";
	};
	img.src = URL.createObjectURL(e.target.files[0]);
}

$(function () {
	"use strict";
	$('#play_picture_attributes_image').on('change', previewSelectedImageFile);
});