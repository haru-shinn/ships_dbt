-- 曜日を取得するマクロ
{% macro to_day_of_week(date_value) %}
  format_date('%A', cast({{ date_value }} as date))
{% endmacro %}

-- DATETIME型をDATE型に変換するマクロ
{% macro to_date(datetime_value) %}
  cast({{ datetime_value }} as date)
{% endmacro %}