# frozen_string_literal: true
#
# 功能：
# 为 _config.yml 中 `hierarchical_topics` 指定的顶层分类生成两级索引页（`/<Top>/<L1>/` 与 `/<Top>/<L1>/<L2>/`），
# 并使用 `_layouts/list.html` 渲染；同时向页面注入 `page.top`、`page.level1`、`page.level2`、`page.title` 供布局使用。
# 
# 在 _config.yml 的用法：
#   # 自定义需要生成的顶层分类列表
#   hierarchical_topics:
#     - Notes
#   # 自定义布局文件名，默认使用 list.html
#   hierarchical_index:
#     layout: list
#
# 前提与约定：
#   - 每篇文章在 Front Matter 的 `categories` 用数组表达层级，例如：
#       categories: [Notes, "Computer Engineering", "CPU"]
#   - 顶层根页（例如 `/notes/`）需由你自行创建（如 `_tabs/notes.md`）。
#   - 本插件只生成索引页，不改写文章。
# 
# 通用“多级索引页”生成器
# 作用：为 _config.yml.hierarchical_topics 中声明的顶层分类（如 Notes）
#       自动生成两级索引：
#         /<top>/<l1>/
#         /<top>/<l1>/<l2>/
#
# 使用前提：
# - 文章 Front Matter 中的 categories 以数组承载层级，例如：
#   Notes 文章：categories: [Notes, Computer Engineering, CPU]
#   Projects：  categories: [Projects]
#   Publications：categories: [Publications]
#
# 生成页会使用 _layouts/list.html 进行渲染，并向该布局注入：
# - page.top    => 顶层名（如 "Notes"）
# - page.level1 => 一级类目（可为空）
# - page.level2 => 二级类目（可为空）
#
# 注意：
# - 该生成器不会生成顶层根页（/notes/），你需要自行在 _tabs/notes.md 提供根页。
# - 为避免 /categories/... 链接，请自行覆盖 post-meta 的分类输出（本文方案已包含）。

# 依赖标准库 Set，用于去重/集合运算
require 'set'

module Jekyll
  # 页面对象：用于生成静态索引页（继承 Jekyll::Page）
class HierIndexPage < Page
    # 构造函数：传入站点对象、站点根、目标目录及三段层级名
  def initialize(site, base, dir, top, l1=nil, l2=nil)
      @site = site
      @base = base
      @dir  = dir
      @name = 'index.html'

      # 设置输出文件名（index.html）
      process(@name)
      # 通用列表布局
      # 选择渲染布局：默认使用 _layouts/list.html
      read_yaml(File.join(base, '_layouts'), 'list.html')

      # 提供给布局/模版使用的变量
      data['layout']  = 'list'
      data['top']     = top
      data['level1']  = l1
      data['level2']  = l2

      # 页面标题：用于 <title> 或页内 H1
      # 标题只取当前层级名：优先 L2，其次 L1，最后 Top
      parts = [top, l1, l2].compact
      # 页面标题：优先使用更深层级的名称
      data['title'] = (l2 || l1 || top).to_s

      # 收集该页对应的文章
      docs = site.posts.docs.select do |p|
        cats = p.data['categories']
        next false unless cats.is_a?(Array) && cats[0].to_s == top
        ok = true
        ok &&= (cats[1].to_s == l1.to_s) if l1
        ok &&= (cats[2].to_s == l2.to_s) if l2
        ok
      end.sort_by { |p| p.data['date'] || p.date }.reverse
      data['posts'] = docs

    end
  end

  class HierarchicalIndexesGenerator < Generator
    safe true
    priority :low  # 较低优先级，避免干扰其他生成器

    def generate(site)
      tops = site.config['hierarchical_topics'] || []
      return if tops.empty?
      
      tops.each do |top|
        # 收集该 top 下的所有文章
        docs = site.posts.docs.select do |p|
          cats = p.data['categories']
          cats.is_a?(Array) && cats.first.to_s == top
        end
        next if docs.empty?

        # 构建 L1 -> Set(L2) 的树
        tree = {} 
        docs.each do |p|
          cats = p.data['categories']
          l1 = cats[1]; l2 = cats[2]
          next unless l1
          tree[l1] ||= Set.new
          tree[l1] << l2 if l2
        end

        top_slug = Jekyll::Utils.slugify(top)

        # 生成 /<top>/<l1>/ 与 /<top>/<l1>/<l2>/
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