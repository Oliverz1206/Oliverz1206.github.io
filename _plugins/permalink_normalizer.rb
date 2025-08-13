# _plugins/permalink_normalizer.rb
# frozen_string_literal: true

module Jekyll
  module PermalinkNormalizer
    module_function

    def slugify(str)
      Jekyll::Utils.slugify(str.to_s, mode: "default")
    end

    # 去掉日期前缀后的文件名尾巴，例如 "2025-06-29-ProjectTest2" -> "ProjectTest2"
    def filename_tail(doc)
      doc.basename_without_ext.to_s.sub(/^\d{4}-\d{2}-\d{2}-/, "")
    end

    def normalize!(doc)
      # 只处理 posts
      return unless doc.respond_to?(:collection) && doc.collection&.label == "posts"

      # A) categories 各段转 slug（只用于 URL，不回写 categories）
      cats_raw  = Array(doc.data["categories"]).map(&:to_s)
      cats_slug = cats_raw.map { |c| slugify(c) }.reject(&:empty?)

      # B) 末段 slug：若现有等于“文件名派生”，用 title 的 slug；否则尊重显式 slug
      fname_tail         = filename_tail(doc)          # 如 "NotesTest1"
      default_slug       = slugify(fname_tail)         # 如 "notestest1"
      existing_slug      = (doc.data["slug"] || fname_tail).to_s
      existing_slug_norm = slugify(existing_slug)
      title_slug         = doc.data["title"] ? slugify(doc.data["title"]) : existing_slug_norm
      final_slug         = (existing_slug_norm == default_slug) ? title_slug : existing_slug_norm

      # C) 回写 slug & permalink（不改 categories）
      doc.data["slug"] = final_slug
      doc.data["permalink"] =
        cats_slug.empty? ? "/#{final_slug}/" : "/#{cats_slug.join('/')}/#{final_slug}/"

      if doc.site.config["slug_rules_debug"]
        Jekyll.logger.info "SLUGRULES",
          "doc=#{doc.path} cats_raw=#{cats_raw.inspect} -> #{cats_slug.inspect}; " \
          "default_slug=#{default_slug.inspect} existing_slug=#{existing_slug.inspect} " \
          "=> final_slug=#{final_slug.inspect}; permalink=#{doc.data['permalink']}"
      end
    end
  end
end

# 1) 文档初始化完成后立即规范化（任何页面开始渲染前）
Jekyll::Hooks.register :documents, :post_init do |doc|
  Jekyll::PermalinkNormalizer.normalize!(doc)
end

# 2) 再用最高优先级的 Generator 兜底（防止某些边缘时序）
class PermalinkGenerator < Jekyll::Generator
  priority :highest
  def generate(site)
    site.posts.docs.each { |doc| Jekyll::PermalinkNormalizer.normalize!(doc) }
  end
end
