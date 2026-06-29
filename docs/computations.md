# Page 24 — Computations

## P24_TICKET_COUNT

- **Computation Point**: Before Box Body
- **Computation Type**: Query
- **Item**: P24_TICKET_COUNT

```sql
SELECT COUNT(*)
  FROM app_ticket
 WHERE status_code NOT IN ('RESOLVED','CLOSED')
   AND (submitted_by = :APP_USER OR assigned_to = :APP_USER)
```

**Purpose**: Populates the "Open Tickets" button label (e.g., "3 Open Tickets") in the Button Bar region. Shows the count of unresolved tickets relevant to the current user.
