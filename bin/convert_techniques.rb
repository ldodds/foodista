$:.unshift File.join(File.dirname(__FILE__), "..", "lib")

require 'rubygems'
require 'rdf'
require 'Technique'

$KCODE="U"
Hpricot.buffer_size = 262144

File.open("#{ARGV[1]}/techniques.nt", "w") do |f|

  Dir.glob("#{ARGV[0]}/*") do |file|
    
    data = File.new(file)
    
    writer = RDF::NTriples::Writer.new( f )
    begin
     technique = Technique.new( File.basename(file), data )
     statements = technique.statements()
     statements.each do |stmt|
        writer << stmt
    end
    rescue StandardError => e
      puts "Failed to convert #{file}"
      puts e
      puts e.backtrace
    end
    
  end

end