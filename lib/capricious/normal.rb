# capricious/normal.rb:  Normal distribution PRNG, with selectable source-randomness policy
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

require 'capricious/generic_prng'

module Capricious
  # Normal-distribution PRNG, uses polar form of Box-Muller transform.
  class Normal
    include PRNG
    
    attr_reader :expected_mean, :expected_variance
    
    # Initializes a new distribution.  mean and variance are the distribution parameters; =seed=,
    # =policy=, and =keep_stats= are as in =PRNG=.
    def initialize(mean, variance, seed=nil, policy=MWC5, keep_stats=false)
      @expected_mean = mean.to_f
      @expected_variance = variance.to_f
      @stddev = Math.sqrt(@expected_variance)
      @values = []
      prng_initialize(seed, policy, keep_stats)
    end
    
    private
    def next_value
      return @values.pop if @values.size() > 0
      u, v, r = 0, 0, 0
      
      begin
        u = 2 * @prng.next_f - 1
        v = 2 * @prng.next_f - 1
        r = u ** 2 + v ** 2
      end while r == 0 || r > 1
      
      c = Math.sqrt(-2 * Math.log(r) / r)
      
      @values << scale(v * c)
      scale(u * c)
    end
    
    def scale(val)
      @expected_mean + (val * @stddev)
    end
  end
end