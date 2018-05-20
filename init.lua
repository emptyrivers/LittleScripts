-- Copyright © 2018 Allen Faure. See LICENSE.md for details.

-- this part defines the framework of the addon.

LittleScripts = {
   __modules = {},
}


local function dummy() end

function LittleScripts:Debug(msg, lvl, api)
   lvl, api = lvl or 2, api or ConsoleAddMessage
   if lvl >= self.debuglvl then
      return api(msg)
   end
end

LittleScripts.debuglvl = 1

local __categories = {
   DAMAGER = {},
   HEALER  = {},
   TANK    = {},
   GENERAL = {},
}

for i = 1, GetNumClasses() do
   local localised_name, name = GetClassInfo(i)
   local classCategory = {}
   __categories[localised_name], __categories[name], __categories[i] = classCategory, classCategory, classCategory
   for j = 1, GetNumSpecializationsForClassID(i) do
      local specCategory = {}
      local specID, specname = GetSpecializationInfoForClassID(i,j)
      __categories[specID], __categories[specname] = specCategory, specCategory
   end
end

LittleScripts.__categories = __categories

function LittleScripts:AddModule(name, module, category, overrideAPI)
   -- ensure sanity
   if type(name) ~= 'string' then
      self:debug("LittleScripts: Improper argument #1 to AddModule: name must be a string.", 4, error)
   elseif type(module) ~= 'table' then
      self:debug("LittleScripts: Improper argument #2 to AddModule: module must be a table.", 4, error)
   elseif category ~= nil and type(category) ~= 'string' and type(category) ~= 'number' and type(category) ~= 'table' then
      self:debug("LittleScripts: Improper argument #3 to AddModule: category must be a string, table, or number if provided.", 4, error)
   elseif LittleScripts.__modules[name] then
      self:debug("LittleScripts: A module by the name of "..name.." already exists.", 4, error)
   elseif module.Init ~= nil and type(module.Init) ~= 'function' then
      self:debug("LittleScripts: "..name.." has invalid type "..type(module.Init).." for Init method.", 4, error)
   elseif module.Enable ~= nil and type(module.Enable) ~= 'function' then
      self:debug("LittleScripts: "..name.." has invalid type "..type(module.Init).." for Enable method.", 4, error)
   elseif module.Disable ~= nil and type(module.Disable) ~= 'function' then
      self:debug("LittleScripts: "..name.." has invalid type "..type(module.Init).." for Disable method.", 4, error)
   elseif type(module.scripts) ~= 'table' then
      self:debug("LittleScripts: "..name.." has invalid type "..type(module.Init).." for scripts attribute.", 4, error)
   end
   for _, method in pairs{"Init", "Enable", "Disable"} do
      module[method] = module[method] or dummy
   end
   self.__modules[name] = module
   if module.api then
      for name, func in pairs(module.api) do
         if overrideAPI or not self[name] then
            self[name] = func
            if self[name] then
               self:debug("Littlescripts - Warning: module "..name.." has added API method "
                          ..k.." which already exists. This may produce unpredictable results.")
            end
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
   module.loaded = true
end

function LittleScripts:GetCategories(id, includeGeneric)
   -- returns spec, class, and (if requested) role categories, as well as generic category
   if id == nil then
      local specID, classID, _, _, role = GetSpecializationInfo(GetSpecialization())
      return {class = classID, spec = specID, role = role, generic = includeGeneric and "GENERIC" or nil}
   elseif type(id) == 'number' then 
      if not GetClassInfo(id) then -- specID, probably
         local _, classID, _, _, role = GetSpecializationInfoByID(id)
         if not classID then return end
         return {class = classID, spec = id, role = role, generic = includeGeneric  and "GENERIC" or nil}
      else  -- classID
         local toReturn = {
            class = classID,
            generic = includeGeneric  and "GENERIC" or nil,
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