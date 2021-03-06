--[[--------------------------------------------------------------------
	PhanxBorder
	Adds shiny borders to things.
	Copyright 2008-2018 Phanx <addons@phanx.net>. All rights reserved.
	https://github.com/Phanx/PhanxBorder
----------------------------------------------------------------------]]

local USE_CLASS_COLOR = true

------------------------------------------------------------------------

local _, Addon = ...
local Masque = IsAddOnLoaded("Masque")

local noop = Addon.noop
local AddBorder = Addon.AddBorder
local ColorByClass = Addon.ColorByClass

------------------------------------------------------------------------

local applyFuncs = {}

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:SetScript("OnEvent", function(self, event)
	for i, func in pairs(applyFuncs) do
		if not func() then -- return true to keep trying
			applyFuncs[i] = nil
		end
	end
	if #applyFuncs == 0 then
		self:UnregisterAllEvents()
		self:SetScript("OnEvent", nil)
		applyFuncs = nil
	elseif event == "PLAYER_LOGIN" then
		self:RegisterEvent("ADDON_LOADED")
		self:RegisterEvent("PLAYER_ENTERING_WORLD")
	end
end)

------------------------------------------------------------------------
--	LibQTip-1.0
------------------------------------------------------------------------

tinsert(applyFuncs, function()
	local QTip = LibStub and LibStub("LibQTip-1.0", true)
	if not QTip then return true end

	local Acquire = QTip.Acquire
	QTip.Acquire = function(lib, ...)
		local tooltip = Acquire(lib, ...)
		if tooltip then
			AddBorder(tooltip)
		end
		return tooltip
	end
end)

------------------------------------------------------------------------
--	Archy
------------------------------------------------------------------------
--[[
tinsert(applyFuncs, function()
	if not ArchyDigSiteFrame then return true end

	AddBorder(ArchyArtifactFrame)
	ArchyArtifactFrame.SetBackdropBorderColor = noop
	ArchyArtifactFrame:SetFrameStrata("LOW")

	ArchyArtifactFrameSkillBarBorder:SetTexture("")

	AddBorder(ArchyDigSiteFrame)
	ArchyDigSiteFrame.SetBackdropBorderColor = noop
	ArchyDigSiteFrame:SetFrameStrata("LOW")

	ArchyDistanceIndicatorFrame:SetPoint("CENTER", ArchyDigSiteFrame, "TOPLEFT", 40, 5)
	ArchyDistanceIndicatorFrameCircleDistance:SetFont((GameFontNormal:GetFont()), 30, "OUTLINE")
	ArchyDistanceIndicatorFrameCircleDistance:SetTextColor(1, 1, 1)
	ArchyDistanceIndicatorFrameSurveyButton:SetNormalTexture("")
	ArchyDistanceIndicatorFrameCrateButton:SetNormalTexture("")
	ArchyDistanceIndicatorFrameLorItemButton:SetNormalTexture("")
end)
]]
------------------------------------------------------------------------
--	AtlasLoot
------------------------------------------------------------------------

tinsert(applyFuncs, function()
	if not AtlasLootTooltip then return true end
	-- print("Adding border to AtlasLootTooltip")
	AddBorder(AtlasLootTooltip)
end)

------------------------------------------------------------------------
--	Auracle
------------------------------------------------------------------------
--[[
tinsert(applyFuncs, function()
	if not Auracle or not Auracle.windows then return true end
	-- print("Adding border to Auracle")
	-- Auracle.windows[1].trackers[1].uiFrame
	local function Auracle_SetVertexColor(icon, r, g, b, a)
		icon:realSetVertexColor(r, g, b, a)
		icon:GetParent():SetBorderAlpha(a)
	end
	for i, window in pairs(Auracle.windows) do
		for i, tracker in ipairs(window.trackers) do
			local f = tracker.uiFrame
			AddBorder(f)

			local cd = f.Auracle_tracker.uiCooldown
			cd:ClearAllPoints()
			cd:SetPoint("TOPLEFT", f, 2, -2)
			cd:SetPoint("BOTTOMRIGHT", f, -2, -2)

			local icon = f.Auracle_tracker.uiIcon
			icon.realSetVertexColor = icon.SetVertexColor
			icon.SetVertexColor = Auracle_SetVertexColor

			local _, _, _, a = icon:GetVertexColor()
			f:SetBorderAlpha(a)
		end
	end
end)
]]
------------------------------------------------------------------------
--	Bagnon
------------------------------------------------------------------------
tinsert(applyFuncs, function()
	if not Bagnon then return true end

	-- TODO: Something to prevent conflicts with Masque?
	if select(4, GetAddOnInfo("Bagnon_Facade")) then
		return print("WARNING: Bagnon_Facade is enabled. You should disable it!")
	end

	local function ItemSlot_Update(button)
		-- button:SetBorderInsets(1) -- fixes scaling issues
		button.icon:SetTexCoord(0.03, 0.97, 0.03, 0.97)
	end
	local function ItemSlot_OnEnter(button)
		button.__UpdateBorder = button.UpdateBorder
		button.UpdateBorder = noop
		ColorByClass(button)
	end
	local function ItemSlot_OnLeave(button)
		button.UpdateBorder = button.__UpdateBorder
		button.__UpdateBorder = noop
		button:UpdateBorder()
	end

	local ItemSlot_Create = Bagnon.ItemSlot.Create
	function Bagnon.ItemSlot:Create()
		local button = ItemSlot_Create(self)
		AddBorder(button, nil, 1)
		button:GetNormalTexture():SetTexture("")
		button:GetHighlightTexture():SetTexture("")
		--button.icon:SetTexCoord(0.04, 0.96, 0.04, 0.96)
		--button.border.Show = button.border.Hide
		hooksecurefunc(button, "HideBorder", button.SetBorderColor)
		hooksecurefunc(button, "Update", ItemSlot_Update)
		button:HookScript("OnEnter", ItemSlot_OnEnter)
		button:HookScript("OnLeave", ItemSlot_OnLeave)
		return button
	end

	local origBorderSize = {}

	local function ResizeChildBorders(frame)
		frame:SetBorderSize()
		if frame.itemFrame then
			for _, button in pairs(frame.itemFrame.buttons) do
				ItemSlot_Update(button)
			end
		end
	end
	
	if USE_CLASS_COLOR then
		hooksecurefunc(Bagnon.Frame, "SetPlayer", function(frame, player)
			--print("Bagnon:SetPlayer", frame.frameID, player)
			local color = Bagnon:GetPlayerColor(player)
			local t = Bagnon.sets.global[frame.frameID].borderColor
			t[1], t[2], t[3], t[4] = color.r, color.g, color.b, 1
			frame:SetBackdropBorderColor(color.r, color.g, color.b, 1)
		end)
	end

	hooksecurefunc(Bagnon, "CreateFrame", function(Bagnon, id)
		local frame = Bagnon.frames[id]
		if origBorderSize[frame] then return end
		--print("Adding border to Bagnon", id)

		AddBorder(frame)
		origBorderSize[frame] = frame:GetBorderSize()
		frame:SetBorderSize()
		hooksecurefunc(frame, "OnSetScale", ResizeChildBorders)

		if USE_CLASS_COLOR then
			local _, class = UnitClass("player")
			local color = (CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS)[class]
			local t = Bagnon.sets.global[id].borderColor
			t[1], t[2], t[3], t[4] = color.r, color.g, color.b, 1
			frame:SetBackdropBorderColor(color.r, color.g, color.b, 1)
		end
	end)
end)
------------------------------------------------------------------------
-- BattlePetBreedID
------------------------------------------------------------------------
tinsert(applyFuncs, function()
	if not BPBID_SetBreedTooltip then return true end
	--print("Adding border to BattlePetBreedID")
	hooksecurefunc("BPBID_SetBreedTooltip", function(parent)
		local tooltip = parent == FloatingBattlePetTooltip and BPBID_BreedTooltip2 or BPBID_BreedTooltip
		if not tooltip.WithBorder then
			Addon.ProcessBorderedTooltip(tooltip)
			-- Don't let the addon overwrite visual properties
			tooltip.SetBackdrop = noop
			tooltip.SetBackdropColor = noop
			tooltip.SetBackdropBorderColor = noop
		end
		local _, _, _, _, y = tooltip:GetPoint(1)
		tooltip:SetPoint("TOPLEFT", parent, "BOTTOMLEFT", 0, y - 8)
		tooltip:SetPoint("TOPRIGHT", parent, "BOTTOMRIGHT", 0, y - 8)
	end)
end)
------------------------------------------------------------------------
--	Bazooka
------------------------------------------------------------------------

tinsert(applyFuncs, function()
	if not Bazooka or not Bazooka.bars or #Bazooka.bars == 0 then return true end
	-- print("Adding border to Bazooka")
	local color = USE_CLASS_COLOR and (CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS)[select(2, UnitClass("player"))]
	for i = 1, #Bazooka.bars do
		local bar = Bazooka.bars[i]
		local db = Bazooka.db.profile.bars[i]

		AddBorder(bar.frame)

		local r, g, b = bar.frame:GetBorderColor()
		db.bgBorderColor.r = r
		db.bgBorderColor.g = g
		db.bgBorderColor.b = b

		if color then
			db.textColor.r = color.r
			db.textColor.g = color.g
			db.textColor.b = color.b
		end

		db.bgBorderInset = 0
		db.bgBorderTexture = "None"

		bar:applyBGSettings()
		bar:applySettings()
	end
end)

------------------------------------------------------------------------
--	BuffBroker
------------------------------------------------------------------------
--[[
tinsert(applyFuncs, function()
	if Masque then return true end
	local btn = BuffBroker and BuffBroker.BuffButton
	if not btn then return true end
	-- print("Adding border to BuffBroker")
	AddBorder(btn)
	btn:GetNormalTexture():SetTexCoord(0.03, 0.97, 0.03, 0.97)
end)
]]
------------------------------------------------------------------------
--	Butsu
------------------------------------------------------------------------

tinsert(applyFuncs, function()
	if not Butsu then return true end
	AddBorder(Butsu)
	--[[
	local color = USE_CLASS_COLOR and (CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS)[select(2, UnitClass("player"))]
	if color then
		Butsu:SetBorderColor(color.r, color.g, color.b)
		Butsu.title:SetTextColor(color.r, color.g, color.b)
	end
	]]
end)

------------------------------------------------------------------------
--	CandyBuckets
------------------------------------------------------------------------

tinsert(applyFuncs, function()
	if not CandyBucketsTooltipFrame then return true end
	AddBorder(CandyBucketsTooltipFrame)
end)

------------------------------------------------------------------------
--	Clique
------------------------------------------------------------------------

tinsert(applyFuncs, function()
	if not CliqueSpellTab then return true end
	AddBorder(CliqueSpellTab)
	CliqueSpellTab:GetNormalTexture():SetTexCoord(0.06, 0.94, 0.06, 0.94)
end)

------------------------------------------------------------------------
--	CoolLine
------------------------------------------------------------------------

tinsert(applyFuncs, function()
	if not CoolLine then return true end
	-- print("Adding border to CoolLine")
	AddBorder(CoolLine)
	CoolLine:SetBorderLayer("OVERLAY")
--[[
	function CoolLine_AddBorders()
		-- print("Adding border to CoolLine icons")
		for i = 1, CoolLine.border:GetNumChildren() do
			local f = select(i, CoolLine.border:GetChildren())
			if f.icon and not f.PhanxBorder then
				-- print("Adding border to CoolLine icon", i)
				AddBorder(f)
				f:SetBackdrop(nil)
				f.icon:SetDrawLayer("BACKGROUND")
			end
		end
	end

	local osa = CoolLine.SetAlpha
	CoolLine.SetAlpha = function(...)
		osa(...)
		if CoolLine.border then
			CoolLine_AddBorders()
		end
	end
]]
end)

------------------------------------------------------------------------
--	CrowBar
------------------------------------------------------------------------

tinsert(applyFuncs, function()
	if not CrowBarButton then return true end
	if LibStub and LibStub("Masque", true) then return end
	AddBorder(CrowBarButton)
end)

------------------------------------------------------------------------
--	DockingStation
------------------------------------------------------------------------
--[[
tinsert(applyFuncs, function()
	local panel = DockingStation and DockingStation:GetPanel(1)
	if not panel then return true end
	-- print("Adding border to DockingStation panels")
	local i = 1
	while true do
		local p = DockingStation:GetPanel(i)
		if not p then break end
		AddBorder(p, nil, nil, nil, true)
		i = i + 1
	end
end)
]]
------------------------------------------------------------------------
--	ExtraQuestButton
------------------------------------------------------------------------

tinsert(applyFuncs, function()
	if not ExtraQuestButton then return true end
	if LibStub and LibStub("Masque", true) then return end
	ExtraQuestButton.Artwork:SetAlpha(0)
	AddBorder(ExtraQuestButton)
end)

------------------------------------------------------------------------
--	Forte_Cooldown
------------------------------------------------------------------------
--[[
tinsert(applyFuncs, function()
	if not FWCDFrame then return true end
	-- print("Adding border to Forte_Cooldown")
	AddBorder(FWCDFrame, nil, nil, true)
end)
]]
------------------------------------------------------------------------
--	Grid
------------------------------------------------------------------------
--[==[
tinsert(applyFuncs, function()
--[[
	if not GridLayoutFrame then return true end

	GridLayoutFrame.texture:SetTexture("")
	GridLayoutFrame.texture:SetGradientAlpha("VERTICAL", 0, 0, 0, 0, 0, 0, 0, 0)
	GridLayoutFrame.texture:Hide()

	AddBorder(GridLayoutFrame, -9)

	local backdrop = GridLayoutFrame:GetBackdrop()
	backdrop.bgFile = "Interface\\BUTTONS\\WHITE8X8"
	GridLayoutFrame:SetBackdrop(backdrop)
	GridLayoutFrame:SetBackdropColor(16/255, 16/255, 16/255, 1)

	GridLayoutFrame.SetBackdrop = noop
	GridLayoutFrame.SetBackdropColor = noop
	GridLayoutFrame.SetBackdropBorderColor = noop
	GridLayoutFrame.texture.SetGradientAlpha = noop
	GridLayoutFrame.texture.SetTexture = noop
	GridLayoutFrame.texture.Show = noop
]]
	local GridFrame = Grid and Grid:GetModule("GridFrame")
	if not GridFrame or not GridFrame.registeredFrames then return true end
	-- print("Adding borders to Grid frames")
--[[
	local function Grid_SetBackdropBorderColor(f, r, g, b, a)
		if a and a == 0 then
			f:SetBorderColor()
		else
			f:SetBorderColor(r, g, b)
		end
	end
	local function Grid_AddBorder(f)
		if not f.SetBorderColor then
			f:SetBorderSize(0)
			AddBorder(f, nil, 1)
			f.SetBackdropBorderColor = Grid_SetBackdropBorderColor
			f.SetBorderSize = noop
		end
	end
	for frame in pairs(GridFrame.registeredFrames) do
		Grid_AddBorder(_G[frame])
	end
	local o = GridFrame.RegisterFrame
	GridFrame.RegisterFrame = function(self, f)
		o(self, f)
		Grid_AddBorder(f)
	end
]]
end)
]==]
------------------------------------------------------------------------
--	InFlight
------------------------------------------------------------------------
--[[
tinsert(applyFuncs, function()
	if not InFlight or not InFlight.CreateBar then return true end
	hooksecurefunc(InFlight, "CreateBar", function()
		-- print("Adding border to InFlight")
		AddBorder(InFlightBar)
	end)
end)
]]
------------------------------------------------------------------------
--	LauncherMenu
------------------------------------------------------------------------

tinsert(applyFuncs, function()
	local dataobj = LibStub and LibStub("LibDataBroker-1.1", true) and LibStub("LibDataBroker-1.1"):GetDataObjectByName("LauncherMenu")
	if not dataobj then return true end

	local OnClick = dataobj.OnClick
	dataobj.OnClick = function(frame)
		OnClick(frame)
		dataobj.OnClick = OnClick
		for i = UIParent:GetNumChildren(), 1, -1 do -- go backwards since it's probably the last one
			local f = select(i, UIParent:GetChildren())
			if f.anchorFrame == frame then
				AddBorder(f)
				break
			end
		end
	end
end)

------------------------------------------------------------------------
--	Omen
------------------------------------------------------------------------
--[[
tinsert(applyFuncs, function()
	if not OmenBarList then return true end
	-- print("Adding border to Omen")
	AddBorder(OmenBarList)
end)
]]
------------------------------------------------------------------------
--	PetBattleTeams
------------------------------------------------------------------------
--[[ TODO: fix
tinsert(applyFuncs, function()
	if not PetBattleTeamsRosterFrame then return true end
	-- print("Adding borders to PetBattleTeams")
	for i, teamFrames in pairs(PetBattleTeamsRosterFrame.scrollChild.teamFrames) do
		for j, unitFrames in pairs(teamFrames.unitFrames) do
			for k, unitFrame in pairs(unitFrames) do
				AddBorder(unitFrame)
			end
		end
	end
end)
]]
------------------------------------------------------------------------
--	PetJournalEnhanced
------------------------------------------------------------------------
--[[ TODO: fix
tinsert(applyFuncs, function()
	local PetJournalEnhanced = LibStub and LibStub("AceAddon-3.0", true) and LibStub("AceAddon-3.0"):GetAddon("PetJournalEnhanced", true)
	if not PetJournalEnhanced then return true end
	--print("Adding borders to PetJournalEnhanced")

	local PetList = PetJournalEnhanced:GetModule("PetList")
	local Sorting = PetJournalEnhanced:GetModule("Sorting")

	local function UpdatePetList()
		--print("UpdatePetList")
		local scrollFrame = PetList.listScroll
		local buttons = scrollFrame.buttons
		local offset = HybridScrollFrame_GetOffset(scrollFrame)
		local isWild = PetJournal.isWild
		for i = 1, #buttons do
			local button = buttons[i]
			local index = offset + i
			AddBorder(button.dragButton, nil, 2)
			if index <= Sorting:GetNumPets() then
				local mappedPet = Sorting:GetPetByIndex(index)
				local petID, _, isOwned, _, _, _, _, name, _, _, _, _, _, _, canBattle = C_PetJournal.GetPetInfoByIndex(mappedPet.index, isWild)
				local colored
				if isOwned and canBattle then
					local _, _, _, _, rarity = C_PetJournal.GetPetStats(petID)
					if rarity and rarity > 2 then
						local color = ITEM_QUALITY_COLORS[rarity - 1]
						button.dragButton:SetBorderColor(color.r, color.g, color.b)
						colored = true
					end
				end
				if not colored then
					button.dragButton:SetBorderColor()
				end
			end
		end
	end

	hooksecurefunc(PetList, "PetJournal_UpdatePetList", UpdatePetList)
	hooksecurefunc(PetList.listScroll, "update", UpdatePetList)
end)
]]
------------------------------------------------------------------------
--	PetTracker
------------------------------------------------------------------------

tinsert(applyFuncs, function()
	if not PetTracker then return true end
	--print("Adding borders to PetTracker")

	AddBorder(PetTrackerMapTip1)

	--[[ Add border to tracker bar
	local bar = PetTracker.Objectives.Bar
	bar:SetHeight(16)
	bar.Overlay.BorderLeft:SetTexture("")
	bar.Overlay.BorderRight:SetTexture("")
	bar.Overlay.BorderCenter:SetTexture("")
	AddBorder(bar.Overlay)]]

	local EnemyActions = PetTracker.EnemyActions
	local function doEnemyActions()
		--print("Adding borders to enemy action buttons")
		for i = 1, #EnemyActions do
			local button = EnemyActions[i]
			button:GetNormalTexture():SetTexture("")
			AddBorder(button, nil, 2)
		end
	end
	if #EnemyActions > 0 then
		doEnemyActions()
	else
		--print("Waiting for enemy action buttons")
		hooksecurefunc(EnemyActions, "Startup", doEnemyActions)
	end
end)

------------------------------------------------------------------------
--	PetTracker_Broker
------------------------------------------------------------------------
--[[
tinsert(applyFuncs, function()
	if not PetTracker_BrokerTip then return true end

	-- print("Adding borders to PetTracker_Broker")
	AddBorder(PetTracker_BrokerTip)

	for i = 1, PetTracker_BrokerTip:GetNumChildren() do
		local child = select(i, PetTracker_BrokerTip:GetChildren())
		local bar = child.Bar
		if bar then
			bar.Overlay.BorderLeft:SetTexture("")
			bar.Overlay.BorderRight:SetTexture("")
			bar.Overlay.BorderCenter:SetTexture("")
			AddBorder(bar.Overlay, 12)
			break
		end
	end
end)
]]
------------------------------------------------------------------------
--	QuestPointer
------------------------------------------------------------------------

tinsert(applyFuncs, function()
	if not QuestPointerTooltip then return true end
	-- print("Adding border to QuestPointerTooltip")
	AddBorder(QuestPointerTooltip)
end)

------------------------------------------------------------------------
--	SexyCooldown
------------------------------------------------------------------------
--[[
tinsert(applyFuncs, function()
	if not SexyCooldown or not SexyCooldown.bars then return true end
	-- print("Adding borders to SexyCooldown")
	local color = USE_CLASS_COLOR and (CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS)[select(2, UnitClass("player"))]
	for i, bar in ipairs(SexyCooldown.bars) do
		AddBorder(bar)
		if color then
			local bcolor = bar.settings.bar.backgroundColor
			bcolor.r, bcolor.g, bcolor.b = color.r * 0.2, color.g * 0.2, color.b * 0.2
			bar:SetBackdropColor(bcolor.r, bcolor.g, bcolor.b, bcolor.a)

			local tcolor = bar.settings.bar.fontColor
			tcolor.r, tcolor.g, tcolor.b = color.r, color.g, color.b
			bar:SetBarFont()
		end
	end
end)
]]
------------------------------------------------------------------------
--	TomTom
------------------------------------------------------------------------

tinsert(applyFuncs, function()
	if not TomTomTooltip then return true end
	-- print("Adding border to TomTomTooltip")
	AddBorder(TomTomTooltip)
end)

------------------------------------------------------------------------
--	Touhin
------------------------------------------------------------------------

tinsert(applyFuncs, function()
	local Touhin = LibStub and LibStub("AceAddon-3.0", true) and LibStub("AceAddon-3.0"):GetAddon("Touhin", true)
	if not Touhin then return true end

	local origSetRow = {}

	local function SetRow(self, icon, color, text, hightlightColor)
		if not origSetRow[self] then
			--print("Adding border to new Touhin frame.")
			origSetRow[self] = self.SetRow
			self.SetRow = SetRow

			Touhin.db.profile.edgeFile = "None"
			Touhin.db.profile.insets = 0

			self:SetBackdrop(nil)

			self.background:ClearAllPoints()
			self.background:SetAllPoints(true)
			local color = Touhin.db.profile.bgColor
			self.background:SetVertexColor(color.r, color.g, color.b, 1)
			self.background.SetVertexColor = noop
			self.background:SetAlpha(1)

			self.iconFrame:SetBackdrop(nil)

			self.icon:SetParent(self)
			self.icon:ClearAllPoints()
			self.icon:SetDrawLayer("BORDER")
			self.icon:SetPoint("TOPLEFT")
			self.icon:SetPoint("BOTTOMLEFT")
			self.icon:SetWidth(self:GetHeight())

			AddBorder(self)
		end

		if not icon then return end

		origSetRow[self](self, icon, color, text, hightlightColor)
		--self:SetWidth(self:GetWidth() + 5)
		self.icon:SetWidth(self:GetHeight())

		if highlightColor then
			self:SetBorderColor()
		end
	end

	local function ProcessRow()
		local f = EnumerateFrames()
		while f do
			if (not f.IsForbidden or not f:IsForbidden()) and f:GetParent() == UIParent and not f:GetName()
			and f.background and f.iconFrame and f.icon and f.rollIcon and f.text and f.fader and f.SetRow then
				if not origSetRow[f] then
					SetRow(f)
				end
			end
			f = EnumerateFrames(f)
		end
	end

	hooksecurefunc(Touhin, "AddCoin", ProcessRow)
	hooksecurefunc(Touhin, "AddCurrency", ProcessRow)
	hooksecurefunc(Touhin, "AddLoot", ProcessRow)
end)

---------------------------------------------------------------------
-- xMerchant
---------------------------------------------------------------------
-- TODO: skin it!
