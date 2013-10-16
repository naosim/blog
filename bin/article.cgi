#!/usr/local/bin/ruby
require 'cgi'
require File.dirname(__FILE__) + '/blogbase'
require File.dirname(__FILE__) + '/environment'

environment = Environment.new

blogData = DataLoader.new(environment.blogDataFile).load

print "Content-Type: text/html\n\n"
cgi = CGI.new
articleId = ArticleId.new(cgi['id'], environment)

if articleId.exists? then
	articleHtmlFactory = ArticleHtmlFactory.new(environment)
	print SingleArticleHtmlFactory.new(blogData, environment, articleHtmlFactory, articleId).create
else
	print NotfoundHtmlFactory.new(blogData, environment.topTempleteFile).create;
end
