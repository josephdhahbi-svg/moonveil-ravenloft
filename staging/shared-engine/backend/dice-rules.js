"use strict";
/** Deterministic, validated d20 resolution. The caller supplies the die face. */
function resolveD20({rawRoll,modifier=0,dc}){
 if(!Number.isSafeInteger(rawRoll)||rawRoll<1||rawRoll>20)throw new RangeError("rawRoll must be 1..20");
 if(!Number.isSafeInteger(modifier)||modifier< -10||modifier>20)throw new RangeError("modifier must be -10..20");
 if(!Number.isSafeInteger(dc)||dc<1||dc>40)throw new RangeError("dc must be 1..40");
 const total=rawRoll+modifier;
 return Object.freeze({rawRoll,modifier,dc,total,success:total>=dc});
}
module.exports={resolveD20};
