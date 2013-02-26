require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

module Capricious
  describe CubicSpline do
    it "should accept supported data input methods" do
      s1 = Capricious::CubicSpline.new(:data => [[1,2],[3,5],[7,11]])
      s2 = Capricious::CubicSpline.new
      s2 << [[1,2],[3,5],[7,11]]

      # the above should be equivalent and yield equivalent results
      s1.domain.should == s2.domain
      s1.x.should == s2.x
      s1.y.should == s2.y
      s1.ypp.should == s2.ypp

      # these should also be equivalent
      s1 = Capricious::CubicSpline.new(:data => [[0,2],[1,5],[2,11]])
      s2 = Capricious::CubicSpline.new
      s2 << [0,2] << [1,5] << [2,11]

      s1.domain.should == s2.domain
      s1.x.should == s2.x
      s1.y.should == s2.y
      s1.ypp.should == s2.ypp
    end

    it "should exactly fit parabolic data inside its sampled domain" do
      # I expect tight tolerances on this quadratic test
      eps = 0.0000001

      # cubic splines are characterized by piecewise linear 2nd derivatives
      # that means splining a parabola gives me a nice test with 'exact' expectations on outputs
      # note that here I want to explicitly fix the first derivative at endpoints to match
      # the corresponding parabolic derivative
      s = Capricious::CubicSpline.new(:data => [[-2,4],[-1,1],[0,0],[1,1],[2,4]], :yp_lower => -4, :yp_upper => 4)

      # these should be exact:
      s.domain.should == [s.x.first, s.x.last]
      s.domain.should == [-2.0, 2.0]
      s.x.should == [-2.0, -1.0, 0.0, 1.0, 2.0]
      s.y.should == [4.0, 1.0, 0.0, 1.0, 4.0]
      
      # these should be very very close to 2, the constant 2nd derivative of the test quadratic:
      s.ypp.each {|v| v.should be_close(2.0, eps) }

      # test at data points and in between for expected quadratic values
      [-2, -1.5, -1, -0.5, 0, 0.5, 1, 1.5, 2].each do |x|
        # the quadratic function itself is x^2
        s.q(x).should be_close(x**2, eps)
        # its 1st derivative is 2x
        s.qp(x).should be_close(2.0*x, eps)
        # 2nd derivative is just 2 everywhere
        s.qpp(x).should be_close(2.0, eps)
      end
    end

    it "should exactly fit cubic data inside its sampled domain" do
      # I expect tight tolerances on this test
      eps = 0.0000001

      # cubic splines are characterized by piecewise linear 2nd derivatives
      # that means splining a cubic polynomial gives me a nice test with 'exact' expectations on outputs
      # note that here I want to explicitly fix the first derivative at endpoints to match
      # the corresponding polynomial derivative
      s = Capricious::CubicSpline.new
      s.put([[0,0],[1,1],[2,8],[3,27]])
      s.configure(:yp_lower => 0, :yp_upper => 27)

      # these should be exact:
      s.domain.should == [s.x.first, s.x.last]
      s.domain.should == [0.0, 3.0]
      s.x.should == [0.0, 1.0, 2.0, 3.0]
      s.y.should == [0.0, 1.0, 8.0, 27.0]
      
      # test at data points and in between for expected quadratic values
      [0, 0.5, 1, 1.5, 2, 2.5, 3].each do |x|
        # the function itself is x^3
        s.q(x).should be_close(x**3, eps)
        # its 1st derivative is 3x^2
        s.qp(x).should be_close(3.0*x**2, eps)
        # 2nd derivative is 6x
        s.qpp(x).should be_close(6.0*x, eps)
      end
    end

    it "should interpolate sin function using natural spline" do
      pi = Math::PI

      # natural spline: unfixed enpoint gradients
      s = Capricious::CubicSpline.new

      # sample a sin function over [-pi/2, pi/2]
      n = 25
      (0..n).each do |j|
        x = -pi/2.0 + pi*j.to_f/n.to_f
        s << [x, Math.sin(x)]
      end

      s.domain.should == [s.x.first, s.x.last]
      
      # 2nd derivative should be zero at endpoints by construction
      # because natural spline was asked for
      s.qpp(s.x.first).should be_close(0.0, 0.00000001)
      s.qpp(s.x.last).should be_close(0.0, 0.00000001)

      # check the interpolated function and its derivatives
      [-1.5, -1.25, -1.0, -0.75, -0.5, -0.25, 0.0, 0.25, 0.5, 0.75, 1.0, 1.25, 1.5].each do |x|
        #print "x=%f   sin(x)=%f  q(x)=%f   cos(x)=%f  q'(x)=%f   -sin(x)=%f  q''(x)=%f\n" % [x, Math.sin(x), s.q(x), Math.cos(x), s.qp(x), -Math.sin(x), s.qpp(x)]
        # approximation to sin(x) should be decent
        s.q(x).should be_close(Math.sin(x), 0.001)
        # 1st derivative approximiation not quite as tight
        s.qp(x).should be_close(Math.cos(x), 0.01)
        # piecewise linear 2nd derivative very coarse fit in some regions
        s.qpp(x).should be_close(-Math.sin(x), 0.33)
      end
    end

    it "should interpolate sin function using fixed endpoint derivatives" do
      pi = Math::PI

      s = Capricious::CubicSpline.new

      # sample a sin function over [-pi/2, pi/2]
      n = 25
      (0..n).each do |j|
        x = -pi/2.0 + pi*j.to_f/n.to_f
        s << [x, Math.sin(x)]
      end
      
      # use my knowledge of endpoint derivatives
      s.configure(:yp_lower => 0, :yp_upper => 0)

      s.domain.should == [s.x.first, s.x.last]

      # 1st derivative should be zero at endpoints by construction
      s.qp(s.x.first).should be_close(0.0, 0.00000001)
      s.qp(s.x.last).should be_close(0.0, 0.00000001)

      # check the interpolated function and its derivatives
      # fixing the correct endpoint derivatives gets significantly better fit with same samples
      [-1.5, -1.25, -1.0, -0.75, -0.5, -0.25, 0.0, 0.25, 0.5, 0.75, 1.0, 1.25, 1.5].each do |x|
        #print "x=%f   sin(x)=%f  q(x)=%f   cos(x)=%f  q'(x)=%f   -sin(x)=%f  q''(x)=%f\n" % [x, Math.sin(x), s.q(x), Math.cos(x), s.qp(x), -Math.sin(x), s.qpp(x)]
        # approximation to sin(x) should be better
        s.q(x).should be_close(Math.sin(x), 0.0001)
        # 1st derivative approximiation not quite as tight
        s.qp(x).should be_close(Math.cos(x), 0.001)
        # piecewise linear 2nd derivative gets better fit than with natural splining
        s.qpp(x).should be_close(-Math.sin(x), 0.01)
      end
    end

  end
end
