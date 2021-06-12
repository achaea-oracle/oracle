--initialization

sqlite3 = require "lsqlite3complete"
ndb = ndb or {}
ndb.namedb, errCode, errMsg = sqlite3.open("ndb.sqlite3") --note that sqlite3.open creates file if it doesn't exist
--print("why?")
if not ndb.namedb then
  print(tostring(ndb.namedb), tostring(errCode), tostring(errMsg))
end

ndb.loaded = {}

--this is probably going to stay hardcoded since they don't really change
--need Wayward and divine colours
ndb.serverCityColours = {Hashan = 32896, Targossas = 16777215, Mhaldor = 255, Rogue = 12632256, Cyrene = 8421376, Eleusis = 65280, Ashtan = 8388736, Guides = 65535}

--TODO: convert this to a SQL table
ndb.cityColours = {Hashan = 32896, Targossas = 16777215, Mhaldor = 255, Rogue = 12632256, Cyrene = 8421376, Eleusis = 65280, Ashtan = 8388736, Guides = 65535} 

ndb.debugMode = false

ndb.debugPrint = function(...)
  if ndb.debugMode then
    print(...)
  else
    return
  end
end

local meta = getmetatable(ndb.namedb)
meta.exe = function(self, ...)
  local errCode = self:execute(...)
  ndb.debugPrint(...)
  ndb.debugPrint(errCode, self:errmsg())
  return errCode
end

ndb.defaultFGColour = 0xFFFFFF
ndb.defaultBGColour = 0

local colDefs = {name = "TEXT PRIMARY KEY",
                 city = "TEXT",
                 house = "TEXT",
                 dorder = "TEXT",
                 pirate = "INTEGER",
                 note = "TEXT",
                 date_added = "DATE",
                 date_modified = "DATE",
                 fg_colour = "INTEGER",
                 bg_colour = "INTEGER",
                }

function ndb:init()

  --make sure adventurers table exists and have suitable columns
  local status = self.namedb:exe(
[[
PRAGMA wal_checkpoint(FULL);
PRAGMA journal_mode = DELETE;
CREATE TABLE IF NOT EXISTS adventurers (
  name TEXT PRIMARY KEY,
  city TEXT,
  house TEXT,
  dorder TEXT,
  pirate INTEGER,
  note TEXT,
  date_added DATE,
  date_modified DATE,
  fg_colour INTEGER,
  bg_colour INTEGER,
  unique(name)
);
]]
)

	local stmt = self.namedb:prepare([[SELECT * FROM adventurers]])
	local existingColumns = stmt:get_names()

	local existingCols = {}
	for _,v in ipairs(existingColumns) do
		existingCols[v] = true
	end
	local missingCols = {}
	for k, v in pairs(colDefs) do
		if not existingCols[k] then
			missingCols[k] = v
		end
	end
	local addColTemplate = [[ALTER TABLE adventurers ADD COLUMN %s %s;]]
	for k,v in pairs(missingCols) do
		local alterStr = string.format(addColTemplate, k, v)
    --print(alterStr)
    self.namedb:exe(alterStr)
    --print(self.namedb:errmsg())
    --self.namedb:execute(string.format(addColTemplate, k, v))
	end
  
  --[[
  --read table into memory
  for row in db:nrows("SELECT * FROM adventurers") do
    ndb.loaded[row.name] = row
  end
  ]]
end --ndb:init

function ndb:addSimple(name,city)
  if not name or not city then
    return
  end
	
  return self:db_set({name = name, city = city})
end --ndb:add

function ndb:getPlayer(name)
  local player
  if type(name) ~= "string" then
    return
  end
  
  local result = self:db_query({{"name", name, "="}})
  if not result or not result[name] then
    return
  else
    self.loaded[name] = result[name]
    return result[name]
  end
end

--based on Nick Gammon's
local fixsql = function(s)
  if type(s) == "string" then
    s = s:gsub("'", "''")
  end
  return string.format("'%s'", s)
end

function ndb:db_set(values, alwaysInsert)
  if type(values) ~= "table" or not values.name then
    return
  end
  local name = values.name
  local columnList = {}
  local valueList = {}
  for k,v in pairs(values) do
    if colDefs[k] and k ~= "name" then
      table.insert(columnList, k)
      if type(v) == "string" then
        table.insert(valueList,fixsql(v))
      elseif type(v) == "boolean" then
        table.insert(valueList, v and 1 or 0)
      else
        table.insert(valueList, tostring(v))
      end
    end
  end
  
  local exists = false
  if not alwaysInsert then
    for row in self.namedb:nrows(string.format([[SELECT * FROM adventurers WHERE name = %s]], fixsql(name))) do
      exists = true
      break
    end
  end
  
  if not alwaysInsert and exists then -- we need to update instead of insert
    local setTable = {}
    if #columnList == 0 then -- nothing to update
      return
    else
      for i,v in ipairs(columnList) do
        if v ~= "name" then
          table.insert(setTable, string.format([[%s = %s]], v, valueList[i]))
        end
      end
    end
    self.namedb:exe(
      string.format(
        [[UPDATE adventurers
            SET %s
            WHERE name = %s;]],
        table.concat(setTable, ", "),
        fixsql(name)
        )
      )
  else
    table.insert(columnList, "name")
    table.insert(valueList, fixsql(name))
    return self.namedb:exe(
      string.format(
        [[REPLACE INTO adventurers(%s)
            VALUES(%s);]],
        table.concat(columnList, ", "),
        table.concat(valueList, ", ")
        )
      )
  end
  return ndb:getPlayer(name)
end

function ndb:db_query(conditions, columns, source)
  local results = {}
  if type(columns) == "table" then
    columns = table.concat(columns, ", ")
  else
    columns = "*"
  end
  
  source = source or "adventurers" --SQL table to select from
  
  conditionsTable = {}
  
  for i,v in ipairs(conditions) do
    if colDefs[v[1]] then
      if type(v[2]) == "string" then
        v[2] = fixsql(v[2])
      end
      table.insert(conditionsTable, string.format("%s %s %s", v[1], v[3], tostring(v[2])))
    end
  end

  for row in self.namedb:nrows(string.format([[SELECT %s FROM %s where %s;]], columns, source, table.concat(conditionsTable, " AND "))) do
    if row.name then
      results[row.name] = row
    else
      table.insert(results, row)
    end
  end
  return results
end 

function ndb:addHighlightTrigger(name, city)
  if not name or not city or not self.cityColours[city] then
    return
  end
  local nameTemplate = [[ndb_highlight_%s]]
  local matchTextTemplate = [[\b%s\b]]
  local responseText = nil
  local flags = 1 + 8 + 32
  local triggerName = string.format(nameTemplate, name)
  local matchText = string.format(matchTextTemplate, name)
  local triggerXML = {
    custom_colour = 17,
    enabled = true,
    group = "ndb_highlights",
    keep_evaluating = true,
    match = matchText,
    name = triggerName,
    regexp = true,
    sequence = 100,
  }
  addxml.trigger(triggerXML)
  SetTriggerOption(triggerName, "other_text_colour", self.cityColours[city])
  ndb.loaded[name] = city
end

ndb:init()

--[[
--test code
ndb:db_set({name = "Andraste", house = "Scions", city = "Eleusis",})
ndb:db_set({name = "Rollanz", house = "Sentinels", city = "Eleusis",})
ndb:db_set({name = "Artanis", house = "Heartwood", city = "Eleusis",})
ndb:db_set({name = "Logistics", house = "Sentinels", city = "Eleusis",})
ndb:db_set({name = "Oceana", house = "Druids", city = "Eleusis",})
ndb:db_set({name = "Shirszae", city = "Eleusis"})

local Artanis = ndb:db_query({{"name", "Artanis", "="}}, {"city"})
print(Artanis[1].city)

local Shirszae = ndb:db_query({{"name", "Shirszae", "="}}, {"city"})
for k,v in pairs(Shirszae[1]) do
 print(k, v)
end

ndb:db_set({name = "Adrik", city = "Hashan"})

local eleusians = ndb:db_query({{"city", "Eleusis", "="}})
for k,_ in pairs(eleusians) do
  print(k)
end

local eleusians_a = ndb:db_query({{"city", "Eleusis", "="}, {"name", "a%", "like"}})
for k,_ in pairs(eleusians_a) do
  print(k)
end

ndb:db_set({name = "Shirszae"})
Shirszae = ndb:db_query({{"name", "Shirszae", "="}}, {"city"})
print("Shirszae's city is", Shirszae[1].city)

ndb:db_set({name = "Shirszae"}, true)
Shirszae = ndb:db_query({{"name", "Shirszae", "="}}, {"city"})
print("Shirszae's city is", Shirszae[1].city)

ndb:db_set({name = "Adrik", city = "Eleusis"})

ndb:addSimple("Nyanko", "Eleusis")
local Nyanko = ndb:getPlayer("Nyanko")
for k,v in pairs(Nyanko) do
  print(k,v)
end
]]