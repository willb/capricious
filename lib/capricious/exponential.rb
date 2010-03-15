# capricious/exponential.rb:  Exponential distribution PRNG, with selectable source-randomness policy
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

require 'capricious/generic_prng'

module Capricious
  class Exponential
    include PRNG
    
    attr_reader :expected_mean, :expected_variance
    
    def initialize(l, seed=nil, policy=MWC5, keep_stats=false)
      @expected_mean = 1 / l.to_f
      @expected_variance = 1 / (l * l).to_f 
      prng_initialize(seed, policy, keep_stats)
    end
    
    private
    def next_value
      u = @prng.next_f
      while u == 0.0 || u == 1.0
        u = @prng.next_f
      end

      -expected_mean * Math.log(u)
    end
  end
end