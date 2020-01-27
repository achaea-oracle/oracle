require "json"
require "luatable"


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
	IRE = {
		Rift = {
			List = {},
			Change = {},
		},
		Target = {
			Set = {},
			Info = {},
		},
	},
}
GMCPDeepUpdate = function(t1,t2)
	if type(t1)~="table" or type(t2)~="table" then
		return
	end
	if t1[1] or t2[1] then --table is an array
		t1 = t2 --replace with new array
	else
		for k,v in pairs(t2) do
			if type(v) == "table" then
				if type(t1[k]) ~= "table" then
					t1[k] = {}
				end
				t1[k] = GMCPDeepUpdate(t1[k], v)
			else
				t1[k] = v
			end
		end
	end
	return t1
end

function handle_GMCP(name, line, wc)
	local command = wc[1]
	local args = wc[2]
	GMCPTrackProcess(command,args)
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

--define tables and methods associated with inventory items
oracle.items = {}
oracle.items.inv = {}
oracle.items.inv.items = {}
oracle.items.inv.wielded = {}
function oracle.items.inv:setWielded(hand, item)
	if hand == "both" then
		self.wielded.both = { name = item.name, id = item.id }
		self.wielded.left = false
		self.wielded.right = false
	elseif hand == "left" then
		self.wielded.left = { name = item.name, id = item.id }
		self.wielded.both = false
	elseif hand == "right" then
		self.wielded.right = { name = item.name, id = item.id }
		self.wielded.both = false
	end
end

function oracle.items.inv:parse()
	for k,v in pairs(self.items) do
		self:parseSingle(v)
	end
end

function oracle.items.inv:parseSingle(item, toRemove) --toRemove is optional
	if not toRemove then
		if item.attrib and string.find(item.attrib, "lL") then
			self:setWielded("both", item )
		elseif item.attrib and string.find(item.attrib, "l") then
			self:setWielded("left", item )
		elseif item.attrib and string.find(item.attrib, "L") then
			self:setWielded("right", item)
		end
	else
		for k,v in pairs(self.wielded) do
			if v and v.id == item.id then
				self.wielded[k] = false
			end
		end
	end
end

function oracle.items.inv:add(item)
	self.items[item.id] = item
	self:parseSingle(item)
end

function oracle.items.inv:remove(item)
	self.items[item.id] = nil
	self:parseSingle(item, true)
end

--This section tracks state based on GMCP messages
GMCPTrack = GMCPTrack or {}

function GMCPTrackProcess(source, message)
	if string.find(source, "Display") then return end -- if

	oracle.debug.print(10, source .. " = " .. message)
	if not GMCPTrack[source] or type(GMCPTrack[source]) ~= "function" then
		return
	else
		GMCPTrack[source](message)
	end -- if
end -- function

GMCPTrack["Char.Status"] = function(message)
	local status = json.decode(message)
	if status.class then
		oracle.myClass = status.class
	end -- if
	GMCPDeepUpdate(gmcp.Char.Status, status)
end -- function

GMCPTrack["Char.Name"] = function(message)
	local name = json.decode(message)
	GMCPDeepUpdate(gmcp.Char.Name, name)
end -- function

GMCPTrack["Char.Vitals"] = function(message)
	local vitals = json.decode(message)
	GMCPDeepUpdate(gmcp.Char.Vitals, vitals)

	local stats = oracle.stats

	stats = stats or {}

		stats.lasthp = tonumber(stats.hp) or 0
	stats.hp = tonumber(vitals.hp) or stats.lasthp or 0
	stats.maxhp = tonumber(vitals.maxhp) or 0
	stats.deltahp = stats.hp - stats.lasthp
	stats.hppercent = percent(stats.hp, stats.maxhp)
	stats.deltahppercent = percent(stats.deltahp, stats.maxhp)
	stats.lastmp = tonumber(stats.mp) or 0
	stats.mp = tonumber(vitals.mp) or stats.lastmp or 0
	stats.maxmp = tonumber(vitals.maxmp) or 0
	stats.deltamp = stats.mp - stats.lastmp
	stats.mppercent = percent(stats.mp, stats.maxmp)
	stats.deltamppercent = percent(stats.deltamp, stats.maxmp)
	stats.lastep = tonumber(stats.ep) or 0
	stats.ep = tonumber(vitals.ep) or 0
	stats.lastwp = tonumber(stats.wp) or 0
	stats.wp = tonumber(vitals.wp) or 0

	-- special charstats --
	if vitals.charstats then
		oracle.charstats = {}
		for _,v in ipairs(vitals.charstats) do
			local k2, v2 = string.match(v, "(.+): (.+)")
			if k2 then
				oracle.charstats[k2] = tonumber(v2) or v2
			end
		end
	end
	local bleed = vitals.charstats[1]
	bleed = bleed:gsub("%d", "")
	stats.bleed = tonumber(bleed)
	local rage = vitals.charstats[2]
	rage = rage:gsub("%D", "")
	stats.rage = rage
end -- function

GMCPTrack["Char.Afflictions.List"] = function(message)
	gmcp.Char.Afflictions.List = json.decode(message)
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
	GMCPDeepUpdate(gmcp.Char.Afflictions.Add, json.decode(message))
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
	gmcp.Char.Defences.List = defsList
	for i,v in ipairs(defsList) do
		oracle.defs[v.name] = true
	end -- for
end -- function

GMCPTrack["Char.Defences.Add"] = function(message)
	oracle.defs = oracle.defs or {}
	local newDef = json.decode(message)
	GMCPDeepUpdate(gmcp.Char.Defences.Add, newDef)
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
	GMCPDeepUpdate(gmcp.Char.Items.List, itemList)
	if itemList.location == "room" then
		oracle.items.room = {}
		for _,v in ipairs(itemList.items) do
			oracle.items.room[v.id] = v
		end -- for
		mobs:parseRoomItems()
	elseif itemList.location == "inv" then
		oracle.items.inv.items = {}
		oracle.items.inv.wielded = {}
		for i,v in ipairs(itemList.items) do
			oracle.items.inv.items[v.id] = v
		end
		oracle.items.inv:parse()
	end
end -- function

GMCPTrack["Char.Items.Add"] = function(message)
	oracle.items = oracle.items or {}
	oracle.items.room = oracle.items.room or {}
	local itemToAdd = json.decode(message)
	GMCPDeepUpdate(gmcp.Char.Items.Add, itemToAdd)
	local attrib = itemToAdd.item.attrib
	if itemToAdd.location == "room" then
		oracle.items.room[itemToAdd.item.id] = itemToAdd.item
		if type(attrib) == "string" and string.match(attrib, "m") and not string.match(attrib, "x") and not string.match(attrib, "d") then
			mobs:add(itemToAdd.item)
		end -- if
	elseif itemToAdd.location == "inv" then
		oracle.items.inv:add(itemToAdd.item)
	end -- if
end -- function

GMCPTrack["Char.Items.Remove"] = function(message)
  oracle.items = oracle.items or {}
	oracle.items.room = oracle.items.room or {}
	local itemToRemove = json.decode(message)
	GMCPDeepUpdate(gmcp.Char.Items.Remove, itemToRemove)
	local attrib = itemToRemove.item.attrib
	if itemToRemove.location == "room" then
		oracle.items.room[itemToRemove.item.id] = nil
		if type(attrib)=="string" and string.match(attrib, "m") then
			mobs:remove(itemToRemove.item)
		end -- if
	elseif itemToRemove.location == "inv" then
		oracle.items.inv:remove(itemToRemove.item)
	end -- if
end -- function

GMCPTrack["Room.Info"] = function(message)
	local roomInfo = json.decode(message)
	GMCPDeepUpdate(gmcp.Room.Info, roomInfo)
	exits = {}
	for k,v in pairs(roomInfo.exits) do
		table.insert(exits, k)
	end -- for
end -- function

GMCPTrack["Room.Players"] = function(message)
	local players = json.decode(message)
	GMCPDeepUpdate(gmcp.Room.Players, players)
end -- function

GMCPTrack["Room.AddPlayer"] = function(message)
	local addPlayer = json.decode(message)
	GMCPDeepUpdate(gmcp.Room.AddPlayer, addPlayer)
end -- function

GMCPTrack["Room.RemovePlayer"] = function(message)
	local removePlayer = json.decode(message)
	gmcp.Room.RemovePlayer = removePlayer
end -- function

GMCPTrack["IRE.Rift.List"] = function(message)
	local riftItems = json.decode(message)
	gmcp.IRE.Rift.List = riftItems
	oracle.rift = oracle.rift or {}
	for k,v in pairs(riftItems) do
		oracle.rift[v.name] = v.amount
	end -- for
end -- function

GMCPTrack["IRE.Rift.Change"] = function(message)
	local riftItem = json.decode(message)
	GMCPDeepUpdate(gmcp.IRE.Rift.Change, riftItem)
	oracle.rift = oracle.rift or {}
	oracle.rift[riftItem.name] = tonumber(riftItem.amount)
end -- function

GMCPTrack["IRE.Target.Info"] = function(message)
	local targetInfo = json.decode(message)
	GMCPDeepUpdate(gmcp.IRE.Target.Info, targetInfo)
end -- function

GMCPTrack["Comm.Channel.List"] = function(message)
	local channels = json.decode(message)
	GMCPDeepUpdate(gmcp.Comm.Channel.List, channels)
end -- function

GMCPTrack["Comm.Channel.Text"] = function(message)
	local data = json.decode(message)
	local text = StripANSI(data.text)
	if text:startswith("(") then return end -- if

	local speaker = data.channel
 
	if string.find(speaker, "tell") then
		speaker = "tells"
	end -- if

	AddToHistory(speaker, false, StripANSI(data.text))
end -- function

GMCPTrack["IRE.Composer.Edit"] = function(message)
	local message = json.decode(message)
	local title = message.title
	local text = message.text:gsub("\n", "\r\n")
	text = utils.editbox("Enter your content below", title, text)
	if not text then
		SendNoEcho("*q")
		SendNoEcho("no")
	else
		CallPlugin("b007454f07bf5e41d15f15a0", "SendGMCPPacket", "IRE.Composer.SetBuffer {" .. text .. "}")
		SendNoEcho("*s")
	end -- if
end -- function
