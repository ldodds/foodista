$:.unshift File.join(File.dirname(__FILE__), "..", "lib")

require 'rubygems'
require 'open-uri'
require 'hpricot'
require 'Crawler'

INDEX = "http://www.foodista.com/browse/foods"

crawler = Crawler.new(INDEX, ARGV[0])
puts "Caching Foods"

pages = crawler.find_pages()
puts "Found #{pages.size} Foods"

crawler.cache_pages()

puts "Completed"