require 'rubygems'
require 'rake'
require 'rake/clean'
require 'pho'

BASE_DIR="data"
CACHE_DIR="#{BASE_DIR}/cache"
DATA_DIR="#{BASE_DIR}/nt"
STATIC_DATA_DIR="etc/static"

CLEAN.include ["#{DATA_DIR}/*.nt", "#{DATA_DIR}/*.gz"]
               
task :cache_foods do  
  sh %{mkdir -p #{CACHE_DIR}/foods}
  sh %{ruby bin/cache_foods.rb #{CACHE_DIR}/foods}end

task :cache_recipes do
  sh %{mkdir -p #{CACHE_DIR}/recipes}
  sh %{ruby bin/cache_recipes.rb #{CACHE_DIR}/recipes}
end

task :cache_techniques do
  sh %{mkdir -p #{CACHE_DIR}/techniques}
  sh %{ruby bin/cache_techniques.rb #{CACHE_DIR}/techniques}
end

task :cache_tools do
  sh %{mkdir -p #{CACHE_DIR}/tools}
  sh %{ruby bin/cache_tools.rb #{CACHE_DIR}/tools}
end

#TODO people
task :cache => [:cache_foods, :cache_techniques, :cache_tools, :cache_recipes]

task :convert_recipes do
  sh %{ruby bin/convert_recipes.rb #{CACHE_DIR}/recipes #{DATA_DIR} }
end

task :convert_foods do
  sh %{ruby bin/convert_foods.rb #{CACHE_DIR}/foods #{DATA_DIR} }
end

task :convert_tools do
  sh %{ruby bin/convert_tools.rb #{CACHE_DIR}/tools #{DATA_DIR} }
end

task :convert_techniques do
  sh %{ruby bin/convert_techniques.rb #{CACHE_DIR}/techniques #{DATA_DIR} }
end

task :convert => [:convert_tools, :convert_techniques, :convert_foods, :convert_recipes]
  
task :package do
  sh %{gzip #{DATA_DIR}/*}
end

task :publish => [:convert, :package]