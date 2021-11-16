#!/usr/bin/env ruby
#-*-ruby-*-
require 'nokogiri'
require 'open-uri'

VERSION_RANGE = 40..94
# VERSION_RANGE = 40..40

class FFVersion
  # @return [String]
  attr_accessor :ff_version
  # @return [Array<String>]
  attr_accessor :os_names

  def fetch
    puts "Fetching v#{ff_version}"
    uri = URI.parse("https://www.mozilla.org/en-US/firefox/#{ff_version}/system-requirements/")
    src = uri.read
    # src = IO.read  `curl ''`
    doc = Nokogiri::HTML::parse(src, "UTF-8")

    os_lis = doc.css('.mzp-c-article h3[id*="operating-systems"]').flat_map do |h3|
      get_next_ul = -> do
        node = h3
        node = node.next until node.name == 'ul'
        node
      end
      get_next_ul[].css('li')
    end
    @os_names = os_lis.map do |os_li|
      os_li.text.strip
    end
    self
  end

  def describe_oses
    os_names.join(', ')
  end
end

versions = VERSION_RANGE.map do |ff_version|
  (FFVersion.new).tap do |it|
    it.ff_version = "#{ff_version}.0"
    it.fetch
  end
end

begin
  table = versions.map do |ver|
    "|#{ver.ff_version}|#{ver.describe_oses}|"
  end.join("\n")

  out = <<-EOS
# Firefox Version to Supported OS Versions Table

See [README.md](README.md) for detail.

|Firefox|Supported OS|
|---|---|
#{table}
  EOS

  IO.write("table.md", out)
end
