require 'rubygems'
require 'rdf'

class Base

  attr_reader :statements
  
  def initialize()
    @statements = []
  end  
  
  def add_property(predicate, object)
    add_statement( @uri, predicate, object )
  end
   
  def add_statement(subject, predicate, object)
    @statements << RDF::Statement.new( subject, predicate, object )
  end
  
  def normalize_tag( text )
    text = text.lstrip.rstrip
    text = text.chomp(";").chomp(".").chomp(")")
    text = text.split(" ").map{|word| word.capitalize}.join(" ")
    return text
  end
    
end