require 'rubygems'
require 'open-uri'
require 'hpricot'

class Crawler
  
  BASE = "http://www.foodista.com"
  
  def initialize(index, basedir)
    @index = index
    @basedir = basedir
    @pages = []
  end
  
  def cache_page(url)    
    match = url.match(/http\:\/\/www\.foodista\.com\/(recipe|food|technique|tool)\/([A-Z0-9]+)\/.+/)
    if match
      uri = URI.parse( url )
      begin
        page_data = uri.read
        f = File.open( File.join(ARGV[0], match[2]), "w" )
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
  
  def add_links(doc)  
    doc.search("#block-system-main .views-field .field-content a").each do |a|
      @pages << "#{BASE}#{a["href"]}"
    end  
  end
  
  def page_count(doc)
    pager = doc.search(".pager-last a")[0]["href"]
    if pager == nil
      puts "Unable to find additional pages!"
      return 0
    end
    
    pages = pager.match(/([0-9]+)$/)[0].to_i
    return pages    
  end
  
  def find_pages
    doc = Hpricot(open(@index))        
    add_links(doc)
    
    pages = page_count(doc)
    pages.times do |page|
      url = "#{@index}?page=#{page+1}"
      puts url
      doc = Hpricot( open(url) )
      add_links(doc)
    end    
    return @pages
  end
  
  def cache_pages(limit=0)
    count = 0
    @pages.each do |page|
      cache_page(page)
      count = count + 1
      if count % 1000 == 0
        puts "Fetched #{count} of #{@pages.size}" 
      end
      if limit != 0 && count >= limit
        puts "Stopping early, reached limit of #{limit}"
        return
      end
    end    
  end
  
end