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
oracle.debug.level = 10 -- lower this before release

local levels = {
	[1] = { color = "red", name = "ERROR" },
	[2] = { color = "OrangeRed", name = "WARNING" },
	[3] = { color = "gold", name = "INFO" },
	[4] = { color = "PaleGoldenrod", name = "DEBUG" },
	default = { color = "light_grey", name = "VERBOSE" },
}

oracle.debug.print = function(level, str)
	local debugLevel = levels[level]
	if oracle.debug.level >= level then
		Note(string.format("[%s]: %s", debugLevel[name], str)
	end -- if
end -- function

oracle.echo = function(what)
	Note("[Oracle]: "..what)
end -- function