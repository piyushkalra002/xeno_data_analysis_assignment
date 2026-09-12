-- target_base for merchant 501, October 2026

with recursive campaign_chain as (

    select
        id as campaign_id,
        id as root_id
    from campaign
    where merchant_id = 501
      and parent_id is null

    union all

    select
        c.id,
        cc.root_id
    from campaign c
    join campaign_chain cc
        on c.parent_id = cc.campaign_id
    where c.merchant_id = 501
),

eligible_sends as (

    select
        cl.id as send_id,
        cl.customer_id,
        cc.root_id,
        cc.campaign_id
    from communication_log cl
    join campaign c
        on cl.communication_id = c.id
    join campaign_chain cc
        on c.id = cc.campaign_id
    where cl.merchant_id = 501
      and cl.communication_type = '2'
      and cl.sent_time >= '2026-10-01'
      and cl.sent_time < '2026-11-01'
      and c.creation_status in ('approved', 'aborted', 'resumed', 'stopped')
      and c.processing_status = 'processed'
),

family_type as (

    select
        root_id,
        max(case when campaign_id <> root_id then 1 else 0 end) as has_retry
    from campaign_chain
    group by root_id
),

family_counts as (

    select
        es.root_id,
        case
            when ft.has_retry = 1
                then count(distinct es.customer_id)
            else count(es.send_id)
        end as target_base
    from eligible_sends es
    join family_type ft
        on es.root_id = ft.root_id
    group by es.root_id, ft.has_retry
)

select sum(target_base) as target_base
from family_counts;