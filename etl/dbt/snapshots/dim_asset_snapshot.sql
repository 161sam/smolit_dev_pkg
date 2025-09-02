{% snapshot dim_asset_snapshot %}

{{
  config(
    target_database = target.database,
    target_schema = var('db_schema_snapshots','snapshots'),
    unique_key = 'asset_id',
    strategy = 'check',
    check_cols = ['symbol','type','status'],
    invalidate_hard_deletes = true
  )
}}

select
  asset_id,
  symbol,
  type,
  status,
  current_timestamp as snapshot_ts
from {{ ref('stg_assets') }}

{% endsnapshot %}
