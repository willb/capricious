# capricious/exponential.rb:  Erlang distribution PRNG, with selectable source-randomness policy
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
require 'capricious/exponential'

module Capricious
  # Models the Erlang distribution, parameterized on the lambda value of the
  # underlying exponential distribution and a shape parameter.
  class Erlang
    include PRNG
    
    attr_reader :expected_mean, :expected_variance
    
    # Initializes a new Erlang distribution.  =l= is the lambda parameter and
    # =shape= is the shape parameter; =seed=, =policy=, and =keep_stats= are
    # as in =PRNG=.
    def initialize(l, shape, seed=nil, policy=MWC5, keep_stats=false)
      @shape = shape
      @expected_mean = shape / l.to_f
      @expected_variance = shape / (l * l).to_f
      @expo = Exponential.new(l, seed, policy, keep_stats)
      prng_initialize(seed, policy, keep_stats)
    end
    
    private
    def next_value
      sum = 0.0
      @shape.times { sum += @expo.next; puts sum }
      sum
    end
  end
end