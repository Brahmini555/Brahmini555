# Setting up your real GitHub profile view counter

This replaces the fake "hit counter" badge with your **actual** view count,
pulled from GitHub's own Traffic API. It updates automatically once a day.

## Why a token is needed
The Traffic API (`/repos/{owner}/{repo}/traffic/views`) only returns real
data to someone with push access to the repo, authenticated with a token.
There's no way around this — it's how GitHub protects that data.

## One-time setup (about 3 minutes)

### 1. Create a Personal Access Token (PAT)
1. Go to **github.com → Settings → Developer settings → Personal access tokens
   → Fine-grained tokens** (or "Tokens (classic)" if you prefer).
2. Click **Generate new token**.
3. Repository access: select **only** your profile repo (`Brahmini555/Brahmini555`).
4. Permissions: under **Repository permissions**, set **Administration: Read-only**
   *(this is what unlocks traffic/insights data)* — you do **not** need write access
   to anything else.
   - If you use a **classic** token instead, just check the `repo` scope box.
5. Generate the token and **copy it now** — GitHub only shows it once.

### 2. Add it as a repo secret
1. In your `Brahmini555/Brahmini555` repo, go to
   **Settings → Secrets and variables → Actions → New repository secret**.
2. Name: `TRAFFIC_TOKEN`
3. Value: paste the token you copied.
4. Save.

### 3. Add these files to your repo
Copy this into your `Brahmini555/Brahmini555` repo, keeping the folder structure:

```
.github/workflows/update-views.yml
.github/scripts/update_views.sh
.github/view-tracking.json
```

Make sure `update_views.sh` stays executable (`chmod +x`) — if you upload
through the GitHub web UI, this happens automatically after the first commit
because the workflow calls it with `bash`, so it doesn't strictly need the
execute bit, but it's good practice.

### 4. Update your README
Your `README.md` should already have this pair of markers where the badge goes
(I've already added them for you):

```html
<!--VIEWS-START-->
<img src="https://img.shields.io/badge/Real%20Profile%20Views-0-0ea5e9?style=for-the-badge" alt="real profile views"/>
<!--VIEWS-END-->
```

The workflow finds these markers and rewrites the badge URL in place every day
— don't remove or reorder them.

### 5. Run it once manually
Go to your repo's **Actions** tab → **Update Real Profile Views** →
**Run workflow**, to confirm it works instead of waiting for the daily cron.

## What the number actually means
- It's a **running cumulative total** of page hits GitHub's own traffic system
  recorded for your profile repo, added up one completed day at a time.
- GitHub's Traffic API only exposes a rolling **14-day window**, so this
  workflow's job is to "bank" each day's number before it falls out of that
  window — that's why the running total lives in `view-tracking.json` in your repo.
- It still counts repeat visits by the same person as separate views (GitHub's
  API itself distinguishes "count" vs "uniques" per day — if you'd rather track
  uniques instead of raw views, change `.count` to `.uniques` in
  `update_views.sh`).
- This is real GitHub data, not a third-party guess — the honest ceiling is
  that it can only start counting from whenever you enable this, not retroactively.
