-- target_base for merchant 501, October 2026
-- Expected outcome = 22
with recursive chain as (
    select id as campaign_id, id as root_id
    from campaign
    where merchant_id = 501
      and parent_id is null
    union alL
    select c.id, ch.root_id
    from campaign c
    join chain ch
      on c.parent_id = ch.campaign_id
),

eligible as (
    select
        cl.id,
        cl.customer_id,
        ch.root_id,
        ch.campaign_id
    from communication_log cl
    join campaign c
      on cl.communication_id = c.id
    join chain ch
      on cl.communication_id = ch.campaign_id
    where cl.merchant_id = 501
      and cl.communication_type = '2'
      and cl.sent_time >= '2026-10-01'
      and cl.sent_time < '2026-11-01'
      and c.creation_status in ('approved', 'aborted', 'resumed', 'stopped')
      and c.processing_status = 'processed'
),

retry_check as (
    select
        root_id,
        max(case when campaign_id != root_id then 1 else 0 end) as has_retry
    from chain
    group by root_id
),

final_count as (
    select
        e.root_id,
        case
            when r.has_retry = 1 then count(distinct e.customer_id)
            else count(e.id)
        end as target_base
    from eligible e
    join retry_check r
      on e.root_id = r.root_id
    group by e.root_id, r.has_retry
)
select sum(target_base) as target_base
from final_count;