-- 曜日を取得するマクロ
{% macro to_day_of_week(date_value) %}
  {% if target.type == 'duckdb' %}
    strftime(cast({{ date_value }} as date), '%A')
  {% else %}
    format_date('%A', cast({{ date_value }} as date))
  {% endif %}
{% endmacro %}

-- DATETIME型をDATE型に変換するマクロ
{% macro to_date(datetime_value) %}
  cast({{ datetime_value }} as date)
{% endmacro %}

-- 現在のタイムスタンプを取得するマクロ
{% macro current_timestamp() %}
  {% if target.type == 'duckdb' %}
    current_timestamp
  {% else %}
    current_timestamp()
  {% endif %}
{% endmacro %}

-- 日付の差分を計算するマクロ
{% macro date_diff(end_date, start_date, unit) %}
  {% if target.type == 'duckdb' %}
    date_diff('{{ unit }}', cast({{ start_date }} as date), cast({{ end_date }} as date))
  {% else %}
    date_diff(cast({{ end_date }} as date), cast({{ start_date }} as date), '{{ unit }}')
  {% endif %}
{% endmacro %}