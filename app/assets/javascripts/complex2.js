Array.prototype.add = function(operand) {
	"use strict";
	return [this[0] + operand[0], this[1] + operand[1]];
};

Array.prototype.addScalar = function(operand) {
	"use strict";
	return [this[0] + operand, this[1]];
};

Array.prototype.subtract = function(operand) {
	"use strict";
	return [this[0] - operand[0], this[1] - operand[1]];
};

Array.prototype.subtractScalar = function(operand) {
	"use strict";
	return [this[0] - operand, this[1]];
};

Array.prototype.multiply = function(operand) {
	"use strict";
	return [this[0] * operand[0] - this[1] * operand[1], this[0] * operand[1] + this[1] * operand[0]];
};

Array.prototype.multiplyScalar = function(operand) {
	"use strict";
	return [this[0] * operand, this[1] * operand];
};

Array.prototype.divide = function(operand) {
	"use strict";
	var denominator = operand[0] * operand[0]  + operand[1] * operand[1];
	return [(this[0] * operand[0] + this[1] * operand[1]) / denominator, (this[0] * operand[1] - this[1] * operand[0]) / denominator];
};

Array.prototype.divideScalar = function(operand) {
	"use strict";
	return [this[0] / operand, this[1] / operand];
};

Array.prototype.isConjugate = function(operand) {
	"use strict";
	return (this[0] === operand[0] && this[1] === -operand[1]);
};

Array.prototype.abs = function() {
	"use strict";
	return Math.sqrt(this[0] * this[0] + this[1] * this[1]);
};

Array.prototype.norm = function() {
	"use strict";
	return this[0] * this[0] + this[1] * this[1];
};

Array.prototype.arg = function() {
	"use strict";
	return Math.atan2(this[1], this[0]);
};

Array.prototype.inverse = function() {
	"use strict";
	var norm = this[0] * this[0] + this[1] * this[1];

	return [this[0] / norm, -this[1] / norm];
};

Array.prototype.conjugate = function() {
	"use strict";
	return [this[0], -this[1]];
};

Array.prototype.exp = function() {
	"use strict";
	var e = Math.exp(this[0]);
	return [e * Math.cos(this[1]), e * Math.sin(this[1])];
};

Array.prototype.log = function() {
	"use strict";
	return [0.5 * Math.log(this[0] * this[0] + this[1] * this[1]), Math.atan2(this[1], this[0])];
};

Array.prototype.log = function() {
	"use strict";
	return [0.5 * Math.log(this.norm()), this.arg()];
};

Array.prototype.power = function(power) {
	"use strict";
	return power.multiply(this.log()).exp();
};

Array.prototype.powerScalar = function(power) {
	"use strict";
	var inverse = false;
	if (power < 0)
	{
		inverse = true; power = -power;
	}

	var result = [1, 0];
	var multiplier = this;
	while (power > 0)
	{
		if (power % 2 === 1) {
			result = result.multiply(multiplier);
		}
		multiplier = multiplier.multiply(multiplier);
		power = Math.floor(power / 2);
	}

	return inverse ? result.inverse() : result;
};

Array.prototype.sqrt = function() {
	"use strict";
	var halfLog = [0.25 * Math.log(this[0] * this[0] + this[1] * this[1]), 0.5 * Math.atan2(this[1], this[0])];
	return halfLog.exp();
};

Array.prototype.sin = function() {
	"use strict";
	return this.multiply([0, 1]).sinh().divide([0, 1]);
};

Array.prototype.cos = function() {
	"use strict";
	return this.multiply([0, 1]).cosh();
};

Array.prototype.sinh = function() {
	"use strict";
	return this.exp().subtract(this.multiply(-1).exp()).multiply(0.5);
};

Array.prototype.cosh = function() {
	"use strict";
	return this.exp().add(this.multiply(-1).exp()).multiply(0.5);
};

Array.findQuadraticRoots = function(a, b, c) {
	"use strict";
	var rootDisc = b.multiply(b).subtract(c.multiply(a).multiplyScalar(4)).sqrt();
	return [
		rootDisc.subtract(b).divide(a.multiplyScalar(2)),
		rootDisc.multiplyScalar(-1).subtract(b).divide(a.multiplyScalar(2))
	];
};