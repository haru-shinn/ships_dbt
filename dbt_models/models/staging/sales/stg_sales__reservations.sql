{{
  config(
    materialized='view'
  )
}}
with source as (
  select
    trim(reservation_id) as reservation_id
    , reservation_name
    , reservation_email
    , reservation_date
    , {{ to_day_of_week('reservation_date') }} as reservation_day_of_week
  from {{ source('sales_source', 'reservations') }}
)

select * from source
