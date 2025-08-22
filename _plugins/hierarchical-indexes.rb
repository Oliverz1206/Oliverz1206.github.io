# frozen_string_literal: true
#
# ============================================================================
#  Hierarchical Indexes Generator | 两级索引页生成器
# ============================================================================
# 作用（What it does）
#   从 `_config.yml.hierarchical_topics` 读取一组“顶层分类”（如 Notes、Projects），
#   为每个顶层分类自动生成两级索引页：
#     - /<Top>/<Level1>/
#     - /<Top>/<Level1>/<Level2>/
#   生成的页面使用 `_layouts/list.html` 渲染，并向布局注入以下变量：
#     - page.top      : 顶层分类名（字符串）
#     - page.level1   : 一级分类名（可能为 nil）
#     - page.level2   : 二级分类名（可能为 nil）
#     - page.title    : 页面标题（优先取 level2，其次 level1，最后 top）
#     - page.posts    : 属于该层级的文章数组，按时间倒序
#
# 前提（Assumptions）
#   1) 每篇文章在 Front Matter 中用数组表示层级：
#        categories: [Notes, "Computer Engineering", "CPU"]
#      其中 categories[0] 是顶层分类（如 Notes）。
#   2) 顶层根页（如 /notes/）需你自行提供（例如 `_tabs/notes.md`）。
#   3) 本插件只“生成索引页”，不会修改文章的 front matter 或内容。
#
# 触发与执行顺序（Lifecycle）
#   - 本文件定义了一个 `Jekyll::Generator`（priority :low），在构建阶段运行；
#   - 它会遍历 `site.posts.docs`，按 `categories` 聚合并生成静态页对象（继承自 Jekyll::Page），
#     然后将这些对象 append 到 `site.pages`，交由后续渲染管线处理。
#
# 配置（_config.yml 示例）
#   hierarchical_topics:
#     - Notes          # 顶层分类名（必须与 categories[0] 完全一致）
#
#   # 注意：虽然早期注释提到可通过 hierarchical_index.layout 自定义布局文件名，
#   # 但当前实现“始终使用 _layouts/list.html”，并且强制设置 data['layout'] = 'list'。
#   # 如需改用自定义布局，请在本文件的 read_yaml(...) 与 data['layout'] 处同步修改。
#
# 布局如何取数据（/_layouts/list.html 示例取值）
#   - 使用 `page.title` 渲染标题；
#   - 使用 `page.top`, `page.level1`, `page.level2` 做面包屑/导航；
#   - 遍历 `page.posts` 输出该层级下的文章列表；
#
# 兼容性与限制
#   - 依赖 Ruby 标准库 `set`（用于 L2 去重）；已在本文件内 `require 'set'`；
#   - GitHub Pages 原生托管不会运行自定义插件，需本地构建或 GitHub Actions 构建后推送产物；
#   - URL 片段使用 `Jekyll::Utils.slugify` 规范化，显示名称仍保留原始分类名；
#   - 仅处理两级（Level1/Level2）索引，更多层级需要扩展代码。
# ============================================================================

require 'set'  # 使用集合去重 L2 分类（Ruby 标准库）

module Jekyll
  # 页面对象：用于生成静态索引页（每个目标目录下一个 `index.html`）
  # 继承自 `Jekyll::Page`，以便加入到 `site.pages` 参与渲染。
  class HierIndexPage < Page
    # @param site [Jekyll::Site] 站点对象（Jekyll 运行时传入）
    # @param base [String]        站点根目录（通常为仓库根）
    # @param dir  [String]        目标输出目录（如 'notes/cpu/'）
    # @param top  [String]        顶层分类名（categories[0]）
    # @param l1   [String,nil]    一级分类名（categories[1]），可为 nil
    # @param l2   [String,nil]    二级分类名（categories[2]），可为 nil
    def initialize(site, base, dir, top, l1=nil, l2=nil)
      @site = site          # 必填：供父类/渲染使用
      @base = base          # 站点根，用于定位布局文件
      @dir  = dir           # 输出到的相对目录（不含文件名）
      @name = 'index.html'  # 固定输出文件名

      process(@name)  # 让父类处理文件名（生成 @ext 等内部字段）

      # 选择用于渲染的布局文件：
      # 这里固定读取 `_layouts/list.html`，
      # 如需可配置化，可改为从 site.config['hierarchical_index']['layout'] 读取。
      read_yaml(File.join(base, '_layouts'), 'list.html')

      # 注入给布局/模板的数据（page.*）
      data['layout']  = 'list'  # 与上面的布局文件名保持一致
      data['top']     = top
      data['level1']  = l1
      data['level2']  = l2

      # 计算用于 <title> 或页内 H1 的标题：优先 level2，其次 level1，最后 top
      # 注：下一行 `parts` 当前未被后续使用，保留不影响功能，属于可清理的冗余变量。
      parts = [top, l1, l2].compact
      data['title'] = (l2 || l1 || top).to_s

      # 根据层级筛选文章：只收集与 (top, l1?, l2?) 完全匹配的 posts
      docs = site.posts.docs.select do |p|
        cats = p.data['categories']
        next false unless cats.is_a?(Array) && cats[0].to_s == top
        ok = true
        ok &&= (cats[1].to_s == l1.to_s) if l1
        ok &&= (cats[2].to_s == l2.to_s) if l2
        ok
      end.sort_by { |p| p.data['date'] || p.date }.reverse  # 时间倒序（优先 front matter 的 date）

      data['posts'] = docs  # 提供给布局循环输出文章列表
    end
  end

  # 生成器：扫描 posts，按顶层分类构建 L1/L2 索引页
  class HierarchicalIndexesGenerator < Generator
    safe true              # 声明插件是“安全”的（可在受限环境运行）
    priority :low          # 低优先级，尽量在其他生成器之后运行

    def generate(site)
      # 读取顶层分类列表；未配置则不生成任何索引页
      tops = site.config['hierarchical_topics'] || []
      return if tops.empty?

      tops.each do |top|
        # 过滤出顶层分类命中的文章（categories[0] == top）
        docs = site.posts.docs.select do |p|
          cats = p.data['categories']
          cats.is_a?(Array) && cats.first.to_s == top
        end
        next if docs.empty?

        # 构建 { L1 => Set[L2, ...] } 的树形映射，去重 L2
        tree = {}
        docs.each do |p|
          cats = p.data['categories']
          l1 = cats[1]; l2 = cats[2]
          next unless l1
          (tree[l1] ||= Set.new)  # 初始化 Set
          tree[l1] << l2 if l2
        end

        # 顶层目录使用 slug 规范化（URL 片段用小写/连字符等规则）
        top_slug = Jekyll::Utils.slugify(top)

        # 逐个 L1 生成: /<top>/<l1>/ 以及其下的 L2: /<top>/<l1>/<l2>/
        tree.each do |l1, l2set|
          dir1 = File.join(top_slug, Jekyll::Utils.slugify(l1))
          site.pages << HierIndexPage.new(site, site.source, dir1, top, l1, nil)

          l2set.compact.each do |l2|
            dir2 = File.join(
              top_slug,
              Jekyll::Utils.slugify(l1),
              Jekyll::Utils.slugify(l2)
            )
            site.pages << HierIndexPage.new(site, site.source, dir2, top, l1, l2)
          end
        end
      end
    end
  end
end
