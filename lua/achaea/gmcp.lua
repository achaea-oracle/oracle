require "json"
local tablex = require "pl.tablex"

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
  GMCPTrackProcess(command,args)
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
	local text = StripANSI(data.text)
	if text:startswith("(") then return end -- if

	local speaker = data.channel
 
	if string.find(speaker, "tell") then
	speaker = "tells"
 end -- if

 AddToHistory(speaker, false, StripANSI(data.text))
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

GMCPTrack["Char.Afflictions.List"] = function(message)
  oracle.affs = {}
	local affsList = json.decode(message)
	for i,v in ipairs(affsList) do
	  oracle.affs[v.name] = true
	end -- for
end -- function

GMCPTrack["Char.Afflictions.Add"] = function(message)
  oracle.affs = oracle.affs or {}
  local newAff = json.decode(message)
  oracle.affs[newAff.name] = true
end -- function

GMCPTrack["Char.Afflictions.Remove"] = function(message)
  oracle.affs = oracle.affs or {}
  affRemoveString=message
  removedAffs = json.decode(message)
  for i,v in ipairs(removedAffs) do
    oracle.affs[v] = false
  end -- for
end -- function

GMCPTrack["Char.Defences.List"] = function(message)
	oracle.defs = {}
	local defsList = json.decode(message)
	for i,v in ipairs(defsList) do
		oracle.defs[v.name] = true
	end -- for
end -- function

GMCPTrack["Char.Defences.Add"] = function(message)
  oracle.defs = oracle.defs or {}
  local newDef = json.decode(message)
  oracle.defs[newDef.name] = true
end -- function

GMCPTrack["Char.Defences.Remove"] = function(message)
  oracle.defs = oracle.defs or {}
	local removedDefs = json.decode(message)
	for i,v in ipairs(removedDefs) do
	  oracle.defs[v] = false
	end -- for
end -- function

