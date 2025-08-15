// assets/js/active-tab.js
(function () {
  // 规范化路径：去掉 index.html，保证以 / 结尾，便于对比
  function norm(pathname) {
    if (!pathname) return "/";
    var p = pathname.replace(/\/index\.html$/i, "");
    if (p.length > 1 && !p.endsWith("/")) p += "/";
    return p;
  }

  var curr = norm(location.pathname);

  // 找到侧栏 / 顶部导航里的所有链接（类名尽量放宽，兼容不同版本的 Chirpy）
  var links = document.querySelectorAll(".sidebar a, .site-nav a, nav a");
  links.forEach(function (a) {
    var href = a.getAttribute("href");
    if (!href || /^https?:\/\//i.test(href)) return; // 跳过外链

    // 用 URL 统一解析相对/绝对路径，然后取 pathname，再规范化
    var u;
    try { u = new URL(a.href, location.origin); } catch (e) { return; }
    var target = norm(u.pathname);

    if (target === curr) {
      a.classList.add("active");
      a.setAttribute("aria-current", "page");
      var li = a.closest("li");
      if (li) li.classList.add("active");
    }
  });
})();
