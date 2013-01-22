require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

module Capricious
  
  describe LogNormal do
    LOGNORMAL_SAMPLE_COUNT = 50000

    def generate_samples(policy, mean, variance, count=LOGNORMAL_SAMPLE_COUNT)
      # identify mu and sigmasq so that log-normal will have requested mean and variance
      # http://en.wikipedia.org/wiki/Log-normal_distribution
      sigmasq = Math.log(1.0 + (variance / (mean**2)))
      mu = Math.log(mean) - 0.5*sigmasq
      @randomvar = Capricious::LogNormal.new(mu, sigmasq, nil, policy, true)
      count.times {@randomvar.next}
    end
    
    [MWC5].each do |policy|
      [[2.5,1.5], [10.0,3.5]].each do |mean, variance|
      
        it "should, given policy #{policy.name}, generate log-normally-distributed numbers with a mean of #{mean} and a variance of #{variance}, as judged by mean estimates" do
          generate_samples(policy, mean, variance)
          @randomvar.aggregate.mean.should be_close(@randomvar.expected_mean, 0.02 * mean)
          @randomvar.aggregate.stddev.should be_close(Math.sqrt(@randomvar.expected_variance), 0.02 * Math.sqrt(variance))
          @randomvar.aggregate.variance.should be_close(@randomvar.expected_variance, 0.02 * variance)
        end
        
      end
      
      it "should, given policy #{policy.name}, generate the same sequence given the same seed" do
        @randomvar = Normal.new(1.0, 1.5, nil, policy, false)
        @randomvar2 = Normal.new(1.0, 1.5, nil, policy, false)
        (LOGNORMAL_SAMPLE_COUNT/10).times { @randomvar2.next.should == @randomvar.next }
      end
      
    end
  end
end
