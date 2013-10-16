#!/usr/local/bin/ruby
require "cgi"
require "blogbase"
require "environment"

environment = Environment.new

blogData = DataLoader.new(environment.blogDataFile).load

print "Content-Type: text/html\n\n"

files = Articles.new(environment)

articleHtmlFactory = ArticleHtmlFactory.new(environment)
articlesHtmlFactory = ArticlesHtmlFactory.new(files, articleHtmlFactory)
print TopHtmlFactory.new(blogData, environment.topTempleteFile, articlesHtmlFactory).create
