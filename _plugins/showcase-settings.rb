# frozen_string_literal: true
#
# _plugins/showcase-settings.rb
#
# 功能（专为 showcase 页面的整合脚本）：
# 1) 禁止非 posts 集合（如 _tabs）中 layout: showcase 文档写出（output:false + published:false），
#    让位给真正的 Page（避免 URL 冲突）。
# 2) 为 posts 计算内部排序键 showcase_rank（置顶优先 + 时间倒序）。
# 3) 在与 _tabs 文档相同 URL 下生成一个真正的 Page（PageWithoutAFile，index.md），
#    复制原 Tab 的前言与正文，并注入 jekyll-paginate-v2 的 pagination。
#    —— 同时强制给接管页带上 `collection: 'tabs'` 与 `tab: true` 等标记，模拟 tabs 页面环境，
#       以便主题的 showcase 布局按“原 tabs 页面”的逻辑渲染大标题/页眉。
# 4) 兜底：对任何 layout: showcase 的 Page 若未写 pagination，则自动注入。
# 5) 更关键新增：在 paginate-v2 运行之前，**统一确保 pagination.title 存在**；
#    值默认来自 _config.yml showcase.pagination.title；若缺省则设为 ':title'，避免 "- page :num"。
# 6) 早期在 documents:pre_render 规范 _tabs showcase 文档的 permalink（替换 :title → slug，清理 URL 缓存）。
#
# 依赖：
#   - jekyll-paginate-v2（Gemfile 与 _config.yml 中启用）
#
require 'time'

module Jekyll
  class ShowcaseSettings < Jekyll::Generator
    # 必须早于 paginate-v2 的 Generator
    priority :highest

    PIN_WEIGHT = 10_000_000_000_000 # 10^13，保证 pin:true 全部排到时间排序前

    def generate(site)
      sc      = site.config['showcase'] || {}
      enabled = sc.key?('enabled') ? !!sc['enabled'] : true
      return unless enabled

      debug   = sc.key?('debug') ? !!sc['debug'] : false

      # 从 _config.yml 读取分页配置（含我们关心的 title 模板）
      pag_cfg     = sc['pagination'] || {}
      per_page    = pag_cfg['per_page'] ? pag_cfg['per_page'].to_i : 12
      sort_reverse = pag_cfg.key?('sort_reverse') ? !!pag_cfg['sort_reverse'] : true
      # NEW: 读取分页标题模板；默认 ':title'
      title_tpl   = (pag_cfg['title'].to_s.strip.empty? ? ':title' : pag_cfg['title'].to_s.strip)

      # 1) 禁止 _tabs 等集合中的 showcase 文档输出（避免和 Page 冲突）
      disable_collection_showcase_output!(site, debug)

      # 2) 计算 posts 的 showcase_rank
      compute_showcase_rank!(site, debug)

      # 3a) 对 _tabs 等集合中的 showcase 文档：在同 URL 下生成接管页（真正的 Page）
      create_takeover_pages!(site, per_page, sort_reverse, title_tpl, debug)

      # 3b) 兜底：对现有 layout: showcase 的 Page 注入 pagination（若未注入）
      inject_pagination_for_pages!(site, per_page, sort_reverse, title_tpl, debug)

      # 5) NEW: 再兜底一层——若页面已有 pagination 但缺 title，也补上
      ensure_pagination_title!(site, title_tpl, debug)
    end

    private

    # 禁止非 posts 集合里 layout: showcase 文档的输出（并标记为 unpublished）
    def disable_collection_showcase_output!(site, debug)
      site.collections.each do |label, coll|
        next if label.to_s == 'posts'
        coll.docs.each do |doc|
          layout = doc.data['layout'].to_s
          next unless layout == 'showcase' || layout == 'showcase.html'
          doc.data['output']    = false
          doc.data['published'] = false
          Jekyll.logger.info 'SHOWCASE_DISABLE', "output=false for #{doc.path}" if debug
        end
      end
    end

    # 计算 posts 的 showcase_rank
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

    # 在与 _tabs 文档相同 URL 下创建真正的 Page（并复制前言与正文；输出 index.md 以便 Markdown 渲染）
    def create_takeover_pages!(site, per_page, sort_reverse, title_tpl, debug)
      site.collections.each do |label, coll|
        next if label.to_s == 'posts'
        coll.docs.each do |doc|
          layout = doc.data['layout'].to_s
          next unless layout == 'showcase' || layout == 'showcase.html'

          title = doc.data['title'].to_s.strip
          next if title.empty?

          # 计算目标 URL（优先 permalink；替换 :title；若为空则用 /<slug>/）
          slug_mode = (site.config['slugify_mode'] || 'default').to_s
          slug = Jekyll::Utils.slugify(title, mode: slug_mode)

          permalink = (doc.data['permalink'] || '').to_s
          target_url = if permalink.empty? || permalink =~ /:title/i || permalink.start_with?('/__tabs_suppressed__/')
                         "/#{slug}/"
                       else
                         permalink
                       end
          target_url = target_url.gsub(/:title|:Title|:TITLE/, slug)

          # 目录形式（若无扩展名则确保以 / 结尾）
          target_dir =
            if File.extname(target_url).empty?
              target_url.end_with?('/') ? target_url : "#{target_url}/"
            else
              File.dirname(target_url) + '/'
            end

          # 纠正 Tab 文档的 permalink，并清 URL 缓存
          doc.data['permalink'] = target_dir
          doc.data['published'] = false
          begin
            doc.instance_variable_set(:@url, nil)
          rescue
          end

          # 生成接管页（index.md），并合并原 Tab 的前言与正文
          page = Jekyll::PageWithoutAFile.new(site, site.source, target_dir, 'index.md')

          # 合并 Tab 文档的前言（保留 icon/order 等），后面再覆盖关键字段
          if doc.data.is_a?(Hash)
            doc.data.each do |k, v|
              next if %w[output published].include?(k.to_s)
              page.data[k] = v
            end
          end

          # 模拟 tabs 页面环境
          page.data['collection'] = (doc.respond_to?(:collection) && doc.collection ? doc.collection.label.to_s : 'tabs')
          page.data['tab'] = true unless page.data.key?('tab')

          # 保留 Tab 正文
          page.content = doc.content.to_s

          # 覆盖关键字段：确保为 showcase + 正确 URL + 分页
          page.data['layout']    = doc.data['layout'].to_s.empty? ? 'showcase' : doc.data['layout']
          page.data['title']     = title
          page.data['permalink'] = target_dir
          page.data['pagination'] = {
            'enabled'      => true,
            'collection'   => 'posts',
            'category'     => title,
            'per_page'     => per_page,
            'sort_field'   => 'showcase_rank',
            'sort_reverse' => sort_reverse,
            # NEW: 明确设置分页标题模板
            'title'        => title_tpl
          }

          site.pages << page
          Jekyll.logger.info 'SHOWCASE_TAKEOVER',
            "collection=#{label} doc=#{doc.path} -> takeover #{target_dir}index.md" if debug
        end
      end
    end

    # 兜底注入 pagination（防止某些情况下接管页之外的 showcase Page 未注入）
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
          # NEW: 无论有没有 category，这里都明确给 title 模板
          'title'        => title_tpl
        }
        pconf['category'] = title_str unless title_str.empty?

        page.data['pagination'] = pconf
        Jekyll.logger.info 'SHOWCASE_PAGINATION',
          "applied to #{page.path}: #{pconf.inspect}" if debug
      end
    end

    # NEW: 再兜底一层——有 pagination 但缺 title 的，也补上
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

    # helpers
    def extract_epoch(doc)
      val = doc.data['date']
      t = to_time(val)
      (t || Time.at(0)).to_i
    end

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

# 更早阶段修正：在 documents:pre_render 规范 _tabs showcase 文档的 permalink，并清理 URL 缓存
Jekyll::Hooks.register :documents, :pre_render do |doc, payload|
  begin
    next unless doc.respond_to?(:collection)
    coll = doc.collection
    next if coll && coll.label.to_s == 'posts'

    layout = doc.data['layout'].to_s
    next unless layout == 'showcase' || layout == 'showcase.html'

    title = doc.data['title'].to_s.strip
    next if title.empty?

    slug_mode = (doc.site.config['slugify_mode'] || 'default').to_s
    slug = Jekyll::Utils.slugify(title, mode: slug_mode)

    permalink = (doc.data['permalink'] || '').to_s
    newp =
      if permalink.empty? || permalink =~ /:title/i || permalink.start_with?('/__tabs_suppressed__/')
        "/#{slug}/"
      else
        permalink.gsub(/:title|:Title|:TITLE/, slug)
      end

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

# Page 初始化后也确保 pagination 注入（早于分页器扫描）
Jekyll::Hooks.register :pages, :post_init do |page|
  site = page.site
  sc = site.config['showcase'] || {}
  enabled = sc.key?('enabled') ? !!sc['enabled'] : true
  next unless enabled

  layout = page.data['layout'].to_s
  next unless layout == 'showcase' || layout == 'showcase.html'

  pag_cfg     = sc['pagination'] || {}
  per_page    = pag_cfg['per_page'] ? pag_cfg['per_page'].to_i : 12
  sort_reverse = pag_cfg.key?('sort_reverse') ? !!pag_cfg['sort_reverse'] : true
  # NEW: 读取并兜底 title 模板
  title_tpl   = (pag_cfg['title'].to_s.strip.empty? ? ':title' : pag_cfg['title'].to_s.strip)

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
