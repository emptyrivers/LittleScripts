-- Copyright © 2018 Allen Faure. See LICENSE.md for details.

local util = {}


function util.makeTempAdder()
  local val = 0
  return function(toAdd, decayTime) --modify upvalue
    val = val + toAdd
    C_Timer.After(decayTime,function()
      val = val - toAdd
    end)
  end,
  function()  return val  end --access upvalue
end

function util.GroupMembers(reverse, forceParty)
   local unit  = (not forceParty and IsInRaid()) and 'raid' or 'party'
   local numGroupMembers = (forceParty and GetNumSubgroupMembers()  or GetNumGroupMembers()) - (unit == "party" and 1 or 0)
   local i = reversed and numGroupMembers or (unit == 'party' and 0 or 1)
   return function()
      local ret
      if i == 0 and unit == 'party' then
         ret = 'player'
      elseif i <= numGroupMembers and i > 0 then
         ret = unit .. i
      end
      i = i + (reversed and -1 or 1)
      return ret
   end
end

function util.HexToRGBA(hex) --expects a 6-8 digit hex string.
  if type(hex) ~= 'string' then return 0,0,0 end
  return tonumber((hex:sub(1,2)) or 0, 16)/255,
         tonumber((hex:sub(3,4)) or 0, 16)/255,
         tonumber((hex:sub(5,6)) or 0, 16)/255,
         tonumber((hex:sub(7,8)) or 0, 16)/255
end

LittleScripts.util = util