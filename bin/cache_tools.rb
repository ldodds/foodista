require 'rubygems'
require 'open-uri'
require 'hpricot'

BASE = "http://www.foodista.com"
INDEX = "http://www.foodista.com/browse/tools"

def cache_page(url)
  
  match = url.match(/http\:\/\/www\.foodista\.com\/tool\/([A-Z0-9]+)\/.+/)
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

puts "Caching Tools"
doc = Hpricot(open(INDEX))
secondary_indexes = []
doc.search("#col1 ul li a").each do |link|
  secondary_indexes << "#{BASE}#{link["href"]}"
end

tools = []
secondary_indexes.each do |index|
  i = Hpricot( open(index) )
  i.search("#col1 ul li a").each do |link|
    tools << "#{BASE}#{link["href"]}"
  end
end

puts "Found #{tools.size} Tools"
count = 0
tools.each do |link|
  cache_page(link)
  count = count + 1
  if count % 1000 == 0
    puts "Fetched #{count} of #{tools.size}" 
  end
end
puts "Completed"