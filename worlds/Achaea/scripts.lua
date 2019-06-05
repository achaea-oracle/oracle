require "json"

local path = require 'pl.path'
local seq = require 'pl.seq'
local stringx = require "pl.stringx"
local tablex = require "pl.tablex"

stringx.import()

-- Define some variables --
sdir = path.abspath("worlds/achaea/sounds/")
savedir = path.abspath("worlds/achaea/")

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
	}
}

function handle_GMCP(name, line, wc)
  local command = wc[1]
  local args = wc[2]
  local handler_func_name = "handle_" .. command:lower():gsub("%.", "_")
  local handler_func = _G[handler_func_name]
	GMCPTrackClass:Process(command,args)
  if handler_func == nil then
  --  Note("No handler " .. handler_func_name .. " for " .. command .. " " .. args)
  else
  --  Note("Processing " .. command .. " with arguments " .. args)
    handler_func(json.decode(args))
  end -- if
end -- function

function handle_room_info(data)
	tablex.update(gmcp.Room.Info, data)
end

function handle_char_name(data)
	tablex.update(gmcp.Char.Name, data)
end -- function

function handle_char_vitals(data)
	tablex.update(gmcp.Char.Vitals, data)
end -- function

function handle_char_status(data)
	tablex.update(gmcp.Char.Status, data)
end -- function

function handle_char_afflictions_list(data)
  
	tablex.update(gmcp.Char.Afflictions.List, data)
end -- function

function handle_char_afflictions_add(data)
	tablex.update(gmcp.Char.Afflictions.Add, data)
	Sound(sdir.."/afflictions/"..data.name..".ogg")
end -- function

function handle_char_afflictions_remove(data)
	gmcp.Char.Afflictions.Remove = data
end -- function

function handle_char_defences_list(data)
	tablex.update(gmcp.Char.Defences.List, data)
end -- function

function handle_char_defences_add(data)
		tablex.update(gmcp.Char.Defences.Add, data)
end -- function

function handle_char_defences_remove(data)
	gmcp.Char.Defences.Remove = data
end -- function


function handle_room_players(data)
	tablex.update(gmcp.Room.Players, data)
end --function

function handle_room_addplayer (data)
	tablex.update(gmcp.Room.AddPlayer, data)
end -- function

function handle_room_removeplayer(data)
	gmcp.Room.RemovePlayer = data
end -- function

function handle_char_items_add (data)
			tablex.update(gmcp.Char.Items.Add, data)
end -- function

function handle_char_items_remove (data)
			gmcp.Char.Items.Add[data.item.id] = nil
end -- function

function handle_char_items_list(data)
	tablex.update(gmcp.Char.Items.List, data)
end -- function

function IsMob(obj)
	return obj.attrib and obj.attrib:startswith('m')
end -- function

function handle_comm_channel_text(data)
	talker = data.channel
	if string.find(talker, "tell") then
	talker = "tells"
	end -- if

	AddToHistory(talker, StripANSI(data.text))
end -- function

function ItemNames(tbl)
  if tbl == nil then
    tbl = {}
  end -- if
  local names = {}
  for id, item in pairs(tbl) do
    names[#names+1] = item.name
  end -- for
  return names
end -- function

function AddToHistory(source, message)
ExecuteNoStack("history_add " .. source .. "=" .. message)
end

GMCPTrackClass = {
	MsgProcesses = {},
	affs = {},
	defs = {},
	vitals = {},
	status = {},
}

function GMCPTrackClass:new()
  local TrackTbl = TrackTbl or {}
	setmetatable(TrackTbl, self)
	self.__index = self
	return TrackTbl
end -- function

function GMCPTrackClass:Process(source, message)
  if not self.MsgProcesses[source] or type(self.MsgProcesses[source]) ~= "function" then
	  --Note(source .. " is not one of the modules enabled for state tracking via GMCP")
	  return
	else
	  self.MsgProcesses[source](message)
	end -- if
end -- function

function GMCPTrackClass:AffsList(message)
  self.affs = {}
	local affs_list = json.decode(message)
	for i,v in ipairs(affs_list) do
	  self.affs[v.name] = true
	end -- for
end -- function

GMCPTrackClass.MsgProcesses["Char.Afflictions.List"] = GMCPTrackClass:AffsList

function GMCPTrackClass:AffsAdd(message)
  self.affs = self.affs or {}
	local new_affs = json.decode(message)
	for i,v in ipairs(new_affs) do
	  self.affs[v.name] = true
	end -- for
end -- function

GMCPTrackClass.MsgProcesses["Char.Afflictions.Add"] = GMCPTrackClass:AffsAdd

function GMCPTrackClass:AffsRemove(message)
  self.affs = self.affs or {}
	local removed_affs = json.decode(message)
	for i,v in ipairs(removed_affs) do
	  self.affs[v.name] = false
	end -- for
end -- function

GMCPTrackClass.MsgProcesses["Char.Afflictions.Remove"] = GMCPTrackClass:AffsRemove

function GMCPTrackClass:DefsList(message)
	self.defs = {}
	local defs_list = json.decode(message)
	for i,v in ipairs(defs_list) do
		self.defs[v.name] = true
	end -- for
end -- function

GMCPTrackClass.MsgProcesses["Char.Defences.List"] = GMCPTrackClass:DefsList

function GMCPTrackClass:DefsAdd(message)
  self.defs = self.defs or {}
	local new_defs = json.decode(message)
	for i,v in ipairs(new_defs) do
	  self.defs[v.name] = true
	end -- for
end -- function

GMCPTrackClass.MsgProcesses["Char.Defences.Add"] = GMCPTrackClass:DefsAdd

function GMCPTrackClass:AffsRemove(message)
  self.defs = self.defs or {}
	local removed_defs = json.decode(message)
	for i,v in ipairs(removed_defs) do
	  self.defs[v.name] = false
	end -- for
end -- function

GMCPTrackClass.MsgProcesses["Char.Defences.Remove"] = GMCPTrackClass:DefsRemove

function GMCPTrackClass:GetAffs()
	return self.affs
end -- function

function GMCPTrackClass:GetDefs()
	return self.defs
end -- function

function GMCPTrackClass:CheckAff(affname)
  if not self.affs then
	  Note("Unable to check for affliction: no affs table found")
		return
	end -- if
	if not self.affs[affname] then
	  return false
	else
	  return true
	end --if
end -- function

function GMCPTrackClass:CheckDef(defname)
  if not self.defs then
	  Note("Unable to check for affliction: no affs table found")
		return
	end -- if
	if not self.defs[defname] then
	  return false
	else
	  return true
	end --if
end -- function


	
-- Helper functions --
function ExecuteNoStack(cmd)
  local s = GetOption("enable_command_stack")
  SetOption("enable_command_stack", 0)
  Execute(cmd)
  SetOption("enable_command_stack", s)
end

