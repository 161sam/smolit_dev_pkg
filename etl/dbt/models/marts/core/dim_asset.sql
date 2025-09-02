with snapshot as (
  select * from {{ ref('dim_asset_snapshot') }}
),
final as (
  select
    row_number() over(order by asset_id, dbt_valid_from) as asset_sk,
    asset_id,
    symbol,
    type,
    status,
    case when dbt_valid_to is null then 1 else 0 end as is_current
  from snapshot
)
select * from final
