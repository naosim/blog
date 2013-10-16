class Environment
	def articleDir
		return 'article/'
	end

	def articleDataFile(id)
		return self.articleDir + id + ".dat"
	end

	def templeteDir
		return 'templete/'
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
		return 'blogdata.dat'
	end

	def articleUrl(id)
		id = id.gsub!(".dat", "").gsub(self.articleDir, "");
		return "article.cgi?id=#{id}"
	end
end