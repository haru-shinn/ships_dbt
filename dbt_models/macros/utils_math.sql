{% macro safe_divide(numerator, denominator) %}
  {% if target.type == 'bigquery' %}
    safe_divide({{ numerator }}, {{ denominator }})
  {% else %}
    -- DuckDBやその他のDB用
    ({{ numerator }}) / NULLIF({{ denominator }}, 0)
  {% endif %}
{% endmacro %}