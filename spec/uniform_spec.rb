require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

module Capricious
  EXPECTED_MEAN = 0.5
  EXPECTED_STDDEV = 0.288675134594813
  SAMPLE_COUNT = 200000

  describe Uniform do
    def generate_samples(count=SAMPLE_COUNT)
      count.times {@uniform.next}
    end
    
    before(:each) do
      @uniform = Capricious::Uniform.new(nil, LFSR, true)
    end
    
    it "should generate numbers in the range (0,1]" do
      generate_samples
      @uniform.aggregate.max.should <= 1.0
      @uniform.aggregate.min.should > 0.0
    end

    it "should generate uniformly-distributed numbers in the range (0,1], as judged by mean and variance estimates" do
      generate_samples
      @uniform.aggregate.mean.should be_close(EXPECTED_MEAN, 0.01)
      @uniform.aggregate.stddev.should be_close(EXPECTED_STDDEV, 0.01)
    end
    
    it "should generate the same sequence given the same seed" do
      @uniform2 = Uniform.new(@uniform.seed, LFSR, true)
      SAMPLE_COUNT.times { @uniform2.next.should == @uniform.next }
    end
  end
end
