module Jekyll
  # render a tag cloud
  class RenderTagCloud < Liquid::Tag
    def initialize(tag_name, text, tokens)
      super
    end

    def render(context)
      base_url = context['site.baseurl']
      tags = context['tags']
      return unless tags.class == Array
      tags.reject! {|i| i.nil? }
      site_tags = context['site.tags']
      by_length = site_tags.values.map(&:length)
      max = by_length.max
      min = by_length.min
      cloud = tags.map do |t|
        tag_size = site_tags[t].length
        "<div class=\"tagcloud-tag #{size_tag(min,max,tag_size)}\">"\
          "<a href=\"#{base_url}/tag/#{t.downcase.gsub(/\s/,'-')}\">"\
          "#{t}"\
          "</a>"\
          "</div>"
      end.join("\n")
      "<div class=\"tagcloud\">#{cloud}</div>"
    end

    private

    def size_tag(min, max, count)
      diff = (max - min)
      if count < 2
        'tagcloud-tag-xs'
      elsif count < (min + (diff * 0.1))
        'tagcloud-tag-s'
      elsif count < (min + (diff * 0.3))
        'tagcloud-tag-m'
      elsif count < (min + (diff * 0.5))
        'tagcloud-tag-l'
      else
        'tagcloud-tag-xl'
      end
    end
  end
end

Liquid::Template.register_tag('render_tagcloud', Jekyll::RenderTagCloud)
