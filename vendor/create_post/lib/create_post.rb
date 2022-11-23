# frozen_string_literal: true

require "bridgetown"
require_all "bridgetown-core/commands/concerns"

module CreatePost
  module Commands
    class Post < Thor::Group
      include Thor::Actions

      SUMMARY = "Creates an empty post file."

      Bridgetown::Commands::Registrations.register do
        register(Post, "post", "post TITLE", SUMMARY)
      end

      desc "Description:\n  #{SUMMARY}"

      def self.banner
        "bridgetown post TITLE"
      end

      argument :title,
        banner: "TITLE",
        type: :string,
        required: true

      class_option :category,
        aliases: "-c",
        banner: "CATEGORY",
        type: :string,
        desc: "The post's main category"

      def create_post
        create_file(path, skip: true) do
          front_matter_data.to_yaml + "---\n\n"
        end
      end

      private

      def front_matter_data
        {
          "title" => title,
          "date" => Time.now,
          "category" => options["category"]
        }
      end

      def path
        File.join("src", "_posts", filename)
      end

      def filename
        "#{date}-#{slug}.md"
      end

      def date
        @_date ||= Date.today.to_s
      end

      def slug
        @_slug ||= Bridgetown::Utils.slugify(title)
      end

      def site
        require "debug";debugger
        @_site ||= Bridgetown::Site.new(configuration_with_overrides(options))
      end
    end
  end
end
