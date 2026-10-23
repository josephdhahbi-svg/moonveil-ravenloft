"use strict";
/** Opt-in SQLite online backups. Uses better-sqlite3 backup() so WAL pages are included. */
const fs=require("node:fs");
const path=require("node:path");
function createBackupService(db,{directory,intervalMs=6*60*60*1000,retain=14,clock=()=>new Date(),logger=console}={}){
 if(!db||typeof db.backup!=="function")throw new TypeError("SQLite backup() required");
 if(typeof directory!=="string"||!directory.trim())throw new TypeError("Backup directory required");
 if(!Number.isSafeInteger(intervalMs)||intervalMs<60_000)throw new RangeError("Minimum interval 60 seconds");
 if(!Number.isSafeInteger(retain)||retain<1||retain>1000)throw new RangeError("Invalid retention");
 const folder=path.resolve(directory);
 let running=false,timer=null;
 async function backupNow(){
  if(running)return {skipped:true,reason:"IN_PROGRESS"};
  running=true;
  let destination;
  try{
   fs.mkdirSync(folder,{recursive:true,mode:0o700});
   const stamp=clock().toISOString().replace(/[:.]/g,"-");
   destination=path.join(folder,"moonveil-"+stamp+"-"+require("node:crypto").randomBytes(4).toString("hex")+".sqlite");
   await db.backup(destination);
   const files=fs.readdirSync(folder).filter(n=>/^moonveil-.*\.sqlite$/.test(n)).sort().reverse();
   for(const file of files.slice(retain))fs.unlinkSync(path.join(folder,file));
   logger.info?.("[Moonveil] SQLite online backup completed");
   return {skipped:false,path:destination};
  }catch(error){
   if(destination){try{fs.unlinkSync(destination);}catch{}}
   logger.error?.("[Moonveil] SQLite backup failed:",error);
   throw error;
  }finally{running=false;}
 }
 function start(){
  if(timer)return;
  timer=setInterval(()=>{backupNow().catch(()=>{});},intervalMs);
  timer.unref?.();
 }
 function stop(){if(timer){clearInterval(timer);timer=null;}}
 return {backupNow,start,stop};
}
module.exports={createBackupService};
