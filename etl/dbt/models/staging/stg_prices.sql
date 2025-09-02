select
  asset_id,
  ts,
  close,
  ingested_at
from {{ source('raw_finance', 'prices') }}
