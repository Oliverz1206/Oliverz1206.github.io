# frozen_string_literal: true
#
# ============================================================================
#  Showcase settings | Showcase 页面整合器
# ============================================================================
# 目标（What）
#   在分页插件 jekyll-paginate-v2 运行之前，统一处理与 `layout: showcase` 相关的对象，
#   以确保：
#   1) 非 posts 集合（如 `_tabs`）里的 showcase 文档**不直接输出**（避免 URL 冲突）。
#   2) posts 集合中的文档拥有用于排序的 `showcase_rank`（置顶优先 + 时间越近越靠前）。
#   3) 针对 `_tabs` 中的 showcase 文档，在其目标 URL 下**生成真正的 Page**（`PageWithoutAFile`），
#      复制其 Front Matter 和正文，注入 `pagination` 供 paginate-v2 使用，并保留 Tab 页面外观上下文。
#   4) 对任何 `layout: showcase` 的 Page，如果**未写** `pagination`，自动注入一份默认配置。
#   5) 无论上述哪种情况，都**确保** `pagination.title` 存在（否则 paginate-v2 标题会出现 "- page :num"）。
#   6) 更早阶段在 `documents:pre_render` 规范 `_tabs` showcase 文档的 `permalink`（将 `:title` 替换为 slug），
#      并清理 URL 缓存，保证接管页与 Tab 文档的 URL 一致。
#
# 运行时机（When）
#   - 作为 `Jekyll::Generator` 执行，`priority :highest`，保证在大多数生成器（含 paginate-v2）之前运行。
#   - 同时注册了两个 Hook：
#       * `documents:pre_render`：渲染前调整 `_tabs` showcase 文档的 `permalink`。
#       * `pages:post_init`     ：Page 初始化后兜底注入/补齐 `pagination`。
#
# 适用范围（Scope）
#   - `posts` 集合：用于计算 `showcase_rank`。
#   - 其它集合（如 `_tabs`）：禁止直接输出其 `layout: showcase` 文档，并由我们生成接管页。
#
# 配置（_config.yml）
#   showcase:
#     enabled: true            # 是否启用本整合逻辑（默认 true）
#     debug: false             # 打印调试日志
#     pagination:
#       per_page: 6            # 每页显示条数（本脚本默认 12）
#       sort_reverse: true     # 是否按 `showcase_rank` 倒序（true = 新→旧；pin 仍优先）
#       title: ':title'        # 分页标题模板；强烈建议配置，避免 "- page :num"
#
# 依赖（Dependencies）
#   - 需要 gem：`jekyll-paginate-v2`（在 Gemfile 与 `_config.yml.plugins` 中启用）。
#   - 若使用 `slugify_mode`，需在 `_config.yml` 设置（本文件在生成 slug 时会读取）。
# ============================================================================
require 'time'

module Jekyll
  class ShowcaseSettings < Jekyll::Generator
    # 必须早于 paginate-v2 的 Generator 执行，确保我们的接管/注入已完成
    priority :highest

    # 置顶权重：一个很大的常数，用于将 `pin: true` 的文章排到所有非置顶之前
    PIN_WEIGHT = 10_000_000_000_000 # 10^13

    # 入口：Jekyll 在站点生成阶段调用此方法
    # @param site [Jekyll::Site]
    def generate(site)
      sc      = site.config['showcase'] || {}
      # 是否启用：默认启用；可以通过 _config.yml 的 showcase.enabled 关闭
      enabled = sc.key?('enabled') ? !!sc['enabled'] : true
      return unless enabled

      # 调试开关：打印各步骤的日志
      debug   = sc.key?('debug') ? !!sc['debug'] : false

      # 从 _config.yml 读取分页配置（我们特别关心 per_page / sort_reverse / title 模板）
      pag_cfg      = sc['pagination'] || {}
      per_page     = pag_cfg['per_page'] ? pag_cfg['per_page'].to_i : 12
      sort_reverse = pag_cfg.key?('sort_reverse') ? !!pag_cfg['sort_reverse'] : true
      # 标题模板：若未提供则回退为 ':title'，可避免分页标题格式残缺
      title_tpl    = (pag_cfg['title'].to_s.strip.empty? ? ':title' : pag_cfg['title'].to_s.strip)

      # 1) 禁止 _tabs 等集合中的 showcase 文档写出（让位给接管页）
      disable_collection_showcase_output!(site, debug)

      # 2) 为 posts 计算 showcase_rank（置顶优先 + 时间倒序）
      compute_showcase_rank!(site, debug)

      # 3a) 针对 `_tabs` 中的 showcase 文档：在其 URL 下生成接管页 PageWithoutAFile
      create_takeover_pages!(site, per_page, sort_reverse, title_tpl, debug)

      # 3b) 兜底：对已有的 `layout: showcase` Page，若缺 pagination 则注入默认
      inject_pagination_for_pages!(site, per_page, sort_reverse, title_tpl, debug)

      # 5) 再兜底：已有 pagination 但缺 title 的，也补上
      ensure_pagination_title!(site, title_tpl, debug)
    end

    private

    # ----------------------------------------------------------------------
    # 禁止非 posts 集合里 `layout: showcase` 文档的输出
    # 目的：把 URL 控制权交给我们稍后创建的接管页（同 URL 下的真正 Page），避免冲突
    # ----------------------------------------------------------------------
    # @param site  [Jekyll::Site]
    # @param debug [Boolean]
    def disable_collection_showcase_output!(site, debug)
      site.collections.each do |label, coll|
        next if label.to_s == 'posts'
        coll.docs.each do |doc|
          layout = doc.data['layout'].to_s
          next unless layout == 'showcase' || layout == 'showcase.html'
          # 核心：不让原文档写出/发布
          doc.data['output']    = false
          doc.data['published'] = false
          Jekyll.logger.info 'SHOWCASE_DISABLE', "output=false for #{doc.path}" if debug
        end
      end
    end

    # ----------------------------------------------------------------------
    # 为 posts 集合计算 `showcase_rank`
    # 规则：rank = (pin? ? 1 : 0) * PIN_WEIGHT + epoch
    #  - pin:true 的文章总在前面；
    #  - epoch 为发布时间的时间戳（秒）；越新越大，排序时越靠前；
    # 该字段供分页排序使用：sort_field = 'showcase_rank'
    # ----------------------------------------------------------------------
    # @param site  [Jekyll::Site]
    # @param debug [Boolean]
    def compute_showcase_rank!(site, debug)
      coll = site.collections['posts']
      return unless coll

      coll.docs.each do |doc|
        pin_val = truthy?(doc.data['pin']) ? 1 : 0
        epoch   = extract_epoch(doc)
        showcase_rank = pin_val * PIN_WEIGHT + epoch
        doc.data['showcase_rank'] = showcase_rank
        Jekyll.logger.info 'SHOWCASE_RANK',
          "doc=#{doc.path} pin=#{pin_val} epoch=#{epoch} -> showcase_rank=#{showcase_rank}" if debug
      end
    end

    # ----------------------------------------------------------------------
    # 在与 `_tabs` 文档相同 URL 下创建接管页（PageWithoutAFile，输出 index.md）
    # 步骤概览：
    #   1) 计算目标 URL：优先使用原文档 permalink；其中的 `:title` 替换为 slug；
    #      若 permalink 为空或被标记为抑制路径，则使用 "/<slug>/"。
    #   2) 将目标 URL 规范为“目录形式”（结尾带 `/`），形成 `target_dir`。
    #   3) 将原 Tab 文档的 `permalink` 改为 `target_dir` 并标记 `published:false`；
    #      同时清理 `@url` 缓存，避免旧 URL 干扰。
    #   4) 创建 `PageWithoutAFile`（路径为 `target_dir/index.md`），
    #      复制原文档 Front Matter（保留 icon/order 等），并保留正文；
    #      强制加上 `collection:'tabs'` 与 `tab:true`，确保主题仍按 Tab 样式渲染头部；
    #      注入 `pagination`（启用、集合 posts、按 `showcase_rank` 排序、标题模板等）。
    # ----------------------------------------------------------------------
    # @param site         [Jekyll::Site]
    # @param per_page     [Integer]
    # @param sort_reverse [Boolean]
    # @param title_tpl    [String]
    # @param debug        [Boolean]
    def create_takeover_pages!(site, per_page, sort_reverse, title_tpl, debug)
      site.collections.each do |label, coll|
        next if label.to_s == 'posts'
        coll.docs.each do |doc|
          layout = doc.data['layout'].to_s
          next unless layout == 'showcase' || layout == 'showcase.html'

          title = doc.data['title'].to_s.strip
          next if title.empty?

          # 计算 slug：使用全站的 slugify_mode（若未设置则为 'default'）
          slug_mode = (site.config['slugify_mode'] || 'default').to_s
          slug = Jekyll::Utils.slugify(title, mode: slug_mode)

          # 目标 URL：优先使用文档 permalink；为空或含 :title 则替换；
          permalink = (doc.data['permalink'] || '').to_s
          target_url = if permalink.empty? || permalink =~ /:title/i || permalink.start_with?('/__tabs_suppressed__/')
                         "/#{slug}/"
                       else
                         permalink
                       end
          target_url = target_url.gsub(/:title|:Title|:TITLE/, slug)

          # 统一为目录形式
          target_dir =
            if File.extname(target_url).empty?
              target_url.end_with?('/') ? target_url : "#{target_url}/"
            else
              File.dirname(target_url) + '/'
            end

          # 修正原 Tab 文档的 permalink，并清理 URL 缓存，避免旧 URL 残留
          doc.data['permalink'] = target_dir
          doc.data['published'] = false
          begin
            doc.instance_variable_set(:@url, nil)
          rescue
          end

          # 创建接管页：`target_dir/index.md`
          page = Jekyll::PageWithoutAFile.new(site, site.source, target_dir, 'index.md')

          # 合并原 Tab 文档的前言（保留 icon/order 等；跳过我们用于禁用输出的键）
          if doc.data.is_a?(Hash)
            doc.data.each do |k, v|
              next if %w[output published].include?(k.to_s)
              page.data[k] = v
            end
          end

          # 维持 Tab 页面的上下文：collection 与 tab 标记（便于主题渲染页眉/大标题）
          page.data['collection'] = (doc.respond_to?(:collection) && doc.collection ? doc.collection.label.to_s : 'tabs')
          page.data['tab'] = true unless page.data.key?('tab')

          # 复制正文（Markdown 内容）
          page.content = doc.content.to_s

          # 关键字段：确保 layout、title、permalink 与 pagination 存在
          page.data['layout']    = doc.data['layout'].to_s.empty? ? 'showcase' : doc.data['layout']
          page.data['title']     = title
          page.data['permalink'] = target_dir
          page.data['pagination'] = {
            'enabled'      => true,
            'collection'   => 'posts',
            'category'     => title,         # 以页面标题作为分类筛选（可根据主题逻辑调整）
            'per_page'     => per_page,
            'sort_field'   => 'showcase_rank',
            'sort_reverse' => sort_reverse,
            'title'        => title_tpl      # 关键：显式指定标题模板
          }

          # 将接管页加入站点页面列表
          site.pages << page
          Jekyll.logger.info 'SHOWCASE_TAKEOVER',
            "collection=#{label} doc=#{doc.path} -> takeover #{target_dir}index.md" if debug
        end
      end
    end

    # ----------------------------------------------------------------------
    # 对已存在的 `layout: showcase` Page：如无 pagination，则注入默认配置
    # （避免遗漏导致 paginate-v2 无法分页）
    # ----------------------------------------------------------------------
    def inject_pagination_for_pages!(site, per_page, sort_reverse, title_tpl, debug)
      site.pages.each do |page|
        layout = page.data['layout'].to_s
        next unless layout == 'showcase' || layout == 'showcase.html'
        next if page.data.key?('pagination')

        title_str = page.data['title'].to_s.strip
        pconf = {
          'enabled'      => true,
          'collection'   => 'posts',
          'per_page'     => per_page,
          'sort_field'   => 'showcase_rank',
          'sort_reverse' => sort_reverse,
          'title'        => title_tpl
        }
        pconf['category'] = title_str unless title_str.empty?

        page.data['pagination'] = pconf
        Jekyll.logger.info 'SHOWCASE_PAGINATION',
          "applied to #{page.path}: #{pconf.inspect}" if debug
      end
    end

    # ----------------------------------------------------------------------
    # 兜底：已有 pagination 但缺 `title` 的，也补上（避免 "- page :num"）
    # ----------------------------------------------------------------------
    def ensure_pagination_title!(site, title_tpl, debug)
      site.pages.each do |page|
        layout = page.data['layout'].to_s
        next unless layout == 'showcase' || layout == 'showcase.html'
        next unless page.data['pagination'].is_a?(Hash)
        if page.data['pagination']['title'].to_s.strip.empty?
          page.data['pagination']['title'] = title_tpl
          Jekyll.logger.info 'SHOWCASE_TITLE',
            "filled pagination.title for #{page.path} => #{title_tpl}" if debug
        end
      end
    end

    # ----------------------------------------------------------------------
    # 帮助方法：从文章中提取用于排序的时间戳（秒）
    # 优先读取 `doc.data['date']`；支持 Time/DateTime/Date/String；失败则回退到 epoch=0。
    # ----------------------------------------------------------------------
    def extract_epoch(doc)
      val = doc.data['date']
      t = to_time(val)
      (t || Time.at(0)).to_i
    end

    # 将多种时间类型转换为 Time；不抛异常，失败返回 nil
    def to_time(val)
      case val
      when Time
        val
      when DateTime, Date
        Time.parse(val.to_s)
      when String
        begin
          Time.parse(val)
        rescue ArgumentError
          nil
        end
      else
        nil
      end
    end

    # 宽松的真值判断：支持 true/false、1/0、yes/no、on/off、字符串形式等
    def truthy?(v)
      return false if v.nil?
      return v if v == true || v == false
      s = v.to_s.strip.downcase
      return true  if %w[1 true yes y on].include?(s)
      return false if %w[0 false no n off].include?(s)
      !!v
    end
  end
end

# ----------------------------------------------------------------------------
# Hook：documents:pre_render —— 规范 `_tabs` showcase 文档的 permalink，并清理 URL 缓存
# 目的：将 `:title` 替换为 slug；若为空或被抑制，则使用基于标题的默认目录 "/<slug>/"；
#       然后把该文档标记为 `published:false` 并清理内部 `@url`，避免旧 URL 干扰。
# ----------------------------------------------------------------------------
Jekyll::Hooks.register :documents, :pre_render do |doc, payload|
  begin
    next unless doc.respond_to?(:collection)
    coll = doc.collection
    next if coll && coll.label.to_s == 'posts'

    layout = doc.data['layout'].to_s
    next unless layout == 'showcase' || layout == 'showcase.html'

    title = doc.data['title'].to_s.strip
    next if title.empty?

    # 按站点配置生成 slug
    slug_mode = (doc.site.config['slugify_mode'] || 'default').to_s
    slug = Jekyll::Utils.slugify(title, mode: slug_mode)

    # 组装/替换 permalink
    permalink = (doc.data['permalink'] || '').to_s
    newp =
      if permalink.empty? || permalink =~ /:title/i || permalink.start_with?('/__tabs_suppressed__/')
        "/#{slug}/"
      else
        permalink.gsub(/:title|:Title|:TITLE/, slug)
      end

    # 如有变化：写回并清理 URL 缓存
    if newp != permalink
      doc.data['permalink'] = newp
      doc.data['published'] = false
      begin
        doc.instance_variable_set(:@url, nil)
      rescue
      end
      if doc.site.config.dig('showcase', 'debug')
        Jekyll.logger.info 'SHOWCASE_PERMALINK(pre_render)', "#{doc.path} -> #{newp}"
      end
    end
  rescue => e
    Jekyll.logger.warn 'SHOWCASE_PERMALINK(pre_render)', "failed for #{doc.path}: #{e}"
  end
end

# ----------------------------------------------------------------------------
# Hook：pages:post_init —— Page 初始化后也确保 pagination 注入（早于分页器扫描）
# 逻辑：若 `layout: showcase` 的页面尚未有 `pagination`，注入默认；
#       若已有但缺 `title`，补 `title` 为配置/默认的 `:title`。
# ----------------------------------------------------------------------------
Jekyll::Hooks.register :pages, :post_init do |page|
  site = page.site
  sc = site.config['showcase'] || {}
  enabled = sc.key?('enabled') ? !!sc['enabled'] : true
  next unless enabled

  layout = page.data['layout'].to_s
  next unless layout == 'showcase' || layout == 'showcase.html'

  pag_cfg      = sc['pagination'] || {}
  per_page     = pag_cfg['per_page'] ? pag_cfg['per_page'].to_i : 12
  sort_reverse = pag_cfg.key?('sort_reverse') ? !!pag_cfg['sort_reverse'] : true
  title_tpl    = (pag_cfg['title'].to_s.strip.empty? ? ':title' : pag_cfg['title'].to_s.strip)

  unless page.data.key?('pagination')
    title_str = page.data['title'].to_s.strip
    pconf = {
      'enabled'      => true,
      'collection'   => 'posts',
      'per_page'     => per_page,
      'sort_field'   => 'showcase_rank',
      'sort_reverse' => sort_reverse,
      'title'        => title_tpl
    }
    pconf['category'] = title_str unless title_str.empty?
    page.data['pagination'] = pconf
  else
    # 若已有 pagination 但缺 title，则补上
    if page.data['pagination'].is_a?(Hash) && page.data['pagination']['title'].to_s.strip.empty?
      page.data['pagination']['title'] = title_tpl
    end
  end
end
