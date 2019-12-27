function handleCommunications(n, l, wc)
local channel = wc[1]
local talker = wc[2]
local text = wc[3]
	AddToHistory(channel, talker, text)
end -- function

function AddToHistory(source, talker, message)
	if not talker then
		ExecuteNoStack("history_add " .. source .. "=" .. message)
	end -- if

	ExecuteNoStack("history_add "..source.."="..talker..": "..message)
end -- function