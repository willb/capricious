# capricious/cubic_hermite_spine.rb:  A cubic Hermite spline utility
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

  class CubicHermiteSpline
    # gradient methods, select with :gradient_method => <method> 
    FINITE_DIFFERENCE = 'finite_difference'
    WEIGHTED_SECANT = 'weighted_secant'
    SMOOTH = 'smooth'

    # these gradient methods not yet implemented
    CARDINAL = 'cardinal'
    CATMULL_ROM = 'catmull_rom'

    # monotonic enforcement options
    NONE = 'none'
    NONSTRICT = 'nonstrict'
    STRICT = 'strict'

    def initialize(args = {})
      reset
      configure(args)
    end

    def reset
      @args = { :data => nil, :gradient_method => FINITE_DIFFERENCE, :strict_domain => true, :monotonic => NONE, :monotonic_epsilon => 1e-6, :fixed_gradients => {}}
      clear
    end

    def clear
      @h = {}
      dirty!
    end

    def configure(args = {})
      @args.merge!(args)

      begin
        t = {}
        @args[:fixed_gradients].to_a.each { |x,y| t[x.to_f] = y.to_f }
        @args[:fixed_gradients] = t
      rescue
        raise ArgumentError, "failed to acquire :fix_gradient arg as mapping of Float -> Float"
      end

      if @args[:data] then
        clear
        enter(canonical(@args[:data]))
        @args[:data] = nil
      end

      dirty!
    end

    def <<(data)
      enter(canonical(data))
      self
    end

    # synonym for << operator above
    def put(data)
      enter(canonical(data))
      nil
    end

    def dirty?
      (@m == nil) or (@x.length != @h.length)
    end

    def configuration
      @args.clone.freeze
    end

    def data
      @h.clone.freeze
    end

    def x
      recompute if dirty?
      @x.clone.freeze
    end

    def y
      recompute if dirty?
      @y.clone.freeze
    end

    def m
      recompute if dirty?
      @m.clone.freeze
    end

    def domain
      recompute if dirty?
      [@x.first, @x.last]
    end

    def q(x)
      recompute if dirty?
      j0, j1, t, h = find(x.to_f)
      (2.0*t**3 - 3.0*t**2 + 1)*@y[j0] + (t**3 - 2.0*t**2 + t)*h*@m[j0] + (3.0*t**2 - 2.0*t**3)*@y[j1] + (t**3 - t**2)*h*@m[j1]
    end

    def qp(x)
      recompute if dirty?
      j0, j1, t, h = find(x.to_f)
      ((6.0*t**2 - 6.0*t)*@y[j0] + (3.0*t**2 - 4.0*t + 1.0)*h*@m[j0] + (6.0*t - 6.0*t**2)*@y[j1] + (3.0*t**2 - 2.0*t)*h*@m[j1])/h
    end

    def qpp(x)
      recompute if dirty?
      j0, j1, t, h = find(x.to_f)
      ((12.0*t - 6.0)*@y[j0] + (6.0*t - 4.0)*h*@m[j0] + (6.0 - 12.0*t)*@y[j1] + (6.0*t - 2.0)*h*@m[j1])/(h**2)
    end

    def recompute
      return if not dirty?

      @x, @y = @h.to_a.sort.transpose
      raise ArgumentError, "insufficient data, require >= 2 points" if @y.length < 2

      # fill gradient 'm' vector using requested method
      case @args[:gradient_method]
        when FINITE_DIFFERENCE
          finite_difference
        when WEIGHTED_SECANT
          weighted_secant
        when SMOOTH
          smooth
        else
          raise ArgumentError, "unimplemented gradient method %s" % [@args[:gradient_method]]
      end

      # fixed gradients override any computed gradients
      fg = @args[:fixed_gradients]
      0.upto(@m.length-1) { |j| @m[j] = fg[@x[j]] if fg.key?(@x[j]) }

      # monotonic enforcement overrides any gradient values
      case @args[:monotonic]
        when NONE
          nil
        when NONSTRICT
          monotonic_correction(false)
        when STRICT
          monotonic_correction(true)
        else
          raise ArgumentError, "unimplemented monotonic enforcement method %s" % [@args[:monotonic]]
      end

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
    # I'm currently just going to let dupes silently overwrite: 
    # other dupe policies could be implemented at will
    def enter(data)
      return if data.length <= 0
      data.each { |x,y| @h[x] = y }
      dirty!
    end

    def dirty!
      # reset anything that will need recomputing
      @x = @y = @m = nil
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
      t = (x - @x[jlo])/h

      [jlo, jhi, t, h]
    end


    def finite_difference
      # http://en.wikipedia.org/wiki/Cubic_Hermite_spline
      n = @x.length
      @m = Array.new(n, 0.0)

      # lower endpoint
      @m[0] = (@y[1]-@y[0]) / (@x[1]-@x[0])

      # interior points
      1.upto(n-2) do |j|
        g0 = (@y[j]-@y[j-1]) / (@x[j]-@x[j-1])
        g1 = (@y[j+1]-@y[j]) / (@x[j+1]-@x[j])
        @m[j] = (g0+g1)/2.0
      end

      # upper endpoint
      @m[n-1] = (@y[n-1]-@y[n-2]) / (@x[n-1]-@x[n-2])
    end


    def weighted_secant
      # this is a tweak of the gradient initialization method
      # described here:
      # http://en.wikipedia.org/wiki/Monotone_cubic_interpolation
      n = @x.length
      @m = Array.new(n, 0.0)
      d = Array.new(n-1, 0.0)

      0.upto(n-2) do |j|
        d[j] = (@y[j+1]-@y[j]) / (@x[j+1]-@x[j])
      end

      @m[0] = d[0]
      @m[n-1] = d[n-2]
      1.upto(n-2) do |j|
        # @m[j] = (d[j-1]+d[j])/2.0
        # this weighted version performs a bit better on non-uniform spacings:
        # it favors the secant that is closest
        h1 = @x[j]-@x[j-1]
        h = @x[j+1]-@x[j]
        @m[j] = (h*d[j-1] + h1*d[j])/(h1+h)
      end
    end


    def smooth
      # construct a tridiagonal matrix equation that embodies the
      # constraint that 2nd derivatives are continuous at knot points
      # (equivalently, 1st derivative is smooth across knots)
      # and solve the system to get the 'm' vector values that satisfy
      # the system
      n = @x.length
      fg = @args[:fixed_gradients]

      # tridiagonal coefficients to be filled below
      abc = []
      d = []

      # left endpoint
      if fg.key?(@x[0]) then
        # fixed gradient at left endpoint
        abc << [0.0, 1.0, 0.0]
        d << fg[@x[0]]
      else
        # default to natural spline:  y'' = 0
        h0 = @x[1]-@x[0]
        abc << [0.0, 4.0/h0, 2.0/h0]
        d << 6.0*(@y[1] - @y[0])/(h0**2)
      end

      # interior knots
      1.upto(n-2) do |j|
        h0 = @x[j]-@x[j-1]
        h1 = @x[j+1]-@x[j]
        abc << [2.0/h0, 4.0/h0 + 4.0/h1, 2.0/h1]
        d << 6.0*(@y[j+1]-@y[j])/(h1**2) + 6.0*(@y[j]-@y[j-1])/(h0**2)
      end

      # right endpoint
      if fg.key?(@x[n-1]) then
        # fixed gradient at left endpoint
        abc << [0.0, 1.0, 0.0]
        d << fg[@x[n-1]]
      else
        # default to natural spline:  y'' = 0
        h1 = @x[n-1]-@x[n-2]
        abc << [2.0/h1, 4.0/h1, 0.0]
        d << 6.0*(@y[n-1] - @y[n-2])/(h1**2)
      end

      # now solve the system for our gradients
      @m = solve_tridiagonal(abc, d)
    end


    def monotonic_correction(strict)
      # corrects gradients to enforce monotonicity
      # assumes 'm' vector is already initialized with gradients
      # http://en.wikipedia.org/wiki/Monotone_cubic_interpolation
      n = @x.length
      d = Array.new(n-1, 0.0)

      0.upto(n-2) do |j|
        d[j] = (@y[j+1]-@y[j]) / (@x[j+1]-@x[j])
      end

      # avoid instability from dividing by very small numbers
      eps = @args[:monotonic_epsilon]

      0.upto(n-2) do |j|
        delta = d[j]
        if delta.abs < eps then
          # a flat region
          @m[j] = @m[j+1] = 0.0
          next
        end

        a = @m[j]/delta
        b = @m[j+1]/delta

        if a < 0.0 or b < 0.0 then
          # the data itself is not monotone - go flat as a fallback
          # another policy might be to interpret this case as an exception
          @m[j] = @m[j+1] = 0.0
          next
        end

        if strict then
          z = a**2 + b**2
          if z > 9.0 then
            tau = 3.0 / Math.sqrt(z)
            @m[j] = tau*delta*a
            @m[j+1] = tau*delta*b
          end
        else
          @m[j] = 3.0*delta if a > 3.0 
          @m[j+1] = 3.0*delta if b > 3.0
        end
      end
    end


    def solve_tridiagonal(abc, d)
      # http://en.wikipedia.org/wiki/Tridiagonal_matrix_algorithm

      # a is sub diagonal, a[j] defined for j = 1 to n-1
      # b is main diagonal, b[j] defined for j = 0 to n-1
      # c is super diagonal, c[j] defined for j = 0 to n-2
      a,b,c = abc.clone.transpose
      x = d.clone
      n = x.length

      c[0] /= b[0]
      x[0] /= b[0]

      1.upto(n-1) do |j|
        z = 1.0 / (b[j] - a[j]*c[j-1])
        c[j] *= z
        x[j] = (x[j] - a[j]*x[j-1]) * z
      end

      (n-2).downto(0) do |j|
        x[j] = x[j] - c[j]*x[j+1]
      end

      # return x as solution to tridiagonal equation
      x
    end

  end

end
