# capricious/generic_prng.rb:  generic PRNG mixin with selectable source-randomness
#
# Copyright (c) 2010 Red Hat, Inc.
#
# Author:  William Benton <willb@redhat.com>
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
  module PRNG
    
    def initialize(seed=nil, policy=MWC5, keep_stats=false)
      prng_initialize(seed, policy, keep_stats)
    end
    
    def prng_initialize(seed=nil, policy=MWC5, keep_stats=false)
      @prng = policy.new_with_seed(seed)
      @seed = @prng.seed
      @aggregate = SampleSink.new if keep_stats
    end
    
    def next
      val = next_value
      @aggregate << val if @aggregate
      val
    end

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