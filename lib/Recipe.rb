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
    
    @other_names = []
    @doc.search(".module p strong").each do |p|
      if p.inner_text =~ /Other Names/
        @other_names = p.parent.inner_text.gsub("Other Names: ", "").split(",").map{|x| x.lstrip.rstrip }
        #puts @other_names.inspect
      end
    end
    
    servings = @doc.at(".module span[@property]")
    if servings
      @servings = servings.inner_text.split(" ")[0]
    end
    
    @tags = []
    @doc.search(".module p a").each do |tag|
      @tags << normalize_tag( tag.inner_text )
    end
    
    @ingredients = []
    @doc.search(".ingredients tr[@rel]").each do |ingredient|
      quantity = ingredient.search("td")[0]
      food = ingredient.search("td")[1]
      
      coder= HTMLEntities.new
      foods = []
      techniques = []
        
      food.search("a").each do |link|
        if link["href"].match(/http\:\/\/www\.foodista\.com\/food\/([A-Z0-9]+)\/.+/)
          foods << link["href"]
        end  
        if link["href"].match(/http\:\/\/www\.foodista\.com\/recipe\/([A-Z0-9]+)\/.+/)
          foods << link["href"]
        end          
        if link["href"].match(/http\:\/\/www\.foodista\.com\/technique\/([A-Z0-9]+)\/.+/)
          techniques << link["href"].match(/http\:\/\/www\.foodista\.com\/technique\/([A-Z0-9]+)\/.+/)[1]
        end
      end
      
      #May be no quantity
      #May have found no foods, e.g. if "ingredient" includes tools
      #Or ingredient isn't linked to known foodstuff
      #Or if its just bad data, e.g. steps have been added as ingredients
      #Or if its further description of the previous ingredient, e.g. ..."into discs"
      #Also chance for spurious connections e.g. "think pepperoni slices as a guide"
      #TODO: include plain text list of ingredients to allow context to be preservied      
      #puts @id if foods.size == 0
      
      #Can have multiple foods
      #E.g. salt and pepper
      #E.g. tablespoons Strega liqueur or other sweet liqueur plus extra
      #E.g. vanilla or lemon yoghurt
      #Also some spurious recipes like Mix and Raw
      #http://www.foodista.com/recipe/VL2S5WX7/raw
      #http://www.foodista.com/recipe/4Z4V5JSK/mix
      
      #puts @id, foods.inspect if foods.size > 1
      
      #puts @id, techniques if techniques.size > 0
      
      @ingredients << {
        :description => Util.clean_ws( coder.decode( ingredient.inner_text ) ),
        :quantity => Util.clean_ws( coder.decode( quantity.inner_text ) ),
        :foods => foods,
        :techniques => techniques
      }
      
    end
    
    instructions = @doc.search("table[@property]")[0]
    @steps = []
    if instructions != nil && instructions.attributes["property"] == "v:instructions"
      instructions.search("tr").each_with_index do |row,index|
        techniques = []
        row.search(".steps-col2 a").each do |link|
          if link["href"].match(/http\:\/\/www\.foodista\.com\/technique\/([A-Z0-9]+)\/.+/)
            techniques << link["href"].match(/http\:\/\/www\.foodista\.com\/technique\/([A-Z0-9]+)\/.+/)[1]
          end
        end
        
        @steps << {
          :description => row.at(".steps-col2 ").inner_text,
          :techniques => techniques
        }
      end

    end
    
    @related = []
    related = @doc.search(".related-recipes-detailed li a").each do |link|
      if link["href"].match(/recipe\/([A-Z0-9]+)\/.+/)
        @related << link["href"].match(/recipe\/([A-Z0-9]+)\/.+/)[1]
      end          
    end

    @tools = []    
    @doc.search(".tools a").each do |link|
      if link["href"].match(/http\:\/\/www\.foodista\.com\/tool\/([A-Z0-9]+)\/.+/)
        @tools << link["href"].match(/http\:\/\/www\.foodista\.com\/tool\/([A-Z0-9]+)\/.+/)[1]
      end      
    end
    
    #TODO other photos
    #TODO author/editors
    #Sometimes have Creator, e.g.http://www.foodista.com/recipe/6275XH2P/sorpotel
    #Sometimes just editors or neither
    #Author homepages list their recipes
    
    generate_statements()
  end
    
  def generate_statements
    recipes = RDF::Vocabulary.new("http://linkedrecipes.org/schema/")
    
    #TODO edit trail
    add_property( RDF.type, recipes.Recipe )
    add_property( RDF::DC.title, @title) if @title
    add_property( RDF::FOAF.depiction, @image) if @image
    add_property( recipes.servings, RDF::Literal.new(@servings, :datatype => RDF::XSD.int) ) if @servings
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
    
    @tools.each do |tool|
      add_property( recipes.uses, RDF::URI.new( Util.canonicalize( "/tool/#{tool}" ) ) )
    end

  end
  
end