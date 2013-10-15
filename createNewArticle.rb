require 'ftools'
require 'bin/blogbase'
# あたらしい記事を生成する

#[設定項目]
NEW_ARTICLE_FILE_PATH = "workspace/newarticle.txt"
BIN_ARTICLE_DIR = "bin/article/"
#----

class ArticleNameDetector
	FILE_FORMAT = "%04d.dat"
	def initialize articles	
		@articles = articles
	end
	def getNewName
		return sprintf(FILE_FORMAT, @articles.length)
	end
end

articleName = ArticleNameDetector.new(Articles.new(BIN_ARTICLE_DIR)).getNewName
File.copy(NEW_ARTICLE_FILE_PATH, BIN_ARTICLE_DIR + articleName)