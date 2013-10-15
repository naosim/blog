#!/usr/local/bin/ruby
require "cgi"
require "blogbase"
require "environment"

environment = Environment.new

blogData = DataLoader.new(environment.blogDataFile).load

print "Content-Type: text/html\n\n"
cgi = CGI.new
article = Article.new(environment.articleDataFile(cgi['id']))
if article.exists? then
	articleHtmlFactory = ArticleHtmlFactory.new(environment)
	articlesHtmlFactory = ArticlesHtmlFactory.new(Array.new.push(article), articleHtmlFactory)
	print TopHtmlFactory.new(blogData, environment.topTempleteFile, articlesHtmlFactory).create
else
	print NotfoundHtmlFactory.new(blogData, environment.topTempleteFile).create;
end
