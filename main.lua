--=======================================================================================================
-- Contract Parameters SCRIPT
--
-- Purpose:     set parameters for ingame contracts 
-- Author:      Mmtrx
-- Copyright:	Mmtrx
-- License:		GNU GPL v3.0
-- Changelog:
--  v1.0.0.0    07.05.2026  initial
--=======================================================================================================
modDirectory = g_currentModDirectory
modName      = g_currentModName

function debugPrint(text, ...)
	if ContractParms.debug == true then
		Logging.info("[Con] ".. text,...)
	end
end

ContractParms = {
	debug = true,
}
local ContractParms_mt = Class(ContractParms)
source(modDirectory .."rewards.lua")
--source(modDirectory .."contractStart.lua")

function ContractParms:new(default)
	local self = {}
	setmetatable(self, ContractParms_mt)
	self.isServer = g_server ~= nil 
	self.isClient = g_dedicatedServerInfo == nil
	self.directory = g_currentModDirectory
	self.name = modName
	self.sName = "Con"
	return self
end
function ContractParms:init()
	-- load and initiate settings page:
	self.settingsPage = SettingsPage.new()
	
	local fname = self.directory .."startContract.xml"
	if fileExists(fname) then
		-- init our contract start dialog
		self.contractStart = ContractStart.new()

		if g_gui:loadGui(fname, "startContract", self.contractStart) == nil 
			and not g_modIsLoaded.FS25_Financing then -- FS25_Financing swallows rc of loadGui()
			Logging.error("[FM] Error loading gui %s", fname)
			return nil
		end
	else
		Logging.error("[FM] Required file '%s' could not be found!", fname)
		return nil
	end
end
function ContractParms:loadMap()
	-- body
	if g_modIsLoaded[modName] then
		g_currentMission.ContractParms = self
		debugPrint("** loadMap: set g_currentMission.ContractParms")
	end
	if g_missionManager == nil or g_missionManager.getMissionTypeDataByName == nil then
		Logging.error("[%s] could not load mission types",self.name)
		return
	end
	g_messageCenter:subscribeOneshot(MessageType.CURRENT_MISSION_START, 
		ContractParms.onMissionStarted, self)
	--self:init()
end

g_ContractParms = ContractParms:new("ContractParms")
addModEventListener(g_ContractParms)
