# capricious/poisson.rb:  Poisson-distribution PRNG, with selectable source-randomness policy
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
  class Poisson
    include PRNG
    
    alias prng_initialize initialize
    attr_reader :z
    
    def initialize(l, seed=nil, policy=LFSR, keep_stats=false)
      @z = Math.exp(-l)
      prng_initialize(seed, policy, keep_stats)
    end
    
    private
    # Algorithm 369, CACM, January 1970
    def next_value
      k = 0

      t = @prng.next_f
      while t > self.z
        k = k + 1
        t = t * @prng.next_f
      end
      
      k
    end
  end
end