#--
# Copyright (c) 2009 Jeremy Hinegardner
# All rights reserved.  See LICENSE and/or COPYING for details.
#++

module Snipe
  module Paths
    # The root directory of the project is considered to be the parent directory
    # of the 'lib' directory.
    #   
    def self.root_dir
      @root_dir ||= (
        path_parts = ::File.expand_path(__FILE__).split(::File::SEPARATOR)
        lib_index  = path_parts.rindex("lib")
        path_parts[0...lib_index].join(::File::SEPARATOR) + ::File::SEPARATOR
      )
    end 

    def self.root_path( sub, *args )
      self.sub_path( root_dir, sub, *args )
    end

    def self.lib_path( *args )
      self.root_path( "lib", *args )
    end 

    def self.spec_path( *args )
      self.root_path( "spec", *args )
    end

    # The home dir is the home directory of snip while it is running, by default
    # this the same as the root_dir.  But if this value is set then it affects
    # other paths
    def self.home_dir
      @home_dir ||= self.root_dir
    end

    def self.home_dir=( other )
      @home_dir = File.expand_path( other )
    end

    def self.home_path( sub, *args )
      self.sub_path( home_dir, sub, *args )
    end

    def self.config_path( *args )
      self.home_path( "config", *args )
    end 

    def self.data_path( *args )
      self.home_path( "data", *args )
    end 

    def self.log_path( *args )
      self.home_path( "log", *args )
    end

    def self.tmp_path( *args )
      self.home_path( "tmp", *args )
    end

    def self.sub_path( parent, sub, *args )
      sp = ::File.join( parent, sub ) + File::SEPARATOR
      sp = ::File.join( sp, *args ) if args
    end
  end
end
