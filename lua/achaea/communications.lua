function handleCommunications(n, l, wc)
local channel = wc[1]
local talker = wc[2]
local text = wc[3]
	AddToHistory(channel, talker, text)
end -- function

function AddToHistory(source, speaker, message)
	if not speaker then
		ExecuteNoStack("history_add " .. source .. "="..message)
		return
	end -- if

	ExecuteNoStack("history_add "..source.."="..speaker..": "..message)
end -- function