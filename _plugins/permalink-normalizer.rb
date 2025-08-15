# frozen_string_literal: true
# 
# 功能：
# 统一 posts 的 slug 和 permalink 规则：
# - categories 仅用于 URL 结构（不回写到文档的 categories）；
# - 若未显式提供 slug 或现有 slug 仅等于“去日期前缀的文件名”，可根据配置决定是否用标题的 slug；
# - 最终生成形如 `/cat1/cat2/slug/` 的 permalink。
#
# 在 _config.yml 的用法：
#   # slugify 与 slug 生成策略
#   slugify_mode: default        # 可选：default / pretty / ascii / latin 等
#   slug_from_title: true        # true: 若未自定义 slug，则用标题的 slug 替代文件名派生的默认值
#   slug_rules_debug: false      # 输出调试日志（可选）
#
# 使用方式：
#   放入 `_plugins/` 后自动生效；同时提供一个 `priority :highest` 的 Generator 兜底规范化。
#
module Jekyll
  module PermalinkNormalizer
    module_function  # 以模块函数形式提供工具方法

    def slugify(str)  # 将任意字符串转为 URL 友好的 slug
      Jekyll::Utils.slugify(str.to_s, mode: "default")
    end

    # 去掉日期前缀后的文件名尾巴，例如 "2025-06-29-ProjectTest2" -> "ProjectTest2"
    def filename_tail(doc)  # 去掉日期前缀，取文件名尾段（用于默认 slug 推断）
      doc.basename_without_ext.to_s.sub(/^\d{4}-\d{2}-\d{2}-/, "")
    end

    def normalize!(doc)  # 规范化单篇文档的 slug 与 permalink
      # 只处理 posts
      return unless doc.respond_to?(:collection) && doc.collection&.label == "posts"  # 仅处理 posts 集合

      # A) categories 各段转 slug（只用于 URL，不回写 categories）
      cats_raw  = Array(doc.data["categories"]).map(&:to_s)  # 原始 categories（不回写，仅用于 URL）
      cats_slug = cats_raw.map { |c| slugify(c) }.reject(&:empty?)  # 每段转 slug，并去除空段

      # B) 末段 slug：若现有等于“文件名派生”，用 title 的 slug；否则尊重显式 slug
      fname_tail         = filename_tail(doc)          # 例："2025-06-29-ProjectTest2" -> "ProjectTest2"          # 如 "NotesTest1"
      default_slug       = slugify(fname_tail)         # 文件名派生的默认 slug         # 如 "notestest1"
      existing_slug      = (doc.data["slug"] || fname_tail).to_s  # 若未显式给 slug，就用文件名尾段
      existing_slug_norm = slugify(existing_slug)      # 规范化后的现有 slug
      title_slug         = doc.data["title"] ? slugify(doc.data["title"]) : existing_slug_norm  # 标题 slug 作为候选
      final_slug         = (existing_slug_norm == default_slug) ? title_slug : existing_slug_norm  # 若未自定义 slug，则用标题 slug

      # C) 回写 slug & permalink（不改 categories）
      doc.data["slug"] = final_slug  # 回写最终 slug（仅字段，不动 categories）
      doc.data["permalink"] =  # 生成形如 "/cat1/cat2/slug/" 的链接
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
# Hook 1：文档初始化后立即规范化，保证渲染前完成
Jekyll::Hooks.register :documents, :post_init do |doc|
  Jekyll::PermalinkNormalizer.normalize!(doc)
end

# 2) 再用最高优先级的 Generator 兜底（防止某些边缘时序）
# Hook 2：再用优先级最高的 Generator 兜底（处理某些边缘时序）
class PermalinkGenerator < Jekyll::Generator
  priority :highest  # 确保早于其他生成器运行
  def generate(site)
    site.posts.docs.each { |doc| Jekyll::PermalinkNormalizer.normalize!(doc) }  # 遍历 posts 集合逐一处理
  end
end