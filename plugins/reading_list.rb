module Jekyll

  class ReadingListEntryTag < Liquid::Tag
    
    def initialize(tag_name, markup, tokens)
      super
      @markup = markup
    end

    def render(context)
      @markup =~ /"([^"]+)"\s*([^\s]+)\s*(.*)/
      title = $1
      url   = $2
      descr = $3
      img   = title.gsub(/\W/, '').downcase
      "<a href='#{url}'><img src='/images/reading-list/#{img}.png'></img></a><strong>#{title}.</strong> #{descr}"
    end
  end
end

Liquid::Template.register_tag('rle', Jekyll::ReadingListEntryTag)
