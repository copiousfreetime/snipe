#
# Julian Time helpers
#
# 
# The date conversions are currently easily enough done with the standard ruby
# libraries.  Snipe uses Modified Julian Day for day values and fractional day 
# in the sense of Julian Day
#
require 'date'
require 'time'
module Snipe
  module Julian
    module Date
      module ClassMethods
        # convert a modified julian day to a civil day
        def mjd_to_civil( mjd )
          jd = ::Date.mjd_to_jd( mjd )
          d = ::Date.jd_to_civil( jd )
        end
      end
      ::Date.extend( ClassMethods )
    end

    module Time

      SECONDS_PER_DAY = 86400

      module ClassMethods

        # convert from a modified julian day to a Time
        def from_mjd( mjd )
          d = ::Date.mjd_to_civil( mjd )
          ::Time.gm( d[0], d[1], d[2] )
        end

        def now_as_mjd_stamp
          ::Time.now.utc.mjd_stamp
        end

        # convert from a modified julian day stamp to a Time
        def from_mjd_stamp( mjd_stamp )
          mjd, fraction = mjd_stamp.split(".")
          d = ::Date.new( *::Date.mjd_to_civil( mjd.to_i ) )

          fraction      = Float( "0.#{fraction}")
          amt = (SECONDS_PER_DAY * fraction).round

          ss  = amt % 60
          amt = (amt - ss) / 60
          mm  = amt % 60
          hh  = (amt - mm) / 60

          ::Time.gm( d.year, d.month, d.day, hh, mm, ss )
        end
      end
      ::Time.extend( ClassMethods )

      module InstanceMethods
        def seconds_of_day
          ((hour * 3600) + (min * 60) + (sec) + (usec/1_000_000)).to_f
        end

        # calculate the modified julian day fraction
        def mjd_fraction
          seconds_of_day / SECONDS_PER_DAY
        end

        # the iteger portion of a modified julian day
        def mjd
          to_date.mjd
        end

        # generate a #####.##### stringn that is the modified julian day plus
        # the fractional portion of the day.
        def mjd_stamp
        "%0.5f" % (mjd + mjd_fraction)
        end
      end
    end
  end
end

class Time
  include Snipe::Julian::Time::InstanceMethods
end
