# capricious/mwc5.rb:  32-bit multiply-with-carry PRNG
#
# Copyright (c) 2010 Red Hat, Inc.
#
# Author:  William Benton <willb@redhat.com>
# Algorithm due to George Marsaglia:  http://groups.google.com/group/comp.lang.c/msg/e3c4ea1169e463ae
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

module Capricious
  class MWC5
    attr_reader :seed, :seeds
    def MWC5.new_with_seed(seed)
      MWC5.new(seed)
    end
    
    def initialize(seed=nil)
      reset(seed)
    end
    
    def reset(seed=nil)
      @seed ||= (seed || Time.now.utc.to_i)
      unless @seeds
        seeder = LFSR.new_with_seed(@seed)
        @seeds = [seeder.next_i & 0xffffffff]
        4.times do
          9.times do
            # the observed lag-10 autocorrelation of the LFSRs is low
            seeder.next_i
          end
          @seeds << (seeder.next_i & 0xffffffff)
        end
      end
      
      @x,@y,@z,@w,@v = @seeds
    end
    
    def next_i
      shift_ks
    end
    
    def next_f
      next_i.quo(0xffffffff.to_f)
    end
    
    private
    def shift_ks
      # XXX:  this is ugly, but it has to be to avoid coercing things into bignums
      t=(@x^(@x>>7)) & 0xffffffff
      @x=@y
      @y=@z
      @z=@w
      @w=@v
      @v=(@v^(@v<<6))^(t^(t<<13)) & 0xffffffff
      yy = ((@y & 0x7fffffff << 1) + 1) & 0xffffffff
      (yy * @v) & 0xffffffff;
    end
  end
end