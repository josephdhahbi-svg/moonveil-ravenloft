"use strict";
const test=require("node:test");
const assert=require("node:assert/strict");
const {resolveD20}=require("./dice-rules");
test("d20 resolution computes stable success and failure",()=>{
 assert.deepEqual(resolveD20({rawRoll:13,modifier:2,dc:15}),{rawRoll:13,modifier:2,dc:15,total:15,success:true});
 assert.deepEqual(resolveD20({rawRoll:1,modifier:-10,dc:40}),{rawRoll:1,modifier:-10,dc:40,total:-9,success:false});
 assert.equal(resolveD20({rawRoll:20,modifier:20,dc:40}).success,true);
});
test("d20 rejects invalid dice and difficulty inputs",()=>{
 for(const rawRoll of [0,21,1.5,NaN,Infinity,"20"])assert.throws(()=>resolveD20({rawRoll,dc:15}),RangeError);
 for(const modifier of [-11,21,NaN,2.2,"2"])assert.throws(()=>resolveD20({rawRoll:12,modifier,dc:15}),RangeError);
 for(const dc of [0,41,NaN,Infinity,1.2,"15"])assert.throws(()=>resolveD20({rawRoll:12,dc}),RangeError);
});
