# Xeno Assignment

## Target Base Reconciliation

Finance reported a `target_base` of 22 for merchant 501 in October 2026.

I started with the communication log and worked through the customer repeats, campaign relationships and campaign status to understand the difference.

### Reconciliation Bridge

|| Step | Description | Result | Reason |
|---|---|---:|---|
| 0 | Raw communication log count | 30 | Starting point |
| 1 | Count distinct customers | 25 | This did not match Finance's 22, so I looked further into the repeated customers |
| 2 | Check repeated customers | C2, C3, C20 and D1 | These customers had more than one send, so I checked why they were repeated |
| 3 | Check campaign relationships | 9001 → 9002 → 9003 and 9201 → 9202 | The `parent_id` values showed that these were retry chains |
| 4 | Check 9001 → 9002 → 9003 | 13 sends / 10 customers | 3 sends were additional attempts for customers already in the chain |
| 5 | Check 9201 → 9202 | 6 sends / 5 customers | 1 send was an additional retry attempt |
| 6 | Check standalone campaign 9101 | 7 sends / 6 customers | C20 was sent twice, but both sends were kept because 9101 is standalone |
| 7 | Check campaign statuses | 9004 = `approval_awaiting` | The data dictionary says campaigns still awaiting approval are not included in reporting |
| 8 | Exclude campaign 9004 | 26 | 9004 had 4 communication records that were not reportable |
| 9 | Adjust 9001 → 9002 → 9003 | 23 | Subtracting the 3 additional retry attempts |
| 10 | Adjust 9201 → 9202 | 22 | Subtracting the 1 additional retry attempt |
| **Final** | **Target base** | **22** | **Matches Finance's reported number** |

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