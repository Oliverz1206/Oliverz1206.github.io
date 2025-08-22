# frozen_string_literal: true
#
# ============================================================================
#  Posts Last-Modified Hook | 为文章注入最后修改时间
# ============================================================================
# 功能（做什么）
#   在构建时为每篇 `post` 写入 `page.last_modified_at`：
#   - 当目标文件在 Git 历史中的提交次数 > 1（即非“首次提交”）时，
#     取该文件最近一次提交的时间并写入 `post.data['last_modified_at']`（UTC、ISO 8601）。
#   - 布局/模板可直接使用 `page.last_modified_at` 显示“更新于 …”。
#
# 触发时机（什么时候运行）
#   - Hook：`Jekyll::Hooks.register :posts, :post_init`
#     在每篇文章对象初始化完成后立即执行（渲染开始前）。
#
# 适用范围（作用对象）
#   - 仅处理 `posts` 集合（`layout: post` 所属集合）。
#
# 依赖与前提（环境要求）
#   - 构建环境必须能访问完整的 Git 历史，且安装了 `git`：
#     * 本地构建：确保本仓库是 Git 仓库。
#     * GitHub Actions：`actions/checkout` 需要 `fetch-depth: 0`（浅克隆拿不到完整历史）。
#   - 对于新文件（仅 1 次提交），本钩子不会写入 `last_modified_at`，
#     页面通常只显示发布日期（由主题/布局控制）。
# ============================================================================

module Jekyll
  module GitLastMod
    module_function

    # 取得文件在 Git 中的提交次数（用于区分是否“仅 1 次提交”）
    # @param repo_root [String] 仓库根目录（通常为 site.source）
    # @param rel_path  [String] 文件相对仓库根的路径（如 "_posts/2025-01-01-foo.md"）
    # @return [Integer] 提交次数，获取失败时返回 0
    def commit_count(repo_root, rel_path)
      cmd = %(git -C "#{repo_root}" rev-list --count HEAD -- "#{rel_path}")
      Integer(`#{cmd}`.to_s.strip)
    rescue
      0
    end

    # 取得文件最近一次提交的 Unix 时间戳（秒）
    # @param repo_root [String]
    # @param rel_path  [String]
    # @return [Integer,nil] 时间戳；失败或无记录时返回 nil
    def last_commit_epoch(repo_root, rel_path)
      cmd = %(git -C "#{repo_root}" log -1 --format=%ct -- "#{rel_path}")
      v = `#{cmd}`.to_s.strip
      i = Integer(v)
      i.positive? ? i : nil
    rescue
      nil
    end

    # 将 epoch 转为 ISO 8601（UTC）字符串："YYYY-MM-DDTHH:MM:SSZ"
    # 这里直接用 strftime 生成，避免依赖 `require 'time'`。
    def iso8601_utc(epoch)
      Time.at(epoch).utc.strftime("%Y-%m-%dT%H:%M:%SZ")
    end
  end

  # 钩子：在每篇文章初始化后，注入 last_modified_at（当且仅当 commit_count > 1）
  Jekyll::Hooks.register :posts, :post_init do |post|
    # 取得仓库根与文章相对路径
    repo_root = post.site.source
    rel_path  = if post.respond_to?(:relative_path) && post.relative_path
                  post.relative_path
                else
                  # 兜底：绝对路径转相对仓库根（若两者同一卷/同一路径前缀）
                  path = post.path.to_s
                  path.start_with?(repo_root) ? path.sub(/^#{Regexp.escape(repo_root)}\/?/, '') : path
                end

    # 仅在有多次提交时才写入 last_modified_at
    if GitLastMod.commit_count(repo_root, rel_path) > 1
      if (epoch = GitLastMod.last_commit_epoch(repo_root, rel_path))
        post.data['last_modified_at'] = GitLastMod.iso8601_utc(epoch)
      end
    end
  end
end
