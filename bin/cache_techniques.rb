$:.unshift File.join(File.dirname(__FILE__), "..", "lib")

require 'rubygems'
require 'open-uri'
require 'hpricot'
require 'Crawler'

INDEX = "http://www.foodista.com/browse/techniques"

crawler = Crawler.new(INDEX, ARGV[0])
puts "Caching Techniques"

pages = crawler.find_pages()
puts "Found #{pages.size} Techniques"

crawler.cache_pages()

puts "Completed"