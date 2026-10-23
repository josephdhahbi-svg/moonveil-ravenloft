"use strict";
/** SQLite schema migrations. Forward-only, transactional, and idempotent. */
const MIGRATIONS = [
  { version:1, name:"campaign access and event ledger", sql:`
CREATE TABLE IF NOT EXISTS vtt_campaigns (
 campaign_id TEXT PRIMARY KEY, name TEXT NOT NULL, created_at TEXT NOT NULL
);
CREATE TABLE IF NOT EXISTS vtt_campaign_members (
 campaign_id TEXT NOT NULL REFERENCES vtt_campaigns(campaign_id) ON DELETE CASCADE,
 actor_id TEXT NOT NULL, role TEXT NOT NULL CHECK(role IN ('DM','PLAYER','OBSERVER')),
 PRIMARY KEY(campaign_id,actor_id)
);
CREATE TABLE IF NOT EXISTS vtt_campaign_events (
 campaign_id TEXT NOT NULL REFERENCES vtt_campaigns(campaign_id) ON DELETE CASCADE,
 revision INTEGER NOT NULL CHECK(revision > 0), event_id TEXT NOT NULL,
 actor_id TEXT NOT NULL, event_type TEXT NOT NULL, payload_json TEXT NOT NULL,
 occurred_at TEXT NOT NULL,
 PRIMARY KEY(campaign_id,revision), UNIQUE(campaign_id,event_id)
);
CREATE INDEX IF NOT EXISTS idx_vtt_events_actor ON vtt_campaign_events(campaign_id,actor_id);
` },
  { version:2, name:"revoked actor sessions", sql:`
CREATE TABLE IF NOT EXISTS vtt_revoked_sessions (
 token_hash TEXT PRIMARY KEY, expires_at INTEGER NOT NULL, revoked_at TEXT NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_vtt_revoked_expiry ON vtt_revoked_sessions(expires_at);
` }
];
function migrate(db) {
  if (!db || typeof db.exec!=="function" || typeof db.prepare!=="function" || typeof db.transaction!=="function")
    throw new TypeError("better-sqlite3 compatible database required");
  db.exec("CREATE TABLE IF NOT EXISTS vtt_schema_migrations (version INTEGER PRIMARY KEY, name TEXT NOT NULL, applied_at TEXT NOT NULL)");
  const apply=db.transaction(()=>{
    const current=db.prepare("SELECT version FROM vtt_schema_migrations ORDER BY version").all().map(row=>row.version);
    const known=new Set(MIGRATIONS.map(m=>m.version));
    if(current.some(v=>!known.has(v)))throw new Error("Database schema is newer than this server");
    for(const m of MIGRATIONS){
      if(current.includes(m.version))continue;
      db.exec(m.sql);
      db.prepare("INSERT INTO vtt_schema_migrations(version,name,applied_at) VALUES(?,?,?)").run(m.version,m.name,new Date().toISOString());
    }
  });
  apply();
}
module.exports={migrate,MIGRATIONS};
