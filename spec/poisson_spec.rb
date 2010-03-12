require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

module Capricious
  LAMBDA = 12
  SAMPLE_COUNT = 200

  describe Poisson do
    def generate_samples(count=SAMPLE_COUNT)
      count.times {@poisson.next}
    end
    
    before(:each) do
      @poisson = Capricious::Poisson.new(LAMBDA, nil, LFSR, true)
    end
    
    it "should generate distributed numbers in a Poisson distribution with lambda #{LAMBDA}, as judged by mean and variance estimates" do
      generate_samples(40000)
      puts @poisson.aggregate.inspect
      @poisson.aggregate.mean.should be_close(LAMBDA, 0.05)
      @poisson.aggregate.variance.should be_close(LAMBDA, 0.05)
    end
    
    it "should generate the same sequence given the same seed" do
      @poisson2 = Poisson.new(LAMBDA, @poisson.seed, LFSR, true)
      SAMPLE_COUNT.times { @poisson2.next.should == @poisson.next }
    end
  end
end
