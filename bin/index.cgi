#!/usr/local/bin/ruby
require "cgi"
require "blogbase"
require "environment"

def getArticleDataFileNameList(articleDir)
	current = Dir.pwd
	Dir.chdir(articleDir)
	result = Dir.glob("*")
	Dir.chdir(current)

	return result.reverse
end

environment = Environment.new

blogData = DataLoader.new(environment.blogDataFile).load

print "Content-Type: text/html\n\n"

files = Articles.new(environment, getArticleDataFileNameList(environment.articleDir))

articleHtmlFactory = ArticleHtmlFactory.new(environment)
articlesHtmlFactory = ArticlesHtmlFactory.new(files, articleHtmlFactory)
print TopHtmlFactory.new(blogData, environment.topTempleteFile, articlesHtmlFactory).create
