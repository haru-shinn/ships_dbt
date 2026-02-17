{{
  config(
    materialized='view'
  )
}}
with source as (
  select
    trim(schedule_id) as schedule_id
    , trim(ship_id) as ship_id
    , trim(route_id) as route_id
    , trim(departure_port_id) as departure_port_id
    , trim(arrival_port_id) as arrival_port_id
    , {{ to_date('departure_time') }} as departure_date
    , cast(departure_time as datetime) as departure_time
    , {{ to_day_of_week('departure_time') }} as departure_day_of_week
    , {{ to_date('arrival_time') }} as arrival_date
    , cast(arrival_time as datetime) as arrival_time
    , {{ to_day_of_week('arrival_time') }} as arrival_day_of_week

  from {{ source('route_operations_source', 'schedules') }}
)

select * from source
