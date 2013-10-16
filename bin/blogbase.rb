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
		currentType = nil
		while text = file.gets do
			if(text.index(TAGWORD)) then
				if(currentKey != nil) then
					result[currentKey] = createConvertedValue(tmp.gsub(TAGWORD, '').strip, currentType)
				end

				tmp = ""
				a = text.gsub(TAGWORD, '').strip.split(':')
				currentKey = a[0]
				currentType = a.length > 0 ? a[1] : nil
			else
				tmp = "#{tmp}#{text}"
			end 
		end
		result[currentKey] = createConvertedValue(tmp.strip, currentType)
		file.close
		return result
	end

	def createConvertedValue(value, type)
		if(type == 'int') then
			return value.to_i
		elsif (type == 'array') then
			# TODO: 改行区切りで配列化
		end

		return value
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
	def initialize(id, environment)
		@environment = environment
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
		return ArticleId.new(self.intValue + num, @environment)
	end

	def -(num)
		return ArticleId.new(self.intValue - num, @environment)
	end

	def filename
		return @environment.articleDataFile(self)
	end

	def exists?
		return File.exists?(self.filename)
	end

	def articleUrl
		return @environment.articleUrl(self)
	end
end

class Article
	def initialize(articleId)
		@filename = articleId.filename
		@id = articleId
	end

	def exists?
		return @id.exists?
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
	def initialize environment, articleDataFileNameList
		# @articleDir = articleDir
		@environment = environment
		@articleDataFileNameList = articleDataFileNameList
	end

	def loadIfNeed
		if @fileList != nil then return end
		current = Dir.pwd
		Dir.chdir(@environment.articleDir)
		@fileList = Array.new
		# Dir.glob("*").each {|name|
		# 	articleId = ArticleId.new(name, @environment)
		# 	@fileList.push(Article.new(articleId))
		# }
		@articleDataFileNameList.each {|name|
			articleId = ArticleId.new(name, @environment)
			@fileList.push(Article.new(articleId))
		}
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
			'ARTICLES' => articleHtmlFactory.create,
			'PREV_TOP_URL' => getUrl(blogData['page'] - 1, blogData['maxArticleCount'], blogData['topArticleCount']),
			'NEXT_TOP_URL' => getUrl(blogData['page'] + 1, blogData['maxArticleCount'], blogData['topArticleCount'])
		}
	end

	def getUrl(page, maxArticleCount, topArticleCount)
		print page
		print maxArticleCount
		if(page < 0 || (page * topArticleCount) >= maxArticleCount) then
			return './'
		end
		return "./p=#{page}"
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
		article = Article.new(articleId)
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
			'NEXT_ARTICLE_URL' => self.getLinkUrl(nextArticleId, environment),

		}
	end

	def getLinkUrl(articleId, environment)
		if(articleId.exists?) then
			return articleId.articleUrl
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
			'ARTICLES' => 'Not Found',
		}
	end

	def create
		parser = TempleteParser.new(@topTempleteFile, @map.keys)
		return parser.create {|tag|
			next @map[tag]
		}
	end
end
