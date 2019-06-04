Math.sign = function(number) {
  "use strict";
  if (number < 0) { return -1; }
  if (number > 0) { return 1; }
  return 0;
};

Math.findQuadraticRoots = function(a, b, c) {
  "use strict";
  if (Math.abs(a) < Math.pow(2, -40)) {
    return [ -c / b ];
  }
  var rootDisc = Math.sqrt(b * b - c * a * 4);
  if (rootDisc < 0) {
    return [ ];
  }
  if (Math.abs(rootDisc) < Math.pow(2, -40)) {
    return [ -b / (2 * a) ];
  }
  return [
    (rootDisc - b) / (2 * a),
    (-rootDisc - b) / (2 * a)
  ];
};