import fs from 'node:fs/promises';
import path from 'node:path';
const root=path.resolve('dist');
const required=['index.html','app.js','engine.js','continuity.js','manifest.webmanifest','sw.js'];
let files=0,bytes=0;
async function walk(dir){for(const entry of await fs.readdir(dir,{withFileTypes:true})){const filename=path.join(dir,entry.name);if(entry.isDirectory())await walk(filename);else if(entry.isFile()){files++;bytes+=(await fs.stat(filename)).size;}}}
await walk(root);
for(const file of required)await fs.access(path.join(root,file));
if(files<120||bytes<100_000_000)throw Error('Incomplete Moonveil release: '+files+' files, '+bytes+' bytes');
console.log('Complete Moonveil PWA verified: '+files+' files, '+bytes+' bytes');
