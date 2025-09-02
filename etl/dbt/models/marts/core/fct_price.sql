with prices as (
  select * from {{ ref('stg_prices') }}
),
assets as (
  select * from {{ ref('dim_asset') }} where is_current = 1
)
select
  a.asset_sk,
  p.ts,
  p.close
from prices p
join assets a on p.asset_id = a.asset_id
