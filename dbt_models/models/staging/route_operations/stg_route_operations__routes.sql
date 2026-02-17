{{
  config(
    materialized='view'
  )
}}
with source as (
  select
    trim(route_id) as route_id
    , route_name
    , is_active
  from {{ source('route_operations_source', 'routes') }}
)

select * from source
