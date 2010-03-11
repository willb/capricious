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
  # Linear-feedback shift register class
  class LFSR

    attr_reader :seed

    def LFSR.new_with_seed(seed)
      LFSR.new(nil, seed)
    end
    
    # initializes
    def initialize(size=nil, seed=nil)
      size = size || (0.size * 8)
      case size
      when 64
        @ns = SixtyFourBitShifter
        class << self ; include SixtyFourBitShifter ; private :shift_reg ; end
      when 32
        @ns = ThirtyTwoBitShifter
        class << self ; include ThirtyTwoBitShifter ; private :shift_reg ; end
      when 16
        @ns = SixteenBitShifter
        class << self ; include SixteenBitShifter ; private :shift_reg ; end
      else
        @ns = ThirtyTwoBitShifter
        class << self ; include ThirtyTwoBitShifter ; private :shift_reg ; end
      end
      
      reset
    end

    def next
      shift_reg
      @reg
    end

    def next_f
      self.next
      @reg.quo(@ns::MASK.to_f)
    end

    def reset(seed=nil)
      @seed ||= (seed || Time.now.utc.to_i) & @ns::MASK
      @reg = @seed
    end
  end

  module SixtyFourBitShifter
    MASK = 0xffffffffffffffff
    SIZE = 64
    BITS = [64,63,61,60]
    BITSELECT = BITS.map {|bit| "@reg[#{SIZE-bit}]"}.join("^")
    
    class_eval <<-SHIFT_REG
    def shift_reg
      bit = #{BITSELECT}
      @reg = (@reg >> 1) | (bit << #{SIZE-1})
    end
    SHIFT_REG
  end 
  
  module ThirtyTwoBitShifter
    MASK = 0xffffffff
    SIZE = 32
    BITS = [32,31,30,10]
    BITSELECT = BITS.map {|bit| "@reg[#{SIZE-bit}]"}.join("^")
    
    class_eval <<-SHIFT_REG
    def shift_reg
      bit = #{BITSELECT}
      @reg = (@reg >> 1) | (bit << #{SIZE-1})
    end
    SHIFT_REG
  end

  module SixteenBitShifter
    MASK = 0xffff
    SIZE = 16
    BITS = [16,14,13,11]
    BITSELECT = BITS.map {|bit| "@reg[#{SIZE-bit}]"}.join("^")
    
    class_eval <<-SHIFT_REG
    def shift_reg
      bit = #{BITSELECT}
      @reg = (@reg >> 1) | (bit << #{SIZE-1})
    end
    SHIFT_REG
  end
  
  nil
end

