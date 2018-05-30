-- Copyright © 2018 Allen Faure. See LICENSE.md for details.

-- integration with WeakAuras
-- since these methods require WeakAuras to be installed, we keep them in a separate file

if not WeakAuras then return end

function LittleScripts:RegisterCategories(categories, force)
   for _, category in pairs(categories) do
      local data = self.__categories[category]
      self:debug('registering category '..category)
      if data and (force or next(data.__auras)) then
         WeakAuras.RegisterAddon(data.__name, data.__desc, data.__desc, data.__icon)
         for _, auraData in pairs(data.__auras) do
            WeakAuras.RegisterDisplay(data.__name, auraData)
         end
      end
   end
end

function LittleScripts:RegisterAllCategories(force)
   local registered = {}
   for _, data in pairs(self.__categories) do
      if not registered[data] and (force or next(data.__auras)) then
         registered[data] = true
         WeakAuras.RegisterAddon(data.__name, data.__desc, data.__desc, data.__icon)
         for _, auraData in pairs(data.__auras) do
            WeakAuras.RegisterDisplay(data.__name, auraData)
         end
      end
   end
end

function LittleScripts:RegisterDisplay(category, auraData)
   if self.__categories[category] then
      WeakAuras.RegisterDisplay(category, auraData)
   end
end


function LittleScripts:DataTemplate(name, regionType, numTriggers)
   local toReturn = {
      id = "name",
      regionType = regionType or "icon",
      numTriggers = numTriggers or 1,
      additional_triggers = numTriggers and numTriggers > 1 and {} or nil,
      animation = {
         start  = {type = "none", duration_type = "seconds"},
         main   = {type = "none", duration_type = "seconds"},
         finish = {type = "none", duration_type = "seconds"},
      },
      actions = {
         init = {},
         start = {},
         finish = {},
      },
      load = {},
      conditions = {},
      untrigger = {},
      activeTriggerMode = WeakAuras.trigger_modes.first_active,
      disjunctive = "all",
   }
end