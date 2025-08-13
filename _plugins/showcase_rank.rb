# frozen_string_literal: true
#
# 为分页等场景提供“先 PIN 再按时间倒序”的通用排序键 showcase_rank
#
# 原理：
#   给指定集合（默认 posts）里的每篇文档计算：
#     showcase_rank = (pin ? 1 : 0) * PIN_WEIGHT + epoch_seconds
#   其中 PIN_WEIGHT 远大于“时间秒数”的量级，确保所有 pin:true 的文档
#   都会整体排在未 pin 的前面；同组内部再按时间倒序（配合 sort_reverse:true）。
#
# 使用方法：
#   1) 把本文件放到 `_plugins/showcase_rank.rb`
#   2) 在需要分页的页面（如 Projects/ Publications）front matter 里写：
#        pagination:
#          enabled: true
#          collection: posts
#          category: "Projects"       # 或 "Publications"
#          per_page: 10
#          sort_field: "showcase_rank"
#          sort_reverse: true         # 倒序：越大越靠前（即先 PIN，且时间越近越靠前）
#   3) 运行前建议 clean 一次：
#        bundle exec jekyll clean && bundle exec jekyll serve
#
# 可选配置（_config.yml）：
#   showcase_rank:
#     enabled: true                   # 缺省 true；设 false 可整体关闭
#     collections: [posts]            # 作用的集合，默认只对 posts
#     pin_field: "pin"                # 置顶字段名（默认 pin）
#     date_fields: ["date"]           # 日期字段优先级（从前到后尝试），默认只看 date
#     pin_weight: 10000000000000      # PIN 权重（10^13），一般无需改
#     debug: false                    # 设 true 输出调试日志
#
# 注意：
#   - 需要自定义插件的构建环境（本地/ GitHub Actions 均可；GitHub Pages原生构建不允许运行插件）。
#   - 若某篇没有 date，会退回到 `doc.date`；若仍取不到，则当作 0（最老）。
#

require "time"

module Jekyll
  module ShowcaseRank
    DEFAULTS = {
      "enabled"     => true,
      "collections" => ["posts"],
      "pin_field"   => "pin",
      "date_fields" => ["date"],
      "pin_weight"  => 10_000_000_000_000, # 10^13
      "debug"       => false
    }.freeze

    def self.config_for(site)
      cfg = site.config["showcase_rank"]
      return DEFAULTS.dup if cfg.nil?

      # 进行浅拷贝并填默认值
      merged = DEFAULTS.merge(cfg) { |_k, _old, newv| newv }
      # 规范类型
      merged["collections"] = Array(merged["collections"]).map(&:to_s)
      merged["date_fields"] = Array(merged["date_fields"]).map(&:to_s)
      merged["pin_field"]   = merged["pin_field"].to_s
      merged
    end

    def self.pick_time(doc, date_fields)
      # 依次尝试从 Front Matter 的 date_fields 里取时间
      date_fields.each do |field|
        v = doc.data[field]
        next if v.nil?

        # 统一转成 Time
        return v if v.is_a?(Time)
        return v.to_time if v.respond_to?(:to_time)

        begin
          return Time.parse(v.to_s)
        rescue StandardError
          # ignore and try next
        end
      end

      # 退回到 Jekyll 给的 doc.date
      return doc.date if doc.respond_to?(:date) && doc.date

      # 实在没有，就用 Unix 0（最老）
      Time.at(0)
    end

    Jekyll::Hooks.register :documents, :post_init do |doc|
      site   = doc.site
      cfg    = ShowcaseRank.config_for(site)

      # 全局开关
      next unless cfg["enabled"]

      # 只处理指定集合（默认 posts）
      coll_label = doc.respond_to?(:collection) ? doc.collection&.label : nil
      next unless cfg["collections"].include?(coll_label)

      # 计算 pin 值
      pin_field = cfg["pin_field"]
      pin_val   = !!doc.data[pin_field] ? 1 : 0

      # 计算时间戳（秒）
      t     = ShowcaseRank.pick_time(doc, cfg["date_fields"])
      epoch = t.to_i

      # 计算 showcase_rank
      weight   = cfg["pin_weight"].to_i
      showcase_rank = pin_val * weight + epoch

      doc.data["showcase_rank"] = showcase_rank

      # 调试日志
      if cfg["debug"]
        Jekyll.logger.info "SHOWCASE_RANK",
          "doc=#{doc.path} pin=#{pin_val} epoch=#{epoch} -> showcase_rank=#{showcase_rank}"
      end
    end
  end
end
