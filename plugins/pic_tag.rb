class PicTag < SiteBuilder
  def build
    liquid_tag :pic
    liquid_tag :pic_cap, as_block: true
  end

  private

  def pic_cap(params, tag)
    <<~HTML
      <figure>
        #{pic(params, tag)}
        <figcaption>#{tag.content}</figcaption>
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

    <<~HTML
      <a href="#{file.url}" target="_blank">
        <img alt="#{alt}" class="image" src="#{file.url}" />
      </a>
    HTML
  end
end
