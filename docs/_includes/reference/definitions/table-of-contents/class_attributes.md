{% if include.definition.class_attributes.size > 0 %}
<li>
  <a href="#class-attributes">Class Attributes</a>
  <ul style="margin-bottom: 0px;">
  {% for attribute in include.definition.class_attributes %}
    <li><a href="#class-attribute-{{ attribute.slug | anchorize_slug }}">{{ attribute.name }}</a></li>
  {% endfor %}
  </ul>
</li>
{% endif %}
