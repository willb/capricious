require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

module Capricious
  EXPECTED_MEAN = 0.5
  EXPECTED_STDDEV = 0.288675134594813
  SAMPLE_COUNT = 20000

  describe Uniform do
    def generate_samples(policy=MWC5, count=SAMPLE_COUNT)
      @uniform = Capricious::Uniform.new(nil, policy, true)
      count.times {@uniform.next}
    end
    
    [LFSR,MWC5].each do |policy|
      it "should, given policy #{policy.name}, generate numbers in the range (0,1]" do
        generate_samples(policy)
        @uniform.aggregate.max.should <= 1.0
        @uniform.aggregate.min.should > 0.0
      end

      it "should, given policy #{policy.name}, generate uniformly-distributed numbers in the range (0,1], as judged by mean and variance estimates" do
        generate_samples(policy)
        @uniform.aggregate.mean.should be_close(EXPECTED_MEAN, 0.01)
        @uniform.aggregate.stddev.should be_close(EXPECTED_STDDEV, 0.01)
      end
    
      it "should, given policy #{policy.name}, generate the same sequence given the same seed" do
        @uniform = Uniform.new(nil, policy, false)
        @uniform2 = Uniform.new(nil, policy, false)
        (SAMPLE_COUNT/10).times { @uniform2.next.should == @uniform.next }
      end
    end
  end
end
