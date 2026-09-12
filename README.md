# Xeno Assignment

## Target Base Reconciliation

Finance reported a `target_base` of 22 for merchant 501 in October 2026.

I started with the communication log and worked through the customer repeats, campaign relationships and campaign status to understand the difference.

### Reconciliation Bridge

| Step | What I checked | Result | Reason |
|---:|---|---:|---|
| 0 | Raw communication log count | 30 | Starting point |
| 1 | Distinct customers | 25 | This did not match Finance's 22, so I looked further into the repeated customers |
| 2 | Exclude campaign 9004 | 26 | 9004 was still `approval_awaiting`, so its 4 records were not included in reporting |
| 3 | Adjust 9001 → 9002 → 9003 | 23 | 3 records were additional attempts for customers already in the retry chain |
| 4 | Adjust 9201 → 9202 | 22 | 1 record was an additional retry attempt |
| Final | `target_base` | **22** | Matches Finance's number |

### Approach

I first checked the basic time period of the data and the values present in the delivery status field. I then counted the communication log records and got 30.

As a simple check, I counted distinct customers and got 25. Since this still did not match Finance's number, I looked at which customers were repeated and where those sends came from.

Some repeated customers appeared across different campaign IDs. Checking `parent_id` showed that 9001 → 9002 → 9003 and 9201 → 9202 were retry chains. I checked the sends in these chains and found that some customers were being sent to again after an earlier attempt.

I also checked campaign 9101 separately because C20 appeared twice there. Since 9101 is a standalone campaign, both sends to C20 were kept as separate events.

I then checked the campaign statuses and found that 9004 was still `approval_awaiting`. It had 4 communication records, but campaigns in this state are not included in official reporting, so these were excluded.

This gave the final reconciliation of 30 → 26 → 23 → 22.

### SQL

The final SQL query is available in [`Sql_Queries.sql`](Sql_Queries.sql).

Running it against the provided database returns:

`target_base = 22`

### One thing I noticed

The main thing that stood out to me was that repeated send records do not always mean duplicate data. In the retry chains, the same customer can appear multiple times because the message was retried, while in the standalone campaign 9101, C20 was sent twice on different dates and both sends are valid. This means that simply counting distinct customers would undercount the target_base, while counting every send would overcount it.