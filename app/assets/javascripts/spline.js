// What is all this insanity, you ask? Fifth-order pythagorean hodographs --
// their arc lengths are monotonic functions of the curve parameter, which turns out to be quite useful.
var Spline =  function(p0, p1, d0, d1) {
	'use strict';
	var self = this;

	self.p0 = p0;
	self.p1 = p1;
	self.d0 = d0.divide(self.p1.subtract(self.p0));
	self.d1 = d1.divide(self.p1.subtract(self.p0));

	// Find the two values for rho.
	var rhoSquared = self.d0.divide(self.d1);
	var rhoPos = rhoSquared.sqrt();
	var rhoNeg = rhoPos.multiply(-1);

	// Find the four values for alpha.
	var one = new Complex(1, 0);

	var alphaBRhoPos = rhoPos.add(1).multiply(-3);
	var alphaCRhoPos = rhoSquared.multiply(6).add(rhoPos.multiply(2)).add(6).subtract(new Complex(30,0).divide(self.d1));
	var alphaRhoPos = Complex.findQuadraticRoots(one, alphaBRhoPos, alphaCRhoPos);

	var alphaBRhoNeg = rhoNeg.add(1).multiply(-3);
	var alphaCRhoNeg = rhoSquared.multiply(6).add(rhoNeg.multiply(2)).add(6).subtract(new Complex(30,0).divide(self.d1));
	var alphaRhoNeg = Complex.findQuadraticRoots(one, alphaBRhoNeg, alphaCRhoNeg);

	// Find the eight values for mu.
	var mu1 = Complex.findQuadraticRoots(one, alphaRhoPos[0].multiply(-1), rhoPos);
	var mu2 = Complex.findQuadraticRoots(one, alphaRhoPos[1].multiply(-1), rhoPos);
	var mu3 = Complex.findQuadraticRoots(one, alphaRhoNeg[0].multiply(-1), rhoNeg);
	var mu4 = Complex.findQuadraticRoots(one, alphaRhoNeg[1].multiply(-1), rhoNeg);

	// Find a, b, and k for each mu.
	var a1 = mu1[0].divide(mu1[0].add(1));
	var b1 = mu1[1].divide(mu1[1].add(1));
	var k1 = self.d0.divide(a1.multiply(a1).multiply(b1).multiply(b1));
	var spline1 = new SplineFunction(self.p0, self.p1, self.d0, self.d1, a1, b1, k1);
	var a2 = mu2[0].divide(mu2[0].add(1));
	var b2 = mu2[1].divide(mu2[1].add(1));
	var k2 = self.d0.divide(a2.multiply(a2).multiply(b2).multiply(b2));
	var spline2 = new SplineFunction(self.p0, self.p1, self.d0, self.d1, a2, b2, k2);
	var a3 = mu3[0].divide(mu3[0].add(1));
	var b3 = mu3[1].divide(mu3[1].add(1));
	var k3 = self.d0.divide(a3.multiply(a3).multiply(b3).multiply(b3));
	var spline3 = new SplineFunction(self.p0,self. p1, self.d0, self.d1, a3, b3, k3);
	var a4 = mu4[0].divide(mu4[0].add(1));
	var b4 = mu4[1].divide(mu4[1].add(1));
	var k4 = self.d0.divide(a4.multiply(a4).multiply(b4).multiply(b4));
	var spline4 = new SplineFunction(self.p0, self.p1, self.d0, self.d1, a4, b4, k4);

	// choose the spline function with the lowest absolute curvature
	self.spline = spline1;
	if (spline2.absoluteCurvature < self.spline.absoluteCurvature) { self.spline = spline2; }
	if (spline3.absoluteCurvature < self.spline.absoluteCurvature) { self.spline = spline3; }
	if (spline4.absoluteCurvature < self.spline.absoluteCurvature) { self.spline = spline4; }

	self.position = self.spline.position;
	self.velocity = self.spline.velocity;
	self.arcLength = self.spline.arcLength;

	self.getPoints = function(spacing, startPosition, points, index) {
		var t = self.findTimeOfArcLength(startPosition, 0, 0);

		var count = 0;
		while (t <= 1) {
			var point = self.position(t);
			points[index++] = [point.real, point.imag];
			++count;

			var a = self.arcLength(t);
			var targetA = a + spacing;
			var lowT = t;
			var lowA = a;
			var nextT = self.findTimeOfArcLength(targetA, lowT, lowA);

			if (nextT > 1) {
				var leftOver = spacing - (self.arcLength(1) - self.arcLength(t));
				return { leftOver: leftOver, count: count, finalX: point.real, finalY: point.imag };
			}
			t = nextT;
		}
	};

	self.findTimeOfArcLength = function(targetA, lowT, lowA) {
		var nextT = lowT + (targetA - lowA) / self.velocity(lowT).abs();
		var nextA = self.arcLength(nextT);

		while (Math.abs(nextA - targetA) > 0.001) {
			if (nextA < targetA) {
				lowT = nextT;
				lowA = nextA;
				nextT = lowT + (targetA - lowA) / self.velocity(lowT).abs();
				nextA = self.arcLength(nextT);
			} else {
				nextT = lowT + (nextT - lowT) / 2;
				nextA = self.arcLength(nextT);
			}
		}

		return nextT;
	};
};

var SplineFunction = function(p0, p1, d0, d1, a, b, k) {
  'use strict';

  var self = this;
  self.p0 = p0;
  self.p1 = p1;
  self.d0 = d0;
  self.d1 = d1;
  self.a = a;
  self.b = b;
  self.k = k;

  // if a and b are conjugates, the derivative is not a function of t,
  // and the only parametric curve with a constant derivative is a straight line
  // if a or b have 0 imaginary parts, the derivative has a 0, which should not be possible, or the curve is degenerate.
  self.isStraightLine = self.a.isConjugate(self.b) || Math.abs(self.a.imag) < Math.pow(2, -40) || Math.abs(self.b.imag) < Math.pow(2, -40);

  self.position = function() {
    if (self.isStraightLine) {
      return function(t) {
        return new Complex(t, 0)
          .multiply(self.p1.subtract(self.p0)).add(self.p0);
      };
    }

    var aCubed = self.a.multiply(self.a).multiply(self.a);
    var aCubedTimesB = aCubed.multiply(self.b);
    var term4 = aCubed.multiply(self.a).multiply(self.a);
    var term5 = aCubedTimesB.multiply(self.a).multiply(-5);
    var term6 = aCubedTimesB.multiply(self.b).multiply(10);
    var sumTerms456 = term4.add(term5).add(term6);
    var kOver30 = self.k.divide(30);
    var p1MinusP0 = self.p1.subtract(self.p0);
    var kOver30TimesDisplacement = kOver30.multiply(p1MinusP0);

    return function(t) {
      var tComplex = new Complex(t, 0);
      var tma = tComplex.subtract(self.a);
      var tmb = tComplex.subtract(self.b);
      var tmaCubed = tma.multiply(tma).multiply(tma);
      var tmaCubedTimesTmb = tmaCubed.multiply(tmb);
      var term1 = tmaCubed.multiply(tma).multiply(tma);
      var term2 = tmaCubedTimesTmb.multiply(tma).multiply(-5);
      var term3 = tmaCubedTimesTmb.multiply(tmb).multiply(10);

      return term1.add(term2).add(term3).add(sumTerms456).multiply(kOver30TimesDisplacement).add(self.p0);
    };
  }();

  self.arcLength = function() {
    if (self.isStraightLine) {
      return function(t) {
        return t * self.p1.subtract(self.p0).abs();
      };
    }

    var scale = self.p1.subtract(self.p0).abs();

    var one = new Complex(1, 0);
    var kSqrt = self.k.sqrt();
    var c0 = kSqrt
      .multiply(self.a)
      .multiply(self.b);
    var c1 = kSqrt
      .multiply(new Complex(-0.5, 0))
      .multiply(one.subtract(self.b).multiply(self.a)
      .add(one.subtract(self.a).multiply(self.b)));
    var c2 = kSqrt
      .multiply(one.subtract(self.a))
      .multiply(one.subtract(self.b));

    var u0 = c0.real, u1 = c1.real, u2 = c2.real;
    var v0 = c0.imag, v1 = c1.imag, v2 = c2.imag;

    var f1 = u0 - 2 * u1 + u2;
    var f2 = 2 * u1 - 2 * u0;
    var f3 = v0 - 2 * v1 + v2;
    var f4 = 2 * v1 - 2 * v0;

    var h5 = (f1 * f1 + f3 * f3) / 5 * scale;
    var h4 = (f1 * f2 + f3 * f4) / 2 * scale;
    var h3 = (f2 * f2 + f4 * f4 + 2 * (f1 * u0 + f3 * v0)) / 3 * scale;
    var h2 = (f2 * u0 + f4 * v0) * scale;
    var h1 = (u0 * u0 + v0 * v0) * scale;

    return function(t) {
      var t2 = t * t;
      var t3 = t2 * t;
      var t4 = t3 * t;
      var t5 = t4 * t;
      return h5 * t5 + h4 * t4 + h3 * t3 + h2 * t2 + h1 * t;
    };
  }();

  self.velocity = function(t) {
    if (self.isStraightLine) {
      return self.p1.subtract(self.p0);
    }

    var tComplex = new Complex(t, 0);
    var root = tComplex.subtract(self.a).multiply(tComplex.subtract(self.b));
    return root.multiply(root).multiply(self.k)
      .multiply(self.p1.subtract(self.p0));
  };

  self.curvature = function() {
    if (self.isStraightLine) {
      return function(t) {
        return 0;
      };
    }

    var q1 = self.a.add(self.b).imag;
    var q2 = 2 * self.a.multiply(self.b).imag;
    var q3 = self.b.multiply(self.a.abs() * self.a.abs()).add(self.a.multiply(self.b.abs() * self.b.abs())).imag;

    return function(t) {
      var y = q1 * t * t
        - q2 * t
        + q3;
      return new Complex(t, y)
        .multiply(self.p1.subtract(self.p0)).add(self.p0);
    };
  }();

  self.absoluteCurvature = function() {
    if (self.isStraightLine) {
      return 0;
    }

    var findAngle = function(t1, t2, z) {
      var near1 = z.subtract(t1).abs();
      var near2 = z.subtract(t2).abs();
      var far = Math.abs(t2 - t1);
      return Math.acos((near1 * near1 + near2 * near2 - far * far) / (2 * near1 * near2));
    };

    if (Math.sign(self.a.imag) === Math.sign(self.b.imag)) {
      return findAngle(0, 1, self.a) + findAngle(0, 1, self.b);
    } else {
      var rootsOfCurvature = Math.findQuadraticRoots(
        self.a.add(self.b).imag,
        -2 * self.a.multiply(self.b).imag,
        self.b.multiply(self.a.abs() * self.a.abs()).add(self.a.multiply(self.b.abs() * self.b.abs())).imag
      );

      var curvatureIntegrationDomains = rootsOfCurvature
        .filter(function(element) { return element >= 0 && element <= 1; });
      curvatureIntegrationDomains.push(0);
      curvatureIntegrationDomains.push(1);
      curvatureIntegrationDomains.sort();
      curvatureIntegrationDomains = curvatureIntegrationDomains
        .filter(function(el, i, a) { return i === a.indexOf(el);  });

      var result = 0;
      for (var i = 0; i < curvatureIntegrationDomains.length - 1; ++i) {
        result += Math.abs(
          findAngle(curvatureIntegrationDomains[i], curvatureIntegrationDomains[i + 1], self.a)
            - findAngle(curvatureIntegrationDomains[i], curvatureIntegrationDomains[i + 1], self.b)
        );
      }
      return result;
    }
  }();
};