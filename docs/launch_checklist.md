# Pre-launch checklist

## Player images and uploads

- [ ] Create a private S3 bucket in the production region.
- [ ] Add `aws-sdk-s3` and enable the `amazon` service in `config/storage.yml`.
- [ ] Change production from `config.active_storage.service = :local` to `:amazon`.
- [ ] Give the app a least-privilege IAM role/user limited to the bucket.
- [ ] Store the bucket name, region, and AWS credentials in deployment secrets—not the repository.
- [ ] Copy existing Active Storage blobs from the persistent local volume to S3 using their existing keys, then update `active_storage_blobs.service_name` only after verifying the copy.
- [ ] Keep the bucket private and verify signed image URLs from the deployed app.
- [ ] Decide whether to put CloudFront in front of S3; configure CORS and cache headers if needed.
- [ ] Enable bucket versioning/lifecycle rules and include uploaded files in backup/restore testing.

## Hosting and security

- [ ] Configure the production domain, DNS, HTTPS, `force_ssl`, and production URL options.
- [ ] Put Rails credentials and environment secrets into the host's secret manager.
- [ ] Rotate development/test ESPN cookies before launch and store production `ESPN_S2`/`ESPN_SWID` securely.
- [ ] Review commissioner-only authorization for league deletion, ESPN synchronization, drafting for teams, and clock controls.
- [ ] Add rate limiting to email sign-in and other unauthenticated endpoints.
- [ ] Configure secure session cookies and verify CSRF protection through the production proxy.

## Email sign-in

- [ ] Choose and configure a transactional email provider.
- [ ] Set the production sender address and domain authentication (SPF, DKIM, and DMARC).
- [ ] Verify sign-in links expire, are single-use, and return users to the intended league/draft.
- [ ] Test delivery and login with every team email before draft day.

## Data and operations

- [ ] Use a production database appropriate for the expected hosting setup and configure automated backups.
- [ ] Verify the persistent volume still covers SQLite/Solid Queue data if those remain in production.
- [ ] Run all migrations during deployment, including Active Storage tables.
- [ ] Run ESPN rules/history/player-score sync and nflverse stats/headshot sync before opening the room.
- [ ] Schedule or document recurring ESPN and nflverse refreshes.
- [ ] Run a full restore drill for the database and Active Storage files.
- [ ] Configure error reporting, uptime checks, structured logs, and disk/queue alerts.
- [ ] Confirm background workers run for Turbo broadcasts, Active Storage cleanup, and Solid Queue jobs.

## Draft-day rehearsal

- [ ] Test the production room on phones, tablets, and desktop browsers without horizontal scrolling.
- [ ] Rehearse commissioner actions: start, pause/resume, draft for any team, finish, and export results.
- [ ] Test reconnects and simultaneous picks with multiple signed-in users.
- [ ] Confirm the canonical team order, roster rules, PPR/scoring, player pool, and all assigned emails.
- [ ] Export a backup immediately before the draft and confirm the results export after completion.
