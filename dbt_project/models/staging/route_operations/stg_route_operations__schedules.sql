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
    , cast(departure_time as datetime) as departure_time
    , cast(arrival_time as datetime) as arrival_time

  from {{ source('route_operations_source', 'schedules') }}
)
select * from source