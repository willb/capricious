# capricious/generic_prng.rb:  generic PRNG mixin with selectable source-randomness
#
# Copyright:: Copyright (c) 2010 Red Hat, Inc.
# Author::  William Benton <willb@redhat.com>
# License:: http://www.apache.org/licenses/LICENSE-2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'capricious/lfsr'
require 'capricious/mwc5'
require 'capricious/sample_sink'

module Capricious
  # Base mixin for distribution simulators.  Manages an underlying PRNG and
  # optional statistics.  Mixing =PRNG= in to a simulator class will define
  # =next= and =reset= methods as well as =@aggregate= and =@seed= attributes
  # and a =@prng= instance variable.  Simulator classes must define a
  # =next_value= method that returns a value in the given distribution and
  # should define =expected_mean= and =expected_variance= methods or
  # attributes.
  module PRNG
    
    # Takes a seed, a policy, and whether or not to keep statistics in the
    # =aggregate= attribute of the distribution object.  If a simulator class
    # overrides =initialize=, it must call =prng_initialize= from within its
    # =initialize= method.    
    def initialize(seed=nil, policy=MWC5, keep_stats=false)
      prng_initialize(seed, policy, keep_stats)
    end
    
    def prng_initialize(seed=nil, policy=MWC5, keep_stats=false)
      @prng = policy.new_with_seed(seed)
      @seed = @prng.seed
      @aggregate = SampleSink.new if keep_stats
    end
    
    # Returns the next value from this simulator.
    def next
      val = next_value
      @aggregate << val if @aggregate
      val
    end

    # Resets the state of the underlying value.
    def reset(seed=nil)
      @prng.reset(seed)
      @aggregate = SampleSink.new if @aggregate
    end
    
    def self.included(base)
      base.class_eval do
        attr_reader :aggregate, :seed
      end
    end
  end
end