require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

module Capricious
  describe Poisson do
    P_LAMBDA = 8
    P_SAMPLE_COUNT = 200

    def generate_samples(count=P_SAMPLE_COUNT)
      count.times {@poisson.next}
    end
    
    before(:each) do
      @poisson = Capricious::Poisson.new(P_LAMBDA, nil, MWC5, true)
    end
    
    it "should generate distributed numbers in a Poisson distribution with lambda #{P_LAMBDA}, as judged by mean and variance estimates" do
      generate_samples(10000)
      @poisson.aggregate.mean.should be_close(P_LAMBDA, 0.05)
      @poisson.aggregate.variance.should be_close(P_LAMBDA, 0.15)
    end
    
    it "should generate the same sequence given the same seed" do
      @poisson2 = Poisson.new(P_LAMBDA, @poisson.seed, MWC5, true)
      P_SAMPLE_COUNT.times { @poisson2.next.should == @poisson.next }
    end
  end
end
