require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

module Capricious

  describe BiasedUniform do
    BU_SAMPLE_COUNT = 60000
    MIN = 13.37
    MAX = 14.53
    
    def generate_samples(policy=MWC5, count=BU_SAMPLE_COUNT)
      @uniform = Capricious::BiasedUniform.new(MIN, MAX, nil, policy, true)
      count.times {@uniform.next}
    end
    
    [LFSR,MWC5].each do |policy|
      it "should, given policy #{policy.name}, generate numbers in the range (#{MIN},#{MAX}]" do
        generate_samples(policy)
        @uniform.aggregate.max.should <= MAX
        @uniform.aggregate.min.should > MIN
      end

      it "should, given policy #{policy.name}, generate uniformly-distributed numbers in the range (#{MIN},#{MAX}], as judged by mean and variance estimates" do
        generate_samples(policy)
        @uniform.aggregate.mean.should be_close(@uniform.expected_mean, 0.01)
        @uniform.aggregate.stddev.should be_close(Math.sqrt(@uniform.expected_variance), 0.01)
      end
    
      it "should, given policy #{policy.name}, generate the same sequence given the same seed" do
        @uniform = BiasedUniform.new(MIN, MAX, nil, policy, false)
        @uniform2 = BiasedUniform.new(MIN, MAX, nil, policy, false)
        (BU_SAMPLE_COUNT/40).times { @uniform2.next.should == @uniform.next }
      end
    end
  end
end
