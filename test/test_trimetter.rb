#!/usr/bin/ruby
require 'test/unit'
require 'trimetter'

class TrimetterTest < Test::Unit::TestCase
    # This is a tough thing to test.  It relies not only on a per-developer
    # developer ID.  It also relies on an external server being alive and
    # reachable from the test workstation.
    def test_query
        if File.exists?(File.expand_path("~/.trimetid"))
            trimetter = TrimetterArrivalQuery.new
            trimetter.debug = false
            trimetter.stop_list = [11925]
            trimetter.route_list = [14]
            results = Array.new
            error_string = ''
            rc = trimetter.fetch_update(results, error_string)
            assert_equal true, rc
            assert_equal '', error_string
        else
            print "No ~/.trimetid file found. Cannot run automated tests.\n"
        end
    end
end


