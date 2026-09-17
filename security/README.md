# security

## What it does

Implements a two-layer security model for the recruiting report on APEX page 24. Layer 1 (page access) uses three APEX Authorization Schemes driven by Fusion roles cached at login. Layer 2 (row-level security) uses an Oracle VPD policy that restricts which applicants a user can see based on their department assignments and optional admin-granted overrides. At login, `pkg_app_security.login_role_check` calls Fusion REST to cache the user's roles and assignments into APEX collections; if REST is unavailable it falls back to BIP/BICC tables. The VPD function in `rec_rls_pkg` builds a WHERE-clause predicate at query time that combines direct access (user is the recruiter or hiring manager on the req) with department grant overrides from the `rec_dept_grant` table. Admins bypass all filtering.

## Database objects

| Object | Type | Description |
|---|---|---|
| `PKG_APP_SECURITY` | Package (spec + body in one file) | Post-authentication procedure. `login_role_check` caches Fusion roles into `FUSION_USER_ROLES` collection and assignments into `FUSION_USER_ASSIGNMENTS` collection. Provides `is_admin`, `is_recruiting_mgr`, `is_hiring_manager` functions for Authorization Schemes. |
| `REC_RLS_PKG` | Package (spec + body) | VPD policy function `read_policy`. Returns NULL (no filter) for admins and non-APEX sessions. Otherwise returns a predicate with five OR paths: (A) user is recruiter, (B) user is hiring manager, (C) wide department grant, (D) recruiter-specific department grant, (E) HM-specific department grant. |
| `APP_USER_ROLES` | Table | Local role assignments. Columns: `username`, `role_code` (ADMIN, HR_USER, SUPPORT_DEV), `is_active`. Identity PK with unique constraint on `(username, role_code)`. |
| `REC_DEPT_GRANT` | Table | Department-based access overrides. Grants a user visibility into a department's requisitions, optionally scoped to a specific recruiter or hiring manager. Additive -- never removes natural access. |
| `REC_DEPT_GRANT_BI` | Trigger | BEFORE INSERT on `rec_dept_grant`. Normalizes `app_user` to uppercase, auto-populates `granted_by` and `granted_ts`. |
| `REC_DEPT_READ_POLICY` | VPD Policy | Applied to `RECRUITING_REPORT_V` for SELECT statements. Dynamic policy type. Calls `REC_RLS_PKG.READ_POLICY`. |

### APEX Authorization Schemes

| Scheme Name | Logic |
|---|---|
| `IS_ADMIN` | `app_user_roles` where `role_code = 'ADMIN'` and `is_active = 'Y'` |
| `IS_RECRUITING_MGR` | ADMIN **or** any of three Fusion recruiting roles (`ORA_IRC_RECRUITER_JOB`, `ORA_IRC_RECRUITING_MANAGER_JOB`, `ORA_PER_RECRUITING_ADMINISTRATOR_JOB`) |
| `IS_HIRING_MANAGER` | ADMIN **or** Fusion role `ORA_IRC_HIRING_MANAGER_ABSTRACT` |

### APEX Application Items (prerequisites)

| Item | Purpose |
|---|---|
| `G_ROLE_COUNT` | Number of Fusion roles cached at login |
| `G_ASSIGNMENT_COUNT` | Number of Fusion assignments cached at login |
| `G_DEPARTMENT_COUNT` | Number of departments (set by Application Computation on each page load) |

## How to deploy

1. **Create tables** (order matters):
   - Run `app_user_roles.sql` to create the role table.
   - Run `rec_dept_grant.sql` to create the department grant table and indexes.
   - Run `rec_dept_grant_trg.sql` to create the BEFORE INSERT trigger.

2. **Compile packages**:
   - Run `pkg_app_security.sql` (contains both spec and body).
   - Run `rec_rls_pkg.sql` (contains both spec and body).
   - Prerequisite: `pkg_bicc_common` must exist (provides `gc_fa_base_url`).

3. **Apply the VPD policy**:
   - Run `apply_rec_vpd_policy.sql` as the schema owner (`WKSP_FREEDEMO`).
   - Requires EXECUTE on `DBMS_RLS` (granted by ADMIN in ATP).
   - The script drops old policies before re-adding, so it is re-runnable.

4. **Wire APEX authentication**:
   - Shared Components > Authentication Schemes > Post-Authentication Procedure Name: `pkg_app_security.login_role_check`.

5. **Create Authorization Schemes**:
   - Type: PL/SQL Function (Returning Boolean).
   - `IS_ADMIN`: `return pkg_app_security.is_admin;`
   - `IS_RECRUITING_MGR`: `return pkg_app_security.is_recruiting_mgr;`
   - `IS_HIRING_MANAGER`: `return pkg_app_security.is_hiring_manager;`

6. **Create Application Items**: `G_ROLE_COUNT`, `G_ASSIGNMENT_COUNT`, `G_DEPARTMENT_COUNT` (Scope: Application, Session State: Per Session).

7. **Seed admin users**:
   ```sql
   INSERT INTO app_user_roles (username, role_code) VALUES ('JSMITH', 'ADMIN');
   ```

## How to modify

- **Grant a user extra department access**: Insert into `rec_dept_grant` with the user's APEX username (uppercase) and the exact Fusion department name. Set `recruiter_id` or `hiring_mgr_id` to scope the grant, or leave both NULL for wide access.
- **Add a new role**: Add the value to the `app_user_roles_ck1` CHECK constraint and add a new function in `pkg_app_security`.
- **Change VPD predicate logic**: Edit `rec_rls_pkg.read_policy`. The five OR paths (A-E) are documented in the header comments. Test with `SELECT rec_rls_pkg.read_policy('WKSP_FREEDEMO','RECRUITING_REPORT_V') FROM dual;` from an APEX session.
- **Debug role caching**: Check `FUSION_USER_ROLES` and `FUSION_USER_ASSIGNMENTS` collections in the user's APEX session. The fallback paths (`cache_roles_from_bip`, `cache_assignments_from_bicc`) are logged as no-ops on exception.
- **Move the APEX app**: No changes needed in these packages -- they use `v('APP_USER')` and APEX collections, not hardcoded app IDs. The APEX credential `gcs_reports` is shared.
- **Security model documentation**: See `security_model_slides.md` for the full presentation-format explanation of the architecture.
