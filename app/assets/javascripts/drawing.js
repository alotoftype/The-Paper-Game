window.performance = window.performance || {};
window.performance.now =
  window.performance.now ||
  window.performance.mozNow    ||
  window.performance.msNow     ||
  window.performance.oNow      ||
  window.performance.webkitNow ||
  Date.now;

window.requestAnimationFrame =
	window.requestAnimationFrame ||
	window.mozRequestAnimationFrame ||
	window.webkitRequestAnimationFrame ||
	window.msRequestAnimationFrame;

if (!window.requestAnimationFrame) {
	var lastTime = 0;
	var startTime = window.performance.now();
	window.requestAnimationFrame = function(callback, element) {
		'use strict';
		var currTime = window.performance.now();
		var timeToCall = Math.max(0, 16 - (currTime - lastTime));
		var id = window.setTimeout(function() { callback(currTime - startTime); },
			timeToCall);
		lastTime = currTime + timeToCall;
		return id;
	};
}

var leftButtonDown = false;

function trackLeftMouseButtonState() {
  'use strict';

  $(document).mousedown(function (e) {
    // Left mouse button was pressed, set flag
    if (e.which === 1) {
      leftButtonDown = true;
    }
  });
  $(document).mouseup(function (e) {
    // Left mouse button was released, clear flag
    if (e.which === 1) {
      leftButtonDown = false;
    }
  });
}

var DrawingPad = function (drawingPad) {
	'use strict';

	window.onbeforeunload = function()
	{
		if (self.drawingPadUsed) {
			return "You were in the middle of something!";
		}
	};

	var self = this;
	self.drawingPadUsed = false;
	self.canvas = drawingPad.find('canvas')[0];

	self.strokeWidth = 5;
	self.hardness = 1;
	self.opacity = 1;
	self.red = 0;
	self.green = 0;
	self.blue = 0;
	self.tool = "marker";

	// The dot arrays always grow in size to prevent lag between strokes, so we need to track their count manually.
	self.pendingDots = [];
	self.pendingDotsPosition = 0;
	self.pendingDotsCount = 0;
	self.preliminaryDots = [];
	self.preliminaryDotsPosition = 0;
	self.preliminaryDotsCount = 0;
	// I realize this looks insane, but it appears to be the only cross-browser way to initialize an array size for real.
	// If we don't start with a decent buffer, the first stroke will lag significantly.
	for (var i = 0; i < 10000; ++i)
	{
		self.pendingDots.push(null);
	}

	self.backBufferCanvas = document.createElement("canvas");
	self.backBufferCanvas.width = self.canvas.width;
	self.backBufferCanvas.height = self.canvas.height;

	self.resetStroke = function() {
		self.x = null;
		self.y = null;
		self.isDrawing = false;
		self.isTouch = false;
		self.currentPosition = null;
		self.currentSlope = null;
		self.previousPosition = null;
		self.previousSlope = null;
		self.twicePreviousPosition = null;
		self.twicePreviousSlope = null;
		self.leftOver = 0;
		if (self.pendingDotsCount === self.pendingDotsPosition)
		{
			self.pendingDotsCount = 0;
			self.pendingDotsPosition = 0;
		}
		self.preliminaryDotsPosition = 0;
		self.preliminaryDotsCount = 0;
		self.frontBufferDirty = false;
	};

	self.resetStroke();

	self.spacingFactor = function () {
		return 5;
	};

	self.spacing = function() {
		return self.strokeWidth / self.spacingFactor();
	};

	self.render = function() {
		var start = window.performance.now();
		var position;
		while (window.performance.now() - start < 1000 / 60 && self.pendingDotsPosition < self.pendingDotsCount)
		{
			if (self.frontBufferDirty) {
				self.readFromBackBuffer();
				self.frontBufferDirty = false;
			}
			position = self.pendingDots[self.pendingDotsPosition++];
			self.drawDot(self.canvas.getContext("2d"), position[0], position[1]);
		}
		while (window.performance.now() - start < 500 / 60 && self.preliminaryDotsPosition < self.preliminaryDotsCount)
		{
			if (!self.frontBufferDirty) {
				self.writeToBackBuffer();
				self.frontBufferDirty = true;
			}
			position = self.preliminaryDots[self.preliminaryDotsPosition++];
			self.drawDot(self.canvas.getContext("2d"), position[0], position[1]);
		}

		window.requestAnimationFrame(self.render, self.canvas);
	};

	window.requestAnimationFrame(self.render, self.canvas);

	// BUFFER CODE: currently, setting opacity will actually act like flow.
	// Need to set up separate canvas with its own opacity and copy over image in endDraw.
	// Erasing, on the other hand, could be quite nasty -- it would require a drawImage call each frame

	//self.buffer = document.createElement('canvas');
	//$(self.buffer).css('position', 'absolute');
	//self.canvas.parentNode.insertBefore(self.buffer, self.canvas);
	//self.buffer.width = self.canvas.width;
	//self.buffer.height = self.canvas.height;

	self.ignore = function (e) {
		if (self.tool === 'hand') {
			return;
		}
		e.preventDefault();
		return false;
	};

	self.beginMouse = function (e) {
		if (self.tool === 'hand') {
			return;
		}
		if (self.isTouch) {
			return;
		}
		self.beginDraw(e, e.pageX, e.pageY);
		return false;
	};

	self.beginTouch = function (e) {
		if (self.tool === 'hand') {
			return;
		}
		if (e.touches.length !== 1) {
			return;
		}
		e.preventDefault();
		self.beginDraw(e, e.touches[0].pageX, e.touches[0].pageY);
		self.isTouch = true;
	};

	self.beginDraw = function (e, x, y) {
		self.resetStroke();
		self.isDrawing = true;
		self.writeToBackBuffer();
		self.draw(e, x, y);
	};

	self.endDraw = function (e) {
		if (self.tool === 'hand') {
			return;
		}
		if (self.isDrawing) {
			e.preventDefault();
			for (var i = self.preliminaryDotsPosition; i < self.preliminaryDotsCount; ++i)
			{
				self.pendingDots[self.pendingDotsCount++] = self.preliminaryDots[i];
			}
			self.resetStroke();
			return false;
		}
	};

	self.drawMouse = function (e) {
		if (self.tool === 'hand') {
			return;
		}
		if (self.isDrawing) {
			if (self.isTouch) {
				return;
			}
			if (!leftButtonDown) {
				self.endDraw(e);
			} else {
				self.draw(e, e.pageX, e.pageY);
			}
			return false;
		}
	};

	self.drawTouch = function (e) {
		if (self.tool === 'hand') {
			return;
		}
		if (e.touches.length === 1) {
			e.preventDefault();
			self.draw(e, e.touches[0].pageX, e.touches[0].pageY);
			return false;
		}
	};

	self.draw = function (e, x, y) {
		if (self.isDrawing) {
			if (self.lastDrawn !== null && window.performance.now() - self.lastDrawn < 1000 / 100) {
				return false;
			}
			self.lastDrawn = window.performance.now();
			self.drawingPadUsed = true;
			self.mouseX = x - self.canvas.offsetLeft;
			self.mouseY = y - self.canvas.offsetTop;

			var movedEnough;
			if (self.x === null || self.y === null) {
				movedEnough = true;
			} else {
				var deltaX = self.mouseX - self.x;
				var deltaY = self.mouseY - self.y;
				var moved = Math.sqrt(deltaX * deltaX + deltaY * deltaY);
				movedEnough = moved > self.spacing();
			}

			if (movedEnough) {
				switch (self.tool) {
					case "marker":
						self.markerDraw();
						break;
					case "eraser":
						self.eraserDraw();
						break;
					default:
						break;
				}
			}
		}
		return false;
	};

	self.markerDraw = function () {
		var context = self.canvas.getContext("2d");
		context.globalCompositeOperation = "source-over";
		var backBufferContext = self.backBufferCanvas.getContext("2d");
		backBufferContext.globalCompositeOperation = "source-over";
		self.updateSpline();
	};

	self.eraserDraw = function () {
		var context = self.canvas.getContext("2d");
		context.globalCompositeOperation = "destination-out";
		var backBufferContext = self.backBufferCanvas.getContext("2d");
		backBufferContext.globalCompositeOperation = "destination-out";
		self.updateSpline();
	};

	self.updateSpline = function() {
		self.twicePreviousPosition =  self.previousPosition;
		self.previousPosition = self.currentPosition;
		self.currentPosition = { x: self.mouseX, y: self.mouseY };

		if (self.currentSlope === null) {
			self.currentSlope = { x: 0, y: 0 };
			self.getDotStroke();
		} else {
			if (self.previousSlope === null) {
				self.previousSlope =  {
					x: self.currentPosition.x - self.previousPosition.x,
					y: self.currentPosition.y - self.previousPosition.y
				};
			} else {
				self.twicePreviousSlope = self.previousSlope;
				self.previousSlope = self.findKnotVelocity(self.twicePreviousPosition, self.previousPosition, self.currentPosition);
				self.getFinalStroke();
			}

			self.currentSlope =  {
				x: self.currentPosition.x - self.previousPosition.x,
				y: self.currentPosition.y - self.previousPosition.y
			};

			self.preliminaryDotsCount = 0;
			self.preliminaryDotsPosition = 0;
			self.getPreliminaryStroke();
		}
	};

	self.getDotStroke = function() {
		self.pendingDots[self.pendingDotsCount++] = [self.currentPosition.x, self.currentPosition.y];
		self.leftOver = self.spacing();
		self.x = self.currentPosition.x;
		self.y = self.currentPosition.y;
	};

	self.getPreliminaryStroke = function() {
		var p0 = new Complex(self.previousPosition.x, self.previousPosition.y);
		var p1 = new Complex(self.currentPosition.x, self.currentPosition.y);
		var d0 = new Complex(self.previousSlope.x, self.previousSlope.y);
		var d1 = new Complex(self.currentSlope.x, self.currentSlope.y);
		if (p1.subtract(p0).abs() < 1)
		{
			d0 = new Complex(0, 0);
			d1 = new Complex(0, 0);
		}
		var result = new Spline(p0, p1, d0, d1).getPoints(self.spacing(), self.leftOver, self.preliminaryDots, self.preliminaryDotsCount);
		self.preliminaryDotsCount += result.count;
		self.x = result.finalX;
		self.y = result.finalY;
	};

	self.getFinalStroke = function() {
		var p0 = new Complex(self.twicePreviousPosition.x, self.twicePreviousPosition.y);
		var p1 = new Complex(self.previousPosition.x, self.previousPosition.y);
		var d0 = new Complex(self.twicePreviousSlope.x, self.twicePreviousSlope.y);
		var d1 = new Complex(self.previousSlope.x, self.previousSlope.y);
		if (p1.subtract(p0).abs() < 1)
		{
			d0 = new Complex(0, 0);
			d1 = new Complex(0, 0);
		}
		var result = new Spline(p0, p1, d0, d1).getPoints(self.spacing(), self.leftOver, self.pendingDots, self.pendingDotsCount);
		self.leftOver = result.leftOver;
		self.pendingDotsCount += result.count;
	};

	self.findKnotVelocity = function (previous, current, next) {
		// Direct the knot velocity in the direction of the overall displacement between the knot's immediate neighbors
		var velocity = { x: next.x - previous.x, y: next.y - previous.y };
		if (Math.abs(velocity.x) < Math.pow(2, -40) && Math.abs(velocity.y) < Math.pow(2, -40)) {
			return { x: 0, y: 0 };
		}
		velocity.length = Math.sqrt(velocity.x * velocity.x + velocity.y * velocity.y);

		// Find the inbound and outbound vectors.
		var previousVector = { x: previous.x - current.x, y: previous.y - current.y};
		var nextVector = { x: next.x - current.x, y: next.y - current.y};
		previousVector.length = Math.sqrt(previousVector.x * previousVector.x + previousVector.y * previousVector.y);
		nextVector.length = Math.sqrt(nextVector.x * nextVector.x + nextVector.y * nextVector.y);

		// Find the projections of the inbound and outbound vectors onto the velocity unit vector.
		var previousProjection = Math.abs(previousVector.x * velocity.x + previousVector.y * velocity.y) / velocity.length;
		var nextProjection = Math.abs(nextVector.x * velocity.x + nextVector.y * velocity.y) / velocity.length;
		// A simple way to choose a vector magnitude that prevents overshoot.
		// Generally, as long as the velocity doesn't exceed the magnitude of the smaller of the inbound/outbound
		// projections, the curve will not overshoot on either side but will still be of fair, rounded shape
		var targetLength = Math.min(previousProjection, nextProjection);

		// The angle between the inbound and outbound vectors between 0 and pi.
		var angle = Math.PI / 2 - Math.asin((previousVector.x * nextVector.x + previousVector.y * nextVector.y) / (previousVector.length * nextVector.length));
		// If the angle is very close to a straight line or 180 turn,
		// the velocity at the knot should be scaled way down to prevent jittery lines and hairpin turns.
		targetLength *= Math.pow(Math.sin(angle), 1 / self.spacingFactor());

		// Multiply the target length by the velocity unit vector.
		return {
			x: velocity.x / velocity.length * targetLength,
			y: velocity.y / velocity.length * targetLength
		};
	};

	self.drawDot = function(context, x, y)
	{
		if (self.hardness === 1) {
			context.fillStyle = 'rgba(' + self.red + ', ' + self.green + ', ' + self.blue + ', ' + self.opacity + ')';
		} else {
			var gradient = context.createRadialGradient(x, y, self.strokeWidth / 2 * self.hardness, x, y, self.strokeWidth / 2);
			gradient.addColorStop(0, 'rgba(' + self.red + ', ' + self.green + ', ' + self.blue + ', ' + self.opacity + ')');
			gradient.addColorStop(1, 'rgba(' + self.red + ', ' + self.green + ', ' + self.blue + ', 0)');
			context.fillStyle = gradient;
		}
		context.strokeStyle = "transparent";

		context.beginPath();
		context.moveTo(x, y);
		context.arc(x, y, self.strokeWidth / 2, 0, 2 * Math.PI, false);
		context.fill();
	};

	self.writeToBackBuffer = function() {
		var context = self.backBufferCanvas.getContext('2d');
		context.save();
		context.globalCompositeOperation = 'source-over';
		context.clearRect(0, 0, self.backBufferCanvas.width, self.backBufferCanvas.height);
		context.drawImage(self.canvas, 0, 0);
		context.restore();
	};

	self.readFromBackBuffer = function() {
		var context = self.canvas.getContext('2d');
		context.clearRect(0, 0, self.canvas.width, self.canvas.height);
		context.save();
		context.globalCompositeOperation = 'source-over';
		context.drawImage(self.backBufferCanvas, 0, 0, self.canvas.width, self.canvas.height, 0, 0, self.canvas.width, self.canvas.height);
		context.restore();
	};

	drawingPad.find('.marker')[0].onclick = function () {
		self.tool = 'marker';
	};

	drawingPad.find('.eraser')[0].onclick = function () {
		self.tool = 'eraser';
	};

	drawingPad.find('.hand')[0].onclick = function () {
		self.tool = 'hand';
	};

	drawingPad.find('.width input')[0].onchange = function (el) {
		self.strokeWidth = Number(drawingPad.find('.width input').val());
		drawingPad.find('.width .current_value').text('(' + self.strokeWidth + 'px)');
	};

	drawingPad.find('.hardness input')[0].onchange = function (el) {
		var value = Number(drawingPad.find('.hardness input').val());
		drawingPad.find('.hardness .current_value').text('(' + value + ')');
		self.hardness = value / 10;
	};

	drawingPad.find('.opacity input')[0].onchange = function (el) {
		var value = Number(drawingPad.find('.opacity input').val());
		drawingPad.find('.opacity .current_value').text('(' + value + ')');
		self.opacity = 1 - Math.pow(1 - value / 10, 0.25);
	};

	function hexToR(h) {return parseInt((cutHex(h)).substring(0,2),16); }
	function hexToG(h) {return parseInt((cutHex(h)).substring(2,4),16); }
	function hexToB(h) {return parseInt((cutHex(h)).substring(4,6),16); }
	function cutHex(h) {return (h.charAt(0)==="#") ? h.substring(1,7):h; }

	drawingPad.find('.color_picker').wColorPicker({
		theme: "white",
		initColor: "#000000",
		mode: "click",
		effect: "fade",
		showSpeed: 200,
		hideSpeed: 200,

		onSelect: function(color) {
			self.red = hexToR(color);
			self.green = hexToG(color);
			self.blue = hexToB(color);
			self.resetStroke();
		}
    });

	var submitButton = drawingPad.find('.submit')[0];
	submitButton.onclick = function () {
		if (submitButton.hasAttribute('data-confirm')) {
			if (!window.confirm(submitButton.getAttribute('data-confirm'))) {
				return;
			}
		}

		var oldSubmitText = submitButton.innerHTML;
		if (submitButton.hasAttribute('data-disable-with'))
		{
			submitButton.innerHTML = submitButton.getAttribute('data-disable-with');
		}

		var submit = function() {
			$.ajax({
				url: Routes.plays_path({ "format":"js" }),
				data: data,
				cache: false,
				contentType: false,
				processData: false,
				type: 'POST',
				complete: function() {
					submitButton.innerHTML = oldSubmitText;
					self.drawingPadUsed = false;
				}
			});
		};

		var data = new FormData();
		data.append('play[sequence_id]', drawingPad.attr("data-sequence-id"));
		data.append('authenticity-token', $('meta[name=csrf-token]').attr('content'));
		if (self.canvas.toBlob) {
			self.canvas.toBlob(function (blob) {
				data.append('play[picture_attributes][image]', blob);
				submit();
			});
		} else {
			data.append('play[picture_attributes][image_base64]', $('canvas')[0].toDataURL().substring(22));
			submit();
		}
	};

	self.canvas.onmousedown = self.beginMouse;
	document.onmouseup = self.endDraw;
	document.onmousemove = self.drawMouse;

	self.canvas.ontouchstart = self.beginTouch;
	self.canvas.ontouchend = self.endDraw;
	self.canvas.ontouchcancel = self.endDraw;
	self.canvas.ontouchmove = self.drawTouch;

	self.canvas.onselectstart = self.ignore;
};