local Scripts = {
	{
		PlacesIds = {2753915549, 4442272183, 7449423635},
		UrlPath = "BloxFruits.luau"
	},
	{
		PlacesIds = {10260193230},
		UrlPath = "MemeSea.luau"
	},
}

-- Cache environment and URLs
local _ENV = (getgenv or getrenv or getfenv)()
local fetcher, urls = {}, {}

-- URL configuration
urls.Owner = "https://raw.githubusercontent.com/sevi0306/"
urls.Repository = urls.Owner .. "Scripts/refs/heads/main/"

-- Debounce execution to prevent rapid successive runs
do
	local last_exec = _ENV.rz_execute_debounce
	
	if last_exec and (tick() - last_exec) <= 5 then
		return nil
	end
	
	_ENV.rz_execute_debounce = tick()
end

-- Teleport queue setup for script persistence
do
	local executor = syn or fluxus
	local queueteleport = queue_on_teleport or (executor and executor.queue_on_teleport)
	
	if not _ENV.rz_added_teleport_queue and type(queueteleport) == "function" then
		_ENV.rz_added_teleport_queue = true
		
		local ScriptSettings = {...}
		local SettingsCode = ""
		
		local success, encodedSettings = pcall(function()
			return game:GetService("HttpService"):JSONEncode(ScriptSettings)
		end)
		
		if success and encodedSettings then
			SettingsCode = "unpack(game:GetService('HttpService'):JSONDecode('" .. encodedSettings .. "'))"
		end
		
		local teleportScript = ("loadstring(game:HttpGet('%smain.luau'))(%s)"):format(urls.Repository, SettingsCode)
		pcall(queueteleport, teleportScript)
	end
end

-- Error handling and HTTP fetching utilities
do
	-- Clean up previous error messages
	if _ENV.rz_error_message then
		_ENV.rz_error_message:Destroy()
		_ENV.rz_error_message = nil
	end
	
	local identifyexecutor = identifyexecutor or function() return "Unknown" end
	
	local function CreateMessageError(text)
		-- Reset farming state
		_ENV.loadedFarm = nil
		_ENV.OnFarm = false
		
		-- Create error message
		local sanitizedText = string.gsub(text, urls.Owner, "")
		local message = Instance.new("Message")
		message.Text = sanitizedText
		message.Parent = workspace
		
		_ENV.rz_error_message = message
		error(text, 2)
	end
	
	local function formatUrl(url)
		for key, path in pairs(urls) do
			local pattern = "{" .. key .. "}"
			if url:find(pattern, 1, true) then
				return url:gsub(pattern, path, 1)
			end
		end
		return url
	end
	
	function fetcher.get(url)
		local formattedUrl = formatUrl(url)
		local success, response = pcall(function()
			return game:HttpGet(formattedUrl, true)
		end)
		
		if success then
			return response
		else
			CreateMessageError(string.format("[1] [%s] Failed to fetch URL: %s\nError: %s", 
				identifyexecutor(), formattedUrl, response))
		end
	end
	
	function fetcher.load(url, concat)
		local rawData = fetcher.get(url)
		if concat then
			rawData = rawData .. concat
		end
		
		local runFunction, errorText = loadstring(rawData)
		
		if type(runFunction) ~= "function" then
			CreateMessageError(string.format("[2] [%s] Syntax error in: %s\nError: %s", 
				identifyexecutor(), url, errorText))
		end
		
		return runFunction
	end
end

-- Utility function to check if current place matches script requirements
local function IsPlaceCompatible(scriptData)
	if scriptData.PlacesIds and table.find(scriptData.PlacesIds, game.PlaceId) then
		return true
	elseif scriptData.GameId and scriptData.GameId == game.GameId then
		return true
	end
	return false
end

-- Main execution loop
for _, scriptData in ipairs(Scripts) do
	if IsPlaceCompatible(scriptData) then
		local scriptUrl = "{Repository}Games/" .. scriptData.UrlPath
		local scriptLoader = fetcher.load(scriptUrl)
		return scriptLoader(fetcher, ...)
	end
end

-- Optional: Return a message if no compatible script found
warn("No compatible script found for current place: " .. game.PlaceId)
return nil
