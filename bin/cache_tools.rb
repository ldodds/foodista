$:.unshift File.join(File.dirname(__FILE__), "..", "lib")

require 'rubygems'
require 'open-uri'
require 'hpricot'
require 'Crawler'

INDEX = "http://www.foodista.com/browse/tools"

crawler = Crawler.new(INDEX, ARGV[0])
puts "Caching Tools"

pages = crawler.find_pages()
puts "Found #{pages.size} Tools"

crawler.cache_pages()

puts "Completed"