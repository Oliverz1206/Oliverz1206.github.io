# frozen_string_literal: true
#
# 在渲染前(:pre_render)强制规范 URL（仅影响 URL，不改动原有 categories 值）：
#   A) categories 用于生成 URL 段：逐段 slugify（空格→-，折叠多余的 -）
#   B) 末段：若现有 slug 与“默认文件名 slug”一致，则用 title 的 slug 覆盖；
#            若不同（确为用户手写），则尊重用户。
#   C) 回写 doc.data['slug'] 与 doc.data['permalink']；不写 doc.data['categories']！
#
module Jekyll
  module PermalinkNormalizer
    def self.slugify_segment(str, mode)
      s = Jekyll::Utils.slugify(str.to_s, mode: mode)
      s = s.downcase.strip.tr(" ", "-")
      s = s.gsub(/-+/, "-").gsub(/\A-+|-+\z/, "")
      s
    end

    def self.default_slug_from_basename(doc, mode)
      base = doc.basename_without_ext.to_s
      base = base.sub(/^\d{4}-\d{2}-\d{2}-/, "")  # 移除 YYYY-MM-DD-
      slugify_segment(base, mode)
    end

    Jekyll::Hooks.register :documents, :pre_render do |doc|
      site = doc.site
      cfg  = site.config

      # 仅处理 posts（或 _config.yml 指定的集合）
      allowed = cfg["slug_from_title_collections"]
      allowed = ["posts"] unless allowed.is_a?(Array) && !allowed.empty?
      coll = doc.respond_to?(:collection) ? doc.collection&.label : nil
      next unless allowed.include?(coll)

      mode  = (cfg["slugify_mode"] || "default").to_sym
      debug = cfg["slug_rules_debug"]

      # A) 从“原始 categories”（不要修改它）生成 URL 用的 slug 段
      cats_raw = doc.data["categories"]
      cats_raw = [cats_raw] unless cats_raw.nil? || cats_raw.is_a?(Array)
      cats_raw = (cats_raw || []).flatten.compact.map(&:to_s).reject(&:empty?)
      cats_slug_arr = cats_raw.map { |c| PermalinkNormalizer.slugify_segment(c, mode) }
      cats_slug     = cats_slug_arr.join("/")

      # B) 末段 slug 计算：默认 vs 现有 vs title
      default_slug  = PermalinkNormalizer.default_slug_from_basename(doc, mode)
      existing_slug = doc.data["slug"].to_s.strip
      use_title     = cfg["slug_from_title"] && !doc.data["title"].to_s.strip.empty?

      final_slug =
        if use_title
          if existing_slug.empty? || existing_slug.casecmp(default_slug).zero?
            PermalinkNormalizer.slugify_segment(doc.data["title"].to_s, mode)
          else
            PermalinkNormalizer.slugify_segment(existing_slug, mode)
          end
        else
          PermalinkNormalizer.slugify_segment(existing_slug.empty? ? default_slug : existing_slug, mode)
        end

      # C) 仅写回 slug & permalink（不动 categories）
      doc.data["slug"]       = final_slug
      doc.data["permalink"]  = cats_slug.empty? ? "/#{final_slug}/" : "/#{cats_slug}/#{final_slug}/"

      if debug
        Jekyll.logger.info "SLUGRULES",
          "doc=#{doc.path} cats_raw=#{cats_raw.inspect} -> #{cats_slug_arr.inspect}; "\
          "default_slug=#{default_slug.inspect} existing_slug=#{existing_slug.inspect} "\
          "=> final_slug=#{final_slug.inspect}; permalink=#{doc.data['permalink']}"
      end
    end
  end
end
