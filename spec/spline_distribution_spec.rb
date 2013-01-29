require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

module Capricious
  describe SplineDistribution do      
    def check_continuity(obj, meth, x)
      d = 0.1
      [0.1, 0.01, 0.001, 0.0001, 0.00001, 0.00001].each do |e|
        while d > 1e-10
          y = obj.send(meth, x)
          yl = obj.send(meth, x-d)  
          yu = obj.send(meth, x+d)
          break if (y-yl).abs + (y-yu).abs < 2.0*e
          d /= 10.0
        end
        d.should > 1e-10
      end
    end

    def check_pdf_cdf(sd, l, u, step = 0.001)
      x = l
      while (x <= u)
        #print "check_pdf_cdf failed: x= %f  pdf(x)= %f  cdf(x)= %f  domain=%s  data=%s\n" % [x, sd.pdf(x), sd.cdf(x), sd.spline.domain, sd.spline.data] if sd.pdf(x) < 0.0
        sd.pdf(x).should >= 0.0

        #print "check_pdf_cdf failed: x= %f  pdf(x)= %f  cdf(x)= %f\n" % [x, sd.pdf(x), sd.cdf(x)] if sd.cdf(x) < 0.0
        sd.cdf(x).should >= 0.0

        #print "check_pdf_cdf failed: x= %f  pdf(x)= %f  cdf(x)= %f\n" % [x, sd.pdf(x), sd.cdf(x)] if sd.cdf(x) > 1.0
        sd.cdf(x).should <= 1.0

        #print "check_pdf_cdf failed: x= %f  pdf(x)= %f  cdf(x)= %f\n" % [x, sd.pdf(x), sd.cdf(x)] if sd.cdf(x) > sd.cdf(x+step)
        sd.cdf(x).should <= sd.cdf(x+step)
        x += step
      end
    end

    it "should properly maintain data and configuration state" do
      sd = Capricious::SplineDistribution.new

      # default initial state
      sd.configuration.should == {:data => nil, :cdf_lb => SplineDistribution::SPLINE, :cdf_ub => SplineDistribution::SPLINE, :cdf_smooth_lb => false, :cdf_smooth_ub => false, :cdf_quantile => 0.05}
      sd.data.should == []
      sd.dirty?.should == true

      # configuration should not alter data (long as :data not given)
      sd.configure(:cdf_lb => -Float::INFINITY)
      sd.configuration.should == {:data => nil, :cdf_lb => -Float::INFINITY, :cdf_ub => SplineDistribution::SPLINE, :cdf_smooth_lb => false, :cdf_smooth_ub => false, :cdf_quantile => 0.05}
      sd.data.should == []
      sd.dirty?.should == true
      
      # adding data should show up, not alter config
      sd << 0
      sd.configuration.should == {:data => nil, :cdf_lb => -Float::INFINITY, :cdf_ub => SplineDistribution::SPLINE, :cdf_smooth_lb => false, :cdf_smooth_ub => false, :cdf_quantile => 0.05}
      sd.data.should == [0.0]
      sd.dirty?.should == true
      
      # ways to add data
      sd << 1
      sd.data.should == [0.0, 1.0]
      sd << [3, 4]
      sd.data.should == [0.0, 1.0, 3.0, 4.0]
      sd.put(5)
      sd.data.should == [0.0, 1.0, 3.0, 4.0, 5.0]
      sd.put([7, 77])
      sd.data.should == [0.0, 1.0, 3.0, 4.0, 5.0, 7.0, 77.0]

      # a recompute should be invoked, and no longer dirty
      sd.cdf(100).should <= 1.0
      sd.pdf(100).should >= 0.0
      sd.dirty?.should == false
      
      # add data, become dirty again
      sd << 10
      sd.dirty?.should == true
      sd.data.should == [0.0, 1.0, 3.0, 4.0, 5.0, 7.0, 77.0, 10.0]

      # a recompute should be invoked, and no longer dirty
      sd.cdf(100).should <= 1.0
      sd.pdf(100).should >= 0.0
      sd.dirty?.should == false
      
      # clear should remove data, but not change config
      sd.clear
      sd.configuration.should == {:data => nil, :cdf_lb => -Float::INFINITY, :cdf_ub => SplineDistribution::SPLINE, :cdf_smooth_lb => false, :cdf_smooth_ub => false, :cdf_quantile => 0.05}
      sd.data.should == []
      sd.dirty?.should == true

      # reset clears data and resets config
      sd << 42
      sd.reset
      sd.configuration.should == {:data => nil, :cdf_lb => SplineDistribution::SPLINE, :cdf_ub => SplineDistribution::SPLINE, :cdf_smooth_lb => false, :cdf_smooth_ub => false, :cdf_quantile => 0.05}
      sd.data.should == []
      sd.dirty?.should == true
    end


    it "should reconstruct a uniform distribution" do
      rv = Capricious::Uniform.new
      sd = Capricious::SplineDistribution.new
      sd.configure(:cdf_quantile => 0.2)
      25000.times { sd << rv.next }

      # check valid cdf/pdf behavior
      check_pdf_cdf(sd, -1.0, 2.0)

      sl, su = sd.support
      sl.should be_close(0.0, 0.01)
      su.should be_close(1.0, 0.01)

      x = sl
      while x <= su
        sd.cdf(x).should be_close(x, 0.025)
        sd.pdf(x).should be_close(1.0, 0.05)
        x += 0.01
      end

      sd.mean.should be_close(0.5, 0.05)
      sd.variance.should be_close(1.0/12.0, 0.005)
    end


    it "should reconstruct a gaussian distribution" do
      rv = Capricious::Normal.new(0.0, 1.0)
      sd = Capricious::SplineDistribution.new
      # request inifinite support
      sd.configure(:cdf_lb => -Float::INFINITY, :cdf_ub=> Float::INFINITY, :cdf_quantile => 0.01)
      50000.times { sd << rv.next }

      # check valid cdf/pdf behavior
      sl, su = sd.spline.domain
      check_pdf_cdf(sd, sl-0.1, su+0.1)

      z = 1.0 / Math.sqrt(2.0*Math::PI)
      x = sl-0.1
      while x <= su+0.1
        f = z * Math.exp(-0.5*x**2)
        #t = sd.pdf(x)
        #print "[%f, %f, %f]\n" % [x, f, t] if (f-t).abs > 0.1
        sd.pdf(x).should be_close(f, 0.1)
        x += 0.01
      end

      sd.support.should == [-Float::INFINITY, Float::INFINITY]

      # examine behavior around spline domain endpoints
      # continuity of y and y' should be obeyed at the boundary of
      # spline and exponential tails
      check_continuity(sd, :cdf, sl)
      check_continuity(sd, :cdf, su)
      check_continuity(sd, :pdf, sl)
      check_continuity(sd, :pdf, su)

      sd.mean.should be_close(0.0, 0.02)
      # variances are biased a bit high by the current algorithm,
      # would be nice to figure out a correction strategy some day
      sd.variance.should be_close(1.0, 0.1)
    end


    it "should reconstruct a gaussian distribution with smooth-endpoints" do
      rv = Capricious::Normal.new(0.0, 1.0)
      sd = Capricious::SplineDistribution.new
      # request inifinite support
      sd.configure(:cdf_smooth_lb => true, :cdf_smooth_ub => true, :cdf_quantile => 0.01)
      50000.times { sd << rv.next }

      # check valid cdf/pdf behavior
      sl, su = sd.spline.domain
      check_pdf_cdf(sd, sl-0.1, su+0.1)

      sd.support.should == [sl, su]
      sd.cdf(sl).should == 0.0
      sd.pdf(sl).should == 0.0
      sd.cdf(su).should == 1.0
      sd.pdf(su).should == 0.0

      z = 1.0 / Math.sqrt(2.0*Math::PI)
      x = sl-0.1
      while x <= su+0.1
        f = z * Math.exp(-0.5*x**2)
        #t = sd.pdf(x)
        #print "[%f, %f, %f]\n" % [x, f, t] if (f-t).abs > 0.1
        sd.pdf(x).should be_close(f, 0.1)
        x += 0.01
      end

      # examine behavior around spline domain endpoints
      # continuity of y and y' should be obeyed at the boundary of
      # spline and exponential tails
      check_continuity(sd, :cdf, sl)
      check_continuity(sd, :cdf, su)
      check_continuity(sd, :pdf, sl)
      check_continuity(sd, :pdf, su)

      sd.mean.should be_close(0.0, 0.02)
      # variances are biased a bit high by the current algorithm,
      # would be nice to figure out a correction strategy some day
      sd.variance.should be_close(1.0, 0.1)
    end

    it "should reconstruct an exponential distribution" do
      rv = Capricious::Exponential.new(1.0, nil, MWC5, true)
      sd = Capricious::SplineDistribution.new
      # request one-sided infinite support
      sd.configure(:cdf_ub=> Float::INFINITY, :cdf_quantile => 0.01)
      n = 0
      sx = 0.0
      sxx = 0.0
      50000.times do
        x = rv.next
        sd << x
        n += 1
        sx += x
        sxx += x**2
      end

      # check valid cdf/pdf behavior
      sl, su = sd.spline.domain
      check_pdf_cdf(sd, sl-0.1, su+0.1)

      sd.support.should == [sl, Float::INFINITY]
      sl.should be_close(0.0, 0.01)

      x = sl
      while x <= su+0.1
        f = Math.exp(-x)
        sd.pdf(x).should be_close(f, 0.1)
        x += 0.01
      end

      # examine behavior around spline domain endpoints
      # continuity of y and y' should be obeyed at the boundary of
      # spline and exponential tails
      check_continuity(sd, :cdf, sl)
      check_continuity(sd, :cdf, su)
      # pdf of an exponential distribution is not continuous on left end
      #check_continuity(sd, :pdf, sl)
      check_continuity(sd, :pdf, su)

      sd.mean.should be_close(1.0, 0.02)
      # variances are biased a bit high by the current algorithm,
      # would be nice to figure out a correction strategy some day
      sd.variance.should be_close(1.0, 0.1)
    end

  end
end
