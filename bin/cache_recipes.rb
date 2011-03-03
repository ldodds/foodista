require 'rubygems'
require 'open-uri'
require 'hpricot'

BASE = "http://www.foodista.com"
INDEX = "http://www.foodista.com/browse/recipes"

def cache_page(url)
  
  match = url.match(/http\:\/\/www\.foodista\.com\/recipe\/([A-Z0-9]+)\/.+/)
  if match
    uri = URI.parse( url )
    begin
      page_data = uri.read
      f = File.open( File.join(ARGV[0], match[1]), "w" )
      f.puts(page_data)
    rescue => e
      puts e
      puts "Unable to fetch #{url}"
    end 
  else
    puts "Warning: Unknown url pattern for #{url}"
  end
  sleep(0.5)  
end

puts "Caching Recipes"
doc = Hpricot(open(INDEX))
secondary_indexes = []
doc.search("#col1 ul li a").each do |link|
  secondary_indexes << "#{BASE}#{link["href"]}"
end

recipes = []
index = secondary_indexes.pop
while (index != nil)
  if !index.start_with?("http://www.foodista.com/browse/recipes")
    recipes << index
  else
    puts "Processing #{index}"
    i = Hpricot( open(index) )
    i.search("#col1 ul li a").each do |link|
      if link["href"].start_with?("/browse/recipes")
        secondary_indexes.push( "#{BASE}#{link["href"]}" )
      else
        recipes << "#{BASE}#{link["href"]}"
      end    
    end    
  end
  index = secondary_indexes.pop
end

puts "Found #{recipes.size} Recipes"
count = 0
recipes.each do |link|
  cache_page(link)
  count = count + 1
  if count % 1000 == 0
    puts "Fetched #{count} of #{recipes.size}" 
  end
end
puts "Completed"
