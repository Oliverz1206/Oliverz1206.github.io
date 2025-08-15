/**
 * @file assets/js/components/lists.js
 * @version 2025-08-15
 * @description 多级目录/索引页的折叠与展开交互；兼容无 Bootstrap 环境，若存在 Bootstrap 5 的 Collapse 组件则启用动画与事件联动。
 * @requires Bootstrap.Collapse (optional)
 * @listens DOMContentLoaded
 * @example <caption>基本用法</caption>
 * <div data-lists>
 *   <div class="l1-row" data-collapse="#level1">一级</div>
 *   <div id="level1" class="collapse">内容</div>
 * </div>
 * <!-- 行内链接不触发展开：<a href="/xxx" data-no-collapse>跳转</a> -->
 * @remarks
 * 仅作用于带 data-lists 的容器内部。
 * 键盘可达性：Enter/Space 触发折叠/展开。
 */
(function () {
  'use strict';

  document.addEventListener('DOMContentLoaded', function () {
    // 页面根：仅在存在 data-lists 的页面启用本交互
    const root = document.querySelector('[data-lists]');
    if (!root) return;

    // 是否可使用 Bootstrap 的 Collapse 动画（可选依赖）
    const hasBootstrap =
      !!(window.bootstrap && bootstrap.Collapse && typeof bootstrap.Collapse.getOrCreateInstance === 'function');

    // 仅阻止“文字链接”的冒泡，保留默认跳转
    // 点击委托：允许 a[data-no-collapse] 正常跳转，其它点击才触发展开/收起
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
    // 键盘可达性：Enter/Space 触发展开/收起
    root.addEventListener('keydown', (e) => {
      if (e.key !== 'Enter' && e.key !== ' ') return;
      if (e.target.closest('a, button, input, textarea, select')) return;
      const row = e.target.closest('.l1-row, .l2-row');
      if (!row) return;
      e.preventDefault();
      row.click();
    });

    // —— 折叠状态 → 触发行视觉同步（含文件夹开/合图标）——
    // 工具：同步行的视觉状态（如 .collapsed 类 与 文件夹图标 open/close）
    /**
     * 同步行的视觉状态（折叠箭头/文件夹图标等）。
     * @param {HTMLElement} row - 触发行（.l1-row 或 .l2-row）。
     * @param {boolean} expanded - 是否处于展开状态。
     */
    function setRowVisual(row, expanded){
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

    // 工具：根据 .collapse 元素找回对应的行触发器（支持 L1 与 L2）
    /**
     * 根据 .collapse 元素查找其对应的触发行（L1/L2）。
     * @param {HTMLElement} collapseEl - 折叠容器元素（.collapse，且带 id）。
     * @returns {HTMLElement[]} 关联的行元素数组（.l1-row/.l2-row）。
     */
    function rowsFor(collapseEl){
      if (!collapseEl.id) return [];
      const idSel = '#' + (window.CSS && CSS.escape ? CSS.escape(collapseEl.id) : collapseEl.id);
      return Array.from(root.querySelectorAll(
        '.l1-row[data-collapse="' + idSel + '"], .l2-row[data-collapse="' + idSel + '"]'
      ));
    }

    if (hasBootstrap) {
      // 监听 Bootstrap 展开事件：同步行视觉（含图标）为“展开”
    root.addEventListener('show.bs.collapse', (e) => {
        rowsFor(e.target).forEach((row) => setRowVisual(row, true));
      });
      root.addEventListener('hide.bs.collapse', (e) => {
        rowsFor(e.target).forEach((row) => setRowVisual(row, false));
      });
    }

    // 初始同步（含文件夹开/合图标）
    if (hasBootstrap) {
      // 初始同步：根据 .show 决定每个折叠块的展开状态，并获取/缓存对应 Collapse 实例
      root.querySelectorAll('.collapse[id]').forEach((col) => {
        const expanded = col.classList.contains('show');
        rowsFor(col).forEach((row) => setRowVisual(row, expanded));
        bootstrap.Collapse.getOrCreateInstance(col, { toggle: false });
      });
    }
  });
})();
