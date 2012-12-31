if ENV.has_key?("COVERAGE")
  require "simplecov"
  SimpleCov.start() do
    add_filter("test")
  end
end

# This line is required to let RubyMine run the test suite,
# since otherwise random packages load other random packages
# in random order and clobber RubyMine's configuration.
# See http://youtrack.jetbrains.com/issue/RUBY-11922
$:.unshift($:.select {|i| i.include? '/patch/'}).flatten!

require 'test/unit'

$:.unshift File.expand_path(File.join([File.dirname(__FILE__), "..", "lib"]))

def read_splunkrc
  file = File.new(File.expand_path("~/.splunkrc"))
  options = {
      :host => 'localhost',
      :port => 8089,
      :username => 'admin',
      :password => 'changeme',
      :scheme => 'https',
      :version => '5.0'
  }
  file.readlines.each do |raw_line|
    line = raw_line.strip()
    if line.start_with?("\#") or line.length == 0
      next
    else
      raw_key, raw_value = line.split('=', limit=2)
      key = raw_key.strip().intern
      value = raw_value.strip()

      if key == 'port'
        value = Integer(value)
      end

      options[key] = value
    end
  end

  options
end

def nokogiri_available?
  begin
    require 'nokogiri'
    return true
  rescue LoadError
    return false
  end
end

class SplunkTestCase < Test::Unit::TestCase
  def setup
    super
    @splunkrc = read_splunkrc()
  end

  def teardown

    super
  end

  def assert_logged_in(context)
    assert_nothing_raised do
      # A request to data/indexes requires you to be logged in.
      context.request(:method=>:GET,
                      :resource=>["data", "indexes"])
    end
  end

  def assert_not_logged_in(context)
    begin
      context.request(:method=>:GET,
                      :resource=>["data", "indexes"])
    rescue SplunkHTTPError => err
      assert_equal(401, err.code, "Expected HTTP status code 401, found: #{err.code}")
    else
      fail("Context is logged in.")
    end
  end
end