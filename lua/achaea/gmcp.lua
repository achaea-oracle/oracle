require "json"
local tablex = require "pl.tablex"

oracle = oracle or {}
-- Define gmcp tables --
gmcp = {
	Room = {
		AddPlayer = {},
			Info = {},
		Players = {},
	},
	Char = {
		Afflictions = {
			Add = {},
			List = {},
		},
		Defences = {
			Add = {},
			List = {},
		},
		Items = {
			Add = {
				item = {},
			},
			List = {},
			Remove = {},
			Update = {},
		},
		Name = {},
		Skills = {
			Groups = {},
			List = {},
			Info = {},
	},
	Status = {},
	Vitals = {},
	},
	Comm = {
		Channel = {
			List = {},
		},
	},
}

function handle_GMCP(name, line, wc)
	local command = wc[1]
	local args = wc[2]
	GMCPTrackProcess(command,args)
end -- function


function handle_comm_channel_text(data)
	local text = StripANSI(data.text)
	if text:startswith("(") then return end -- if

	local speaker = data.channel
 
	if string.find(speaker, "tell") then
		speaker = "tells"
	end -- if

	AddToHistory(speaker, false, StripANSI(data.text))
end -- function

--This section defines the mobs table
--mobs
oracle.mobs = oracle.mobs or {}
local mobs = oracle.mobs
mobs.list = {}

function mobs:add(mob)
	if not mob or not mob.id then
		return
	end
	for i,v in ipairs(self.list) do
		if v.id == mob.id then
			return
		end
	end
	self.list[#self.list + 1] = mob
end

function mobs:remove(mob)
	if not mob or not mob.id then
		return
	end
	for i,v in ipairs(self.list) do
		if v.id == mob.id then
			table.remove(self.list, i)
			return
		end
	end
end

function mobs:clear()
	self.list = {}
end

function mobs:parseRoomItems()
	if not oracle.items or not oracle.items.room then
		return
	end
	self:clear()
	for k,v in pairs(oracle.items.room) do
		if type(v.attrib) == "string" then
			if string.match(v.attrib, "m") and not string.match(v.attrib, "x") and not string.match(v.attrib, "d") then
				mobs.list[#mobs.list + 1] = v
			end
		end
	end
end

--This section tracks state based on GMCP messages

GMCPTrack = GMCPTrack or {}

function GMCPTrackProcess(source, message)
	--Note(source .. " = " .. message)
	if not GMCPTrack[source] or type(GMCPTrack[source]) ~= "function" then
		return
	else
		GMCPTrack[source](message)
	end -- if
end -- function

GMCPTrack["Char.Status"] = function(message)
	local status = json.decode(message)
	tablex.update(gmcp.Char.Status, status)
end -- function

GMCPTrack["Char.Name"] = function(message)
	local name = json.decode(message)
	tablex.update(gmcp.Char.Name, name)
end -- function

GMCPTrack["Char.Vitals"] = function(message)
	local vitals = json.decode(message)
	tablex.update(gmcp.Char.Vitals, vitals)
end -- function

GMCPTrack["Char.Afflictions.List"] = function(message)
	tablex.update(gmcp.Char.Afflictions.List, json.decode(message))
	if oracle.affs and oracle.affs.pressure then
		local pressLevel = oracle.affs.pressure
	end -- if
	oracle.affs = {}
	local affsList = json.decode(message)
	for i,v in ipairs(affsList) do
		local name, level = string.match(v.name, "(%a+) %((%d+)%)")
		if name and level then
			oracle.affs[name] = tonumber(level)
		elseif v.name == "pressure" then
			if pressLevel then
				oracle.affs[v.name] = pressLevel
			else
				oracle.affs[v.name] = 1
			end -- if
		else
			oracle.affs[v.name] = true
		end --if
	end -- for
end -- function

GMCPTrack["Char.Afflictions.Add"] = function(message)
	tablex.update(gmcp.Char.Afflictions.Add, json.decode(message))
	oracle.affs = oracle.affs or {}
	local newAff = json.decode(message)
	local name, level = string.match(newAff.name, "(%a+) %((%d+)%)")
	if name and level then
		oracle.affs[name] = tonumber(level)
	else
		oracle.affs[newAff.name] = true
	end --if
end -- function

GMCPTrack["Char.Afflictions.Remove"] = function(message)
	oracle.affs = oracle.affs or {}
	affRemoveString=message
	removedAffs = json.decode(message)
	gmcp.Char.Afflictions.Remove = removedAffs
	for i,v in ipairs(removedAffs) do
		local name, level = string.match(v, "(%a+) %((%d+)%)")
		if name and level then
			oracle.affs[name] = tonumber(level) - 1
			if oracle.affs[name] <= 0 then
				oracle.affs[name] = false
			end -- if
		else
			oracle.affs[v] = false
		end --if
	end -- for
end -- function

GMCPTrack["Char.Defences.List"] = function(message)
	oracle.defs = {}
	local defsList = json.decode(message)
	tablex.update(gmcp.Char.Defences.List, defsList)
	for i,v in ipairs(defsList) do
		oracle.defs[v.name] = true
	end -- for
end -- function

GMCPTrack["Char.Defences.Add"] = function(message)
	oracle.defs = oracle.defs or {}
	local newDef = json.decode(message)
	tablex.update(gmcp.Char.Defences.Add, newDef)
	oracle.defs[newDef.name] = true
end -- function

GMCPTrack["Char.Defences.Remove"] = function(message)
	oracle.defs = oracle.defs or {}
	local removedDefs = json.decode(message)
	gmcp.Char.Defences.Remove = removedDefs
	for i,v in ipairs(removedDefs) do
		oracle.defs[v] = false
	end -- for
end -- function

GMCPTrack["Char.Items.List"] = function(message)
	oracle.items = oracle.items or {}
	local itemList = json.decode(message)
	tablex.update(gmcp.Char.Items.List, itemList)
	if itemList.location == "room" then
		oracle.items.room = {}
		for _,v in ipairs(itemList.items) do
			oracle.items.room[v.id] = v
		end -- for
		mobs:parseRoomItems()
	end -- if
end -- function

GMCPTrack["Char.Items.Add"] = function(message)
	oracle.items = oracle.items or {}
	oracle.items.room = oracle.items.room or {}
	local itemToAdd = json.decode(message)
	tablex.update(gmcp.Char.Items.Add, itemToAdd)
	local attrib = itemToAdd.item.attrib
	if itemToAdd.location == "room" then
		oracle.items.room[itemToAdd.item.id] = itemToAdd.item
		if string.match(attrib, "m") and not string.match(attrib, "x") and not string.match(attrib, "d") then
			mobs:add(itemToAdd.item)
		end -- if
	end -- if
end -- function

GMCPTrack["Char.Items.Remove"] = function(message)
  oracle.items = oracle.items or {}
	oracle.items.room = oracle.items.room or {}
	local itemToRemove = json.decode(message)
	tablex.update(gmcp.Char.Items.Remove, itemToRemove)
	local attrib = itemToRemove.item.attrib
	if itemToRemove.location == "room" then
		oracle.items.room[itemToRemove.item.id] = nil
		if string.match(attrib, "m") then
			mobs:remove(itemToRemove.item)
		end -- if
	end -- if
end -- function

