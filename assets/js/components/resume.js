/*!
 * resume.js — 简历页交互（英文默认 → 点击切换中文）
 * 依赖：无
 * 可配置（由布局上的 data- 属性提供）：
 *   data-default-lang="en|cn"         // 默认语言（默认 en）
 *   data-remember-lang="true|false"   // 是否记住上次选择（默认 false）
 */

(function () {
  'use strict';

  document.addEventListener('DOMContentLoaded', function () {
    const root = document.querySelector('[data-resume]');
    if (!root) return;

    const en = root.querySelector('#lang-en');
    const cn = root.querySelector('#lang-cn');
    const toggleBtn  = root.querySelector('#toggle-lang');
    const toggleText = root.querySelector('#toggle-lang-text');
    const downloadBtn  = root.querySelector('#download-btn');
    const downloadText = root.querySelector('#download-text');

    // 读取布局提供的配置
    const defaultLang = (root.dataset.defaultLang || 'en').toLowerCase() === 'cn' ? 'cn' : 'en';
    const remember = (root.dataset.rememberLang || 'false').toLowerCase() === 'true';

    // 缺少另一种语言时隐藏切换按钮
    if (!en || !cn) {
      if (toggleBtn) toggleBtn.style.display = 'none';
    }

    function getHref(lang) {
      if (!downloadBtn) return null;
      const k = lang === 'cn' ? 'hrefCn' : 'hrefEn';
      return downloadBtn.dataset[k] || downloadBtn.getAttribute('href');
    }

    function applyLang(lang) {
      const isCN = (lang === 'cn');

      if (en) en.classList.toggle('is-hidden', isCN);
      if (cn) cn.classList.toggle('is-hidden', !isCN);

      if (toggleText) {
        toggleText.textContent = isCN ? 'Switch to English' : '切换为中文';
      }
      if (downloadBtn) {
        const href = getHref(isCN ? 'cn' : 'en');
        if (href) downloadBtn.setAttribute('href', href);
      }
      if (downloadText) {
        downloadText.textContent = isCN ? '下载 PDF' : 'Download PDF';
      }

      // 是否记住用户选择
      try {
        if (remember) localStorage.setItem('resumeLang', isCN ? 'cn' : 'en');
        else localStorage.removeItem('resumeLang');
      } catch (e) {}
    }

    // 计算初始语言：优先“页面默认”，仅当 remember=true 时才读取本地偏好
    let initial = defaultLang; // 这里默认就是 en
    if (remember) {
      try {
        const saved = localStorage.getItem('resumeLang');
        if (saved === 'en' || saved === 'cn') initial = saved;
      } catch (e) {}
    }

    // 兜底：如果默认选择对应语言内容不存在，自动切换到另一种
    if (initial === 'en' && !en && cn) initial = 'cn';
    if (initial === 'cn' && !cn && en) initial = 'en';

    applyLang(initial);

    if (toggleBtn) {
      toggleBtn.addEventListener('click', function (e) {
        e.preventDefault();
        const enVisible = en && !en.classList.contains('is-hidden');
        applyLang(enVisible ? 'cn' : 'en');
      });
    }
  });
})();
