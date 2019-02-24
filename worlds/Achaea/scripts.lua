require "json"
sdir = ''
local seq = require 'pl.seq'
local stringx = require "pl.stringx"
local tablex = require "pl.tablex"

stringx.import()

-- Define gmcp tables --
gmcp = {
	Room = {
		Info = {},
		Mobs = {},
		Objects = {},
		Players = {},
	},
	Char = {
		Afflictions = {},
		Defences = {},
		Name = {},
		Status = {},
		Vitals = {},
	}
}

function handle_GMCP(name, line, wc)
  local command = wc[1]
  local args = wc[2]
  local handler_func_name = "handle_" .. command:lower():gsub("%.", "_")
  local handler_func = _G[handler_func_name]
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
	update = {}
	for k, v in pairs(data) do
		update[data[k].name] = v
	end -- for
	gmcp.Char.Afflictions = update
end -- function

function handle_char_afflictions_add(data)
	if string.find(data.name, "fracture") or string.find(data.name, "pressure") or string.find(data.name, "temper") then
		return
	end -- if
	gmcp.Char.Afflictions[data.name] = data
	-- Sound(sdir.."/afflictions/"..data.name..".ogg")
end -- function

function handle_char_afflictions_remove(data)
	for k, v in ipairs(data) do
		gmcp.Char.Afflictions[v] = nil
 end -- for
end -- function

function handle_char_defences_list(data)
	update = {}
	for k, v in pairs(data) do
		update[data[k].name] = v
	end -- for
	gmcp.Char.Defences = update
end -- function

function handle_char_defences_add(data)
		gmcp.Char.Defences[data.name] = data
end -- function

function handle_char_defences_remove(data)
	for k, v in ipairs(data) do
		gmcp.Char.Defences[v] = nil
 end -- for
end -- function


function handle_room_players(data)
	local update = {}
	for index, player in pairs(data) do
		update[player.name] = player
	end -- for
	gmcp.Room.Players = update
end --function

function handle_room_addplayer (data)
	gmcp.Room.Players[data.name] = data
end -- function

function handle_room_removeplayer(data)
  gmcp.Room.Players[data] = nil
end -- function

function handle_char_items_add (data)
  update = {}
  update[data.item.id] = data.item
	if data.location == 'room' then
		if IsMob(data.item) then
			tablex.update(gmcp.Room.Mobs, update)
    else
			tablex.update(gmcp.Room.Objects, update)
    end -- if
      end -- if
end -- function

function handle_char_items_remove (data)
	if data.location == 'room' then
		if IsMob(data.item) then
			gmcp.Room.Mobs[data.item.id] = nil
    else
			gmcp.Room.Objects[data.item.id] = nil
    end -- if
  end -- if
end -- function

function handle_char_items_list(data)
  Mobs = {}
  Objects = {}
  for index, item in ipairs(data.items) do
    if IsMob(item) then
			Mobs[item.id] = item
    else
			Objects[item.id] = item
    end -- if
  end -- for
  update = {
		Mobs = Mobs,
		Objects = Objects,
  }
	gmcp.Room.Objects = {}
	gmcp.Room.Mobs = {}
	tablex.update(gmcp.Room, update)
end -- function

function IsMob(obj)
	return obj.attrib and obj.attrib:startswith('m')
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

