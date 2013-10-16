#!/usr/local/bin/ruby
require "cgi"
# require "blogbase"
# require "environment"
require File.expand_path(File.dirname(__FILE__) + '/blogbase')
require File.expand_path(File.dirname(__FILE__) + '/environment')

def getArticleDataFileNameList(articleDir)
	current = Dir.pwd
	Dir.chdir(articleDir)
	result = Dir.glob("*")
	Dir.chdir(current)

	return result.reverse
end


environment = Environment.new

blogData = DataLoader.new(environment.blogDataFile).load
cgi = CGI.new
page = cgi['p'].to_i
blogData['page'] = page
print "Content-Type: text/html\n\n"

filenameList = getArticleDataFileNameList(environment.articleDir)
blogData['maxArticleCount'] = filenameList.length
filenameList = filenameList[page * blogData['topArticleCount'], blogData['topArticleCount']]
files = Articles.new(environment, filenameList)
articleHtmlFactory = ArticleHtmlFactory.new(environment)
articlesHtmlFactory = ArticlesHtmlFactory.new(files, articleHtmlFactory)
print TopHtmlFactory.new(blogData, environment.topTempleteFile, articlesHtmlFactory).create
