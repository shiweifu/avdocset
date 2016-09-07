require 'redcarpet'

# 传入 md 文件名
FILENAME = ARGV[0]
HTML_FMT = open('fmt.html').read
f = open(FILENAME)
md = f.read
subject_arr = md.split(/^### /)

def render(markdown, options = {})
options = options.fetch(:with, {})

if options.kind_of?(Array)
  options = Hash[options.map {|o| [o, true]}]
end

renderer = Redcarpet::Render::HTML.new()


parser = Redcarpet::Markdown.new(renderer, options)

parser.render(markdown).chomp
end

INSERT_SQL_FMT = "Insert into `searchIndex`(`name`, `type`, `path`) VALUES('%s', 'Guides', '%s');"

subject_arr.each_index { | idx | 
	s = subject_arr[idx]
	title = s.split("\n")[0]

	next if title.empty?

	s = "### #{s}"

	html = render(s, with: [:fenced_code_blocks, :lax_spacing])

	html = HTML_FMT.gsub('{{content}}', html)

	save_fn = "doc/#{FILENAME}_#{idx}.html"
	File.write(save_fn, html)
	sql = INSERT_SQL_FMT % [title, save_fn.sub('doc/', '')]
	puts sql
}
