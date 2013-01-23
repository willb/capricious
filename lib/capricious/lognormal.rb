# capricious/lognormal.rb:  Log Normal distribution PRNG, with selectable source-randomness policy
#
# Copyright:: Copyright (c) 2013 Red Hat, Inc.
# Author::  Erik Erlandson <eje@redhat.com>
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
  # Log Normal distribution PRNG, uses polar form of Box-Muller transform.
  class LogNormal
    include PRNG
    
    attr_reader :expected_mean, :expected_variance
    
    # Initializes a new distribution.  =mu= and =sigmasq= are the distribution parameters; =seed=,
    # =policy=, and =keep_stats= are as in =PRNG=.
    def initialize(mu, sigmasq, seed=nil, policy=MWC5, keep_stats=false)
      @mu = mu.to_f
      @sigma = Math.sqrt(sigmasq.to_f)

      # http://en.wikipedia.org/wiki/Log-normal_distribution
      @expected_mean = Math.exp(@mu + 0.5*@sigma**2)
      @expected_variance = (Math.exp(@sigma**2) - 1.0)*@expected_mean**2

      @saved = nil
      prng_initialize(seed, policy, keep_stats)
    end

    private
    def next_value
      if @saved then
        r = @saved
        @saved = nil
        return r
      end

      u, v, r = 0, 0, 0
      begin
        u = 2 * @prng.next_f - 1
        v = 2 * @prng.next_f - 1
        r = u ** 2 + v ** 2
      end while r == 0 || r > 1
      
      c = Math.sqrt(-2 * Math.log(r) / r)

      @saved = Math.exp(@mu + @sigma*v*c)
      Math.exp(@mu + @sigma*u*c)
    end

  end
end
