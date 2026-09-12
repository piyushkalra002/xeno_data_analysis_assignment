# Xeno Assignment

## Target Base Reconciliation

Finance reported a `target_base` of 22 for merchant 501 in October 2026.

I started with the raw communication log and worked through the campaign statuses and retry relationships to reconcile the number.

### Reconciliation Bridge

| Step | Description | Result | Reason |
|---|---|---:|---|
| 0 | Raw communication log count | 30 | Starting point |
| 1 | Exclude campaign 9004 | 26 | Campaign was still `approval_awaiting` and was not included in official reporting |
| 2 | 9001 → 9002 → 9003 | 23 | 3 sends were additional attempts for customers already in the retry chain |
| 3 | 9201 → 9202 | 22 | 1 send was an additional retry attempt |
| Final | `target_base` | **22** | Matches Finance's number |

### My Approach

I started by counting all the records in `communication_log`, which gave 30. I then checked the number of unique customers, which gave 25, so simply counting unique customers was not enough to match Finance's target_base of 22.

I looked at the customers who appeared more than once and checked which campaigns those records belonged to. This led me to the `parent_id` field in the campaign table, which showed that 9001 - 9002 - 9003 and 9201 - 9202 were retry chains. For these chains, repeated attempts for the same customer should only count once.

I also checked campaign 9101 separately because C20 appeared twice there. Since 9101 is a standalone campaign(that i rechecked from the readme.me provided to us) and not part of a retry chain, both sends to C20 were kept.

After that, I checked the campaign status fields and found that campaign 9004 was still `approval_awaiting`. The data dictionary says campaigns in this state are not included in official reporting, and 9004 had 4 communication records, so those records were excluded.

This gave the final reconciliation: 30 raw records → 26 after excluding 9004 → 23 after adjusting the first retry chain → 22 after adjusting the second retry chain.

I then checked the campaign statuses and found that campaign 9004 was still `approval_awaiting`. Its 4 communication records were therefore excluded from the reporting count.

### SQL

The final SQL query is available in [`Sql_Queries.sql`](Sql_Queries.sql).

Running it against the provided SQLite database gives:

`target_base = 22`

### One thing I noticed

One thing that stood out was that campaign 9004 already had communication log records even though it was still awaiting approval. I also found that repeated customers cannot always be treated as duplicates, since C20 was sent twice in the standalone campaign 9101.