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

class Article
	def initialize(filename)
		@filename = filename
	end

	def loadIfNeed
		if(@articleData != nil) then return end
		loader = DataLoader.new(filename)
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
	def initialize articleDir
		@articleDir = articleDir
	end

	def loadIfNeed
		if @fileList != nil then return end
		current = Dir.pwd
		Dir.chdir(@articleDir)
		@fileList = Array.new
		Dir.glob("*").each {|name|
			@fileList.push(Article.new(@articleDir + name))
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
			'ARTICLE_URL' => @environment.articleUrl(article.filename)
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
