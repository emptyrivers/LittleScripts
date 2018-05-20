-- Copyright © 2018 Allen Faure. See LICENSE.md for details.

--this part contains all of the code that handles ADDON_LOADED and PLAYER_LOGIN

local loadFrame = CreateFrame("FRAME")

loadFrame:RegisterEvent("ADDON_LOADED")
loadFrame:SetScript("OnEvent",
   function(self,event,arg,...)
      if event == "ADDON_LOADED" and arg == "LittleScripts" then
         --call init functions for each module, replace dummy functions
         __littlesaves = __littlesaves  or {}
         for _, module in pairs(LittleScripts.__modules) do
            LittleScripts.LoadModule(module)
         end
      end
      LittleScripts.loaded = true
   end
)