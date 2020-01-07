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
