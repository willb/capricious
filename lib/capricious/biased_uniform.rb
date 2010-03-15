# capricious/biased_uniform.rb:  biased uniform-distribution PRNG, with specifiable max and min and selectable source-randomness policy
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

require 'capricious/uniform'

module Capricious
  # Models a uniform distribution, parameterized on minimum and maximum values.
  class BiasedUniform < Uniform
    def initialize(min=Uniform::UNIFORM_MIN, max=Uniform::UNIFORM_MAX, seed=nil, policy=MWC5, keep_stats=false)
      @min = min
      @max = max
      prng_initialize(seed, policy, keep_stats)
    end
    
    private
    def next_value
      (@prng.next_f * (max - min)) + min
    end
  end
end