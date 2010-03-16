require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

module Capricious

  describe Exponential do
    EXP_LAMBDA = 8
    EXP_SAMPLE_COUNT = 200

    def generate_samples(count=EXP_SAMPLE_COUNT)
      count.times {@expo.next}
    end
    
    before(:each) do
      @expo = Capricious::Exponential.new(EXP_LAMBDA, nil, MWC5, true)
    end
    
    it "should generate distributed numbers in an exponential distribution with lambda #{EXP_LAMBDA}, as judged by mean and variance estimates" do
      generate_samples(10000)
      
      @expo.aggregate.mean.should be_close(@expo.expected_mean, 0.05)
      @expo.aggregate.variance.should be_close(@expo.expected_variance, 0.15)
    end
    
    it "should generate the same sequence given the same seed" do
      @expo2 = Exponential.new(EXP_LAMBDA, @expo.seed, MWC5, true)
      EXP_SAMPLE_COUNT.times { @expo2.next.should == @expo.next }
    end
  end
end
