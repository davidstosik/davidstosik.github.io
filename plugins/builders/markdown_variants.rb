# frozen_string_literal: true

# Automatically generate Markdown variants for resources whose layout has a
# matching `*-md` layout. For example, a post using `layout: post` will also be
# written with `layout: post-md` when `src/_layouts/post-md.liquid` exists.
class Builders::MarkdownVariants < SiteBuilder
  MARKDOWN_VARIANT_FLAG = "markdown_variant"

  def build
    hook :site, :pre_render do
      @markdown_variant_models = []
    end

    hook :resources, :pre_render do |resource|
      if markdown_variant_layout_for(resource)
        resource.data["markdown_url"] = markdown_permalink(resource)
      end
    end

    hook :resources, :post_render do |resource|
      variant_model = markdown_variant_model_for(resource)
      @markdown_variant_models << variant_model if variant_model
    end

    hook :site, :post_write do
      @markdown_variant_models.each do |variant_model|
        variant_model.render_as_resource.write
      end
    end
  end

  private

  def markdown_variant_model_for(resource)
    markdown_layout = markdown_variant_layout_for(resource)
    return unless markdown_layout

    Bridgetown::Model::Base.build(
      self,
      resource.collection.label,
      markdown_variant_path(resource),
      markdown_variant_data(resource, markdown_layout)
    )
  end

  def markdown_variant_layout_for(resource)
    return if resource.data[MARKDOWN_VARIANT_FLAG]
    return unless resource.write?
    return unless resource.data.layout
    return if resource.data.layout.to_s.end_with?("-md")

    markdown_layout = "#{resource.data.layout}-md"
    markdown_layout if site.layouts.key?(markdown_layout)
  end

  def markdown_variant_data(resource, markdown_layout)
    resource.data.to_h.merge(
      MARKDOWN_VARIANT_FLAG => true,
      "layout" => markdown_layout,
      "permalink" => markdown_permalink(resource),
      "sitemap" => false,
      "_content_" => resource.untransformed_content || resource.content.to_s
    )
  end

  def markdown_variant_path(resource)
    "#{resource.relative_path_basename_without_prefix}-md.liquid"
  end

  def markdown_permalink(resource)
    url = resource.destination.relative_url
    url = url.delete_suffix("/") if url.end_with?("/")
    url = url.sub(%r{(?:/index)?\.html?$}, "")
    "#{url}.md"
  end
end
