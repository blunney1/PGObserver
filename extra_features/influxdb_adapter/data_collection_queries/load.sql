select
  load_timestamp as "timestamp",
  extract(epoch from load_timestamp::timestamp with time zone at time zone 'utc')::int as "time",
  "min1",
  "min5",
  "min15",
  ((xlog_location_mb_delta / extract (epoch from load_timestamp_delta)) * 3600 * 10^6)::int8 as xlog_b_1h_rate
from (
  select
    *,
    xlog_location_mb - lag(xlog_location_mb) over(order by load_timestamp) as xlog_location_mb_delta,
    load_timestamp - lag(load_timestamp) over(order by load_timestamp) as load_timestamp_delta
  from
    (
  select
    load_timestamp,
    round(load_1min_value::numeric/100.0, 1)::float as "min1",
    round(load_5min_value::numeric/100.0, 1)::float as "min5",
    round(load_15min_value::numeric/100.0, 1)::float as "min15",
    xlog_location_mb
  from
    monitor_data.host_load
  where
    load_timestamp > %(from_timestamp)s - %(lag_interval)s::interval
    and load_timestamp <= %(to_timestamp)s
    and load_host_id = %(host_id)s
  ) a
) b
where
  xlog_location_mb_delta >= 0
  and load_timestamp_delta > '1s'::interval -- filter against "funny" data
  and load_timestamp > %(from_timestamp)s
order by
  load_timestamp;
