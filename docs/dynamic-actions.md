# Page 24 — Dynamic Actions

All dynamic actions are button click handlers that call JavaScript functions defined in the extracted JS files.

| # | DA Name | Seq | Trigger | Action | JS Function |
|---|---------|-----|---------|--------|-------------|
| 1 | Cancel Button Click | 10 | CANCEL_BTN click | Execute JS | `cancelMoveForm()` |
| 2 | Move Button Click | 20 | MOVE_BTN click | Execute JS | `submitMove()` |
| 3 | Cancel Ranking Click | 30 | CANCEL_RANKING_BTN click | Execute JS | `cancelRankingForm()` |
| 4 | Save Ranking Click | 40 | SAVE_RANKING_BTN click | Execute JS | `submitRanking()` |
| 5 | Copy Ref Link Click | 50 | COPY_REF_LINK_BTN click | Execute JS | `copyRefLink()` |
| 6 | Send Ref Email Click | 60 | SEND_REF_EMAIL_BTN click | Execute JS | `sendRefLinkEmail()` |
| 7 | Cancel Ref Link Click | 70 | CANCEL_REFLINK_BTN click | Execute JS | `cancelRefLinkForm()` |

All DAs:
- Bind type: `bind`
- Execution type: `IMMEDIATE`
- Execute on page init: `N`
- Event result: `TRUE`
