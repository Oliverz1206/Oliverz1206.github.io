# frozen_string_literal: true
#
# ============================================================================
#  Post Tail Includes Classifier | 文章页尾组件分类器
# ============================================================================
# 目的（What）：
#   按文章的“顶层分类”（categories[0]，或从路径推断）自动设置 `page.tail_includes`，
#   以控制文章页底部是否展示：
#     - related-posts  （相关文章模块）
#     - post-nav       （上一篇/下一篇导航）
#
# 适用范围（Scope）：
#   仅对 `layout: post` 的文档生效（Jekyll 的 posts 集合）。
#
# 触发时机（Lifecycle）：
#   `Jekyll::Hooks.register :posts, :post_init` —— 每篇文章对象初始化完成后立即执行。
#   这是“早”阶段写入 `post.data["tail_includes"]`，保证后续渲染能读取到。
#
# 配置（_config.yml）：
#   post_tail_format:
#     both:          ["Blogs"]       # 顶层分类在该列表 -> 同时显示 related-posts 与 post-nav
#     post_nav_only: []               # 顶层分类在该列表 -> 只显示 post-nav
#     related_only:  ["Notes"]       # 顶层分类在该列表 -> 只显示 related-posts
#     none:          ["Projects", "Publications"]   # 顶层分类在该列表 -> 两者都不显示
#   # 说明：匹配不区分大小写；未命中任何分组时，默认等同于 both。
#
# 依赖（Requirements）：
#   无外部 Gem 依赖；但 **自定义插件仅在自托管构建**（本地或 GitHub Actions）中执行。
#   GitHub Pages 的托管构建 **不会运行** _plugins/ 下的 Ruby 插件。
#
# 实现要点（How）：
#   1) 读取 `_config.yml.post_tail_format`，把每个数组标准化为小写、去空白；
#   2) 从文章对象取 `categories[0]` 作为顶层分类；若缺失，则从相对路径 `_posts/<top>/...` 推断；
#   3) 依次判断顶层分类属于哪一组，决定 `tail_includes` 的最终值；
#   4) **不读取** front matter 中已有的 `tail_includes`，而是直接覆盖（保持行为稳定、可控）。
# ============================================================================

module Jekyll
  # 小工具：列表标准化与顶层分类推断
  module TailFormatUtil
    module_function

    # 将配置项统一标准化为小写的字符串数组，去掉空白与空项
    # 例如：nil        => []
    #      "Notes"    => ["notes"]
    #      ["Notes", " Projects "] => ["notes", "projects"]
    def norm_list(v)
      Array(v).map { |s| s.to_s.downcase.strip }.reject(&:empty?)
    end

    # 获取文章的顶层分类：
    # 1) 优先取 front matter 的 categories[0]
    # 2) 若为空，再从相对路径推断 `_posts/<top>/...`
    # 返回小写字符串（可能为空字符串）
    def top_category_of(doc)
      top = Array(doc.data["categories"]).first.to_s.strip.downcase
      return top unless top.empty?

      # —— 路径回退推断 ——
      #   常见路径：_posts/<top>/<YYYY-MM-DD-title>.md
      #   在 docs 集合中，通常可以从 `relative_path` 拿到；若取不到则退到 `path`
      rel = (doc.respond_to?(:relative_path) ? doc.relative_path : nil)
      rel = doc.path if rel.to_s.empty? && doc.respond_to?(:path)
      rel = rel.to_s

      # 从 `_posts/<top>/` 中抽取 <top>
      m = rel.match(%r{_posts/([^/]+)/})
      m ? m[1].to_s.downcase : ""
    end
  end

  # 在每篇文章初始化后，按顶层分类写入 tail_includes
  Jekyll::Hooks.register :posts, :post_init do |post|
    # 读入配置块（容错：缺失则用空 Hash）
    cfg = post.site.config.fetch("post_tail_format", {}) || {}

    # 各组名单标准化为小写列表，便于统一匹配
    both     = Jekyll::TailFormatUtil.norm_list(cfg["both"])            # 同时展示 related-posts 与 post-nav
    nav_only = Jekyll::TailFormatUtil.norm_list(cfg["post_nav_only"])   # 仅展示 post-nav
    rel_only = Jekyll::TailFormatUtil.norm_list(cfg["related_only"])    # 仅展示 related-posts
    none     = Jekyll::TailFormatUtil.norm_list(cfg["none"])            # 全部不展示

    # 获取文章顶层分类（小写）
    top = Jekyll::TailFormatUtil.top_category_of(post)

    # 依据所属分组决定页尾组件
    includes =
      if both.include?(top)         then %w[related-posts post-nav]
      elsif nav_only.include?(top)  then %w[post-nav]
      elsif rel_only.include?(top)  then %w[related-posts]
      elsif none.include?(top)      then []
      else                                %w[related-posts post-nav]  # 默认 both
      end

    # 按要求：不检测/保留 front matter 的原值，直接覆盖，保证主题行为统一
    post.data["tail_includes"] = includes
  end
end
