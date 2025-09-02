select
  asset_id,
  symbol,
  type,
  status,
  ingested_at
from {{ source('raw_finance', 'assets') }}
