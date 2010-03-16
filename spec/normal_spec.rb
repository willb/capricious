require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

module Capricious
  SAMPLE_COUNT = 30000
  
  describe Normal do
    def generate_samples(policy, mean, variance, count=SAMPLE_COUNT)
      @normal = Capricious::Normal.new(mean, variance, nil, policy, true)
      count.times {@normal.next}
    end
    
    [LFSR,MWC5].each do |policy|
      [[0.0,1.0], [10.0,3.5]].each do |mean, variance|
      
        it "should, given policy #{policy.name}, generate normally-distributed numbers with a mean of #{mean} and a variance of #{variance}, as judged by mean estimates" do
          generate_samples(policy, mean, variance)
          @normal.aggregate.mean.should be_close(@normal.expected_mean, 0.01 * [mean, 1.0].max)
        end
        
        it "should, given policy #{policy.name}, generate normally-distributed numbers with a mean of #{mean} and a variance of #{variance}, as judged by variance estimates" do
          generate_samples(policy, mean, variance)
          @normal.aggregate.stddev.should be_close(Math.sqrt(@normal.expected_variance), 0.075 * variance)
        end
      end
      
      it "should, given policy #{policy.name}, generate the same sequence given the same seed" do
        @normal = Normal.new(0.0, 1.0, nil, policy, false)
        @normal2 = Normal.new(0.0, 1.0, nil, policy, false)
        (SAMPLE_COUNT/10).times { @normal2.next.should == @normal.next }
      end
      
    end
  end
end
