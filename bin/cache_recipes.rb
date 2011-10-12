$:.unshift File.join(File.dirname(__FILE__), "..", "lib")

require 'rubygems'
require 'open-uri'
require 'hpricot'
require 'Crawler'

INDEX = "hhttp://www.foodista.com/browse/recipes/page/1/0"

crawler = Crawler.new(INDEX, ARGV[0])
puts "Caching Recipes"

pages = crawler.find_pages()
puts "Found #{pages.size} Recipes"

crawler.cache_pages()

puts "Completed"