require 'rubygems'
require 'Util'
require 'hpricot'
require 'Base'

class Tool < Base
  
  attr_reader :statements
  def initialize(id, html)
    @id = id
    @doc = Hpricot(html)
    @statements = []
    @uri = RDF::URI.new( Util.canonicalize("/tool/#{@id}"))
      
    @doc.search("meta").each do |meta|
      case meta["property"]
      when "og:title"
        @title = meta["content"]
      when "og:url"
        @homepage = meta["content"]
      when "og:image"
        @image = meta["content"] if @doc.search(".photo-vote").empty?
      end      
    end  
    
    @tags = []
    @doc.search("#content-meta p a").each do |link|
      if link["href"].match(/\/search\?tag=/)
        @tags << normalize_tag( link.inner_text )
      end
    end
    
    @other_names = []
    @doc.search("#content-meta p strong").each do |p|
      if p.inner_text =~ /Other Names/
        @other_names = p.parent.inner_text.gsub("Other Names: ", "").split(",").map{|x| x.lstrip.rstrip }
      end
    end

    @doc.search("h2").each do |heading|
      if heading.inner_text =~ /About #{@title}/
        if heading.next_sibling.at("p")
          @about = heading.next_sibling.at("p").inner_text
        end
      end
    end

    @related_links = []
    @doc.search(".related-external .more").each do |link|
      @related_links << link["href"]
    end
        
    generate_statements()    
  end
  
  def generate_statements()
    recipes = RDF::Vocabulary.new("http://linkedrecipes.org/schema/")
    
    add_property( RDF.type, recipes.Tool )
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
            
    @related_links.each do |link|
      #TODO primaryTopic/topic
      if ( /en\.wikipedia\.org/.match(link) )    
          dbpedia_uri = RDF::URI.new( link.sub("en.wikipedia.org/wiki", "dbpedia.org/resource") )
          add_property( RDF::OWL.sameAs, RDF::URI.new( dbpedia_uri ) )
          add_property( RDF::FOAF.isPrimaryTopicOf, RDF::URI.new( link ) )
          add_statement( RDF::URI.new( link ), RDF::FOAF.primaryTopic, @uri )
      end
    end
    
  end
end