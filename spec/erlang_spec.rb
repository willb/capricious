require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

module Capricious

  describe Erlang do
    ERL_LAMBDA = 3
    R = 6
    ERL_SAMPLE_COUNT = 200

    def generate_samples(count=ERL_SAMPLE_COUNT)
      count.times {@erlang.next}
    end
    
    before(:each) do
      @erlang = Capricious::Erlang.new(ERL_LAMBDA, R, nil, MWC5, true)
    end
    
    it "should generate distributed numbers in an Erlang distribution with lambda #{ERL_LAMBDA} and r #{R}, as judged by mean and variance estimates" do
      generate_samples(10000)
      
      @erlang.aggregate.mean.should be_close(@erlang.expected_mean, 0.05)
      @erlang.aggregate.variance.should be_close(@erlang.expected_variance, 0.15)
    end
    
    it "should generate the same sequence given the same seed" do
      @erlang2 = Erlang.new(ERL_LAMBDA, R, @erlang.seed, MWC5, true)
      ERL_SAMPLE_COUNT.times { @erlang2.next.should == @erlang.next }
    end
  end
end
