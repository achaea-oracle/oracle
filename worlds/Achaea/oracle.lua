require "json"
require "luaTable" -- extra table functions
require "tprint" -- useful in global namespace

local path = require 'pl.path'
local seq = require 'pl.seq'
local stringx = require "pl.stringx"
local tablex = require "pl.tablex"

stringx.import()

-- Achaea imports --
require "achaea/communications"
require "achaea/gmcp"
require "achaea/goldtracker"
require "achaea/sound"

-- Define some variables --
savedir = path.abspath("worlds/achaea/")

-- Helper functions --
function ExecuteNoStack(cmd)
  local s = GetOption("enable_command_stack")
  SetOption("enable_command_stack", 0)
  Execute(cmd)
  SetOption("enable_command_stack", s)
end

-- Define oracle --
oracle = oracle or {}
oracle.affs = oracle.affs or {}
oracle.defs = oracle.defs or {}
oracle.items = oracle.items or {}
oracle.stats = oracle.stats or {}

-- debug functions --
oracle.debug = oracle.debug or {}
oracle.debug.level = 2 -- lower this before release

local levels = {
	[1] = { colour = "red", bg = "#00FF00", name = "ERROR" },
	[2] = { colour = "orangered", bg = "black", name = "WARNING" },
	[3] = { colour = "gold", bg = "black", name = "INFO" },
	[4] = { colour = "palegoldenrod", bg = "black", name = "DEBUG" },
	default = { colour = "lightgrey", bg = "black", name = "VERBOSE" },
}

oracle.debug.print = function(level, str)
	if oracle.debug.level >= level then
		local debugLevel = levels[level] or levels.default
		ColourNote(debugLevel.colour, debugLevel.bg, string.format("[%s]: %s", debugLevel.name, str))
	end -- if
end -- function

oracle.echo = function(what)
	Note("[Oracle]: "..what)
end -- function

-- listener --
oracle.listener = {}
oracle.listener.callbacks = {}
oracle.listener.callbackonce = {}

--listener returns true if it proceeds to the end
function oracle.listener:register(event, func, once)
	local t
	if type(event) ~= "string" or type(func) ~= "function" then
		return
	end -- if
	if not once then
		t = self.callbacks[event]
	else
		t = self.callbackonce[event]
	end -- if
	if not t or type(t) ~= "table" then
		t = {}
		if not once then
			self.callbacks[event] = t
		else
			self.callbackonce[event] = t
		end -- if
	end -- if
	for _,v in ipairs(t) do
		if v == func then
			return -- already registered
		end -- if
	end -- for
	table.insert(t, func)
	return true
end -- function

--call returns true if it proceeds to the end and none of the functions called raised errors, false otherwise
function oracle.listener:call(event, arg)
	if type(event) ~= "string" then
		return false
	end --if
	local t = self.callbacks[event]
	local t2 = self.callbackonce[event]
	local no_error = true
	if type(t) == "table" and #t > 0 then
		for i,v in ipairs(t) do
			no_error = pcall(v,arg) and no_error
		end	 -- for
	end -- if
	if type(t2) == "table" and #t2 > 0 then
		ColourNote("red", "blue", event)
		for i,v in ipairs(t2) do
			no_error = pcall(v,arg) and no_error
		end -- for
	end -- if
	self.callbackonce[event] = nil
	return no_error
end -- function

--unregister returns true if func was found and removed, nil if invalid argumetns, false otherwise
function oracle.listener:unregister(event, func, once)
	if type(event) ~= "string" or type(func) ~= "function" then
		return
	end -- if
	if not once then
		local t = self.callbacks[event]
	else
		local t = self.callbackonce[event]
	end -- if
	if type(t) ~= "table" or #t == 0 then
		return false
	else
		for i,v in ipairs(t) do
			if v == func then
				table.remove(t, i)
				return true
			end -- if
		end -- for
	end -- if
end -- function