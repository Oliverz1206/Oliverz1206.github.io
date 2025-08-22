# frozen_string_literal: true
#
# ============================================================================
#  Permalink Normalizer | posts 的 slug / permalink 规范器
# ============================================================================
# 功能（做什么）
#   统一 `posts` 集合中文章的 `slug` 与 `permalink`：
#   - 不改写文章 front matter 的 `categories`（它们只用于拼接 URL）。
#   - 若未显式提供 slug，或现有 slug 等于“文件名派生的默认值”，可按开关改用“标题的 slug”。
#   - 最终写回形如 `/cat1/cat2/<slug>/` 的 `permalink` 到 `doc.data['permalink']`。
#
# 触发时机（什么时候运行）
#   1) Hook：`Jekyll::Hooks.register :documents, :post_init` —— 文档初始化后立即规范化。
#   2) Generator：`priority :highest` —— 再兜底一次，确保在其它生成器前完成。
#
# 适用范围（作用对象）
#   仅处理 `posts` 集合（`doc.collection.label == 'posts'`）。
#
# _config.yml 写法（只支持“嵌套配置”，不做旧键位兼容）
#   slugify:
#     mode: default          # 可选：default / pretty / ascii / latin
#     slug_from_title: true  # true：当现有 slug 等于“文件名派生值”时，用“标题 slug”替代
#     slug_rules_debug: false# true：构建时打印调试日志，便于排查
#
# 布局如何取值（给模板的字段）
#   - `page.slug`         : 末段 slug（由本插件写入 `doc.data['slug']`）
#   - `page.permalink`    : 完整链接（由本插件写入 `doc.data['permalink']`）
#   - `page.categories`   : 仍使用你原文的 categories（本插件不改动）
# ============================================================================

module Jekyll
  module PermalinkNormalizer
    module_function

    # 读取并整理配置（仅从嵌套键 `slugify:` 读取；提供默认值）
    # 返回 Hash：{"mode"=>..., "slug_from_title"=>..., "slug_rules_debug"=>...}
    def cfg(site)
      group = site.config["slugify"] || {}
      {
        "mode"             => group.fetch("mode", "default"),
        "slug_from_title"  => group.fetch("slug_from_title", true),
        "slug_rules_debug" => group.fetch("slug_rules_debug", false)
      }
    end

    # 将任意字符串转为 URL 友好形式的 slug（使用 cfg 中的 mode）
    def slugify_for(site, str)
      Jekyll::Utils.slugify(str.to_s, mode: cfg(site)["mode"])  # 等价：第二参传入选项哈希
    end

    # 取得“去掉日期前缀”的文件名尾段
    # 例："2025-06-29-My-Post.md" -> "My-Post"
    def filename_tail(doc)
      base =
        if doc.respond_to?(:basename_without_ext)
          doc.basename_without_ext.to_s
        else
          File.basename(doc.path.to_s, File.extname(doc.path.to_s))
        end
      base.sub(/^\d{4}-\d{2}-\d{2}-/, "")
    end

    # 规范化单篇文档（仅处理 posts）
    def normalize!(doc)
      return unless doc.respond_to?(:collection) && doc.collection&.label == "posts"

      site = doc.site
      conf = cfg(site)

      # A) categories：只用于 URL 结构，不回写到文档
      cats_raw  = Array(doc.data["categories"]).map(&:to_s)
      cats_slug = cats_raw.map { |c| slugify_for(site, c) }.reject(&:empty?)

      # B) 计算末段 slug：
      #    - 文件名派生默认值（default_slug）
      #    - 现有 slug（existing_slug_norm）
      #    - 标题 slug（title_slug）
      fname_tail         = filename_tail(doc)
      default_slug       = slugify_for(site, fname_tail)
      existing_src       = (doc.data["slug"] || fname_tail).to_s
      existing_slug_norm = slugify_for(site, existing_src)
      title_str          = doc.data["title"].to_s
      title_slug         = title_str.empty? ? "" : slugify_for(site, title_str)

      final_slug =
        if conf["slug_from_title"] && existing_slug_norm == default_slug && !title_slug.empty?
          # 仅当“现有等于文件名派生默认值”且开关允许时，替换为“标题 slug”
          title_slug
        else
          existing_slug_norm
        end

      # C) 回写 slug 与 permalink（不改 categories）
      doc.data["slug"] = final_slug
      doc.data["permalink"] =
        cats_slug.empty? ? "/#{final_slug}/" : "/#{cats_slug.join('/')}/#{final_slug}/"

      # D) 调试日志（可选）
      if conf["slug_rules_debug"]
        rel = doc.respond_to?(:relative_path) ? doc.relative_path : doc.path
        Jekyll.logger.info(
          "SLUGRULES",
          {
            path:       rel,
            mode:       conf["mode"],
            cats_raw:   cats_raw,
            cats_slug:  cats_slug,
            default:    default_slug,
            existing:   existing_src,
            picked:     final_slug,
            permalink:  doc.data["permalink"]
          }.inspect
        )
      end
    end
  end
end

# Hook 1：文档初始化后立即规范化（保证渲染前完成）
Jekyll::Hooks.register :documents, :post_init do |doc|
  Jekyll::PermalinkNormalizer.normalize!(doc)
end

# Hook 2：再用优先级最高的生成器兜底（处理边缘时序）
class PermalinkGenerator < Jekyll::Generator
  priority :highest
  def generate(site)
    site.posts.docs.each { |doc| Jekyll::PermalinkNormalizer.normalize!(doc) }
  end
end
