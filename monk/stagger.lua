-- Copyright © 2018 Allen Faure. See LICENSE.md for details.

--this holds code for normalized stagger

local api = {}
local util = LittleScripts.util

local addToPool, getVal = util.makeTempAdder()

local staggerDebuffs = {[124275] = true, [124274] = true, [124273] = true,}

local function getTick()
   if UnitStagger'player' > 0 then
      for i = 1, 40 do
         local _, _, _, _, _, _, _, _, _, id, _, _, _, _, _, tickval = UnitDebuff('player', i)
         if not id then return 0 end
         if staggerDebuffs[i] then return tickval end
      end
   end
   return 0
end

local function getColor()
   local perc = getTick()/UnitHealthMax'player'
   if perc <= .015 then
     return util.HexToRGBA('a9a9a9')
   elseif perc <= .03 then
     return util.HexToRGBA('e3df24')
   elseif perc <= .05 then
     return util.HexToRGBA('e39723')
   elseif perc <= .1 then
     return util.HexToRGBA('fd1300')
   else
     return util.HexToRGBA('fd00b2')
   end
 end

local stagger = CreateFrame('FRAME')

stagger.timeLimit = IsEquippedItem(137044) and 13 or 10

stagger.scripts = {
   OnEvent = function(self, event, unit, eventType, _, _, spellID, _, _, destGUID, ...)
      if event == "COMBAT_LOG_EVENT_UNFILTERED" then
         if destGUID == UnitGUID'player' then --grab only things that target me
            local offset = 4
            if eventType=="SPELL_ABSORBED" then --stagger's mitigation is all in absorb
               if GetSpellInfo((select(offset, ...)))==(select(offset + 1, ...)) then
                  offset = offset + 3
               end
               if select(offset + 4,...) == 115069 then --we only want damage that is staggered
                  addToPool((select(offset + 7, ...)), self.timeLimit)
               end
            end
         end
      elseif event == "UNIT_AURA" then
         for i = 1,40 do
            local _,_,_,_,_,_,_,_,_,haveBuff = UnitBuff('player',i)
            if haveBuff == 228563 then
               self.haveBuff = true
               break
            elseif not haveBuff then
               self.haveBuff = false
               break
            end
         end
      elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
         if spellID == 115388 and self.haveBuff then
            self.pauseExpiry = self.pauseExpiry and (self.pauseExpiry + 3) or (GetTime() + 3)
            self.pauseDuration = self.pauseDuration and (self.pauseDuration + 3) or (3)
            return self:SetScript("OnUpdate",self, scripts.OnUpdate)
         end
      elseif event == "PLAYER_REGEN_ENABLED" then
         return self:Disable()
      elseif event == "PLAYER_REGEN_DISABLED" then
         return self:Enable()
      elseif event == "PLAYER_SPECIALIZATION_CHANGED" then
         if GetSpecialization() ~= 1 then
            self:UnregisterEvent("PLAYER_REGEN_DISABLED")
            self:UnregisterEvent("PLAYER_REGEN_ENABLED")
            return self:Disable()
         else
            self:RegisterEvent("PLAYER_REGEN_ENABLED")
            self:RegisterEvent("PLAYER_REGEN_DISABLED")
            return self:Enable()
         end
      else
         if InCombatLockdown() then
            return self:Enable()
         else
            return self:Disable()
         end
      end
   end,
   OnUpdate = function(self)
      if not self.pauseExpiry or self.pauseExpiry < GetTime() then
         self.pauseDuration, self.pauseExpiry = nil, nil
         self:SetScript("OnUpdate", nil)
      end
   end
}

stagger.events = {"COMBAT_LOG_EVENT_UNFILTERED", "PLAYER_REGEN_DISABLED", "PLAYER_REGEN_ENABLED", "PLAYER_SPECIALIZATION_CHANGED"}
stagger.unitevents = {"UNIT_AURA","UNIT_SPELLCAST_SUCCEEDED"}

function stagger:Init()
   if select(2, UnitClass('player')) ~= "MONK" then return end -- don't even bother if not a monk
   for handler, script in pairs(self.scripts) do
      self:SetScript(handler, script)
   end
   for _, event in pairs(self.events) do
      self:RegisterEvent(event)
   end
   for _, event in pairs(self.unitevents) do
      self:RegisterUnitEvent(event,"player")
   end
   self.scripts.OnEvent(self,"PLAYER_SPECIALIZATION_CHANGED")
end

function stagger:Enable()
  self.timeLimit = IsEquippedItem(137044) and 13 or 10
  self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
  self:RegisterUnitEvent("UNIT_AURA","player")
  self:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED","player")
end

function stagger:Disable()
  self:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
  self:UnregisterEvent("UNIT_AURA")
  self:UnregisterEvent("UNIT_SPELLCAST_SUCCEEDED")
end

stagger.api = {
   GetNormalizedStagger = getVal,
   GetStaggerTick = getTick,
   GetStaggerColor = getColor,
   GetStaggerPause = function()
      return stagger.pauseDuration, stagger.pauseExpiry
   end,
}

LittleScripts:AddModule('stagger', stagger, LittleScripts:GetCategories())
