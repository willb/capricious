# capricious/cubicspine.rb:  A cubic spline utility
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

module Capricious

  class CubicSpline
    def initialize(args = {})
      reset
      configure(args)
    end

    # clears out data and sets configurations to defaults
    def reset
      @args = { :data => nil, :yp_lower => nil, :yp_upper => nil, :strict_domain => true }
      clear
    end

    # clears out data, but not configured behaviors
    def clear
      @h = {}
      dirty!
    end

    # update configuration.   config parameters not set here retain previous values
    # current data remains unchanged, unless :data is given
    def configure(args = {})
      @args.merge!(args)

      begin
        @ypl = @ypu = nil
        @ypl = @args[:yp_lower].to_f if @args[:yp_lower]
        @ypu = @args[:yp_upper].to_f if @args[:yp_upper]
      rescue
        raise ArgumentError, "failed to acquire :yp_lower and/or :yp_upper as a floating point"
      end

      @strict_domain = @args[:strict_domain]

      # if a :data argument was provided, then reset data to that argument
      if @args[:data] then
        clear
        enter(canonical(@args[:data]))
        # this one needs to be reset to nil - don't want it to persist after this call
        @args[:data] = nil
      end

      # compute state is now dirty
      dirty!
    end

    # add data to use for splining
    # supported formats include:
    # [x,y]
    # [[x,y], [x,y], ...]
    # { x=>y,  x=>y, ... }
    def <<(data)
      enter(canonical(data))
      self
    end

    # synonym for << operator above
    def put(data)
      enter(canonical(data))
      nil
    end

    # returns true if spline structures out of sync with current data entered
    def dirty?
      (@ypp == nil) or (@ypp.length != @h.length)
    end

    def configuration
      @args.clone.freeze
    end

    # return array of x values, as used by the spline algorithm
    def x
      recompute if dirty?
      @x.clone.freeze
    end

    # return array of y values, as used by the spline algorithm
    def y
      recompute if dirty?
      @y.clone.freeze
    end

    # return array of y'' values, as used by the spline algorithm
    def ypp
      recompute if dirty?
      @ypp.clone.freeze
    end

    # returns the [lower-bound, upper-bound] of the x axis the spline is defined on
    def domain
      recompute if dirty?
      return [@x.first, @x.last]
    end

    # returns the spline interpolation q(x)
    def q(x)
      recompute if dirty?
      jlo, jhi, h, a, b = find(x.to_f)
      a*@y[jlo] + b*@y[jhi] + ((a**3-a)*@ypp[jlo] + (b**3-b)*@ypp[jhi])*(h**2)/6.0
    end

    # returns the 1st derivative of the spline interpolation q'(x)
    def qp(x)
      recompute if dirty?
      jlo, jhi, h, a, b = find(x.to_f)
      (@y[jhi]-@y[jlo])/h - (3.0*a**2 - 1.0)*h*@ypp[jlo]/6.0 + (3.0*b**2 - 1.0)*h*@ypp[jhi]/6.0
    end

    # returns the 2nd derivative of the spline interpolation q''(x)
    def qpp(x)
      recompute if dirty?
      jlo, jhi, h, a, b = find(x.to_f)
      a*@ypp[jlo] + b*@ypp[jhi]
    end

    # explicitly invoke recomputation of spline structures
    def recompute
      return if not dirty?

      # first fill @x and @y from @h
      @x, @y = @h.to_a.sort.transpose
      raise ArgumentError, "insufficient data, require >= 2 points" if @y.length < 2

      # compute 2nd derivative vector
      compute_ypp
      nil
    end

    private
    def canonical(data)
      d = nil
      begin
        d = data.to_a
        case
          when d.count{|e| e.class<=Array and e.length == 2} == d.length
            d = d
          when d.length == 2
            d = [d]
          else
            raise ""
        end
        d.map!{|p| p.map{|e| e.to_f} }
      rescue
        raise ArgumentError, "failed to acquire data in supported format: [x,y], [[x1,y1], [x2,y2], ...], {x1 => y1, x2 => y2, ...}"
      end
      d
    end

    # assumes data in canonical format [[x,y],[x,y],...]
    # there are possible duplicate entry policies one could support
    # here: duplicate raises exception, duplicates are ignored, etc.
    # I'm currently just going to let dupes silently overwrite: 
    # any policy support can be backward compatible
    def enter(data)
      return if data.length <= 0
      data.each { |x,y| @h[x] = y }
      dirty!
    end

    def dirty!
      # reset anything that will need recomputing
      @x = @y = @ypp = nil
    end

    def find(x)
      raise ArgumentError, ("argument %f out of defined range (%f, %f)" % [x, @x.first, @x.last]) if (@strict_domain and (x < @x.first or x > @x.last))
      jlo = 0
      jhi = @y.length - 1
      while jhi - jlo > 1
        j = (jlo + jhi) / 2
        if @x[j] > x then
          jhi = j
        else
          jlo = j
        end
      end
      h = @x[jhi] - @x[jlo]
      # is this grossly inefficient? should look into it
      [jlo, jhi, h, (@x[jhi]-x)/h, (x-@x[jlo])/h]
    end

    def compute_ypp
      # compute 2nd derivatives y'' at each (x[j], y[j])
      # Numerical Recipes in C, 2nd ed.  Press, Teukolsky, Vetterling, Flannery
      # section 3.3: cubic spline interpolation

      n = @y.length
      @ypp = Array.new(n, 0.0)
      u = Array.new(n, 0.0)
      if @ypl then
        # low-end 1st derivative is being set by user
        # (default is to set 2nd derivative to zero for natural spline)
        @ypp[0] = -0.5
        u[0] = (3.0/(@x[1]-@x[0])) * ((@y[1]-@y[0])/(@x[1]-@x[0]) - @ypl)
      end

      # tridiagonal decomposition
      1.upto(n-2) do |j|
        sig = (@x[j]-@x[j-1])/(@x[j+1]-@x[j-1])
        p = sig*@ypp[j-1] + 2.0
        @ypp[j] = (sig-1.0)/p
        t = (@y[j+1]-@y[j])/(@x[j+1]-@x[j]) - (@y[j]-@y[j-1])/(@x[j]-@x[j-1])
        u[j] = (6.0*t/(@x[j+1]-@x[j-1]) - sig*u[j-1])/p
      end

      yppn = 0.0
      if @ypu then
        # high end 1st derivative is being set by user (otherwise natural spline)
        yppn = 0.5
        u[n-1] = (3.0/(@x[n-1]-@x[n-2])) * (@ypu - (@y[n-1]-@y[n-2])/(@x[n-1]-@x[n-2]))
      end

      # tridiagonal backsub
      @ypp[n-1] = (u[n-1] - yppn*u[n-2])/(yppn*@ypp[n-2] + 1.0)
      (n-2).downto(0) do |j|
        @ypp[j] = @ypp[j]*@ypp[j+1] + u[j]
      end
    end
  end
end
