-- Copyright © 2018 Allen Faure. See LICENSE.md for details.

-- this part defines the framework of the addon.


LittleScripts = {}
local Littlescripts = Littlescripts
local function noop() end

function LittleScripts:debug(msg, lvl, api)
   lvl, api = lvl or 2, api or ConsoleAddMessage
   if lvl >= self.debuglvl then
      return api(msg)
   end
end

LittleScripts.loaded = false

LittleScripts.debuglvl = 1

local __categories = {
   DAMAGER = {
      __auras = {},
      __icon = [[Interface\addons\LittleScripts\media\dps_icon.blp]],
      __desc = "LittleScripts - DPS auras",
      __name = "LSDAMAGER"
   },
   HEALER  = {
      __auras = {},
      __icon = [[Interface\addons\LittleScripts\media\heal_icon.blp]],
      __desc = "LittleScripts - Healer auras",
      __name = "LSHEALER"
   },
   TANK    = {
      __auras = {},
      __icon = [[Interface\addons\LittleScripts\media\tank_icon.blp]],
      __desc = "LittleScripts - Tank auras",
      __name = "LSTANK"
   },
   GENERAL = {
      __auras = {},
      __icon = [[Interface\addons\LittleScripts\media\generic_icon.blp]],
      __desc = "LittleScripts - Generic auras",
      __name = "LSGENERAL"
   },
}
local nameForm, descForm = "LS%s", "LittleScripts - %s auras"
for i = 1, GetNumClasses() do
   local localised_name, name = GetClassInfo(i)
   local icon, desc = ([[Interface\ICONS\crest_%s.blp]]):format(name:lower()), descForm:format(localised_name)
   local classCategory = {
      __auras = {},
      __icon = icon,
      __desc = desc,
      __name = nameForm:format(name)
   }
   __categories[localised_name], __categories[name], __categories[i] = classCategory, classCategory, classCategory
   for j = 1, GetNumSpecializationsForClassID(i) do
      local specID, specname, _, specicon = GetSpecializationInfoForClassID(i,j)
      local specCategory = {
         __auras = {},
         __icon = specicon,
         __desc = descForm:format(specname),
         __name = nameForm:format(specname)
      }
      __categories[specID], __categories[specname] = specCategory, specCategory
   end
end

LittleScripts.__categories = __categories

LittleScripts.__modules = {}
LittleScripts.__api = {}

function LittleScripts:AddModule(name, module, category, overrideAPI)
   -- ensure sanity
   if type(name) ~= 'string' then
      return self:debug("LittleScripts: Improper argument #1 to AddModule: name must be a string.", 4, error)
   elseif type(module) ~= 'table' then
      return self:debug("LittleScripts: Improper argument #2 to AddModule: module must be a table or frame.", 4, error)
   elseif module.auras and type(category) ~= 'string' and type(category) ~= 'number' and type(category) ~= 'table' then
      return self:debug("LittleScripts: Improper argument #3 to AddModule: category must be a string, table, or number if auras are provided.", 4, error)
   elseif LittleScripts.__modules[name] then
      return self:debug("LittleScripts: A module by the name of "..name.." already exists.", 4, error)
   elseif module.Init ~= nil and type(module.Init) ~= 'function' then
      return self:debug("LittleScripts: "..name.." has invalid type "..type(module.Init).." for Init method.", 4, error)
   elseif module.Enable ~= nil and type(module.Enable) ~= 'function' then
      return self:debug("LittleScripts: "..name.." has invalid type "..type(module.Enable).." for Enable method.", 4, error)
   elseif module.Disable ~= nil and type(module.Disable) ~= 'function' then
      return self:debug("LittleScripts: "..name.." has invalid type "..type(module.Disable).." for Disable method.", 4, error)
   elseif module.scripts and type(module.scripts) ~= 'table' then
      return self:debug("LittleScripts: "..name.." has invalid type "..type(module.scripts).." for scripts attribute.", 4, error)
   end
   for _, method in pairs{"Init", "Enable", "Disable"} do
      module[method] = module[method] or noop
   end
   self.__modules[name] = module
   if module.auras then
      if type(category) == 'table' then
         for _, auraData in pairs(module.auras) do
            for _, cat in pairs(category) do
               if self.__categories[cat] then
                  table.insert(self.__categories[cat].__auras, auraData)
               else
                  self:debug("LittleScripts: Attempt to add aura data to non-existent category "..cat)
               end
            end
         end
      else
         if self.__categories[category] then
            for _, auraData in pairs(module.auras) do
               table.insert(self.__categories[category].__auras, auraData)
            end
         else
            self:debug("LittleScripts: Attempt to add aura data to non-existent category "..category)
         end
      end
   end
   if module.api then
      for apiname in pairs(module.api) do
         if overrideAPI or not self.__api[apiname] then
            if self.__api[apiname] then
               self:debug("Littlescripts - Warning: module "..name.." has added API method "
                          ..apiname.." which already exists. This may produce unpredictable results.")
            end
            self.__api[apiname] = module
         end
      end
   end
   if self.loaded then
      self:LoadModule(module)
   end
end

function LittleScripts:LoadModule(module)
   if module.loaded then return end
   module:Init()
   for name, func in pairs(module.api) do
      self[name] = func
   end
end

setmetatable(LittleScripts, { -- don't actually load module until something requests api from module
   __index = function(self, apiname)
      if not self.loaded then return noop end
      if self.__api[apiname] then
         self:LoadModule(self.__api[apiname])
      end
      return rawget(self,apiname)
   end
})


function LittleScripts:GetCategories(id, includeGeneric)
   -- returns spec, class, and (if requested) role categories, as well as generic category
   if id == nil then
      local specID, _, _, _, role = GetSpecializationInfo(GetSpecialization())
      local classID = UnitClass'player'
      return {class = classID, spec = specID, role = role, generic = includeGeneric and "GENERAL" or nil}
   elseif type(id) == 'number' then 
      if not GetClassInfo(id) then -- specID, probably
         local _, specname, _, _, role = GetSpecializationInfoByID(id)
         if not specname then return end
         return {class = UnitClass'player', spec = id, role = role, generic = includeGeneric  and "GENERAL" or nil}
      else  -- classID
         local toReturn = {
            class = classID,
            generic = includeGeneric  and "GENERAL" or nil,
         }
         for i = 1, GetNumSpecializationsForClassID(id) do
            local specID, _, _, _, role = GetSpecializationInfoForClassID(id, i)
            toReturn['spec'..i] = specID
            toReturn[role] = role
         end
         return toReturn
      end
   else
      if self.__categories[id] then
         return id
      end
   end
end

function LittleScripts:GetScripts(categories, includeFrame)
   -- use to collect all methods in a given category or collection of categories
   if not self.loaded then return end
   categories = categories or self:GetCategories()
   local scripts = {}
   if type(categories) == "table" then
      for _, category in pairs(categories) do
         if self.__categories[category] then
            scripts[category] = includeFrame and self.__categories[category] or nil
            if self.__categories[category].api then
               for name, func in pairs(scripts[category].api) do
                  scripts[name] = func
               end
            end
         end
      end
   else
      if self.__categories[categories] then
         scripts[categories] = includeFrame and self.__categories[categories] or nil
         if self.__categories[category].api then
            for name, func in pairs(scripts[categories].api) do
               scripts[name] = func
            end
         end
      end
   end
   return scripts
end

local loadframe = CreateFrame("FRAME")
loadframe:RegisterEvent("ADDON_LOADED")
loadframe:RegisterEvent("PLAYER_LOGIN")
loadframe:SetScript("OnEvent",
   function(self,event,arg,...)
      if event == "PLAYER_LOGIN" then
         LittleScripts:RegisterCategories(LittleScripts:GetCategories(nil, true))
      elseif event == "ADDON_LOADED" and arg == "LittleScripts" then
         --call init functions for each module, replace noop functions
         __littlesaves = __littlesaves  or {}
         LittleScripts.__saveddata = __littlesaves
         LittleScripts.loaded = true
      end
   end
)