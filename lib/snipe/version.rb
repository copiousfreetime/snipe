#--
# Copyright (c) 2009 Jeremy Hinegardner
# All rights reserved.  See LICENSE and/or COPYING for details
#++

module Snipe
  module Version
    MAJOR   = 0
    MINOR   = 0
    BUILD   = 1

    def self.to_a 
      [MAJOR, MINOR, BUILD]
    end

    def self.to_s
      to_a.join(".")
    end

    def self.to_hash
      { :major => MAJOR, :minor => MINOR, :build => BUILD }
    end

    STRING = Version.to_s
  end
  VERSION = Version.to_s
end
