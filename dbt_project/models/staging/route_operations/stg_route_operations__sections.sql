{{
  config(
    materialized='view'
  )
}}
with source as (
  select
    trim(route_id) as route_id
    , dep_section_seq
    , arr_section_seq
    , trim(departure_port_id) as departure_port_id
    , trim(arrival_port_id) as arrival_port_id
    , travel_time_minutes
  from {{ source('route_operations_source', 'sections') }}
)
select * from source