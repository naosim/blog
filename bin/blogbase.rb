# 独自形式のdatファイルをパースしてhashを作る
class DataLoader
	TAGWORD = '###'
	def initialize(filename)
		@filename = filename
	end

	def load
		result = Hash.new
		file = open(@filename)
		tmp = ""
		currentKey = nil
		while text = file.gets do
			if(text.index(TAGWORD)) then
				if(currentKey != nil) then
					result[currentKey] = tmp.gsub(TAGWORD, '').strip
				end

				tmp = ""
				currentKey = text.gsub(TAGWORD, '').strip
			else
				tmp = "#{tmp}#{text}"
			end 
		end
		result[currentKey] = tmp.strip
		file.close
		return result
	end
end

class TempleteParser
	TAGWORD = '###'
	def initialize(templeteFile, scheme)
		@templeteFile = templeteFile
		@scheme = scheme
	end

	# schemeにヒットした文字列をyieldで取得した文字列に置換して返す
	def create
		f = open(@templeteFile)
		result = f.read
		f.close
		@scheme.each {|key|
			tag = TAGWORD + key + TAGWORD
			if(result.include?(tag)) then
				result = result.gsub(tag, (yield key));
			end
		}
		return result
	end
end

class ArticleId
	def initialize(id)
		if(id.instance_of?(String)) then
			# TODO 正規表現等を使って数値だけを取り出す
			if id.include?(".dat") then id = id.gsub(".dat", "") end
			if id.include?("article/") then id = id.gsub("article/", "") end
			@id = id
		else
			@id = sprintf("%04d", id)
		end
	end

	def id
		return @id
	end

	def intValue
		return @id.to_i
	end

	def +(num)
		return ArticleId.new(self.intValue + num)
	end

	def -(num)
		return ArticleId.new(self.intValue - num)
	end

	def filename(environment)
		return environment.articleDataFile(self)
	end

	def exists?(environment)
		return File.exists?(self.filename(environment))
	end

	def articleUrl(environment)
		return environment.articleUrl(self)
	end
end

class Article
	def initialize(filename)
		@filename = filename
		@id = ArticleId.new(self.filename)
	end

	def exists?
		return File.exists?(@filename)
	end

	def id
		return @id
	end

	def loadIfNeed
		if(@articleData != nil) then return end
		loader = DataLoader.new(self.filename)
		@articleData = loader.load
	end

	def filename
		return @filename
	end

	def title
		self.loadIfNeed
		return @articleData['title']
	end

	def date
		self.loadIfNeed
		return @articleData['date']
	end

	def body
		self.loadIfNeed
		return @articleData['body']
	end
end


class Articles
	def initialize environment
		# @articleDir = articleDir
		@environment = environment
	end

	def loadIfNeed
		if @fileList != nil then return end
		current = Dir.pwd
		Dir.chdir(@environment.articleDir)
		@fileList = Array.new
		Dir.glob("*").each {|name|
			@fileList.push(Article.new(@environment.articleDir + name))
		}
		@fileList.reverse!
		Dir.chdir(current)
		return self
	end

	def length
		self.loadIfNeed
		return @fileList.length
	end

	# 各記事のファイル名を渡す
	def each
		self.loadIfNeed
		@fileList.each {|obj|
			yield obj
		}
	end

	def get(index)
		self.loadIfNeed
		return @fileList[index]
	end
end

# 1件分の記事のHTMLを生成する
class ArticleHtmlFactory
	def initialize (environment)
		@environment = environment
	end

	def setItem article
		@map = {
			'TITLE' => article.title,
			'DATE' => article.date,
			'BODY' => article.body,
			'ARTICLE_URL' => @environment.articleUrl(article.id)
		}
	end

	def create
		parser = TempleteParser.new(@environment.articleTempleteFile, @map.keys)
		return parser.create {|tag|
			next @map[tag]
		}
	end
end

# 記事(複数)のHTMLを生成する
class ArticlesHtmlFactory
	def initialize(articles, articleTemplete)
		@articles = articles
		@articleTemplete = articleTemplete
	end

	def create
		result = ""
		@articles.each {|file|
			@articleTemplete.setItem(file)
			result = result + @articleTemplete.create
		}
		return result
	end
end

# トップページのHTMLを生成する
class TopHtmlFactory

	def initialize(blogData, topTempleteFile, articleHtmlFactory)
		@topTempleteFile = topTempleteFile
		@map = {
			'BLOG_TITLE' => blogData["title"],
			'BLOG_DESCRIPTION' => blogData["descripton"],
			'BLOG_URL' => blogData["url"],
			'ARTICLES' => articleHtmlFactory.create
		}
	end

	def create
		parser = TempleteParser.new(@topTempleteFile, @map.keys)
		return parser.create {|tag|
			next @map[tag]
		}
	end
end

# 個別ページ用
class SingleArticleHtmlFactory

	def initialize(blogData, environment, articleHtmlFactory, articleId)
		article = Article.new(articleId.filename(environment))
		prevArticleId = articleId + 1
		nextArticleId = articleId - 1
		@templeteFile = environment.singleArticleTempleteFile
		articleHtmlFactory.setItem(article)
		@map = {
			'BLOG_TITLE' => blogData["title"],
			'BLOG_DESCRIPTION' => blogData["descripton"],
			'BLOG_URL' => blogData["url"],
			'ARTICLE_TITLE' => article.title,
			'ARTICLES' => articleHtmlFactory.create,
			'PREV_ARTICLE_URL' => self.getLinkUrl(prevArticleId, environment),
			'NEXT_ARTICLE_URL' => self.getLinkUrl(nextArticleId, environment)
		}
	end

	def getLinkUrl(articleId, environment)
		if(articleId.exists?(environment)) then
			return articleId.articleUrl(environment)
		else
			return "./"
		end
	end

	def create
		parser = TempleteParser.new(@templeteFile, @map.keys)
		return parser.create {|tag|
			next @map[tag]
		}
	end
end


class NotfoundHtmlFactory
	def initialize(blogData, topTempleteFile)
		@topTempleteFile = topTempleteFile
		@map = {
			'BLOG_TITLE' => blogData["title"],
			'BLOG_DESCRIPTION' => blogData["descripton"],
			'BLOG_URL' => blogData["url"],
			'ARTICLES' => 'Not Found'
		}
	end

	def create
		parser = TempleteParser.new(@topTempleteFile, @map.keys)
		return parser.create {|tag|
			next @map[tag]
		}
	end
end
