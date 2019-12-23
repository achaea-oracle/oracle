require "json"

local path = require 'pl.path'
local seq = require 'pl.seq'
local stringx = require "pl.stringx"
local tablex = require "pl.tablex"

stringx.import()

-- Achaea imports --
require "achaea/gmcp"

-- Define some variables --
sdir = path.abspath("worlds/achaea/sounds/")
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

oracle.echo = function(what)
	Note("[Oracle]: "..what)
end -- function