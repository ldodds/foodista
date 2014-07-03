require 'rubygems'
require 'hpricot'
require 'htmlentities'
require 'rdf'
require 'Base'
require 'Util'

class Recipe < Base
  
  attr_reader :statements
  def initialize(id, html)
    @id = id
    @doc = Hpricot(html)
    @statements = []
    @uri = RDF::URI.new( Util.canonicalize("/recipe/#{@id}"))
    
    #title
    @title = @doc.at("h1").inner_text.lstrip
    
    #url
    @doc.search("link").each do |link|
      if link["rel"] == "canonical"
        @homepage = link["href"]
      end
    end
    
    #image
    @image = @doc.at(".featured-image img")["src"]
        
    #about
    about = @doc.at(".pane-node-body .field-item")
    @about = normalize_tag(about.inner_text) if about
              
    #other names        
    @other_names = []
    food_info = @doc.search(".food_information .inline-field")
    if food_info.length > 1
      @other_names = food_info[0].inner_text.gsub("Other names: ", "").split(",").map{|x| x.lstrip.rstrip }      
    end
    
    @tags = []
    @doc.search(".field-type-taxonomy-term-reference .field-item").each do |tag|
      @tags << normalize_tag( tag.inner_text )
    end
        
    servings = @doc.at(".field-name-field-yield .field-item")
    if servings
      servings = servings.inner_text.split(" ")
      if servings[0] == "Serves"
        @servings = servings[1]
      else
        @servings = servings[0]
      end
    end

    @related = []
    related = @doc.search(".pane-apachesolr-mlt-001 li a").each do |link|
      if link["href"].match(/recipe\/([A-Z0-9]+)\/.+/)
        @related << link["href"].match(/recipe\/([A-Z0-9]+)\/.+/)[1]
      end          
    end    
    
    @ingredients = []
    @doc.search(".field-name-field-rec-ing .field-item").each do |ingredient|
      #quantity = ingredient.search("td")[0]
      #food = ingredient.search("td")[1]
      
      coder= HTMLEntities.new
      foods = []
        
      ingredient.search("a").each do |link|
        if link["href"].match(/\/food\/([A-Z0-9]+)\/.+/)
          foods << "http://www.foodista.com#{link["href"]}"
        end  
        if link["href"].match(/^\/([A-Z0-9]+)$/)
          id = link["href"].match(/^\/([A-Z0-9]+)$/)[1]
          #TODO: this is a hack!
          foods << "http://www.foodista.com/food/#{id}/x"
        end          
        if link["href"].match(/\/recipe\/([A-Z0-9]+)\/.+/)
          foods << "http://www.foodista.com#{link["href"]}"
        end          
      end
            
      @ingredients << {
        :description => Util.clean_ws( coder.decode( ingredient.inner_text ) ),
        :foods => foods
      }
      
    end
    
    #-----    
    instructions = @doc.search(".field-name-field-rec-steps")
    @steps = []
      
    if instructions != nil
      instructions.search(".step-body").each_with_index do |step,index|
        techniques = []
        step.search("a").each do |link|
          if link["href"].match(/\/technique\/([A-Z0-9]+)\/.+/)
            techniques << link["href"].match(/\/technique\/([A-Z0-9]+)\/.+/)[1]
          end
          if link["href"].match(/^\/([A-Z0-9]+)$/)
            id = link["href"].match(/^\/([A-Z0-9]+)$/)[1]
            #TODO another hack
            techniques << id
          end          
        end
        
        @steps << {
          :description => step.inner_text,
          :techniques => techniques
        }
      end

    end
    
    @tools = []    
    #FIXME site doesn't appear to expose Tools?
#    @doc.search(".tools a").each do |link|
#      if link["href"].match(/http\:\/\/www\.foodista\.com\/tool\/([A-Z0-9]+)\/.+/)
#        @tools << link["href"].match(/http\:\/\/www\.foodista\.com\/tool\/([A-Z0-9]+)\/.+/)[1]
#      end      
#    end
    
    generate_statements()
  end
    
  def generate_statements
    recipes = RDF::Vocabulary.new("http://linkedrecipes.org/schema/")
    
    #TODO edit trail
    add_property( RDF.type, recipes.Recipe )
    add_property( RDF::DC.title, @title) if @title
    add_property( RDF::DC.description, @about) if @about
    add_property( RDF::FOAF.depiction, @image) if @image
    add_property( recipes.servings, RDF::Literal.new(@servings.to_f.ceil, :datatype => RDF::XSD.int) ) if @servings
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
    
    @related.each do |related|
      add_property( RDF::DC.related, RDF::URI.new( Util.canonicalize("/recipe/#{related}")))
    end
    
    #TODO allow for all variations and notes as described in the constructor. for now just list
    #the foods as this will support finding recipes based on ingredients
    @ingredients.each do |ingredient|
      ingredient[:foods].each do |food|
        if food.match(/http\:\/\/www\.foodista\.com\/food\/([A-Z0-9]+)\/.+/)
          id = food.match(/http\:\/\/www\.foodista\.com\/food\/([A-Z0-9]+)\/.+/)[1]
          ingredient_uri = Util.canonicalize("/food/#{id}")
        end  
        if food.match(/http\:\/\/www\.foodista\.com\/recipe\/([A-Z0-9]+)\/.+/)
          id = food.match(/http\:\/\/www\.foodista\.com\/recipe\/([A-Z0-9]+)\/.+/)[1]
          ingredient_uri = Util.canonicalize("/recipe/#{id}")
        end          
        add_property( recipes.ingredient, RDF::URI.new( ingredient_uri ) )
      end
    end

    #TODO full steps descriptions        
    #simple use relations  
    @steps.each do |step|
      step[:techniques].each do |technique|
        add_property( recipes.uses, RDF::URI.new( Util.canonicalize( "/technique/#{technique}" ) ) )
      end  
    end
    
#    @tools.each do |tool|
#      add_property( recipes.uses, RDF::URI.new( Util.canonicalize( "/tool/#{tool}" ) ) )
#    end

  end
  
end
