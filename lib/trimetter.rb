#!/usr/bin/ruby
# Trimetter : a simple Ruby library for interfacing with Trimet data
# Copyright (C) 2012, Brian Enigma <http://netninja.com>
#
# For more information about this library see: (TBD)
# For more information about the Trimet API see: <http://developer.trimet.org/>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

require "rexml/document"
require "net/http"
require "uri"

# ----------------------------------------

# A pure-data class to bundle a number of arrival properties
class TrimetterArrival
    attr_accessor :route, :location, :arrival_time, :arriving_in_minutes, :status, :sign_full, :sign_short
    def initialize()
        @route = ''
        @location = 0
        @arrival_time = Time.at(0)
        @arriving_in_minutes = 0
        @status = :invalid # can be invalid, estimated, scheduled, delayed, canceled, error
        @sign_full = 0
        @sign_short = 0
    end
    
    def to_s()
        result = '#'
        result << "#{@route} \"#{@sign_short}\"/\"#{@sign_full}\""
        result << " @ StopID #{@location}, "
        if :error == @status
            result << "[error]"
        elsif :canceled == @status
            result << "[canceled]"
        elsif :invalid == @status
            result << "[uninitialized]"
        elsif :estimated == @status
            result << "Arriving in #{@arriving_in_minutes} minute#{@arriving_in_minutes == 1 ? '' : 's'}"
        elsif :scheduled == @status
            result << "Arriving in #{@arriving_in_minutes} minute#{@arriving_in_minutes == 1 ? '' : 's'}???"
        elsif :delayed == @status
            result << "Arriving @ #{@arrival_time.strftime('%I:%M%p')}"
        else
            result << "YOU SHOULDN'T BE SEEING THIS"
        end
        return result
    end
end

# ----------------------------------------

# You will need to supply three things when calling:
#  - A Trimet developer ID.  Get one from http://developer.trimet.org/registration/
#  - An array of one or more stop IDs.  These are the 4 or 5 digits numbers assigned to each stop.
#  - An array of one or more bus numbers.  For instance, 14 or 17 or 9.
# Once these have been assigned, you can then call fetch_update.
# This will return an array of TrimetArrival structures.
# This class will automatically check for ~/.trimetid and, if it exists, use the
# first line as your Trimet developer ID.  This is so that you don't have to embed
# your ID in code (and risk accidentally checking it in to source control).
class TrimetterArrivalQuery
    attr_accessor :developer_id, :debug
    def initialize()
        @developer_id = ''
        @stop_list = Array.new
        @route_list = Array.new
        @debug = false;
        if File.exists?(File.expand_path("~/.trimetid"))
            f = File.new(File.expand_path("~/.trimetid"), "r")
            @developer_id = f.readline().strip()
            f.close()
        end
    end
    
    # Add elements, forcing numbers, removing duplicates
    def stop_list=(new_list)
        @stop_list.clear()
        new_list.flatten().each() { |i|
            @stop_list << i.to_i
        }
        @stop_list.uniq!
    end

    # Add elements, removing duplicates
    def route_list=(new_list)
        @route_list = new_list.flatten().uniq
    end
    
    # After setting your query parameters, call this to retrieve
    # live data from the server.  Note that all requests are tied
    # to your developer ID.  Try to space them out and not
    # overload their server.  If you slam their server, they can
    # block your ID.
    def fetch_update(result_array, error_string)
        result_array.clear()
        error_string.gsub!(/.*/, '')
        error_string << 'No developer ID given' if @developer_id.empty?
        error_string << 'No stop list given' if @stop_list.empty?
        error_string << 'No route list given' if @route_list.empty?
        return false unless error_string.empty?
        
        # Build request
        url = "http://developer.trimet.org/ws/V1/arrivals?appID=#{@developer_id}&locIDs="
        url << @stop_list.join(',')
        
        # Send request
        print "Sending request to #{url}\n" if @debug
        response = Net::HTTP.get(URI(url))
        print "Received #{response.length()} bytes\n" if @debug
        if response.empty?
            error_string << "Empty document returned"
            return false
        end
        print "\n\n#{response}\n\n\n" if @debug
        
        # Parse resulting XML
        begin
            document = REXML::Document.new(response)
        rescue
            error_string << "Error parsing XML"
            return false
        end
        
        # Server returned valid XML, but it contained an error node
        document.each_element("//errorMessage") { |el|
            error_string << el.get_text() if !el.get_text().empty?
        }
        return false unless error_string.empty?
        
        # Look for arrivals
        now = Time.new
        document.each_element("//arrival") { |el|
            arrival = TrimetterArrival.new
            arrival.route = el.attributes["route"].to_s.strip
            arrival.location = el.attributes["locid"].to_s.strip
            if el.attributes.has_key?("estimated")
                arrival.arrival_time = Time.at(el.attributes["estimated"].to_s.strip.to_i / 1000)
                arrival.status = :estimated
            elsif el.attributes.has_key?("scheduled")
                arrival.arrival_time = Time.at(el.attributes["scheduled"].to_s.strip.to_i / 1000)
                arrival.status = :scheduled
            end
            arrival.arriving_in_minutes = ((arrival.arrival_time - now) / 60).to_i
            if (arrival.arriving_in_minutes < 0 || arrival.arriving_in_minutes > 120)
                arrival.status = :error
            end
            if el.attributes["status"].to_s == "delayed"
                arrival.status = :delayed
            elsif el.attributes["status"].to_s == "canceled"
                arrival.status = :canceled
            end
            arrival.sign_full = el.attributes["fullSign"].to_s.strip
            arrival.sign_short = el.attributes["shortSign"].to_s.strip
            print "#{arrival.inspect}\n" if @debug
            result_array << arrival
        }
        error_string << 'No records found' if result_array.empty?
        return error_string.empty?
    end
end
