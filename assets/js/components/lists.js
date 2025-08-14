/*!
 * 行级折叠/展开（Bootstrap 动画） + 文字链接正常跳转
 * - 行元素(.l1-row/.l2-row)使用 data-collapse="#ID"
 * - JS 调用 bootstrap.Collapse API 执行动画与切换
 * - a[data-no-collapse] 仅 stopPropagation，保留默认跳转
 */
(function () {
  'use strict';

  document.addEventListener('DOMContentLoaded', function () {
    const root = document.querySelector('[data-lists]');
    if (!root) return;

    const hasBootstrap =
      !!(window.bootstrap && bootstrap.Collapse && typeof bootstrap.Collapse.getOrCreateInstance === 'function');

    // 1) 链接点击：捕获阶段阻止冒泡，保证文字跳转但不触发行折叠
    root.addEventListener('click', (e) => {
      const a = e.target.closest('a[data-no-collapse]');
      if (a && root.contains(a)) {
        e.stopPropagation();               // 不触发行折叠
        // 可选：若上层脚本曾经阻止默认，可强制导航（建议先不用）
        // window.location.assign(a.href);
        // e.preventDefault();
      }
    }, true);

    // 2) 行级点击：捕获阶段执行，避免被其他脚本截断；用 Bootstrap API 切换
    document.addEventListener('click', (e) => {
      if (!root.contains(e.target)) return;
      if (e.target.closest('a[data-no-collapse]')) return; // 文字链接不处理

      const row = e.target.closest('.l1-row, .l2-row');
      if (!row || !root.contains(row)) return;

      const sel = row.getAttribute('data-collapse');
      if (!sel) return;

      const target = root.querySelector(sel);
      if (!target) return;

      if (!hasBootstrap) return; // 必须加载 bootstrap.bundle.js 才有动画与事件

      const inst = bootstrap.Collapse.getOrCreateInstance(target, { toggle: false });
      inst.toggle();
    }, true);

    // 3) 键盘可达性：在行上按 Enter/Space 触发行点击
    root.addEventListener('keydown', (e) => {
      if (e.key !== 'Enter' && e.key !== ' ') return;
      if (e.target.closest('a, button, input, textarea, select')) return;
      const row = e.target.closest('.l1-row, .l2-row');
      if (!row) return;
      e.preventDefault();
      row.click();
    });

    // 4) 将 Bootstrap 折叠事件映射到触发行元素以维护 .collapsed 与 aria-expanded
    function rowsFor(collapseEl) {
      if (!collapseEl.id) return [];
      const idSel = '#' + (window.CSS && CSS.escape ? CSS.escape(collapseEl.id) : collapseEl.id);
      return Array.from(root.querySelectorAll(
        '.l1-row[data-collapse="' + idSel + '"], .l2-row[data-collapse="' + idSel + '"]'
      ));
    }

    if (hasBootstrap) {
      root.addEventListener('show.bs.collapse', (e) => {
        rowsFor(e.target).forEach((row) => {
          row.classList.remove('collapsed');
          row.setAttribute('aria-expanded', 'true');
        });
      });
      root.addEventListener('hide.bs.collapse', (e) => {
        rowsFor(e.target).forEach((row) => {
          row.classList.add('collapsed');
          row.setAttribute('aria-expanded', 'false');
        });
      });
    }

    // 5) 初始同步与实例化（不自动切换）
    if (hasBootstrap) {
      root.querySelectorAll('.collapse[id]').forEach((col) => {
        const expanded = col.classList.contains('show');
        rowsFor(col).forEach((row) => {
          row.classList.toggle('collapsed', !expanded);
          row.setAttribute('aria-expanded', expanded ? 'true' : 'false');
        });
        bootstrap.Collapse.getOrCreateInstance(col, { toggle: false });
      });
    }
  });
})();
