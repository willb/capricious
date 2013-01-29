# capricious:  random number generators for Ruby
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

require 'capricious/lfsr'
require 'capricious/mwc5'
require 'capricious/sample_sink'
require 'capricious/uniform'
require 'capricious/biased_uniform'
require 'capricious/poisson'
require 'capricious/exponential'
require 'capricious/erlang'
require 'capricious/normal'
require 'capricious/lognormal'
require 'capricious/cubic_spline'
require 'capricious/cubic_hermite_spline'
require 'capricious/spline_distribution'
