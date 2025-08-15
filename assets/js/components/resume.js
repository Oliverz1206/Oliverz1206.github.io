/**
 * @file assets/js/components/resume.js
 * @version 2025-08-15
 * @description 简历页面的中英切换与下载按钮联动：根据 data-* 配置选择默认语言，可选记住用户偏好。
 * @listens DOMContentLoaded
 * @example <caption>基本用法</caption>
 * <article data-resume data-default-lang="en" data-remember-lang="false">
 *   <div id="lang-en">...</div>
 *   <div id="lang-cn" class="is-hidden">...</div>
 *   <button id="toggle-lang"><span id="toggle-lang-text">切换为中文</span></button>
 *   <a id="download-btn" data-href-en="/resume_en.pdf" data-href-cn="/resume_cn.pdf">
 *     <span id="download-text">Download PDF</span>
 *   </a>
 * </article>
 * @remarks
 * 当 remember=true 时使用 localStorage('resumeLang') 存储偏好。
 * 若默认语言对应内容不存在，自动回退到另一种语言。
 */

(function () {
  'use strict';

  document.addEventListener('DOMContentLoaded', function () {
    // 页面根：仅在数据属性 data-resume 存在时启用
    const root = document.querySelector('[data-resume]');
    if (!root) return;

    // 两种语言的内容区块（由布局渲染）
    const en = root.querySelector('#lang-en');
    const cn = root.querySelector('#lang-cn');
    const toggleBtn  = root.querySelector('#toggle-lang');
    const toggleText = root.querySelector('#toggle-lang-text');
    const downloadBtn  = root.querySelector('#download-btn');
    const downloadText = root.querySelector('#download-text');

    // 读取布局提供的配置
    // 默认语言：来自 data-default-lang（非法/缺省时回退为 en）
    const defaultLang = (root.dataset.defaultLang || 'en').toLowerCase() === 'cn' ? 'cn' : 'en';
    // 是否记住用户选择：来自 data-remember-lang
    const remember = (root.dataset.rememberLang || 'false').toLowerCase() === 'true';

    // 缺少另一种语言时隐藏切换按钮
    if (!en || !cn) {
      if (toggleBtn) toggleBtn.style.display = 'none';
    }

    // 根据当前语言从 data-href-en / data-href-cn 中取下载链接，缺省回退到 href
    /**
     * 获取当前语言对应的下载链接。
     * @param {'en'|'cn'} lang - 语言标记。
     * @returns {string} 对应的 href。
     */
    function getHref(lang){
      if (!downloadBtn) return null;
      const k = lang === 'cn' ? 'hrefCn' : 'hrefEn';
      return downloadBtn.dataset[k] || downloadBtn.getAttribute('href');
    }

    // 应用语言切换：显示/隐藏内容区块，更新按钮文案与下载链接，记录本地偏好
    /**
     * 应用语言切换：切换可见区块、更新按钮文案与下载链接，并按需记录偏好。
     * @param {'en'|'cn'} lang - 目标语言。
     * @returns {void}
     */
    function applyLang(lang){
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
    // 初始语言：先取默认，再按需要读取本地偏好
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
      // 点击切换：根据当前可见状态在 en/cn 之间切换
      toggleBtn.addEventListener('click', function (e) {
        e.preventDefault();
        const enVisible = en && !en.classList.contains('is-hidden');
        applyLang(enVisible ? 'cn' : 'en');
      });
    }
  });
})();
