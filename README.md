# OEMX Operations Platform

Labour hire operations platform for OEMX Diesel: roster, staff register, mobilisation, and (in later stages) vacancies, quotes, job status, JMPs, leave, employee app, timesheets and Xero.

- `site/` – the web app (single page, hosted on Netlify). Talks to Supabase project `oemx-ops` (Sydney).
- `db/` – database scripts, run in order in the Supabase SQL Editor.
- `docs/platform-spec.md` – agreed build spec.

The page only contains the Supabase **publishable** key; all data access is controlled by row-level security and logins.
