# capricious/lfsr.rb:  linear-feedback shift register class
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

module Capricious
  class LFSR
  
    # initializes
    def initialize(size=nil, seed=nil)
      size = size || (0.size * 8)
      case size
      when 64
        @ns = SixtyFourBitShifter
      when 32
        @ns = ThirtyTwoBitShifter
      when 16
        @ns = SixteenBitShifter
      else
        @ns = ThirtyTwoBitShifter
      end
      
      reset(seed)
    end

    def next
      shift_reg
      @reg
    end
    
    def reset(seed=nil)
      @seed ||= (seed || Time.now.utc.to_i) & @ns::MASK
      @reg = @seed
    end
    
    private
    def shift_reg
      bit = @ns::BITS.inject(0) {|acc, bit| acc ^= @reg[@ns::SIZE-bit] ; acc }
      @reg = (@reg >> 1) | (bit << @ns::SIZE-1)
    end
    
  end

  module SixtyFourBitShifter
    MASK = 0xffffffffffffffff
    SIZE = 64
    BITS = [64,63,61,60]
  end 
  
  module ThirtyTwoBitShifter
    MASK = 0xffffffff
    SIZE = 32
    BITS = [32,22,2,1]
  end

  module SixteenBitShifter
    MASK = 0xffff
    SIZE = 16
    BITS = [16,14,13,11]
  end
  
  nil
end

