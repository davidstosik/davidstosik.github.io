class PicTag < SiteBuilder
  def build
    liquid_tag :pic
    liquid_tag :pic_cap, as_block: true
  end

  private

  def pic_cap(params, tag)
    site = tag.context.registers[:site]
    converter = site.find_converter_instance(Bridgetown::Converters::Markdown)
    content = Bridgetown::Utils.reindent_for_markdown(tag.content)
    markdownified_content = converter.convert(content)

    <<~HTML
      <figure>
        #{pic(params, tag)}
        <figcaption>#{markdownified_content}</figcaption>
      </figure>
    HTML
  end

  def pic(params, tag)
    name, alt = params.split(",", 2).map(&:strip)
    alt ||= name

    date = tag.context["page"].date.to_date

    file = tag.context["site"].static_files.find do |file|
      file.relative_path =~ %r{images/#{date}/#{name}}
    end

    url = file&.url || "notfound"

    <<~HTML
      <a href="#{url}" target="_blank">
        <img alt="#{alt}" class="image" src="#{url}" />
      </a>
    HTML
  end
end
