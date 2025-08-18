# _plugins/post-classifier.rb
# 依据 categories[0] 为每篇 layout: post 的文章设置 page.tail_includes
# 需要自托管构建（本地或 GitHub Actions）。GitHub Pages 原生托管不执行自定义插件。

module Jekyll
  module TailFormatUtil
    module_function

    def norm_list(v)
      Array(v).map { |s| s.to_s.downcase.strip }.reject(&:empty?)
    end

    # 取 categories[0]；若为空，回退从路径 _posts/<top>/... 推断
    def top_category_of(doc)
      top = Array(doc.data["categories"]).first.to_s.strip.downcase
      return top unless top.empty?

      path = (doc.respond_to?(:relative_path) ? doc.relative_path : doc.path).to_s
      parts = path.split("/").reject(&:empty?)
      idx = parts.index("_posts")
      (idx && parts[idx + 1]) ? parts[idx + 1].downcase : ""
    end
  end
end

Jekyll::Hooks.register :posts, :pre_render do |post, _payload|
  # 只处理 layout: post，避免干扰其它布局
  next unless post.data["layout"].to_s == "post"

  cfg = post.site.config.fetch("post_tail_format", {}) || {}
  both      = Jekyll::TailFormatUtil.norm_list(cfg["both"])
  nav_only  = Jekyll::TailFormatUtil.norm_list(cfg["post_nav_only"])
  rel_only  = Jekyll::TailFormatUtil.norm_list(cfg["related_only"])
  none      = Jekyll::TailFormatUtil.norm_list(cfg["none"])

  top = Jekyll::TailFormatUtil.top_category_of(post)

  includes =
    if both.include?(top)         then %w[related-posts post-nav]
    elsif nav_only.include?(top)  then %w[post-nav]
    elsif rel_only.include?(top)  then %w[related-posts]
    elsif none.include?(top)      then []
    else                               %w[related-posts post-nav]  # 默认 both
    end

  # 按要求：不检测 front matter，直接设置
  post.data["tail_includes"] = includes
end
