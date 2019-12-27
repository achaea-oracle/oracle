-- Random bits that MUSHclient doesn't have --

function fileExists(filename)
 local file = io.open(filename)
 if file then
 io.close(file)
 return true
 else
 return false
 end
end

function fsize (file)
 local file=io.open(file)
 if file then
 file:seek() -- get current position
 local size = file:seek("end") -- get file size
 file:close()
 return size
 else
 return nil
 end
end

function table.contains(tbl, what)
 for k, v in pairs(tbl) do
 if v == what or k == what then 
 return true
 end
 end
 return false
end

function table.index_of(tbl, what)
 for i, v in ipairs(tbl) do
 if v == what then return i end
 end
 return false
end

function table.keys(tbl)
 local keyset={}
 local n=0

 for k,v in pairs(tbl) do
  n=n+1
  keyset[n]=k
 end -- for

 return keyset
end -- function

function table.save(table, tname)
if (table==nil) then return end -- if

	if type(table) == "string" then
		if type(tname) ~= "string" then
			tname = table
		end -- if
	end -- if

	local t = _G[tname]

local vars=savedir.."/"..tname..".ach"
local exfw=assert(io.open(vars, "w"))
exfc=serialize.save_simple(t)
assert (exfw:write (tname.." = "..exfc))
exfw:close()
end -- function

function table.load(filename)
 local f = loadfile(filename)
 if (f == nil) then
 Note("File '" .. filename .. "' appears to be corrupt. Ignoring.")
 else
 return f()
 end
end

function loadSettingsFile(filename)
 local file = savedir.."/"..filename..".ach"
 table.load(file)
end -- function
