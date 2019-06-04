var Complex = function(real, imag) {
  "use strict";
  if (!(this instanceof Complex)) {
    return new Complex (real, imag);
  }

  if (typeof real === "string" && imag === null) {
    return Complex.parse (real);
  }

  this.real = Number(real) || 0;
  this.imag = Number(imag) || 0;
};

Complex.parse = function(string) {
  "use strict";
  var real, imag, regex, match, a, b, c;

  regex = /^([\-+]?(?:\d+|\d*\.\d+))?[\-+]?(\d+|\d*\.\d+)?[ij]$/i;
  string = String(string).replace (/\s+/g, '');

  match = string.match (regex);
  if (!match) {
    throw new Error("Invalid input to Complex.parse, expecting a + bi format");
  }

  a = match[1];
  b = match[2];
  c = match[3];

  real = a !== null ? parseFloat (a) : 0;
  imag = parseFloat ((b || "+") + (c || "1"));

  return new Complex(real, imag);
};

Complex.prototype.copy = function() {
  "use strict";
  return new Complex(this.real, this.imag);
};

Complex.prototype.add = function(operand) {
  "use strict";
  var real, imag;

  if (operand instanceof Complex) {
    real = operand.real;
    imag = operand.imag;
  } else {
    real = Number(operand);
    imag = 0;
  }

  return new Complex(this.real + real, this.imag + imag);
};

Complex.prototype.subtract = function(operand) {
  "use strict";
  var real, imag;

  if (operand instanceof Complex) {
    real = operand.real;
    imag = operand.imag;
  } else {
    real = Number(operand);
    imag = 0;
  }

  return new Complex (this.real - real, this.imag - imag);
};

Complex.prototype.multiply = function(operand) {
  "use strict";
  var real, imag;

  if (operand instanceof Complex) {
    real = operand.real;
    imag = operand.imag;
  } else {
    real = Number(operand);
    imag = 0;
  }

  return new Complex (this.real * real - this.imag * imag, this.real * imag + this.imag * real);
};

Complex.prototype.divide = function(operand) {
  "use strict";
  var real, imag, denominator;

  if (operand instanceof Complex) {
    real = operand.real;
    imag = operand.imag;
  } else {
    real = Number(operand);
    imag = 0;
  }

  denominator = real * real + imag * imag;
  return new Complex((this.real * real + this.imag * imag) / denominator, (this.imag * real - this.real * imag) / denominator);
};

Complex.prototype.isConjugate = function(operand) {
  "use strict";
  var real, imag;

  if (operand instanceof Complex) {
    real = operand.real;
    imag = operand.imag;
  } else {
    real = Number(operand);
    imag = 0;
  }

  return (this.real === real && this.imag === -imag);
};

Complex.prototype.abs = function() {
  "use strict";
  return Math.sqrt(this.norm());
};

Complex.prototype.norm = function() {
  "use strict";
  return this.real * this.real + this.imag * this.imag;
};

Complex.prototype.arg = function() {
  "use strict";
  return Math.atan2(this.imag, this.real);
};

Complex.prototype.inverse = function() {
  "use strict";
  var norm = this.norm;

  return new Complex(this.real / norm, -this.imag / norm);
};

Complex.prototype.conjugate = function() {
  "use strict";
  return new Complex(this.real, -this.imag);
};

Complex.prototype.exp = function() {
  "use strict";
  var e = Math.exp(this.real);
  return new Complex(e * Math.cos(this.imag), e * Math.sin(this.imag));
};

Complex.prototype.log = function() {
  "use strict";
  return new Complex(0.5 * Math.log(this.norm()), this.arg());
};

Complex.prototype.power = function(power) {
  "use strict";
  if (power instanceof Complex) {
    return (power.multiply(this.log())).exp();
  }

  var inverse = false;
  if (power < 0)
  {
    inverse = true; power = -power;
  }

  var result = new Complex(1, 0);
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

Complex.prototype.sqrt = function() {
  "use strict";
  return this.log().multiply(0.5).exp();
};

Complex.prototype.sin = function() {
  "use strict";
  return this.multiply(new Complex(0, 1)).sinh().divide(new Complex(0, 1));
};

Complex.prototype.cos = function() {
  "use strict";
  return this.multiply(new Complex(0, 1)).cosh();
};

Complex.prototype.sinh = function() {
  "use strict";
  return this.exp().subtract(this.multiply(-1).exp()).multiply(0.5);
};

Complex.prototype.cosh = function() {
  "use strict";
  return this.exp().add(this.multiply(-1).exp()).multiply(0.5);
};

Complex.findQuadraticRoots = function(a, b, c) {
  "use strict";
  var rootDisc = b.multiply(b).subtract(c.multiply(a).multiply(4)).sqrt();
  return [
    rootDisc.subtract(b).divide(a.multiply(2)),
    rootDisc.multiply(-1).subtract(b).divide(a.multiply(2))
  ];
};