_VERSION = [[Version 3.141 - October 31, 2019]]
_REPO_EDITION = [[Install Reactor Version π (3.14)]]
--[[
==============================================================================
Reactor Installer - v3.141 2019-10-31
==============================================================================
Requires    : Fusion v9.0.2 to v16.1+ or Resolve v15 to v16.1+
Created By  : Andrew Hazelden [andrew@andrewhazelden.com]

==============================================================================
Overview
==============================================================================

Reactor is a package manager for Fusion and Resolve. Reactor streamlines the installation of 3rd party content through the use of "Atom" packages that are synced automatically with a Git repository.

The Reactor Installer script can be dragged from a folder on your desktop into the Fusion Console tab or the Resolve Fusion page "Nodes" view.

A Reactor install dialog will appear and Reactor will be installed automatically. Alternatively, you could paste the Reactor Installer Lua script code into the Fusion Console tab text input field manually and the installer script will be run.

Reactor Announcement Page:
https://www.steakunderwater.com/wesuckless/viewtopic.php?p=13348#p13348

Reactor Support Forum:
https://www.steakunderwater.com/wesuckless/viewforum.php?f=32

Reactor GitLab Public Repository:
https://gitlab.com/WeSuckLess/Reactor

==============================================================================
Reactor Installer Usage
==============================================================================

Step 1. Drag the Reactor-Installer.lua script from your desktop into the Fusion Standalone or the Resolve Fusion page "Console" view. Alternatively, you could copy and then paste the Reactor Installer Lua script code into the Fusion Console tab text input field manually and the installer script will be run.

Note: Fusion Standalone v16.1 Beta and Resolve v16.1 Beta seem to have an issue with dragging the Reactor installer script from your desktop folder to the Nodes view to run it automatically so you will have to open the Console window to drag and drop run the script until this issue is solved.

Step 2. Click the "Install and Launch" button.

The Reactor.fu file will be downloaded from GitLab and saved into the "Config:/Reactor.fu" folder.

The GitLab repo string is then written into a new "AllData:Reactor:/System/Reactor.cfg" file that is used to control what GitLab repositories are used with Reactor.

When the installer finishes, Fusion will open the Reactor Package Manager so it is ready for use. 

If you are running Fusion Standalone v9-16.1+ you will see Reactor installed under the "Script > Reactor > Open Reactor..." menu immediately after the installer completes. The root level Reactor menu will only appear after you re-launch Fusion once since it is added by a "Reactor.fu" file. :D

In Resolve you can launch Reactor from the "Workspaces > Scripts > Reactor > Open Reactor..." menu item. The Reactor menu items will be installed to "Reactor:/System/Scripts/Comp/Reactor/".

Step 3. When you open the Reactor Package Manager window in the future using the "Reactor > Open Reactor..." menu item the tool will sync up with the GitLab website and download the newest details about the git commits that have happened on the Reactor repository since the last time you ran the tool.

This sync information is all stored in the Reactor:/ folder on disk.

==============================================================================
Reactor Technical Details
==============================================================================

The Lua based Reactor Installer script uses Fusion's built in cURL library to make a port 80 HTTP connection to the GitLab.com website to download the config Reactor.fu file, and the Reactor.lua lua script file. This script connects to the GitLab Reactor repository page to download the resources.

Your firewall has to allow this network connection to happen if you want to install Reactor.

Reactor saves the downloaded and installed content to the Reactor:/ PathMap location in Fusion which is also known as AllData:/Reactor:/

To install Reactor successfully you have to allow for administrative write permissions to the AllData:/ folder so Fusion will be able to create the initial Reactor folder that the downloaded content is placed inside of.


The AllData:/Reactor:/ folder is located here:


Fusion Paths

Windows Reactor Path:

C:\ProgramData\Blackmagic Design\Fusion\Reactor\


Mac Reactor Path:

/Library/Application Support/Blackmagic Design/Fusion/Reactor/


Linux Reactor Path:

/var/BlackmagicDesign/Fusion/Reactor/



Resolve Paths

Windows Reactor Path:

C:\ProgramData\Blackmagic Design\DaVinci Resolve\Fusion\Reactor\


Mac Reactor Path:

/Library/Application Support/Blackmagic Design/DaVinci Resolve/Fusion/Reactor/


Linux Reactor Path:

/var/BlackmagicDesign/DaVinci Resolve/Fusion/Reactor/



When the Reactor package manager window is opened up and is running inside of Fusion, the atom packages are downloaded and synced from the same GitLab repository as the original Reactor installation files were downloaded from.

The installed files you select inside of the Reactor Package Manager window are saved to Reactor:/Deploy/

If you are curious about the open source technology behind Reactor and how it works you can check out the Reactor.fu and Lua script files, along with the atom packages on the Reactor GitLab Public Repository page here:

https://gitlab.com/WeSuckLess/Reactor

==============================================================================
Environment Variables
==============================================================================

The `REACTOR_BRANCH` environment variable can be set to a custom value like "dev" to override the default master branch setting for syncing with the GitLab repo:

export REACTOR_BRANCH=dev

Note: If you are using macOS you will need to use an approach like a LaunchAgents file to define the environment variables as Fusion + Lua tends to ignore .bash_profile based environment variables entries.

The `REACTOR_INSTALL_PATHMAP` environment variable can be used to change the Reactor installation location to something other then the default PathMap value of "AllData:"

export REACTOR_INSTALL_PATHMAP=AllData:
]]--

-- Add the Reactor Public ProjectID to Reactor.cfg
local reactor_project_id = "5058837"


-- Check the "REACTOR_BRANCH" environment variable to find out which GitLab branch should be used (master/dev/)
local branch = os.getenv("REACTOR_BRANCH")
if branch == nil then
	branch = "master"
end

-- Add the platform specific folder slash character
local osSeparator = package.config:sub(1,1)

-- Check for a pre-existing PathMap preference
local reactor_existing_pathmap = fusion:GetPrefs("Global.Paths.Map.Reactor:")
if reactor_existing_pathmap and reactor_existing_pathmap ~= "nil" then
	-- Clip off the "reactor_root" style trailing "Reactor/" subfolder
	reactor_existing_pathmap = string.gsub(reactor_existing_pathmap, "Reactor" .. osSeparator .. "$", "")
end

-- Default Reactor install location
local reactor_pathmap = os.getenv("REACTOR_INSTALL_PATHMAP") or reactor_existing_pathmap or "AllData:"

function dprint(str)
	-- Display the debug output in the Console tab
	local cmp = fusion.CurrentComp
	if cmp then
		cmp:Print(tostring(str) .. "\n\n")
	else
		print(tostring(str) .. "\n")
	end

	-- Add the platform specific folder slash character
	local osSeparator = package.config:sub(1,1)
	
	-- Return a string with the directory path where the Lua script was run from
	-- If the script is run by pasting it directly into the Fusion Console define a fallback path
	local fallbackPath = fusion:MapPath("Temp:/Reactor/")
	local reactor_install_log_root = ""
	if debug.getinfo(1).source == "???" then
		-- Fallback absolute filepath
		reactor_install_log_root = fallbackPath
	else
		-- Filepath coming from the Lua script's location on disk
		local debugPath = string.sub(debug.getinfo(1).source, 2) or fallbackPath
		reactor_install_log_root = string.match(debugPath, "^(.+[/\\])")
	end

	local reactor_log = reactor_install_log_root .. "ReactorInstallLog.txt"
	eyeon.createdir(reactor_install_log_root)
	log_fp, err = io.open(reactor_log, "a")
	if err then
		print("[Log Error] Could not open ReactorInstallLog.txt for writing")
	else
		time_stamp = os.date('[%Y-%m-%d|%I:%M:%S %p] ')
		log_fp:write("\n" .. time_stamp)
		log_fp:write(str)
		log_fp:close()
	end
end


-- Download a file using cURL + FFI
-- Example: DownloadURL(fuURL, fuDestFilename, shortFilename, msgwin, msgitm, "Installation Status", statusMsg, 2, totalSteps, 1)
function DownloadURL(url, fuDestFilename, shortFilename, win, itm, title, text, progressLevel, progressMax, delaySeconds)
	local req = ezreq(url)
	local body = {}
	req:setOption(curl.CURLOPT_SSL_VERIFYPEER, 0)
	req:setOption(curl.CURLOPT_WRITEFUNCTION, ffi.cast("curl_write_callback", function(buffer, size, nitems, userdata)
		table.insert(body, ffi.string(buffer, size*nitems))
		return nitems
	 end))

	text = "[Download URL]\n" .. tostring(url)
	ProgressWinUpdate(win, itm, title, text, progressLevel, progressMax, delaySeconds)

	ok, err = req:perform()
	if ok then
		-- Write the output to the terminal
		if os.getenv("REACTOR_DEBUG_FILES") == "true" then
			dprint(table.concat(body))
		end

		-- Check if the file was downloaded correctly
		if table.concat(body) == [[{"message":"401 Unauthorized"}]] then
			text = "[Error] The \"Token ID\" field is empty. Please enter a GitLab personal access token and then click the \"Install and Launch\" button again.\n"
			errwin,erritm = ErrorWin("Installation Error", text)
			win:Hide()
			errwin:Hide()
			exit()
			return
		elseif table.concat(body) == [[{"message":"404 Project Not Found"}]] then
			text = "[Error] The \"Token ID\" field is empty. Please enter a GitLab personal access token and then click the \"Install and Launch\" button again.\n"
			errwin,erritm = ErrorWin("Installation Error", text)
			win:Hide()
			errwin:Hide()
			exit()
			return
		elseif table.concat(body) == [[{"message":"404 File Not Found"}]] then
			text = "[Error] The main Reactor GitLab file has been renamed. Please download and install a new Reactor Bootstrap Installer script or you can try manually installing the latest Reactor.fu file.\n"
			errwin,erritm = ErrorWin("Installation Error", text)
			win:Hide()
			errwin:Hide()
			exit()
			return
		elseif table.concat(body) == [[{"error":"invalid_token","error_description":"Token was revoked. You have to re-authorize from the user."}]] then
			text = "[Error] Your GitLab TokenID has been revoked. Please enter a new TokenID value in your Reactor.cfg file, or switch to the Reactor Public repo and remove your existing Reactor.cfg file.\n"
			errwin,erritm = ErrorWin("Installation Error", text)
			win:Hide()
			errwin:Hide()
			exit()
			return
		elseif table.concat(body) == [[{"message":"404 Commit Not Found"}]] then
			text = "[Error] GitLab Previous CommitID Empty Error. Please remove your existing Reactor.cfg file and try again. Alternativly, you may have a REACTOR_BRANCH environment variable active and it is requesting a branch that does not exist.\n"
			errwin,erritm = ErrorWin("Installation Error", text)
			win:Hide()
			errwin:Hide()
			exit()
			return
		elseif table.concat(body) == [[{"error":"insufficient_scope","error_description":"The request requires higher privileges than provided by the access token.","scope":"api"}]] then
			text = "[Error] GitLab TokenID Permissions Scope Error. Your current GitLab TokenID privileges do not grant you access to this repository.\n"
			errwin,erritm = ErrorWin("Installation Error", text)
			win:Hide()
			errwin:Hide()
			exit()
			return
		end

		-- Save file to disk
		local fuFile = io.open(fuDestFilename, "w")
		if fuFile ~= nil then
			fuFile:write(table.concat(body))
			fuFile:close()

			text = "[" .. shortFilename .. " Saved] " .. fuDestFilename .. "\n"
			ProgressWinUpdate(win, itm, "Installation Status", text, progressLevel, progressMax, delaySeconds)
		else
			text = "[" .. shortFilename .. "Write Error] " .. fuDestFilename .. "\n"
			errwin,erritm = ErrorWin("Installation Error", text)
			win:Hide()
			errwin:Hide()

			exit()
			return
		end
	end
end


-- The Install & Launch button was pressed
function Install(token)
	-- ==============================================================================
	-- Setup the installation variables
	-- ==============================================================================
	local sysPath = app:MapPath(tostring(reactor_pathmap) .. "Reactor/System/")

	local fuURL = "https://gitlab.com/api/v4/projects/" .. reactor_project_id .. "/repository/files/Reactor%2Efu/raw?ref=" .. branch .. "&private_token=" .. token
	local fuDestFile = app:MapPath("Config:/Reactor.fu")
	local cfgDestFile = sysPath .. "Reactor.cfg"

	-- Save a copy of the Reactor.lua script to be autorun on the first boot of Reactor
	local luaURL = "https://gitlab.com/api/v4/projects/" .. reactor_project_id .. "/repository/files/System%2FReactor%2Elua/raw?ref=" .. branch .. "&private_token=" .. token
	local tempPath = app:MapPath("Temp:/Reactor/")
	bmd.createdir(tempPath)

	local autorunLuaDestFile = sysPath .. "Reactor.lua"

	-- Delay in seconds
	statusDelay = 1
	-- ==============================================================================
	-- Create the installer progress window
	-- ==============================================================================

	-- Number of steps in the HTML progress bar
	totalSteps = 8

	-- Show the intital progress window
	local msgwin,msgitm = ProgressWinCreate()

	statusMsg = "[Downloads Started]"
	ProgressWinUpdate(msgwin, msgitm, "Installation Status", statusMsg, 1, totalSteps, statusDelay)

	-- ==============================================================================
	-- Access the FFI and cURL Libraries
	-- ==============================================================================
	ffi = require "ffi"
	curl = require "lj2curl"
	ezreq = require "lj2curl.CRLEasyRequest"
	local autorunComp = ''
	local compFile = nil

	-- ==============================================================================
	-- Download Reactor.fu
	-- ==============================================================================
	local req = ezreq(fuURL)
	statusMsg = "[Download URL]\n" .. tostring(fuURL) .. "\n"
	DownloadURL(fuURL, fuDestFile, "Reactor.fu", msgwin, msgitm, "Installation Status", statusMsg, 2, totalSteps, 1)

	-- ==============================================================================
	-- Download Reactor.lua and save it as AutorunReactor.lua
	-- ==============================================================================
	statusMsg = "[Download URL]\n" .. tostring(luaURL)
	DownloadURL(luaURL, autorunLuaDestFile, "Reactor.lua", msgwin, msgitm, "Installation Status", statusMsg, 3, totalSteps, 1)

	-- ==============================================================================
	-- Create Reactor.cfg
	-- ==============================================================================
	local cfgFile = io.open(cfgDestFile, "w")
	if cfgFile then
		cfgFile:write([[
{
	Repos = {
		_Core = {
			Protocol = "GitLab",
			ID = ]] .. reactor_project_id .. [[,
		},
		Reactor = {
			Protocol = "GitLab",
			ID = ]] .. reactor_project_id .. [[,
		},
	},
	Settings = {
		Reactor = {
			AskForInstallScriptPermissions = true,
			LiveSearch = true,
			MarkAsNew = true,
			NewForDays = 7,
			Token = "]] .. token .. [[",
			ViewLayout = "Balanced View",
		},
	},
}
]])
		cfgFile:close()

		statusMsg = "[Reactor.cfg Saved]\n" .. tostring(cfgDestFile)
		ProgressWinUpdate(msgwin, msgitm, "Installation Status", statusMsg, 4, totalSteps, statusDelay*2)
	else
		statusMsg = "[Reactor.cfg Write Error]\n" .. cfgDestFile
		errwin,erritm = ErrorWin("Installation Error", statusMsg)
		msgwin:Hide()
		errwin:Hide()
		exit()
		return
	end

	statusMsg = "[Reactor]\nAll Downloads Completed"
	ProgressWinUpdate(msgwin, msgitm, "Installation Status", statusMsg, 5, totalSteps, statusDelay*2)

	-- Open Reactor:/System/ folder in a desktop file browser window
	statusMsg = "[Showing Reactor Folder]\n" .. tostring(sysPath)
	ProgressWinUpdate(msgwin, msgitm, "Installation Status", statusMsg, 6, totalSteps, statusDelay*2)
	bmd.openfileexternal("Open", sysPath)

	-- ==============================================================================
	-- Open the Reactor GUI - Run the script Temp:/Reactor/AutorunReactor.lua
	-- ==============================================================================

	ProgressWinUpdate(msgwin, msgitm, "Installation Complete", "Opening Reactor...", 7, totalSteps, statusDelay)

	-- Hide the progress window
	msgwin:Hide()

	-- Auto open the Reactor window
	-- The old Reactor Installer era "restart to load the Reactor.fu menu thing is over now".
	app:RunScript(autorunLuaDestFile)
end

-- Correct version of Fusion detected
function VersionOK(host, ver, os)
	-- Print out the script info
	dprint("----------------------------------------------------------------------------")
	dprint("[Reactor Installer] " .. tostring(_VERSION))
	dprint("[Created By] Andrew Hazelden <andrew@andrewhazelden.com>")
	dprint("[Reactor Installer] Detected " .. host .. " " .. ver .. " running on " .. os .. ".")
end

-- Create the "Install Reactor" dialog
function InstallReactorWin()
	-- Reactor logo size in px
	local logoSize = {80,80}

	-- Configure the window Size
	local originX, originY, width, height = 450, 300, 525, 150

	-- Create the new UI Manager Window
	local win = disp:AddWindow({
		ID = "InstallReactorWin",
		TargetID = "InstallReactorWin",
		WindowTitle = _REPO_EDITION,
		WindowFlags = {
			Window = true,
			WindowStaysOnTopHint = true,
		},
		Geometry = {
			originX,
			originY,
			width,
			height,
		},

		ui:VGroup{
			ID = "root",
			-- Add your GUI elements here:

			ui:HGroup{
				Weight = 1,
				ui:VGroup{
					Weight = 0.25,
					-- Add the Reactor Logo
					ui:TextEdit{
						Weight = 1,
						ID = "Logo",
						HTML = ReactorLogo(),
						ReadOnly = true,
						MinimumSize = logoSize,
						BaseSize = logoSize,
					},
					ui:VGap(40),
				},
				ui:VGroup{
					Weight = 1,

					-- Ready to Install label
					ui:Label{
						ID = "InstallLabel",
						Text = "Ready to Install",
						ReadOnly = true,
						Alignment = {
							AlignHCenter = true,
							AlignVCenter = true,
						},
					},

					-- About Reactor
					ui:VGroup{
						Weight = 1,
						ui:Label{
							ID = "AboutLabel",
							Text = [[Reactor is a package manager for Fusion and Resolve. It was created by the <a href="https://www.steakunderwater.com/wesuckless/viewforum.php?f=32" style="color: rgb(139,155,216)">We Suck Less Fusion Community</a>.]],
							OpenExternalLinks = true,
							WordWrap = true,
							Alignment = {
								AlignHCenter = true,
								AlignVCenter = true,
							},
						},
					},

					ui:HGroup{
						Weight = 0,

						-- Add a horizontal spacer
						-- ui:HGap(0, 2.0),
						ui:HGap(0, 1.0),

						-- Custom Install Path Button
						ui:Button{
							ID = "CustomButton",
							Text = "Custom Install Path",
						},

						-- Install and Launch Button
						ui:Button{
							ID = "InstallButton",
							Text = "Install and Launch",
						},
					},

				},
			},
		},
	})

	-- Add your GUI element based event functions here:
	itm = win:GetItems()

	-- The window was closed
	function win.On.InstallReactorWin.Close(ev)
		disp:ExitLoop()
	end

		-- The Custom Install Path button was clicked
	function win.On.CustomButton.Clicked(ev)
		dprint("[Reactor] Custom Install Path\n")
		local selected_path = tostring(fu:RequestDir(reactor_pathmap) or reactor_pathmap)
		reactor_pathmap = selected_path

		-- List the modified Reactor install path
		dprint("[Install Folder] \"" .. tostring(reactor_pathmap) .. "\"")
	end

	-- The Install and Relaunch Button was clicked
	function win.On.InstallButton.Clicked(ev)
		dprint("[Reactor] Installation Started")

		-- Set the customized Reactor PathMap
		local reactor_root = app:MapPath(tostring(reactor_pathmap) .. "Reactor/")
		app:SetPrefs("Global.Paths.Map.Reactor:", reactor_root)
		local userpath = app:GetPrefs("Global.Paths.Map.UserPaths:")
		if not userpath:find("Reactor:Deploy") then
			userpath = userpath .. ";Reactor:Deploy"
			app:SetPrefs("Global.Paths.Map.UserPaths:", userpath)
		end

		-- Add a "Reactor:System/Scripts" Scripts PathMap entry
		local scriptpath = app:GetPrefs("Global.Paths.Map.Scripts:")
		if not scriptpath:find("Reactor:System/Scripts") then
			scriptpath = scriptpath .. ";Reactor:System/Scripts"
			app:SetPrefs("Global.Paths.Map.Scripts:", scriptpath)
		end
		app:SavePrefs()
		
		dprint("[Reactor: PathMap] \"" .. tostring(app:GetPrefs("Global.Paths.Map.Reactor:")) .. "\"")

		-- Create the Reactor:/System/ folder
		bmd.createdir(app:MapPath(tostring(reactor_pathmap) .. "Reactor/System/"))

		-- Run the installer
		win:Hide()
		Install("")
	end

	-- The app:AddConfig() command that will capture the "Control + W" or "Control + F4" hotkeys so they will close the window instead of closing the foreground composite.
	app:AddConfig("InstallReactorWin", {
		Target {
			ID = "InstallReactorWin",
		},

		Hotkeys {
			Target = "InstallReactorWin",
			Defaults = true,

			CONTROL_W = "Execute{ cmd = [[ app.UIManager:QueueEvent(obj, 'Close', {}) ]] }",
			CONTROL_F4 = "Execute{ cmd = [[ app.UIManager:QueueEvent(obj, 'Close', {}) ]] }",
		},
	})

	-- Init the window
	win:Show()
	disp:RunLoop()
	win:Hide()
	app:RemoveConfig('InstallReactorWin')
	collectgarbage()

	return win,win:GetItems()
end


-- Reactor message dialog
-- Example: local msgwin,msgitm = ProgressWinCreate()
function ProgressWinCreate()
	local win = disp:AddWindow({
		ID = "MsgWin",
		WindowTitle = "Fusion Reactor",
		TargetID = "MsgWin",
		Geometry = {450,300,540,250},

		ui:VGroup{
			ui:Label{
				ID = "Title",
				Text = "",
				Alignment = {
					AlignHCenter = true,
					AlignVCenter = true,
				},
				-- Font = ui:Font{
				-- 	PixelSize = 18,
				-- },
				WordWrap = true,
			},

			ui:Label{
				ID = "Message",
				Text = "",
				Alignment = {
					AlignHCenter = true,
					AlignVCenter = true,
				},
				WordWrap = true,
			},

			ui:TextEdit{
				ID = "ProgressHTML",
				ReadOnly = true,
			},

		}
	})

	-- Add your GUI element based event functions here:
	itm = win:GetItems()

	win:Show()

	return win,itm
end


-- Update the Reactor progress dialog
-- Example: ProgressWinUpdate(msgwin, msgitm, "Initializing...", "Restarting Fusion", 1, 10, 1)
function ProgressWinUpdate(win, itm, title, text, progressLevel, progressMax, delaySeconds)
	-- Update the window title
	itm.MsgWin.WindowTitle = tostring(_REPO_EDITION) .. " - " .. tostring(title)

	-- Update the heading Text
	itm.Title.Text = title .. "\nStep " .. tostring(progressLevel) .. " of " .. tostring(progressMax)
	itm.Message.Text = text

	dprint(title .. " Step " .. tostring(progressLevel) .. " of " .. tostring(progressMax))
	dprint(text)
	
	-- Add the webpage header text
	html = "<html>\n"
	html = html .."\t<head>\n"
	html = html .."\t\t<style>\n"
	html = html .."\t\t</style>\n"
	html = html .."\t</head>\n"
	html = html .."\t<body>\n"
	html = html .. "\t\t<div>"
	html = html .. "\t\t\t<div style=\"float:right;width:46px;\">\n"

	-- progressScale is a multiplier to adjust to the progressMax range vs number of bar elements rendered onscreen
	progressScale = 7

	-- Scale the progress values to better fill the window size
	progressLevelScaled = progressLevel * progressScale
	progressMaxScaled = progressMax * progressScale

	-- Update the activity monitor view - Turn the images into HTML <img> tags
	for img = 1, progressLevelScaled do
		-- These images are the progressbar "ON" cells
		html = html .. ProgressbarCellON()
	end

	for img = progressLevelScaled + 1, progressMaxScaled do
		-- These images are the progressbar "OFF" cells
		html = html .. ProgressbarCellOFF()
	end

	html = html .. "\t\t\t</div>\n"
	html = html .. "\t\t</div>\n"
	html = html .. "\t</body>\n"
	html = html .. "</html>"

	-- Refresh the progress bar
	-- print("[HTML]\n" .. html)
	itm.ProgressHTML.HTML = html

	-- Pause to show the message
	bmd.wait(delaySeconds)
end


-- Reactor message dialog
-- Example: local errwin,erritm = ErrorWin("Initializing...", "Restarting Fusion")
function ErrorWin(title, text)
	local win = disp:AddWindow({
		ID = "errWin",
		TargetID = "errWin",
		WindowTitle = "Fusion Reactor - " .. tostring(title),
		Geometry = {510,580,500,150},

		ui:VGroup
		{
			ui:Label{
				ID = "Title",
				Text = title or "",
				Alignment = {
					AlignHCenter = true,
					AlignVCenter = true,
				},
				-- Font = ui:Font{
				-- 	PixelSize = 18,
				-- },
			},

			-- ui:VGap(0),

			ui:Label{
				ID = "Message",
				Text = text or "",
				Alignment = {
					AlignHCenter = true,
					AlignVCenter = true,
				},
				WordWrap = true,
			},

			ui:HGroup{
				Weight = 1,
				-- Add a horizontal spacer
				ui:HGap(0, 2.0),

				-- OK Button
				ui:Button{
					ID = "OkButton",
					Text = "Ok",
				},
			},

		}
	})

	-- Add your GUI element based event functions here:
	itm = win:GetItems()

	-- The window was closed
	function win.On.errWin.Close(ev)
		win:Hide()
		disp:ExitLoop()
	end

	-- The OK Button was clicked
	function win.On.OkButton.Clicked(ev)
		disp:ExitLoop()
	end

	-- The app:AddConfig() command that will capture the "Control + W" or "Control + F4" hotkeys so they will close the window instead of closing the foreground composite.
	app:AddConfig("errWin", {
		Target {
			ID = "errWin",
		},

		Hotkeys {
			Target = "errWin",
			Defaults = true,

			CONTROL_W = "Execute{ cmd = [[ app.UIManager:QueueEvent(obj, 'Close', {}) ]] }",
			CONTROL_F4 = "Execute{ cmd = [[ app.UIManager:QueueEvent(obj, 'Close', {}) ]] }",
		},
	})

	-- Print the error to the Console tab
	dprint(title)
	dprint(text)

	win:Show()

	disp:RunLoop()
	win:Hide()
	app:RemoveConfig('errWin')
	collectgarbage()

	return win,win:GetItems()
end


-- Close all of the Active Comps
function CloseComps()
	local openComps = "\n"

	local compList = fu:GetCompList()
	for i = 1, table.getn(compList) do
		-- Set cmp to the pointer of the current composite
		cmp = compList[i]

		-- Close the active comp
		if cmp:GetAttrs()["COMPS_FileName"] == "" then
			-- Print out the active composite name
			openComps = openComps .. "[Closing Comp] " .. tostring(cmp:GetAttrs()["COMPS_Name"]) .. " \n"
			-- Force close any unsaved comps that have no filename (do this to avoid a Fusion 9 crash issue)
			cmp:Lock()
			cmp:Close()
		else
			-- Print out the active composite name
			openComps = openComps .. "[Saving and Closing Comp] " .. tostring(cmp:GetAttrs()["COMPS_Name"]) .. " \n"
			-- Ask to save comps that have files open
			cmp:Lock()
			cmp:Save(cmp:GetAttrs()["COMPS_FileName"])
			cmp:Close()
		end
	end

	-- Add an extra newline
	openComps = openComps .. "\n"

	-- Re-update the comp variable
	new_comp = fusion:NewComp()
	composition = fusion.CurrentComp
	comp = composition

	return openComps
end

-- The Main function
function Main()
	-- Find out the current Fusion host platform (Windows/Mac/Linux)
	if string.find(fusion:MapPath('Fusion:/'), 'Program Files', 1) then
		platform = 'Windows'
	elseif string.find(fusion:MapPath('Fusion:/'), 'PROGRA~1', 1) then
		platform = 'Windows'
	elseif string.find(fusion:MapPath('Fusion:/'), 'Applications', 1) then
		platform = 'Mac'
	else
		platform = 'Linux'
	end

	-- Now that we know Fusion 7/8 aren't being used, add the Fu 9+ requiring platform check to handle non Program Files folder based Resolve/Fusion OS detection
	platform = (FuPLATFORM_WINDOWS and "Windows") or (FuPLATFORM_MAC and "Mac") or (FuPLATFORM_LINUX and "Linux")

	local ver = app:GetVersion()
	local fuVersion = ver[1] + ver[2]/10 + ver[3]/100

	-- Resolve 15+ was detected - Note: Resolve 16 added "fu:GetVersion().app" so Fu 15 needs to be detected by fuVersion equalling "15"
	if fu:GetVersion() and fu:GetVersion().App == "Resolve" or math.floor(fuVersion) == 15 then
		-- Show the version info
		VersionOK("Resolve", fuVersion, platform)
	else
		-- Show the version info
		VersionOK("Fusion", fuVersion, platform)
	
		-- Close all of the active comps
		closedLst = CloseComps()

		-- Print out a list of the comps that were closed
		dprint(closedLst)
	
		-- Show the version info in the Fusion 9 Console tab that is remaining open after closing other tabs
		VersionOK("Fusion", fuVersion, platform)
	end
	dprint("[GitLab Branch] \"" .. tostring(branch) .. "\"")

	-- Check Reactor.cfg
	local sysPath = app:MapPath(tostring(reactor_pathmap) .. "Reactor/System/")
	local cfgDestFile = sysPath .. "Reactor.cfg"
	if eyeon.fileexists(cfgDestFile) == false then
		dprint("[Reactor.cfg] Does not exist yet")
		bmd.createdir(sysPath)
	end

	-- Display the "Install Reactor" dialog
	ui = app.UIManager
	disp = bmd.UIDispatcher(ui)
	InstallReactorWin()
end

-- Progressbar ON cell encoded as Base64 content
-- Example: itm.Progress.HTML = ProgressbarCellON()
function ProgressbarCellON()
	return [[<img src='data:image/png;base64,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'/>]]
end

-- Progressbar off cell encoded as Base64 content
-- Example: itm.Progress.HTML = ProgressbarCellOFF()
function ProgressbarCellOFF()
	return [[<img src='data:image/png;base64,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'/>]]
end

-- Reactor logo encoded as Base64 content
-- Example: itm.Logo.HTML = ReactorLogo()
function ReactorLogo()
	return [[<center><img width="68" height="68" src='data:image/png;base64,
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
'/></center>]]
end

-- ==============================================================================
-- Show the Reactor Install GUI
-- ==============================================================================
Main()
