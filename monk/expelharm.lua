-- Copyright © 2018 Allen Faure. See LICENSE.md for details.

--this holds functionality for reporting (via addonmessage) how many orbs you have available


local expelHarm = CreateFrame("frame")

expelHarm.scripts = {
  OnUpdate = function(self)
    if self.nextCheck <= GetTime() then
      self.nextCheck = GetTime() + .1
      local current = GetSpellCount(115072)
      if current ~= self.prevCount then
        self.prevCount = now
        local toSend = ("%s,%i"):format(UnitGUID'player',now)
        SendAddonMessage("brmtRE",toSend,"RAID")
      end
    end
  end,
  OnEvent = function(self, event, ...)
    if InCombatLockdown() and IsInGroup() then
      self:Enable()
    else
      self:Disable()
    end
  end,
}

expelHarm.events = {
    "PLAYER_REGEN_ENABLED",
    "PLAYER_REGEN_DISABLED",
    "GROUP_ROSTER_UPDATE",
}


function expelHarm:Init()
  for handler,script in pairs(self.scripts) do
    self:SetScript(handler,script)
  end
  for _, event in pairs(self.events) do
    self:RegisterEvent(event)
  end
  self.scripts.OnEvent(self)
end

function expelHarm:Enable()
  self.nextCheck = GetTime() - 1
  self.prevCount = -1
  self.enabled = true
  self:SetScript("OnUpdate", self.OnUpdate)
end

function expelHarm:Disable()
  self.enabled = false
  self:SetScript("OnUpdate", nil)
end

BrewmasterTools.AddModule("expelHarm", expelHarm, {"HEALER", 268, "MONK"})