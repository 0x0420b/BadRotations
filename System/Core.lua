local brMainThread = nil
deadPet = false

function br:Engine()
	-- Hidden Frame
	if Pulse_Engine == nil then
		Pulse_Engine = CreateFrame("Frame", nil, UIParent)
		Pulse_Engine:SetScript("OnUpdate", BadRotationsUpdate)
		Pulse_Engine:Show()
	end
end
function br:ObjectManager()
	-- Object Manager
	if OM_Engine == nil then
		OM_Engine = CreateFrame("Frame", nil, UIParent)
		OM_Engine:SetScript("OnUpdate", ObjectManagerUpdate)
		OM_Engine:Show()
	end
end

--[[This function is refired everytime wow ticks. This frame is located at the top of Core.lua]]
function getUpdateRate()
	local updateRate = updateRate or 0.1
	if updateRate < 0.1 then
		updateRate = 0.1
	end

	local FrameRate = GetFramerate() or 0
 	if isChecked("Auto Delay") then
 		if FrameRate ~= 0 and FrameRate < 100 then
 			updateRate = (100 - FrameRate)/100
 		else
 			updateRate = 0.1
 		end
	elseif getOptionValue("Bot Update Rate") == nil then
	 	updateRate = 0.1 else updateRate = getOptionValue("Bot Update Rate")
	end

	return updateRate
end

function ObjectManagerUpdate(self)
	-- Check for Unlocker
	if FireHack == nil then
	 	br.ui:closeWindow("all")
		if getOptionCheck("Start/Stop BadRotations") then
			ChatOverlay("Unable To Load")
			if isChecked("Notify Not Unlocked") and br.timer:useTimer("notLoaded", getOptionValue("Notify Not Unlocked")) then
				Print("|cffFFFFFFCannot Start... |cffFF1100BR |cffFFFFFFcan not complete loading. Please check requirements.")
			end
		end
		return false
	else
		-- Check Enabled State
		if br.loadMsg == nil then br.loadMsg = false end
		if not br.loadMsg then ChatOverlay("Loaded") br.loadMsg = true end
		if br.data.settings ~= nil then
			if br.data.settings[br.selectedSpec].toggles["Power"] ~= nil and br.data.settings[br.selectedSpec].toggles["Power"] ~= 1 then
				br.ui:closeWindow("all")
				return false
			else
				-- Pulse Object Manager for Caching
				if pulse == nil then pulse = GetTime() end
				if GetTime() > pulse then
					pulse = GetTime() + getUpdateRate()
					cacheOM()
					getOMUnits()
					FindEnemy()
				end
			end
		end
	end
end

function BadRotationsUpdate(self)
	local startTime = debugprofilestop()
	-- Check for Unlocker
	if FireHack == nil then
	 	br.ui:closeWindow("all")
		if getOptionCheck("Start/Stop BadRotations") then
			ChatOverlay("Unable To Load")
			if isChecked("Notify Not Unlocked") and br.timer:useTimer("notLoaded", getOptionValue("Notify Not Unlocked")) then
				Print("|cffFFFFFFCannot Start... |cffFF1100BR |cffFFFFFFcan not complete loading. Please check requirements.")
			end
		end
		return false
	else
		if br.loadMsg == nil then br.loadMsg = false end
		if not br.loadMsg then ChatOverlay("Loaded") br.loadMsg = true end
		if br.data.settings ~= nil then
			if br.data.settings[br.selectedSpec].toggles["Power"] ~= nil and br.data.settings[br.selectedSpec].toggles["Power"] ~= 1 then
				br.ui:closeWindow("all")
				return false
			elseif br.timer:useTimer("playerUpdate", getUpdateRate()) then
				br.fallDist = getFallDistance() or 0
				-- if br.fallDist > 0 then print(br.fallDist) end
				-- if pHealth == nil then pHealth = 0 end
				-- if printed == nil then printed = false end
				-- if pHealth == 0 and UnitHealth("player") < UnitHealthMax("player") then pHealth = UnitHealth("player") end
				-- if pHealth > 0 and printed == false then print (pHealth) printed = true end
				if isChecked("Talent Anywhere") then
					talentAnywhere()
				end
			-- Blizz CastSpellByName bug bypass
				if castID then
					-- Print("Casting by ID")
					CastSpellByID(botSpell,botUnit)
					castID = false
				end
			-- Load Spec Profiles
			    br.selectedProfile = br.data.settings[br.selectedSpec]["Rotation".."Drop"] or 1
			    local playerSpec = GetSpecializationInfo(GetSpecialization())
			    -- Initialize Player
				if br.player == nil or br.player.profile ~= br.selectedSpec then
			        br.player = br.loader:new(playerSpec,br.selectedSpec)
			        setmetatable(br.player, {__index = br.loader})
			        br.player:createOptions()
			        br.player:createToggles()
			        br.player:update()
			    end
			    -- Update Player
			    if br.player ~= nil and not CanExitVehicle() then --and br.timer:useTimer("playerUpdate", getUpdateRate()) then --br.debug.cpu.pulse.currentTime/10) then
					br.player:update()
				end
			-- Enemy Engine
				-- if br.timer:useTimer("cacheOM",1) then
				-- 	cacheOM()
				-- end
				-- if br.timer:useTimer("unitsUpdate", getUpdateRate()) then --br.debug.cpu.enemiesEngine.units.currentTime/10) then
					-- getOMUnits()
				-- end
				-- if br.timer:useTimer("enemyUpdate", getUpdateRate()) then --br.debug.cpu.enemiesEngine.enemy.currentTime/10) then
					-- FindEnemy()
				-- end
			-- Healing Engine
				if isChecked("HE Active") then
					br.friend:Update()
				end
			-- Auto Loot
				autoLoot()
			-- Close windows and swap br.selectedSpec on Spec Change
				if select(2,GetSpecializationInfo(GetSpecialization())) ~= br.selectedSpec then
			    	-- Closing the windows will save the position
			        br.ui:closeWindow("all")

			    	-- Update Selected Spec/Profile
			        br.selectedSpec = select(2,GetSpecializationInfo(GetSpecialization()))
			        br.activeSpecGroup = GetActiveSpecGroup()
			        br:loadSettings()

			        -- Recreate Config Window and commandHelp with new Spec
			        if br.ui.window.config.parent == nil then br.ui:createConfigWindow() end
					commandHelp = nil
					commandHelp = ""
					slashHelpList()
			    end

			-- Display Distance on Main Icon
		    	targetDistance = getDistance("target") or 0
		    	displayDistance = math.ceil(targetDistance)
				mainText:SetText(displayDistance)

			-- Queue Casting
				if (isChecked("Queue Casting") or (br.player ~= nil and br.player.queue ~= 0)) and not UnitChannelInfo("player") then
					-- Catch for spells not registering on Combat log
				    if castQueue() then return end
				end

			-- LoS Line Draw
				if isChecked("Healer Line of Sight Indicator") then
					inLoSHealer()
				end

		    -- get DBM Timer/Bars
			    -- global -> br.DBM.Timer
			    br.DBM:getBars()

			-- Accept dungeon queues
				br:AcceptQueues()

			-- Profession Helper
				ProfessionHelper()

		    -- Rotation Log
		    	br.ui:toggleDebugWindow()
			end --End Update Check
		end -- End Update In Progress Check
 	end -- End Main Button Active Check
	if isChecked("Debug Timers") then
		br.debug.cpu.pulse.totalIterations = br.debug.cpu.pulse.totalIterations + 1
		br.debug.cpu.pulse.currentTime = debugprofilestop()-startTime
		br.debug.cpu.pulse.elapsedTime = br.debug.cpu.pulse.elapsedTime + debugprofilestop()-startTime
		br.debug.cpu.pulse.averageTime = br.debug.cpu.pulse.elapsedTime / br.debug.cpu.pulse.totalIterations
	end
end -- End Bad Rotations Update Function
