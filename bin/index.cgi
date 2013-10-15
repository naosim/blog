#!/usr/local/bin/ruby
require "cgi"
require "blogbase"

ARTICLE_DIR = "article/"
TOP_TEMPLETE_FILE = "templete/top_templete.txt"
ARTICLLE_TEMPLETE_FILE = "templete/article_templete.txt"

blogData = DataLoader.new('blogdata.dat').load

print "Content-Type: text/html\n\n"

files = Articles.new(ARTICLE_DIR)
articleHtmlFactory = ArticleHtmlFactory.new(ARTICLLE_TEMPLETE_FILE)
articlesHtmlFactory = ArticlesHtmlFactory.new(files, articleHtmlFactory)
print TopHtmlFactory.new(blogData, TOP_TEMPLETE_FILE, articlesHtmlFactory).create
