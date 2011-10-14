require 'rubygems'
require 'Util'
require 'hpricot'
require 'Base'

class Technique < Base
  
  attr_reader :statements
  def initialize(id, html)
    @id = id
    @doc = Hpricot(html)
    @statements = []
    @uri = RDF::URI.new( Util.canonicalize("/technique/#{@id}"))
      
    #title
    @title = @doc.at("h1").inner_text
    @title = @title.gsub("Technique: ", "")
    
    #url
    @doc.search("link").each do |link|
      if link["rel"] == "canonical"
        @homepage = link["href"]
      end
    end
    
    #image
    @image = @doc.at(".featured-image img")["src"]
    
    #tags
    #FIXME tools no longer have tags?
    @tags = []
    
    #about
    about = @doc.at(".pane-node-field-about .pane-content")
    @about = normalize_tag(about.inner_text) if about
              
    #other names        
    @other_names = []
    food_info = @doc.search(".technique_information .inline-field")
    if food_info.length > 1
      @other_names = food_info[0].inner_text.gsub("Other names: ", "").split(",").map{|x| x.lstrip.rstrip }      
    end
        
    generate_statements()    
  end
  
  def generate_statements()
    recipes = RDF::Vocabulary.new("http://linkedrecipes.org/schema/")
    
    add_property( RDF.type, recipes.PreparationMethod )
    add_property( RDF::RDFS.label, @title) if @title
    add_property( RDF::DC.description, @about) if @about 
    add_property( RDF::FOAF.depiction, @image) if @image
    if @homepage
      home = RDF::URI.new(@homepage)
      add_property( RDF::FOAF.isPrimaryTopicOf, home)
      add_statement( home, RDF::FOAF.primaryTopic, @uri)
    end
    
    @tags.each do |tag|
      uri = RDF::URI.new( Util.canonicalize( "/tags/#{ Util.slug(tag) }" ) )
      add_property( recipes.category, uri )
      add_statement( uri, RDF.type, RDF::SKOS.Concept )
      add_statement( uri, RDF::SKOS.prefLabel, RDF::Literal.new( tag ) )
    end
       
    @other_names.each do |name|
      add_property( RDF::SKOS.altLabel, RDF::Literal.new( name ) )
    end
    
  end
end