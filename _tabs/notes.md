---
layout: default
title: Notes
icon: fas fa-book
permalink: /notes/
order: 4
---

# Notes

You can find any notes here.

These are notes I compiled during my undergraduate and graduate studies, along with additional material from my independent learning. I’ve aimed to keep them detailed and clear, though some inaccuracies may remain and are being continuously revised. They primarily serve as a personal archive and reference, but I’d be glad to discuss any part that interests you.

{% include lang.html %}

{% assign HEAD_PREFIX = 'h_' %}
{% assign LIST_PREFIX = 'l_' %}
{% assign group_index = 0 %}
{% assign notes_posts = site.posts | where_exp: "post", "post.tags contains 'notes'" %}

{% assign second_levels = "" | split: "" %}
{% for post in notes_posts %}
  {% assign level2 = post.categories[0] %}
  {% if level2 and level2 != '' %}
    {% unless second_levels contains level2 %}
      {% assign second_levels = second_levels | push: level2 %}
    {% endunless %}
  {% endif %}
{% endfor %}
{% assign second_levels = second_levels | sort %}

{% for level2 in second_levels %}
  {% assign sub_posts = notes_posts | where_exp: "p", "p.categories[0] == level2" %}
  {% assign third_levels = "" | split: "" %}

  {% for post in sub_posts %}
    {% assign level3 = post.categories[1] %}
    {% if level3 and level3 != '' %}
      {% unless third_levels contains level3 %}
        {% assign third_levels = third_levels | push: level3 %}
      {% endunless %}
    {% endif %}
  {% endfor %}
  {% assign third_levels = third_levels | sort %}

  <div class="card categories">
    <div
      id="{{ HEAD_PREFIX }}{{ group_index }}"
      class="card-header d-flex justify-content-between align-items-center hide-border-bottom"
    >
      <span class="ms-2 d-flex align-items-center">
        <i class="far fa-folder{% if third_levels.size > 0 %}-open{% endif %} fa-fw"></i>
        {% capture _notes_url %}/notes/{{ level2 | slugify | url_encode }}/{% endcapture %}
        <a href="{{ _notes_url | relative_url }}" class="ms-2 text-decoration-none">{{ level2 }}</a>
        <span class="text-muted small font-weight-light ms-2">
          {% if third_levels.size > 0 %}
            {{ third_levels.size }} categories,
          {% endif %}
          {{ sub_posts.size }} posts
        </span>
      </span>

      <span
        class="clickable-header"
        role="button"
        data-bs-toggle="collapse"
        data-bs-target="#{{ LIST_PREFIX }}{{ group_index }}"
        aria-expanded="true"
        aria-controls="{{ LIST_PREFIX }}{{ group_index }}"
      >
        <i class="fas fa-angle-down fa-fw rotate-icon"></i>
      </span>
    </div>

    <div id="{{ LIST_PREFIX }}{{ group_index }}" class="collapse show" aria-labelledby="{{ HEAD_PREFIX }}{{ group_index }}">
      <ul class="list-group">
        {% assign has_second_only = sub_posts | where_exp: "p", "p.categories.size == 1" %}
        {% for post in has_second_only %}
          <li class="list-group-item">
            <i class="far fa-file fa-fw"></i>
            <a href="{{ post.url | relative_url }}" class="mx-2">{{ post.title }}</a>
          </li>
        {% endfor %}

        {% for level3 in third_levels %}
          {% assign third_level_posts = sub_posts | where_exp: "p", "p.categories[1] == level3" %}
          <li class="list-group-item">
            <div class="d-flex justify-content-between align-items-center toggle-subfolder" data-bs-toggle="collapse" data-bs-target="#subcat-{{ group_index }}-{{ forloop.index }}" aria-expanded="false">
              <span>
                <i class="fas fa-chevron-right fa-fw me-2 toggle-icon"></i>
                <i class="far fa-folder fa-fw"></i>
                <span class="mx-2">{{ level3 }}</span>
                <span class="text-muted small font-weight-light">
                  {{ third_level_posts.size }} post{% if third_level_posts.size > 1 %}s{% endif %}
                </span>
              </span>
            </div>

            <ul class="list-group ms-4 mt-2 collapse" id="subcat-{{ group_index }}-{{ forloop.index }}">
              {% for post in third_level_posts %}
                <li class="list-group-item">
                  <i class="far fa-file fa-fw"></i>
                  <a href="{{ post.url | relative_url }}" class="mx-2">{{ post.title }}</a>
                </li>
              {% endfor %}
            </ul>
          </li>
        {% endfor %}
      </ul>
    </div>
  </div>

  {% assign group_index = group_index | plus: 1 %}
{% endfor %}


<style>
.rotate-icon {
  transition: transform 0.3s ease;
  transform: rotate(0deg);
}

.toggle-icon {
  transition: transform 0.3s ease;
  transform: rotate(0deg);
  font-size: 0.65rem !important;
}
</style>


<script>
document.addEventListener("DOMContentLoaded", function () {
  document.querySelectorAll('.clickable-header').forEach(function(header) {
    header.addEventListener('click', function () {
      const icon = header.querySelector('.rotate-icon');
      const isCollapsed = header.getAttribute('aria-expanded') === 'true';
      if (icon) {
        icon.style.transition = 'transform 0.3s ease';
        icon.style.transform = isCollapsed ? 'rotate(0deg)' : 'rotate(90deg)';
      }
    });
  });


  document.querySelectorAll('.toggle-subfolder').forEach(function(toggle) {
    toggle.addEventListener('click', function () {
      const icon = toggle.querySelector('.toggle-icon');
      if (icon) {
        const isExpanded = toggle.getAttribute('aria-expanded') === 'true';
        icon.style.transition = 'transform 0.3s ease';
        icon.style.transform = isExpanded ? 'rotate(90deg)' : 'rotate(0deg)';
      }
    });
  });
});
</script>
