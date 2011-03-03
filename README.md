This code crawls the Foodista website to create a local cache of the key pages (food, recipes, etc) and 
enables their conversion into RDF.

[http://foodista.com]

AUTHOR
------

Leigh Dodds (leigh@kasabi.com)


INSTALLATION
------------

The code is written in Ruby and relies on the Hpricot gem for parsing the HTML files, and 
the RDF.rb library for serializing the RDF as ntriples.

After downloading the code, run the following to pull in the required dependencies:

	sudo gem install hpricot rdf

USAGE
-----

A Rakefile is provided to run the converson.

To build a local cache of the datbase in data/cache run:

	rake cache

The file names are derived from the Foodista URLs. Please do not run this unnecessarily in order to avoid 
putting load onto their website.

To convert the data into RDF run:

	rake convert
	
The converted output is stored in data/nt as a number of ntriples files. One for each of the main types 
of resource: food, recipes, tools, techniques. There are rake tasks available for running individual 
steps:

	rake convert_food

DATA MODEL
----------

The code generates a model based on that described in the Linked Recipes project:

[http://code.google.com/p/linkedrecipes/]