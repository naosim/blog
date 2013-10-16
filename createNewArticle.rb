require 'ftools'
require 'bin/blogbase'
# あたらしい記事を生成する

#[設定項目]
NEW_ARTICLE_FILE_PATH = "workspace/newarticle.txt"
BIN_ARTICLE_DIR = "bin/article/"
#----

def getArticleDataFileNameList(articleDir)
	current = Dir.pwd
	Dir.chdir(articleDir)
	result = Dir.glob("*")
	Dir.chdir(current)

	return result.reverse
end

class ArticleNameDetector
	FILE_FORMAT = "%04d.dat"
	def initialize articleDir	
		current = Dir.pwd
		Dir.chdir(articleDir)
		@length = Dir.glob("*").length
		Dir.chdir(current)
	end

	def getNewName
		return sprintf(FILE_FORMAT, @length)
	end
end

articleName = ArticleNameDetector.new(BIN_ARTICLE_DIR).getNewName
File.copy(NEW_ARTICLE_FILE_PATH, BIN_ARTICLE_DIR + articleName)