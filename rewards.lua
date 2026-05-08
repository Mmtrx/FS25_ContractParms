-- to change rewards for specific missions, please change the number only
rewardPerHa = {  						-- game default:
  BALEMISSION = 			2200, -- 2200
  CHAFFMISSION = 			2000, -- 5000 			--AC mod
  CULTIVATEMISSION = 	1500, -- 1500
  FERTILIZEMISSION = 	1500, -- 1500
  FRUITCOLLECTMISSION=2000, -- 3100 			--AC mod
  HARVESTMISSION = 		2500, -- 2500  			-- for grain harvest
  HERBICIDEMISSION = 	1500, -- 1500
  HOEMISSION = 				1500, -- 1500
  MOWMISSION = 				2500, -- 2500
  MULCHERMISSION = 		1000, -- 2000 			--AC mod
  PLOWMISSION = 			2800, -- 2800
  ROLLERMISSION =			1000, -- 1500				--AC mod
  SOWMISSION = 				2000, -- 2000
  STONEPICKMISSION = 	2200, -- 2200
  TEDDERMISSION = 		1500, -- 1500
  WEEDMISSION = 			2000, -- 2000
}
rewardPer = {  															-- original value
  BALEWRAPMISSION = 	{"Bale", 			500}, 	-- 300 per bale
  BALECOLLECTMISSION = 	{"Bale", 		100}, 	-- 310 AC mod
  DEADWOODMISSION =  	{"Tree", 			650},		-- 150 per tree
  DESTRUCTIBLEROCKMISSION = {"Rock",550}, 	-- 550 per rock 
  TREETRANSPORTMISSION = {"Tree", 	255}, 	-- 255 per tree
}
-- additional contracts mod:
ACrewards = {  					-- values are max possible reward per contract
  AnimalDealerMission = 	2500,  
  FieldHeapMission =			1800,
  -- UniversalMission types:
  LostCargoMission =						2200,
  SupplyDeliveryBulkMission =		2300,
  SupplyFieldGoodsMission =			2400,
  VehicleTransferMission =			2500,
  VehicleTransportMission =			2600,
}
function setHarvest()
return {
 { 	types = {FruitType.POTATO, FruitType.SUGARBEET, FruitType.RICE,FruitType.RICELONGGRAIN},
	reward = 3500
 }, -- root crops and rice
 { 	types = {FruitType.BEETROOT, FruitType.CARROT, FruitType.PARSNIP, FruitType.ONION},
	reward = 4000
 }, -- VEGETABLES
 { 	types = {FruitType.GREENBEAN, FruitType.PEAS, FruitType.SPINACH},
	reward = 4200
 }, -- greens
}
end
function ContractParms:getData(name)
	local data = g_missionManager:getMissionTypeDataByName(name)
	if data == nil then 
		Logging.warning("[%s] could not get type data for %s", self.name,name)
	end
	return data
end
function getReward(self,superf)
	-- overwrites FieldHeapMission:getReward()
	local org = superf(self)
	local className = self.className
	local names = className:split('.')
	local name = names[2]
	local rew = ACrewards[name] or 100000 
	if rew < org then
		debugPrint("** capped reward for %s to %d", name, rew)
	end
	return math.min(org, rew)
end
function setACrewards(self)
	if not g_modIsLoaded["FS25_AdditionalContracts"] then return 
	end
	-- body
	local type, typeClass
	for _, name in ipairs({"animalDealerMission","fieldHeapMission"}) do
		type = g_missionManager:getMissionType(name)
		if type ~= nil then 
			typeClass = type.classObject 
			self[name] = type.classObject
			typeClass.getReward = Utils.overwrittenFunction(typeClass.getReward, getReward)
		end
	end
	if g_missionManager:getMissionType("universalMission") ~= nil then
		-- only for AddtionalContracts version from 1.0.0.4 and later
		local gEnv = getmetatable(_G).__index
		local acTypes = gEnv.FS25_AdditionalContracts.g_additionalContractTypes
		for _, name in ipairs({"supplyDeliveryBulkMission","supplyFieldGoodsMission",
				"lostCargoMission","vehicleTransferMission","vehicleTransportMission"}) do
			local class = acTypes:getTyp(name)
			class.getReward = Utils.overwrittenFunction(class.getReward, getReward)
		end
	end
end
function ContractParms:onMissionStarted()
	local data

	-- reset rewards per ha
	for name, reward in pairs(rewardPerHa) do
		data = self:getData(name)
		if data then
			data.rewardPerHa = reward
			Logging.info('[%s] set %s to %d',self.sName, name, reward)
		else
			Logging.error("[%s] getdata(%s) is nil",self.name, name)
		end
	end

	-- root crop / vegetable / greens harvest rewards
	data = self:getData(HarvestMission.NAME)
	local harvestPerHa = setHarvest()
	for _, info in ipairs(harvestPerHa) do
		for _,type in ipairs(info.types) do
			if type ~= nil then 
				data.rewardPerFruitHa[type] = info.reward
			end
		end
	end

	-- special missions, reward not per ha
	for name, info in pairs(rewardPer) do
		data = self:getData(name)
		if data then
			data["rewardPer"..info[1]] = info[2]
		Logging.info('[%s] set %s %s to %d',self.sName, name, info[1],info[2])
		end
	end
	
	-- adjust rewards for AC animalDealer, fieldHeap, and universal missions
	setACrewards(self) 
	Logging.info('[%s] Mission rewards changed',self.sName)
end

