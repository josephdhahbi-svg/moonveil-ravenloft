"use strict";
const test=require("node:test");
const assert=require("node:assert/strict");
const fs=require("node:fs");
const os=require("node:os");
const path=require("node:path");
const {createBackupService}=require("./backup-service");
test("online backups retain newest snapshots and stop timer",async()=>{
 const directory=fs.mkdtempSync(path.join(os.tmpdir(),"moonveil-backup-"));
 let index=0;
 const db={backup:async destination=>{fs.writeFileSync(destination,"sqlite-"+(++index));}};
 const service=createBackupService(db,{directory,retain:2,clock:()=>new Date("2026-10-15T12:00:00Z"),logger:{info(){},error(){}}});
 try{
  service.start();service.start();
  await service.backupNow();await service.backupNow();await service.backupNow();
  const files=fs.readdirSync(directory);
  assert.equal(files.length,2);
  assert.ok(files.every(f=>f.endsWith(".sqlite")));
  assert.equal(index,3);
 }finally{service.stop();fs.rmSync(directory,{recursive:true,force:true});}
});
test("failed backup removes incomplete file and allows retry",async()=>{
 const directory=fs.mkdtempSync(path.join(os.tmpdir(),"moonveil-backup-failure-"));
 let fail=true;
 const db={backup:async destination=>{fs.writeFileSync(destination,"partial");if(fail)throw Error("disk failed");}};
 const service=createBackupService(db,{directory,logger:{info(){},error(){}}});
 try{
  await assert.rejects(service.backupNow(),/disk failed/);
  assert.deepEqual(fs.readdirSync(directory),[]);
  fail=false;assert.equal((await service.backupNow()).skipped,false);
  assert.equal(fs.readdirSync(directory).length,1);
 }finally{service.stop();fs.rmSync(directory,{recursive:true,force:true});}
});
test("backup rejects unsafe configuration",()=>{
 assert.throws(()=>createBackupService({}, {directory:"x"}),/backup/);
 assert.throws(()=>createBackupService({backup(){}},{directory:"x",retain:0}),/retention/);
 assert.throws(()=>createBackupService({backup(){}},{directory:"x",intervalMs:500}),/interval/);
});
