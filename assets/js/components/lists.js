/*!
 * 行级折叠/展开（Bootstrap 动画） + 文字链接跳转
 * 额外：展开时将 .l1-folder-icon/.l2-folder-icon 从 fa-folder 切到 fa-folder-open；收起时反之
 */
(function () {
  'use strict';

  document.addEventListener('DOMContentLoaded', function () {
    const root = document.querySelector('[data-lists]');
    if (!root) return;

    const hasBootstrap =
      !!(window.bootstrap && bootstrap.Collapse && typeof bootstrap.Collapse.getOrCreateInstance === 'function');

    // 仅阻止“文字链接”的冒泡，保留默认跳转
    root.addEventListener('click', (e) => {
      const a = e.target.closest('a[data-no-collapse]');
      if (a && root.contains(a)) {
        e.stopPropagation();
      }
    }, true); // capture

    // 行级点击（用 data-collapse 目标；由 Bootstrap 执行动画）
    document.addEventListener('click', (e) => {
      if (!root.contains(e.target)) return;
      if (e.target.closest('a[data-no-collapse]')) return;

      const row = e.target.closest('.l1-row, .l2-row');
      if (!row || !root.contains(row)) return;

      const sel = row.getAttribute('data-collapse');
      if (!sel) return;

      const target = root.querySelector(sel);
      if (!target || !hasBootstrap) return;

      const inst = bootstrap.Collapse.getOrCreateInstance(target, { toggle: false });
      inst.toggle();
    }, true); // capture

    // 键盘可达性
    root.addEventListener('keydown', (e) => {
      if (e.key !== 'Enter' && e.key !== ' ') return;
      if (e.target.closest('a, button, input, textarea, select')) return;
      const row = e.target.closest('.l1-row, .l2-row');
      if (!row) return;
      e.preventDefault();
      row.click();
    });

    // —— 折叠状态 → 触发行视觉同步（含文件夹开/合图标）——
    function setRowVisual(row, expanded) {
      row.classList.toggle('collapsed', !expanded);
      row.setAttribute('aria-expanded', expanded ? 'true' : 'false');

      const icon = row.querySelector('.l1-folder-icon, .l2-folder-icon');
      if (icon) {
        if (expanded) {
          icon.classList.remove('fa-folder');
          icon.classList.add('fa-folder-open');
        } else {
          icon.classList.remove('fa-folder-open');
          icon.classList.add('fa-folder');
        }
      }
    }

    function rowsFor(collapseEl) {
      if (!collapseEl.id) return [];
      const idSel = '#' + (window.CSS && CSS.escape ? CSS.escape(collapseEl.id) : collapseEl.id);
      return Array.from(root.querySelectorAll(
        '.l1-row[data-collapse="' + idSel + '"], .l2-row[data-collapse="' + idSel + '"]'
      ));
    }

    if (hasBootstrap) {
      root.addEventListener('show.bs.collapse', (e) => {
        rowsFor(e.target).forEach((row) => setRowVisual(row, true));
      });
      root.addEventListener('hide.bs.collapse', (e) => {
        rowsFor(e.target).forEach((row) => setRowVisual(row, false));
      });
    }

    // 初始同步（含文件夹开/合图标）
    if (hasBootstrap) {
      root.querySelectorAll('.collapse[id]').forEach((col) => {
        const expanded = col.classList.contains('show');
        rowsFor(col).forEach((row) => setRowVisual(row, expanded));
        bootstrap.Collapse.getOrCreateInstance(col, { toggle: false });
      });
    }
  });
})();
