class Environment
	def articleDir
		return File.dirname(__FILE__) + '/article/'
	end

	def articleDataFile(id)
		return self.articleDir + id.id + ".dat"
	end

	def templeteDir
		return File.dirname(__FILE__) + '/templete/'
	end

	def topTempleteFile
		return self.templeteDir + 'top_templete.txt'
	end

	def articleTempleteFile
		return self.templeteDir + 'article_templete.txt'
	end

	def singleArticleTempleteFile
		return self.templeteDir + 'single_article_templete.txt'
	end

	def blogDataFile
		return File.dirname(__FILE__) + '/blogdata.dat'
	end

	def articleUrl(id)
		return "article.cgi?id=#{id.id}"
	end
end