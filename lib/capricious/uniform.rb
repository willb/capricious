# capricious/uniform.rb:  uniform-distribution PRNG, with selectable source-randomness policy
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
  
  # Creates pseudorandom numbers in the range [0,1) that satisfy a uniform distribution.
  class Uniform
    include PRNG
    UNIFORM_MIN = 0.0
    UNIFORM_MAX = 1.0
    
    # Returns the expected mean for this distribution:  =(min + max) / 2=.
    def expected_mean
      (min + max) / 2
    end
    
    # Returns the expected variance for this distribution:  =(max - min) ** 2 / 12=.
    def expected_variance
      ((max - min) ** 2) / 12
    end
    
    private
    def min
      @min || UNIFORM_MIN
    end
    
    def max
      @max || UNIFORM_MAX
    end
    
    def next_value
      @prng.next_f
    end
  end
end