require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

module Capricious
  describe CubicHermiteSpline do

    def check_monotonic(s, l, u, step = 0.001)
      x = l
      while (x <= u)
        #print "check_monotonic failed: x= %f  q(x)= %f  q'(x)= %f  q''(x)= %f   m= %s\n" % [x, s.q(x), s.qp(x), s.qpp(x), s.m] if s.qp(x) < 0.0
        s.qp(x).should >= 0.0

        #print "check_monotonic failed: x= %f  q(x)= %f  q'(x)= %f  q''(x)= %f   m= %s\n" % [x, s.q(x), s.qp(x), s.qpp(x), s.m] if s.q(x) > s.q(x+step)
        s.q(x).should <= s.q(x+step)

        x += step
      end
    end


    def check_gradients(s, x)
      passed = true
      y = s.q(x)
      [ 0.01, 0.001, 0.0001, 0.00001 ].each do |e|
        d = 0.01
        while true
          return false if (d < 1e-10)
          break if (y - s.q(x+d)).abs < e
          d /= 10.0
        end
      end

      yp = s.qp(x)
      [ 0.01, 0.001, 0.0001, 0.00001 ].each do |e|
        d = 0.01
        while true
          return false if (d < 1e-10)
          break if (yp - (s.q(x+d)-y)/d).abs < e
          d /= 10.0
        end
      end

      ypp = s.qpp(x)
      [ 0.01, 0.001, 0.0001, 0.00001 ].each do |e|
        d = 0.01
        while true
          return false if (d < 1e-10)
          break if (ypp - (s.qp(x+d)-yp)/d).abs < e
          d /= 10.0
        end
      end

      return true
    end


    it "should properly maintain data and configuration state" do
      s = CubicHermiteSpline.new

      # default initial state
      s.configuration.should == { :data => nil, :gradient_method => CubicHermiteSpline::FINITE_DIFFERENCE, :strict_domain => true, :monotonic_epsilon => 1e-6, :fixed_gradients => {}}
      s.data.should == {}
      s.dirty?.should == true

      # configuration should not alter data (long as :data not given)
      s.configure(:strict_domain => false)
      s.configuration.should == { :data => nil, :gradient_method => CubicHermiteSpline::FINITE_DIFFERENCE, :strict_domain => false, :monotonic_epsilon => 1e-6, :fixed_gradients => {}}
      s.data.should == {}
      s.dirty?.should == true

      # adding data should show up, not alter config
      s << [1,1]
      s.configuration.should == { :data => nil, :gradient_method => CubicHermiteSpline::FINITE_DIFFERENCE, :strict_domain => false, :monotonic_epsilon => 1e-6, :fixed_gradients => {}}
      s.data.should == {1.0 => 1.0}
      s.dirty?.should == true
      
      # ways to add data
      s << [2,2]
      s.data.should == {1.0 => 1.0, 2.0 => 2.0}
      s << [[3,3], [4,4]]
      s.data.should == {1.0 => 1.0, 2.0 => 2.0, 3.0 => 3.0, 4.0 => 4.0}
      s.put([5,5])
      s.data.should == {1.0 => 1.0, 2.0 => 2.0, 3.0 => 3.0, 4.0 => 4.0, 5.0 => 5.0}
      s.put([[6,6],[7,7]])
      s.data.should == {1.0 => 1.0, 2.0 => 2.0, 3.0 => 3.0, 4.0 => 4.0, 5.0 => 5.0, 6.0 => 6.0, 7.0 => 7.0}

      # a recompute should be invoked, and no longer dirty
      s.q(1).should == 1.0
      s.dirty?.should == false

      # add data, become dirty again
      s << [8,8]
      s.dirty?.should == true
      s.data.should == {1.0 => 1.0, 2.0 => 2.0, 3.0 => 3.0, 4.0 => 4.0, 5.0 => 5.0, 6.0 => 6.0, 7.0 => 7.0, 8.0 => 8.0}

      s.q(4).should == 4.0
      s.dirty?.should == false

      # clear should remove data, but not change config
      s.clear
      s.configuration.should == { :data => nil, :gradient_method => CubicHermiteSpline::FINITE_DIFFERENCE, :strict_domain => false, :monotonic_epsilon => 1e-6, :fixed_gradients => {}}
      s.data.should == {}
      s.dirty?.should == true

      # reset clears data and resets config
      s << [9,9]
      s.reset
      s.configuration.should == { :data => nil, :gradient_method => CubicHermiteSpline::FINITE_DIFFERENCE, :strict_domain => true, :monotonic_epsilon => 1e-6, :fixed_gradients => {}}
      s.data.should == {}
      s.dirty?.should == true
    end


    it "should interpolate a sin function using finite difference" do
      pi = Math::PI
      s = CubicHermiteSpline.new

      # sample a sin function over [-pi/2, pi/2]
      n = 50
      (0..n).each do |j|
        x = -pi/2.0 + pi*j.to_f/n.to_f
        s << [x, Math.sin(x)]
      end

      s.domain.should == [s.x.first, s.x.last]

      # check the interpolated function and its derivatives
      [-1.5, -1.25, -1.0, -0.75, -0.5, -0.25, 0.0, 0.25, 0.5, 0.75, 1.0, 1.25, 1.5].each do |x|
        s.q(x).should be_close(Math.sin(x), 0.001)
        s.qp(x).should be_close(Math.cos(x), 0.01)
        s.qpp(x).should be_close(-Math.sin(x), 0.1)

        check_gradients(s, x) == true
      end
    end

    it "should interpolate tricksy data in monotonic mode" do
      # this dataset produces a non-monotonic spline with finite-difference gradients
      tricksy = [[0.1, 3], [0.2, 2.9], [0.3, 2.5], [0.4, 1], [0.5, 0.9], [0.6, 0.8], [0.7, 0.5], [0.8, 0.2], [0.9, 0.1]]

      s = CubicHermiteSpline.new(:data => tricksy, :gradient_method => CubicHermiteSpline::STRICT_MONOTONIC)

      0.upto(tricksy.length-1) do |j|
        x, y = tricksy[j]
        s.q(x).should be_close(y, 0.000001)
        s.qp(x).should < 0.0
      end

      step = 0.001
      x = s.x.first
      while x+step <= s.x.last
        # monotonic decreasing
        s.q(x).should > s.q(x+step)
        s.qp(x).should < 0.0
        x += 0.001
      end

      x = s.x.first + 0.02
      while x < s.x.last - 0.02
        check_gradients(s, x)
        x += 0.01
      end
    end

    it "should interpolate tricksy data in monotonic mode (increasing)" do
      # this dataset produces a non-monotonic spline with finite-difference gradients
      tricksy = [[0.1, 0.1], [0.2, 0.2], [0.3, 0.5], [0.4, 0.8], [0.5, 0.9], [0.6, 1], [0.7, 2.5], [0.8, 2.9], [0.9, 3]]

      s = CubicHermiteSpline.new(:data => tricksy, :gradient_method => CubicHermiteSpline::STRICT_MONOTONIC)

      0.upto(tricksy.length-1) do |j|
        x, y = tricksy[j]
        s.q(x).should be_close(y, 0.000001)
        s.qp(x).should > 0.0
      end

      step = 0.001
      x = s.x.first
      while x+step <= s.x.last
        # monotonic increasing
        s.q(x).should < s.q(x+step)
        s.qp(x).should > 0.0
        x += 0.001
      end

      x = s.x.first + 0.02
      while x < s.x.last - 0.02
        check_gradients(s, x)
        x += 0.01
      end
    end

    it "should interpolate tricksy data in non-strict monotonic mode (increasing)" do
      # this dataset produces a non-monotonic spline with finite-difference gradients
      tricksy = [[0.1, 0.1], [0.2, 0.2], [0.3, 0.5], [0.4, 0.8], [0.5, 0.9], [0.6, 1], [0.7, 2.5], [0.8, 2.9], [0.9, 3]]

      s = CubicHermiteSpline.new(:data => tricksy, :gradient_method => CubicHermiteSpline::MONOTONIC)

      0.upto(tricksy.length-1) do |j|
        x, y = tricksy[j]
        s.q(x).should be_close(y, 0.000001)
        s.qp(x).should >= 0.0
      end

      step = 0.001
      x = s.x.first
      while x+step <= s.x.last
        # monotonic increasing
        s.q(x).should <= s.q(x+step)
        s.qp(x).should >= 0.0
        x += 0.001
      end

      x = s.x.first + 0.02
      while x < s.x.last - 0.02
        check_gradients(s, x)
        x += 0.01
      end
    end

    it "should interpolate exponential function using monotonic" do
      s = CubicHermiteSpline.new(:gradient_method => CubicHermiteSpline::STRICT_MONOTONIC)

      # sample exp function over [-2, 2]
      n = 100
      (0..n).each do |j|
        x = -2.0 + 4.0*j.to_f/n.to_f
        s << [x, Math.exp(x)]
      end

      lb,ub = s.domain
      lb.should be_close(-2.0, 0.0000001)
      ub.should be_close(2.0, 0.0000001)

      # check the interpolated function and its derivatives
      # behavior of qp(x) and qpp(x) at endpoints is fairly different from that of e^x,
      # due to effects of one-sided gradient estimation
      # q(x) does well, however
      [-1.75, -1.5, -1.25, -1.0, -0.75, -0.5, -0.25, 0.0, 0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 1.75].each do |x|
        #print "x=%f   exp(x)=%f  q(x)=%f   q'(x)=%f   q''(x)=%f\n" % [x, Math.exp(x), s.q(x), s.qp(x), s.qpp(x)]        
        s.q(x).should be_close(Math.exp(x), 0.001)
        s.qp(x).should be_close(Math.exp(x), 0.02)
        check_gradients(s, x) == true
      end
    end

    it "should interpolate exponential function using monotonic with fixed gradients" do
      s = CubicHermiteSpline.new(:gradient_method => CubicHermiteSpline::STRICT_MONOTONIC)

      # sample exp function over [-2, 2]
      n = 100
      (0..n).each do |j|
        x = -2.0 + 4.0*j.to_f/n.to_f
        s << [x, Math.exp(x)]
      end

      # cheat with fixed gradients.
      # this is easy with e^x
      s.configure(:fixed_gradients => s.data)

      lb,ub = s.domain
      lb.should be_close(-2.0, 0.0000001)
      ub.should be_close(2.0, 0.0000001)

      # check the interpolated function and its derivatives
      # fixing derivatives improves fit, of course, especially at endpoints
      [-2.0, -1.75, -1.5, -1.25, -1.0, -0.75, -0.5, -0.25, 0.0, 0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0].each do |x|
        #print "x=%f   exp(x)=%f  q(x)=%f   q'(x)=%f   q''(x)=%f\n" % [x, Math.exp(x), s.q(x), s.qp(x), s.qpp(x)]        
        s.q(x).should be_close(Math.exp(x), 0.001)
        s.qp(x).should be_close(Math.exp(x), 0.001)
        s.qpp(x).should be_close(Math.exp(x), 0.01)
        check_gradients(s, x) == true
      end
    end


    it "should interpolate a sin function using monotonic gradients fixed to zero at endpoints" do
      pi = Math::PI
      s = CubicHermiteSpline.new

      # sample a sin function over [-pi/2, pi/2]
      n = 50
      (0..n).each do |j|
        x = -pi/2.0 + pi*j.to_f/n.to_f
        s << [x, Math.sin(x)]
      end

      s.domain.should == [s.x.first, s.x.last]

      s.configure(:gradient_method => CubicHermiteSpline::MONOTONIC, :fixed_gradients => {s.x.first => 0.0, s.x.last => 0.0})

      # check the interpolated function and its derivatives
      [-1.5, -1.25, -1.0, -0.75, -0.5, -0.25, 0.0, 0.25, 0.5, 0.75, 1.0, 1.25, 1.5].each do |x|
        s.q(x).should be_close(Math.sin(x), 0.001)
        s.qp(x).should be_close(Math.cos(x), 0.01)
        s.qpp(x).should be_close(-Math.sin(x), 0.1)

        check_gradients(s, x) == true
      end

      step = 0.001
      x = s.x.first
      while x+step <= s.x.last
        # monotonic increasing
        s.q(x).should <= s.q(x+step)
        s.qp(x).should >= 0.0
        x += 0.001
      end
    end

    it "should interpolate a sin function using strict monotonic gradients fixed to zero at endpoints" do
      pi = Math::PI
      s = CubicHermiteSpline.new

      # sample a sin function over [-pi/2, pi/2]
      n = 50
      (0..n).each do |j|
        x = -pi/2.0 + pi*j.to_f/n.to_f
        s << [x, Math.sin(x)]
      end

      s.domain.should == [s.x.first, s.x.last]

      s.configure(:gradient_method => CubicHermiteSpline::STRICT_MONOTONIC, :fixed_gradients => {s.x.first => 0.0, s.x.last => 0.0})

      # check the interpolated function and its derivatives
      [-1.5, -1.25, -1.0, -0.75, -0.5, -0.25, 0.0, 0.25, 0.5, 0.75, 1.0, 1.25, 1.5].each do |x|
        s.q(x).should be_close(Math.sin(x), 0.001)
        s.qp(x).should be_close(Math.cos(x), 0.01)
        s.qpp(x).should be_close(-Math.sin(x), 0.1)

        check_gradients(s, x) == true
      end

      step = 0.001
      x = s.x.first + step
      while x+step < s.x.last
        # monotonic increasing
        s.q(x).should < s.q(x+step)
        s.qp(x).should > 0.0
        x += 0.001
      end
    end

    it "should yield monotonic gradient (> 0) on sampled gaussian cdf" do
      data={-4.688791821788602=>3.999840006399744e-05, -1.6586371136261417=>0.0500379984800608, -1.3046562825563783=>0.1000359985600576, -1.0585991730429565=>0.1500339986400544, -0.8503819522760259=>0.2000319987200512, -0.6843423603976588=>0.250029998800048, -0.5343365012569704=>0.3000279988800448, -0.39296083510325713=>0.3500259989600416, -0.2624319742883667=>0.4000239990400384, -0.13325007586972948=>0.4500219991200352, -0.011579531102110765=>0.500019999200032, 0.12175742387365864=>0.5500179992800288, 0.2526208288094714=>0.6000159993600256, 0.38616795499830364=>0.6500139994400224, 0.5235683479504966=>0.7000119995200192, 0.6732220650984888=>0.750009999600016, 0.8452512292193505=>0.8000079996800128, 1.0444070020971699=>0.8500059997600096, 1.2843441198060288=>0.9000039998400065, 1.6543865091627852=>0.9500019999200032, 4.103609078585672=>0.999960001599936}

      s = CubicHermiteSpline.new
      s.configure(:gradient_method => CubicHermiteSpline::STRICT_MONOTONIC)
      s << data

      lb, ub = s.domain

      check_monotonic(s, lb, ub)
    end
  end
end
