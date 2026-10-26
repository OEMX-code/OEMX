# OEMX Labour Hire Operations Platform — build spec (draft for review)
Owner: Adam Herbert · Drafted 25 Oct 2026 · Status: design agreed through 5 rounds — awaiting Adam's confirmation

## 1. Platform decision
- Hosted web app with its own logins (not a claude.ai page). Works in a phone browser / home-screen app. No SharePoint access needed.
- Proposed stack: **Supabase** (Postgres database, logins, row-level security, file storage for PO/prestart/signature/form attachments, scheduled jobs) + **Netlify** hosting + **GitHub** repo for the code. All accounts owned by OEMX.
- Runs in **parallel** with current systems during testing: monday.com is **read-only**. Nothing is written to monday.com. Jotforms stay live during the test.
- Starting point: the existing Labour Hire Planner (roster to 30 Jun 2027, legend codes, staff, utes, Xero rate items) migrates across.

## 2. Users and access
| Role | Access |
|---|---|
| Coordinator | Full: roster, staff, vacancies, mobilisation, JMPs, quotes, job status, **invoice block approval**, form submissions, leave dashboard, Monday payroll reconfirmation |
| Manager (Adam) | Full + JMP escalations + leave approvals that breach the 4-week policy |
| Mobilisation Officer (Chamara Powers) | Team compliance and mobilising people to site: edits roster (travel, accommodation, induction, medical, START codes), staff register, utes, mobilisation tabs; "Processed by Mobilisation" on leave; owns the compliance register (proposed, see 3.2). No invoice approval, payroll or login management |
| Accounts | View-only + invoicing (only blocks the coordinator has approved); marks leave "Processed by Accounts"; reviews and posts the weekly draft pay run in Xero |
| Employee | Own roster (PO-confirmed work only), job cards, own timesheets, forms portal, own JMPs, phone directory |
| Site supervisor | Signs timesheets, service reports and leave (site approval) on the employee's phone (no separate login) |

## 3. Coordinator dashboard (one workspace)
- **Roster** (FY view, existing legend site and travel codes).
- **Staff register** (replaces the monday.com register function; sync from monday.com on open during the parallel test).
- **Open vacancies / opportunities board**: client labour-hire requests entered here; a vacancy can be dragged onto a person's roster where dates line up → creates the mobilisation and quote automatically. Leave requests can also be pushed here (see 3.1).
- **Mobilisation tabs** (built from roster data): client, site, in/out dates, travel codes, accommodation (AC / ACC / JAC = booked / not booked / Jared accommodation), allocated ute (from staff record unless roster names another asset), PO, induction/medical codes.
- **Job finalisation — site contacts**: when a job's client drops into the job card, the coordinator sees that client's full contact list (from the monday.com Client Site Contact List) and **must tick which contacts apply** before the job can be finalised. Only ticked contacts appear on the employee's job card.
- **JMP board** (drive travel only), columns as per monday.com LH JMP Board: JMP Status (Active / Arrived / Issue / Cancelled / Completed), Site, Client, In Accom, In Date, Out Date, Out Date Accom, Shift, PO #, plus sign-off name + date.
- **Quotes and job status pipeline**: Pending → Awaiting PO → Awaiting timesheets → **Awaiting coordinator check** → **Awaiting Adam's approval** → Ready to invoice → Invoiced (or Cancelled). A **PO value bar** on each job shows quoted / approved / invoiced / remaining against the PO.
- **Payroll week** screen (see 5.2).
- **Form submissions inbox**: Take 5, pre-start, service report, hazard report and incident statements, filterable by person / client / site / date. Take 5 "STOP – see your supervisor" outcomes, risk rating ≥ 5, hazards marked High, pre-start "Requires Attention" on Category A items and any incident statement raise an in-app alert to the coordinator.

### 3.1 Leave dashboard
- **All leave requests** land in one dashboard: employee, department, leave type, first/last day, total days, reason, client/site, site approval status, OEMX approval (Approved / Rejected / Pending), Processed by Mobilisation, Processed by Accounts, medical certificate attached.
- Requests that start **inside 4 weeks** are badged **"Breaches 4-week policy – additional approval required"** and routed to the manager.
- Every request has a **"Push to open vacancies"** button: creates an opportunity on the vacancies board for the person's client/site and leave dates (if coverage is required), linked back to the leave request.
- Approved leave writes the leave code (AL / SL·PL / LWP) onto the roster for those days.

### 3.2 Compliance register (proposed 25 Oct — awaiting Adam's confirmation)
- Owned by the Mobilisation Officer. Per person: licences, tickets, VOCs, medicals, D&A (DAS), site inductions (e.g. F2F), with issue/expiry dates and the document attached.
- Per client/site: the list of requirements to mobilise there, shown as a **site requirements matrix** (rows = client sites, columns = requirements such as licences, tickets, VOCs, medical, D&A, site/client inductions; each cell = Required / Not required / Required for certain trades).
- **Suitability indicator** when filling a vacancy or dragging someone onto the roster: each candidate is checked against that site's matrix and the trade/dates of the request.
  - Green: meets every requirement, valid through the swing end date.
  - Amber: meets the requirements, but something expires during the swing, or is booked or in progress (e.g. medical booked, induction scheduled).
  - Red: something is missing or expired. The indicator lists exactly what.
- Candidates for a request are sorted by suitability, then by availability on the roster for those dates (and trade match).
- Mobilisation check: when someone is rostered to a site, flag anything missing or expiring before their in-date; expiry warnings at 30 days.
- Source boards in monday.com (read only during the parallel test): Chamara uses **both** "Competency/ Licences Register" (workspace 1476495; subitems board 5029293262) and "Employee Site Induction Tracker" (1933995039).

### 3.3 Long-term direction — one master ecosystem (Adam, 25 Oct)
- Over time the platform becomes the single home for the whole employee lifecycle: **HR/onboarding → compliance → mobilisation → rostering → timesheets → payroll and invoicing**, replacing the separate monday.com boards.
- Design rule from now on: one person record (staff register) that every module hangs off, so onboarding, compliance documents, mobilisations, roster, timesheets and pay all link to the same person.
- Other monday.com boards likely to fold in later: LH Open Vacancies (1933267895), OEMX Vehicle Allocations – Confirmed (5028706657), LH Training & Trade Upkills (5028504333), Employee Skills Matrix – Trade (1921348226), LH Employee Performance Reviews (2051440917).

## 4. Quoting rules
- One quote per mobilisation, created automatically when a swing is rostered to a client site.
- Rates: client contracted rates from Xero items (client prefix, e.g. THIESS HDF A); clients without contracted rates use **Standard (STD)** items.
- Standard hours = the site's usual daily hours (from past timesheets), editable.
- Travel: km and drive hours from monday.com **SITE TRAVEL KMS & HOURS** (board 2007085984, site × base town). Drive hours billed as labour on travel days. Travel km only where quoted.
- Vehicle hire per day only if quoted **and** the person is assigned a vehicle.
- Unquoted travel: employee paid $35/hr, **not** on-charged to the client.
- Output: quote PDF matching the current Xero quote layout (sample quote to be supplied) + lines copied for Xero. "Mark as sent" → Awaiting PO.
- **PO received**: PO number, **PO value (ex GST)**, optional PO expiry date and attachment → Awaiting timesheets. Standing / monthly POs can be linked to many swings and people.

## 5. Invoicing rules
- Per-person-PO clients invoiced **per swing**; standing-PO clients (e.g. Thiess) **monthly**.
- Invoice up to the last day of the month where all timesheets for those days are submitted.
- A block (swing, or month for standing-PO clients) reaches **Awaiting coordinator approval** when every rostered day has signed timesheet hours and the travel-out date has passed (or month end for monthly clients).

### 5.1 Coordinator approval gate and PO check
- **Invoicing cannot start until the coordinator has checked the block and Adam has given final approval.** The approval screen shows, per day and in total, the **hours, kms and vehicle-hire days** — timesheet actuals against what was quoted — with the line values at the client's rates. Vehicle hire only appears if it was quoted and a vehicle was assigned; km only where quoted.
- The coordinator can adjust a line (with a required reason, kept in the audit trail) and then clicks **Approve for invoicing** → Ready to invoice. Until then the block is locked from invoicing and from any Xero draft invoice.
- **PO exceeded pop-up**: on approval, the platform totals this block plus everything already approved or invoiced against the same PO. If that exceeds the PO value, a pop-up appears: **"PO [number] exceeded — PO value $X, approved/invoiced to date $Y, this block $Z, over by $W."** Options:
  - **Request PO variation** → job set to **Awaiting PO variation**; block stays unapproved until a new PO value or PO number is entered.
  - **Approve anyway** → the coordinator can proceed with a required reason; logged.
  - **Cancel** → back to the approval screen.
- **Early warning** (confirmed): an amber notice when a PO reaches 90% of its value (approved + invoiced), shown on the job, on the PO value bar and in the coordinator's alerts.
- **PO expiry** (if entered): pop-up if the block includes days after the PO expiry date.
- Approved blocks drive the Xero draft invoice (stage 3) — only approved hours, kms and vehicle hire are sent.

### 5.2 Weekly payroll → Xero Payroll (Monday 1 pm)
- **Pay week**: Monday–Sunday. Timesheets are signed by the employee and site supervisor during the week (and the Sunday pre-start rule applies).
- **Monday morning reconfirmation**: the coordinator opens the **Payroll week** screen, which lists every employee's hours for the week ending Sunday, split by pay type, against what was rostered. The coordinator ticks **"Reconfirmed"** per person (or "Reconfirm all"). Anyone not signed off or not reconfirmed is shown in red with the reason (no timesheet, no supervisor signature, no Sunday pre-start, hours differ from roster).
- **1:00 pm Monday (Perth time) automatic push** (on/off switch, plus a "Push now" button):
  - Sends a **timesheet** for each reconfirmed employee to **Xero Payroll (AU)** for that week, using their Xero employee record and the mapped earnings rates.
  - Creates the **weekly pay run as a draft** for the weekly pay calendar. It is **never posted or finalised automatically** — accounts reviews and posts it in Xero as now.
  - People not reconfirmed by 1 pm are **held back**, listed in an in-app alert to the coordinator and accounts, and can be pushed later with "Push now" (added to the same draft pay run if it's still open).
  - Re-pushing replaces that person's draft timesheet for the week rather than duplicating it.
- **What gets sent per day**: ordinary hours; **travel hours at the $35/hr travel rate** for unquoted travel; overtime / night-shift / weekend lines per the earnings-rate mapping; allowances where set up (e.g. meal, LAFHA) once confirmed.
- **Excluded**: subcontractors (type SUB) and anyone flagged "exclude from Xero payroll" (e.g. SprintPay-only staff).
- **Audit trail**: who reconfirmed, when the push ran, what was sent, and Xero's response for each person, kept against the pay week.
- Payroll is independent of invoice approval: employees are paid on reconfirmed timesheets even if the client block is waiting on a PO variation.
- **Needs**: a Xero connection with **payroll** access (payroll timesheet and pay run permissions — the current Xero connection is read-only with no payroll access); each employee matched to their Xero employee record; an earnings-rate mapping table agreed with accounts.

## 6. Employee app (phone)
### 6.1 Roster and job cards
- Login; sees own roster with **PO-confirmed** work only.
- Once a job is finalised (PO received and site contacts ticked), the employee can expand that swing to open its **job card**:
  - Client, site, swing dates, shift (D/N), PO number
  - **Accommodation** booked (name, dates in/out)
  - **Travel details**: travel-in / travel-out codes and dates (fly/drive/bus), flight details if entered, and any **unfilled travel flagged "to be confirmed"**
  - **Quoted hours and km** per day
  - **Site contacts** — only the contacts the coordinator ticked
  - **OEMX staff on site at the same time** — identified from the roster (same site code, overlapping days), with numbers from the directory
  - Allocated vehicle (ute) if any
### 6.2 Timesheets
- Only on days the coordinator has rostered; prefilled with quoted hours and km; employee confirms and signs; **site supervisor signs on the employee's phone**.
- **Vehicle pre-start** must be completed before the **Sunday** timesheet can be submitted if a vehicle is assigned.
- Signed timesheets feed the Monday payroll reconfirmation (5.2) and the invoice block approval (5.1).
### 6.3 JMP
- "Activate JMP" logs departure time; "Arrived" logs arrival and closes it.
- Fatigue questions on activation: hours of sleep last night; are you fatigued; will you reach your destination before 8 pm; are road conditions safe to drive.
- Any concerning answer **or under 6 hours' sleep** → coordinator notified to apply additional fatigue measures.
- Overdue arrival escalation: **5 pm → coordinator**, **7 pm → manager (Adam)**.
- Notifications: **in-app** initially; SMS and/or email considered later.
### 6.4 Forms portal
Six forms, matching the current Jotforms question-for-question (field lists in Appendix A). Name, email, department, date, and — where rostered that day — client, site, fleet number and supervisor are **prefilled** from the employee's profile and roster. Each submission is stored against the person and job, with signatures and uploads kept in file storage.
1. **Take 5** (jotform 250481110753044)
2. **Vehicle Pre-Start** (jotform 250219272440045) — required every Sunday with the timesheet and before driving
3. **Service Report** (jotform 243168288037867) — employee + site supervisor signatures
4. **Hazard Report** (jotform 261398146131860)
5. **Incident – Event Statement** (jotform 250767425537060)
6. **Leave Application** (jotform 243104414235848) — **4-week rule**: if First Day of Leave is less than 28 days from today, a pop-up says the request **breaches the 4-week leave policy and additional approvals are required**; it can still be submitted and is flagged for manager approval. Medical certificate required for more than 2 days of Personal/Sick leave.
### 6.5 Phone directory
- OEMX contacts (name, location, mobile, landline, email) mirrored from the monday.com **OEMX Telephone Directory** (board 1928712599; groups: OEMX Telephone Directory, Welshpool – Head Office, Forrestfield – Fabrication Workshop).
- Updates automatically when the monday.com board changes (scheduled refresh, read-only). Tap-to-call / tap-to-email.

## 7. Integrations
- monday.com (read only): staff register (1911160390), SITE TRAVEL KMS & HOURS (2007085984), Vehicle Pre-Start (1925803985), OEMX Telephone Directory (1928712599), Client Site Contact List (1937872096).
- Jotform: form definitions above (rebuilt natively in the platform; Jotforms remain live during the parallel test).
- Xero accounting: contracted + STD rate items (read); draft invoices from coordinator-approved blocks only (write, stage 3).
- **Xero Payroll (AU)**: employees and earnings rates (read); weekly timesheets and draft pay run (write, stage 3).
- timesheets@oemxdiesel.com.au: daily check, import hours and km into the roster (needs delegate access from IT; currently refused).

## 8. Delivery stages
1. Coordinator dashboard on the hosted platform (roster, staff, vacancies, mobilisation, site-contact selection, JMP board, quotes, job status with PO value tracking, leave dashboard).
2. Employee app (roster + job cards, timesheets with supervisor sign-off, forms portal incl. leave rule, pre-start, JMP with fatigue check and in-app alerts, phone directory) + **invoice block approval with PO-exceeded check** + Payroll week reconfirmation screen.
3. Xero draft invoices, **Monday 1 pm Xero Payroll push (draft pay run)**, timesheets inbox import; SMS/email alerts optional.
4. (Proposed) HR/onboarding and compliance register (3.2) with mobilisation checks against site requirements, absorbing the monday.com compliance and induction boards (3.3).

## 9. Outstanding items from Adam
- ~~Supabase~~ connected 25 Oct — project **oemx-ops** (ref gaflnumnajejnprlpghw) created in **Sydney (ap-southeast-2)**, free tier. Empty Seoul default project can be deleted.
- ~~Netlify~~ connected 25 Oct (free team).
- **GitHub** still to be linked (claude.ai Settings → Connectors) — needed before app code is written so OEMX holds the code.
- Sample Xero quote PDF.
- IT: delegate read access to timesheets@ for Adam's account.
- Xero write access (accounting and **payroll**) via a Xero app connection before stage 3.
- With accounts: weekly pay calendar name in Xero; earnings-rate mapping (ordinary, overtime tiers, night shift, weekend, travel $35/hr, allowances); confirm who is paid through Xero Payroll vs SprintPay/XoomCloud.

## 10. Decisions log
- 25 Oct: JMP alerts in-app first; SMS/email later.
- 25 Oct: Job cards, employee forms portal, phone directory synced from monday.com added to scope.
- 25 Oct: All leave requests in one dashboard with "Push to open vacancies"; coordinator must tick applicable client site contacts before finalising a job; Incident – Event Statement form added; Jotform links supplied.
- 25 Oct: Weekly payroll — coordinator reconfirms Monday morning; automatic push to Xero Payroll at 1 pm Monday creates a draft pay run (never auto-posted).
- 25 Oct: Invoicing cannot start until the coordinator approves the block of hours, kms and vehicle hire; PO-exceeded pop-up on approval.
- 25 Oct: 90% PO early warning confirmed.
- 25 Oct: Site requirements matrix plus a green/amber/red compliance suitability indicator on vacancy candidates and roster assignment (to confirm: warn-only vs block on red).
- 25 Oct: Office logins — Adam Herbert (manager), Joshua Howell and Stephen Clarkson (coordinators), Chamara Powers (new Mobilisation Officer role: compliance and mobilising to site). Logins limited to an invite list; employees later via their staff-register email.

## 11. Round 1 decisions (grilling, 25 Oct)
- Q1 PO over-run: coordinator may "Approve anyway" with a reason (no manager sign-off required).
- Q2 Source of truth (parallel test): monday.com decides employment and status; the platform owns rostering details (pattern, ute, site, notes).
- Q3 Stage 1 migrates everything from the claude.ai planner; the old planner then becomes read-only.
- Q4 Employee login: email one-time link/code, stay signed in 30 days.
- Q5 Timesheet day: start, finish, break, total (calculated), travel hours, km, shift D/N.
- Q6 Coordinator edits after sign-off: reason required, logged, employee notified; no re-signing.
- Q7 Platform splits hours into ordinary / overtime / night / weekend / travel using accounts' rules; ordinary + travel only until rules are supplied.
- Q8 Employee app works offline (timesheets, pre-starts, Take 5, JMP) and syncs when back in range, keeping the real timestamps.
- Q9 7 pm overdue-JMP alert to Adam also sent by email from day one.
- Q10 JMP overdue = 5 pm (coordinator) / 7 pm (Adam), or expected arrival + 1 h if earlier (expected arrival = departure + drive hours from SITE TRAVEL KMS board).
- Q11 Medical certificates, incident statements and fatigue answers visible only to coordinator and Adam.
- Q12 Web address and Q13 hosting cost: settled in round 2.

## 12. Round 2 decisions (25 Oct)
- Adam gets an in-app notice (with the coordinator's reason) whenever a block is approved past its PO.
- People marked Resigned/Terminated in monday.com lose platform access automatically; history kept.
- Each staff record has a home base town, used for km, drive hours and JMP expected arrival.
- Timesheets prefill each site's usual start/finish times from past timesheets; employee can change them.
- Site supervisor gets a PDF copy of the signed timesheet if their email is entered.
- Cutover: coordinator stays on the current planner until stage 1 is signed off, then one week running both.
- Hosting: free Supabase/Netlify tiers while testing; upgrade to Supabase Pro (~US$25/month) before employees go live.
- Address: free Netlify address while testing; ops.oemxdiesel.com.au at employee go-live.
- New input: "Invoice approvals are completed by Adam" — approval flow to be settled in round 3.

## 13. Round 3 decisions (25 Oct)
- **Invoice approval is two-step**: the coordinator checks the block (hours, kms, vehicle hire, PO check), then **Adam gives final approval** before anything is invoiced or sent to Xero. Status: Awaiting timesheets → Awaiting coordinator check → Awaiting Adam's approval → Ready to invoice.
- Employees also see planned swings without a PO (greyed, "Tentative") and their R&R days.
- Employees get an in-app notice when their roster or job card changes.
- Supervisor signature is required before a timesheet can be submitted (no "sign later").
- If driving a company vehicle, a pre-start must be completed that day before a JMP can be activated.
- Quotes do **not** need Adam's approval before sending.
- Vacancy records: client, site, trade, headcount, start/end dates, roster pattern, shift, rate item. Vacancies close automatically when every position is filled.

## 14. Round 4 decisions (25 Oct)
- **No supervisor available** → the timesheet is held until a supervisor signs. Payroll still runs on Monday for everyone else; late timesheets are submitted the following week and paid in the next pay run.
- Adam's invoice approvals: one daily digest (in-app + email); approve in bulk or open any block; rejecting sends it back to the coordinator with a comment; Adam can nominate a delegate while away.
- Tentative swings show **dates only — no site code** and no job card details until the PO is in.
- No separate "now confirmed" notice (covered by the general roster-change notice).

## 15. Round 5 decisions (25 Oct)
- Late timesheets go into the next pay run with their original work dates.
- Reminders: in-app + email to employees at **4:30 pm Sunday** for unsubmitted/unsigned timesheets; coordinator gets a list at **9 am Monday** of who is missing a timesheet.
- No pilot group: all labour hire employees are invited at employee go-live.
- Records kept 7 years (timesheets, pay, invoices); safety forms kept indefinitely.
- One-page how-to guides for coordinator, employees and accounts.

---
## Appendix A — Form fields (from the live Jotforms, 25 Oct 2026)

### A1. Vehicle Pre-Start Form — "To be completed every Sunday with Timesheet and Prior to Driving Vehicle"
- **Vehicle details**: Pre-Start Date; Fleet Number (OEMX-01 … OEMX-100); Department (Field Service / Labour Hire / Fabrication); Odometer Reading; Next Service Km; Photos of Vehicle (upload).
- **Category A** — acknowledgement (required): "I must not operate the vehicle if the following items are not operational… tag out the vehicle and organise repairs immediately." Items (Good Order / Requires Attention / Not Applicable, required): Headlights Operation; Park & Foot Brake Operation; Horn Operation; Steering Operation; Speedometer; Two Way Radio; Fire Extinguisher; Seat Belt Operation; Wheel Nuts Torque & Wheel Nut Indicators.
- **Category B** — acknowledgement (required): "…I must rectify the fault first." Items: Engine Oil Level; Coolant Level; Power Steering Fluid Level; Brake Fluid Level; Clutch Fluid Level; Spills/Leaks; Vehicle Interior/Exterior clean and presents well; Brake/Tail Lights/Indicator Lights; Mirrors – Clean & In Place; Tyre Condition.
- **Category C** items: Whip Arial/Flag; Revolving Light Operation; Battery Secure; Washer Reservoir Level; Reversing Alarm; Instrumentation; Wheel Chocks; Signage and Decals Condition; Damage (+ Any additional Damage text); Wipers; Windscreen.
- Comments/Fault Details (required); Is your Electrical Equipment Tagging in Date? (Yes/No — if No, notify Coordinator or Workshop).
- **Name & Sign**: OEMX Team Member Name; Signature; Team Member Email (all required).
- Platform rule: any Category A "Requires Attention" → vehicle shown as tagged out and coordinator alerted.

### A2. Take 5
- Name; Date; Department (Field Service / Fleet Maintenance / Corporate / Labour Hire / Fabrication WS / Fabrication FS); Location; Task; Client Take 5 Image (upload).
- **Stop! Think through the task** (Yes/No; No → "STOP – See your supervisor"): clear on the task; required skills, training and licences; checked JSA/JHA/SWMS/procedures; equipment and tools correct and in good order; necessary permits; correct PPE.
- **Look for hazards** (Yes/No, Yes → note for risk assessment): Atmosphere; Biological; Chemical; Electrical; Environment; Fire/Explosions; Gravitational; Manual Handling; Mechanical; Pressure.
- Likelihood (Rare / Unlikely / Possible / Likely / Almost Certain); Impact (Low / Minor / Moderate / Major / Critical); Risk Rating (calculated).
- **Assess**: Is the Risk Rating 5 or above? (Yes → "STOP – See your supervisor. Further action required.")
- **Make the hazard safe**: removed hazards / implemented effective controls? (No → STOP); if Yes, what controls were implemented; can I complete the task safely? (No → STOP).
- Signature.
- To confirm: the exact risk-rating calculation (likelihood × impact matrix) used by the Jotform.

### A3. Hazard Report Form
- Hazard; Department (Field Service / Labour Hire / Fabrication – FS / Fabrication – WS / Fleet Maintenance / Corporate); OEMX Team Member Name; OEMX Manager Hazard Reported to; Client; Site; Report Date & Time; Hazard Status (Monitoring / Active / Closed); Initial Risk Level (Low / Medium / High); Initial Controls (Make It Safe); Post Control Risk Level (Low / Medium / High); Suggested Controls/Preventative Actions; Upload Completed Hazard Report Form; OEMX Team Member Signature.

### A4. Incident – Event Statement Form
- **Person details**: Name; Company; Position; Supervisor; Email; Site; Phone Number; Department.
- **Incident details**: Date; Location of Incident; Date of Statement; Time of Event; Time Reported; Role in the Incident (Witness / Person Involved / Supervisor).
- **Details of activity**: risk assessments conducted prior to task (Take Control/5, JHA, Supervisor); Was this task planned? (Planned / Unplanned); tasks completed from start of shift to time of event.
- **Environment**: Did weather contribute? (Yes/No) → If yes, how; Other work crews in the area (details); Tools and equipment used (and familiarity); Sequence of events (who, where, what, when, why, how, approximate times).
- Platform addition (to confirm): employee signature.

### A5. Leave Application
- Date of Request; Employee Name*; Employee Email*; Department* (Admin/Accounts/Mobilisation / Fleet Maintenance / Fabrication FS / Fabrication WS / Field Services / Labour Hire / Management); OEMX Supervisor/Approver*; OEMX Approval (Approved / Rejected / Pending).
- Leave Type* (Annual Leave / Personal Leave/Sick Leave / LWOP); Reason for Leave; First Day of Leave*; Last Day of Leave*; Total Days of Leave Taken (auto-calculated); Employee Signature.
- **Client/Site details***: Client; Site; Client Site Supervisor/Approving Manager; Client Supervisor Email; Client Site Supervisor/Approver Signature; Site Approval Status (Approved / Rejected).
- OEMX Supervisor/Approver Signature; Approval Date; Processed by Mobilisation Team* (Yes / No / Pending); Processed by Accounts Team* (Yes / No / Pending).
- Medical Certificate upload (required for more than 2 days of Personal Leave); Signed Copy of Leave Form (if printed for site approval).
- Platform rules: 4-week policy pop-up and manager routing; client/site prefilled from the roster for the leave dates; "Push to open vacancies" from the leave dashboard.

### A6. Service Report
- Date; Department (Labour Hire / Field Services / Fabrication – FS / Fabrication – WS / Fleet Maintenance / Corporate); Employee Name*; Task/Job Name*; Customer*; Site*; Supervisor Name; Supervisor Email; Discipline (Fitter / Sparky / BMW / LB); Asset Number; Machine Make/Model; SMU.
- Components (up to 4): Component Name; Part Number; Serial Number; Serial Off; Serial On.
- What was the customer's complaint?; What issue/s did you find?; What did you do to rectify the issue?; What did you do to confirm the issue is resolved?
- File Upload; Employee Sign; Site Supervisor Sign.
