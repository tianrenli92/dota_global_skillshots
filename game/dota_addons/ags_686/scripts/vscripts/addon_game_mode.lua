--[[
Author, 作者: Tim the hexed
Mod name, 地图名称: Dota Global Skillshots, Dota全图流
Mod link, 地图链接: http://steamcommunity.com/sharedfiles/filedetails/?id=466843568
Please feel free to refer to my scripts :)
请随意参考我的脚本~
]]

require('settings')
require('notifications')
require('storageapi/json')
require('storageapi/storage')
require('statcollection/init')

if CagsGameMode == nil then
	CagsGameMode = class({})
end

function Precache( context )
	--[[
		Precache things we know we'll use.  Possible file types include (but not limited to):
			PrecacheResource( "model", "*.vmdl", context )
			PrecacheResource( "soundfile", "*.vsndevts", context )
			PrecacheResource( "particle", "*.vpcf", context )
			PrecacheResource( "particle_folder", "particles/folder", context )
	]]
end

-- Create the game mode when we activate
function Activate()
	GameRules.ags = CagsGameMode()
	GameRules.ags:InitGameMode()
end

function CagsGameMode:InitGameMode()
	print( "ags is loaded." )
	Storage:SetApiKey("fc80985d01e14165c9ca9d03848eaecd58d3ede3")
	CountN = 0
	TooltipReport = false
	FewPlayer = false
	FewPlayerBroadcast = false
	WinStreakRecord = false
	HostRecord = false
	
	PudgeExist = false
	PudgeAbandon = false
	MiranaExist = false
	MiranaAbandon = false
	DruidExist = false
	TechiesSuicide = false
	FinalNotice = false
	HostQualityPunish = false
	MegaAutoSpawn = false
	
	PlayerSum = PlayerResource:GetPlayerCount()
	RadiantPlayers = 0
	DirePlayers = 0
	RadiantPlayersNow = 0
	DirePlayersNow = 0
	PlayerRandom = {false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false}
	PlayerRepick = {false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false}
	PlayerSelect = {false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false}
	PlayerAbandon = {false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false}
	PlayerDisconnect = {false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false}
	PlayerDisconnectTime = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}
	MaxDCTime = 180
	RespawnPenalty = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}
	PlayerTeam = {}
	PlayerIDtoHeroIndex = {}
	PlayerStorage = {}
	GoldCoef = {2,1.414214,1.224745,1.154701,1.118034} --nil,sqrt(2/1),sqrt(3/2),sqrt(4/3),sqrt(5/4)
	RadiantGC = 1
	DireGC = 1
	RadiantScore = 0
	DireScore = 0
	BaseElo = 3000
	EloVar = 50
	--PlayerHeroRandomName = {}
	--SendToServerConsole("sv_cheats 1")
	
	Convars:RegisterCommand("test_storage", function(wtfnoobnil) DeepPrintTable(PlayerStorage) end, "Test the storage.", 0)
	Convars:RegisterCommand("test_broadcast", function(wtfnoobnil, num) if PlayerResource:GetSteamAccountID(Convars:GetCommandClient():GetPlayerID()) == 161697269 and num then CagsGameMode:WinStreakBC(tonumber(num)) end end, "Test the broadcast of a player.", 0)
	Convars:RegisterCommand("test_quickinit", function(wtfnoobnil) if PlayerResource:GetSteamAccountID(Convars:GetCommandClient():GetPlayerID()) == 161697269 then CagsGameMode:TestInit() end end, "Combo cheat commands.", 0)
	Convars:RegisterCommand("test_fastend", function(wtfnoobnil, num) if PlayerResource:GetSteamAccountID(Convars:GetCommandClient():GetPlayerID()) == 161697269 and num then CagsGameMode:FastEnd(tonumber(num)) end end, "Fast end test. 2/3 for rad/dire.", 0)
	Convars:RegisterCommand("test_changeelo", function(wtfnoobnil, num) if PlayerResource:GetSteamAccountID(Convars:GetCommandClient():GetPlayerID()) == 161697269 and num then CagsGameMode:EloChange(0,tonumber(num)) end end, "Adjust elo.", 0)
	Convars:RegisterCommand("test_printmodifiers", function(wtfnoobnil, num) if PlayerResource:GetSteamAccountID(Convars:GetCommandClient():GetPlayerID()) == 161697269 and num then CagsGameMode:PrintModifiers(tonumber(num)) end end, "Print modifiers.", 0)

	GameRules:GetGameModeEntity():SetThink( "HeroSelectionThink", self, "HST")
	GameRules:GetGameModeEntity():SetThink( "AbandonCheckThink", self, "ACT")
	GameRules:GetGameModeEntity():SetThink( "AbandonReimburseThink", self, "ART")
	
	GameRules:SetCustomGameSetupAutoLaunchDelay(10)
	--GameRules:SetHeroSelectionTime(30)
	--GameRules:SetPreGameTime(30)
	
	GameRules:GetGameModeEntity():SetLoseGoldOnDeath( false )
	GameRules:SetUseUniversalShopMode( true )
	GameRules:GetGameModeEntity():SetTopBarTeamValuesOverride ( true )
	GameRules:GetGameModeEntity():SetTopBarTeamValue(DOTA_TEAM_GOODGUYS,RadiantScore)
	GameRules:GetGameModeEntity():SetTopBarTeamValue(DOTA_TEAM_BADGUYS,DireScore)
	GameRules:GetGameModeEntity():SetCameraDistanceOverride(1350)
	
	ListenToGameEvent( "player_connect", Dynamic_Wrap( CagsGameMode, 'OnPlayerConnect' ), self )
	ListenToGameEvent( "game_rules_state_change", Dynamic_Wrap( CagsGameMode, 'OnStateChange' ), self )
	ListenToGameEvent( "dota_player_pick_hero", Dynamic_Wrap( CagsGameMode, 'OnHeroPicked' ), self )
	ListenToGameEvent( "npc_spawned", Dynamic_Wrap( CagsGameMode, 'OnNpcSpawned' ), self )
	ListenToGameEvent( "dota_player_used_ability", Dynamic_Wrap( CagsGameMode, 'OnPlayerUseAbility' ), self )
	ListenToGameEvent( "entity_hurt", Dynamic_Wrap( CagsGameMode, 'OnEntityHurt' ), self )
	ListenToGameEvent( "entity_killed", Dynamic_Wrap( CagsGameMode, 'OnEntityKilled' ), self )
	ListenToGameEvent( "player_chat", Dynamic_Wrap( CagsGameMode, "OnPlayerSay"), self)
	ListenToGameEvent( "player_score", Dynamic_Wrap( CagsGameMode, 'OnScoreChanged' ), self )
	ListenToGameEvent( "player_disconnect", Dynamic_Wrap( CagsGameMode, 'OnPlayerDisconnect' ), self )
	ListenToGameEvent( "player_reconnected", Dynamic_Wrap( CagsGameMode, 'OnPlayerReconnect' ), self )
	ListenToGameEvent( "game_end", Dynamic_Wrap( CagsGameMode, 'OnGameEnd' ), self )
	
	CustomGameEventManager:RegisterListener( "myui_open", OnMyUIOpen )
  CustomGameEventManager:RegisterListener( "js_to_lua", OnJsToLua )
  CustomGameEventManager:RegisterListener( "lua_to_js", OnLuaToJs )

end

function OnMyUIOpen( index,keys )
         CustomUI:DynamicHud_Create(keys.PlayerID,"MyUIMain","file://{resources}/layout/custom_game/rank_info_main.xml",nil)
end

function OnJsToLua( index,keys )
         print("num:"..keys.num.." str:"..tostring(keys.str))
         CustomUI:DynamicHud_Destroy(keys.PlayerID,"MyUIMain")
end
  
function OnLuaToJs( index,keys )
         CustomGameEventManager:Send_ServerToPlayer( PlayerResource:GetPlayer(keys.PlayerID), "on_lua_to_js", {str="Lua"} )
         CustomUI:DynamicHud_Destroy(keys.PlayerID,"MyUIMain")
end

function CagsGameMode:HeroSelectionThink()
	--print(GameRules:State_Get())
	if (GameRules:State_Get() >= DOTA_GAMERULES_STATE_HERO_SELECTION) and (GameRules:State_Get() <= DOTA_GAMERULES_STATE_PRE_GAME) then
		--ShowGenericPopup("#addon_game_name", "#addon_game_name", "", "",0|1)
		if not(TooltipReport) then
			GameRules:SendCustomMessage("#addon_report",0,0)
			TooltipReport = true
		end
		if (FewPlayerBroadcast) then
			GameRules:SendCustomMessage("#addon_few_player",0,0)
			GameRules:SendCustomMessage((math.floor(RadiantGC*100)/100).."x & "..(math.floor(DireGC*100)/100).."x",0,0)
			FewPlayerBroadcast = false
		end
		for i = 0,31 do
			if (PlayerResource:HasRepicked(i)==true) and (PlayerRepick[i+1] == false) then
				GameRules:SendCustomMessage("#addon_repick", i, 0)	
				PlayerRepick[i+1] = true
			else
				if (PlayerResource:HasRandomed(i)==true) and (PlayerRandom[i+1] == false) then
					--PlayerHeroRandomName[i+1] = PlayerResource:GetSelectedHeroName(i)
					--PlayerHeroRandomName[i+1] = string.sub(PlayerHeroRandomName[i+1],15,string.len(PlayerHeroRandomName[i+1]))
					PlayerRandom[i+1] = true
					GameRules:SendCustomMessage("#addon_random_pick", i, 0)
				end
			end
		end
	end
	return 0.5
end

function CagsGameMode:AbandonCheckThink()
	--[[
	for i = 0, 31 do
		if (PlayerIDtoHeroIndex[i+1]~=nil) then
			if (EntIndexToHScript(PlayerIDtoHeroIndex[i+1]):HasOwnerAbandoned()==true) and (PlayerAbandon[i+1]==false) then
				GameRules:SendCustomMessage("%s1 has abandoned. Reimbursement will be realized in future updates ", i, 0)
				PlayerAbandon[i+1]=true
			end
		end
	end
	]]
	if GameRules:State_Get()>=DOTA_GAMERULES_STATE_STRATEGY_TIME then
		GameTime = math.floor(GameRules:GetGameTime())
		for i = 0, 31 do
			if (PlayerTeam[i+1]==2)or(PlayerTeam[i+1]==3) then
			
				ConnectionState = PlayerResource:GetConnectionState(i)
				
				if (ConnectionState==DOTA_CONNECTION_STATE_CONNECTED)and(PlayerDisconnect[i+1]==true) then
					PlayerDisconnect[i+1]=false
				end
				
				if (ConnectionState==DOTA_CONNECTION_STATE_DISCONNECTED)and(PlayerDisconnect[i+1]==false) then
					PlayerDisconnect[i+1]=true
					PlayerDisconnectTime[i+1]=GameTime
				end
				
				if ( (ConnectionState==DOTA_CONNECTION_STATE_ABANDONED) or (_G.AbandonTest[i+1]) or (ConnectionState==DOTA_CONNECTION_STATE_DISCONNECTED)and(GameTime-PlayerDisconnectTime[i+1]>MaxDCTime) ) and (PlayerAbandon[i+1]==false) then
	
					PlayerAbandon[i+1]=true
					if PlayerResource:GetSelectedHeroName(i)=="npc_dota_hero_mirana" then
						MiranaAbandon = true
					end
					if PlayerResource:GetSelectedHeroName(i)=="npc_dota_hero_pudge" then
						PudgeAbandon = true
					end	
									
					if PlayerTeam[i+1]==2 then
					
						GCMulti = GoldCoef[RadiantPlayersNow]
						RadiantGC = RadiantGC * GCMulti
						for j = 0, 31 do
							if PlayerTeam[j+1]==2 then
								ItemCost = 0 --get player j total item cost
								if PlayerResource:GetSelectedHeroEntity(j) then
									for k = 0, 11 do
										if PlayerResource:GetSelectedHeroEntity(j):GetItemInSlot(k) then
											ItemCost = ItemCost + PlayerResource:GetSelectedHeroEntity(j):GetItemInSlot(k):GetCost()
										end
									end
								end
								if i==j then
									ItemCosti = ItemCost
								end
								PlayerResource:ModifyGold(j,math.floor((PlayerResource:GetGold(j)+ItemCost)*(GCMulti-1)), false, 0)
							end
						end				
						for k = 0, 11 do
							if PlayerResource:GetSelectedHeroEntity(i):GetItemInSlot(k) then
								PlayerResource:GetSelectedHeroEntity(i):RemoveItem(PlayerResource:GetSelectedHeroEntity(i):GetItemInSlot(k))
							end
						end									
						PlayerResource:ModifyGold(i,math.floor(ItemCosti), false, 0)
						--GameRules:SendCustomMessage("%s1 abandoned. All radiant players' gold, GPM and respawn speed become "..((math.floor(RadiantGC*100))/100).."x.", i, 0)				
	  				Notifications:BottomToAll({hero=PlayerResource:GetSelectedHeroName(i), imagestyle="landscape", duration=10.0})
	  				Notifications:BottomToAll({text="#addon_abandon_radiant_01", continue=true, style={["font-size"]="30px"}})
	  				Notifications:BottomToAll({text=""..((math.floor(RadiantGC*100))/100), continue=true, style={["font-size"]="30px"}})
	  				Notifications:BottomToAll({text="#addon_abandon_radiant_02", continue=true, style={["font-size"]="30px"}})
						RadiantPlayersNow = RadiantPlayersNow - 1
											
						if RadiantPlayersNow==0 and not(MegaAutoSpawn) then
							MegaAutoSpawn = true
							CagsGameMode:DestroyRadiantBarracks()
						end
						
					else
					
						GCMulti = GoldCoef[DirePlayersNow]
						DireGC = DireGC * GCMulti
						for j = 0, 31 do
							if PlayerTeam[j+1]==3 then
								ItemCost = 0 --get player j total item cost
								if PlayerResource:GetSelectedHeroEntity(j) then
									for k = 0, 11 do
										if PlayerResource:GetSelectedHeroEntity(j):GetItemInSlot(k) then
											ItemCost = ItemCost + PlayerResource:GetSelectedHeroEntity(j):GetItemInSlot(k):GetCost()
										end
									end
								end
								if i==j then
									ItemCosti = ItemCost
								end
								PlayerResource:ModifyGold(j,math.floor((PlayerResource:GetGold(j)+ItemCost)*(GCMulti-1)), false, 0)
							end
						end				
						for k = 0, 11 do
							if PlayerResource:GetSelectedHeroEntity(i):GetItemInSlot(k) then
								PlayerResource:GetSelectedHeroEntity(i):RemoveItem(PlayerResource:GetSelectedHeroEntity(i):GetItemInSlot(k))
							end
						end									
						PlayerResource:ModifyGold(i,math.floor(ItemCosti), false, 0)
						--GameRules:SendCustomMessage("%s1 abandoned. All dire players' gold, GPM and respawn speed "..((math.floor(DireGC*100))/100).."x.", i, 0)				
	  				Notifications:BottomToAll({hero=PlayerResource:GetSelectedHeroName(i), imagestyle="landscape", duration=10.0})
	  				Notifications:BottomToAll({text="#addon_abandon_dire_01", continue=true, style={["font-size"]="30px"}})
	  				Notifications:BottomToAll({text=""..((math.floor(DireGC*100))/100), continue=true, style={["font-size"]="30px"}})
	  				Notifications:BottomToAll({text="#addon_abandon_dire_02", continue=true, style={["font-size"]="30px"}})
						DirePlayersNow = DirePlayersNow - 1
						
						if DirePlayersNow==0 and not(MegaAutoSpawn) then
							MegaAutoSpawn = true
							CagsGameMode:DestroyDireBarracks()
						end

					end
					
				end --if abandon
				
			end --if team 2|3
		end --for i
	end --if state>=pre
	return 3
end

function CagsGameMode:DestroyRadiantBarracks()
	--Entities:FindAllByClassname("npc_dota_barracks")
	RaxDestroy=Entities:FindAllByName("good_rax_melee_top")
	for k,ent in pairs(RaxDestroy) do
		ent:ForceKill(false)
	end
	RaxDestroy=Entities:FindAllByName("good_rax_range_top")
	for k,ent in pairs(RaxDestroy) do
		ent:ForceKill(false)
	end
	RaxDestroy=Entities:FindAllByName("good_rax_melee_mid")
	for k,ent in pairs(RaxDestroy) do
		ent:ForceKill(false)
	end
	RaxDestroy=Entities:FindAllByName("good_rax_range_mid")
	for k,ent in pairs(RaxDestroy) do
		ent:ForceKill(false)
	end
	RaxDestroy=Entities:FindAllByName("good_rax_melee_bot")
	for k,ent in pairs(RaxDestroy) do
		ent:ForceKill(false)
	end
	RaxDestroy=Entities:FindAllByName("good_rax_range_bot")
	for k,ent in pairs(RaxDestroy) do
		ent:ForceKill(false)
	end
end

function CagsGameMode:DestroyDireBarracks()
	RaxDestroy=Entities:FindAllByName("bad_rax_melee_top")
	for k,ent in pairs(RaxDestroy) do
		ent:ForceKill(false)
	end
	RaxDestroy=Entities:FindAllByName("bad_rax_range_top")
	for k,ent in pairs(RaxDestroy) do
		ent:ForceKill(false)
	end
	RaxDestroy=Entities:FindAllByName("bad_rax_melee_mid")
	for k,ent in pairs(RaxDestroy) do
		ent:ForceKill(false)
	end
	RaxDestroy=Entities:FindAllByName("bad_rax_range_mid")
	for k,ent in pairs(RaxDestroy) do
		ent:ForceKill(false)
	end
	RaxDestroy=Entities:FindAllByName("bad_rax_melee_bot")
	for k,ent in pairs(RaxDestroy) do
		ent:ForceKill(false)
	end
	RaxDestroy=Entities:FindAllByName("bad_rax_range_bot")
	for k,ent in pairs(RaxDestroy) do
		ent:ForceKill(false)
	end
end

function CagsGameMode:FastEnd(flag)
	if flag==2 then
		CagsGameMode:DestroyRadiantBarracks()
	end
	if flag==3 then
		CagsGameMode:DestroyDireBarracks()
	end
end

function CagsGameMode:TestInit()
	SendToServerConsole("dota_dev forcegamestart") -- startgame
	SendToServerConsole("dota_ability_debug 1") -- wtf
	SendToServerConsole("dota_all_vision 1") -- allvision
	
	SendToServerConsole("dota_dev hero_level 25") -- lvlup 25
	SendToServerConsole("dota_create_item item_blink") -- item item_blink
	SendToServerConsole("dota_dev player_givegold 99999") -- gold 99999
	
	SendToServerConsole("dota_create_unit axe enemy") -- enemy axe x3
	SendToServerConsole("dota_create_unit axe enemy") -- enemy axe x3
	SendToServerConsole("dota_create_unit axe enemy") -- enemy axe x3
	
	GameRules:GetGameModeEntity():SetThink("TestInitThink", self, "TIT", 1)	
end

function CagsGameMode:TestInitThink()
	SendToServerConsole("dota_bot_give_level 25") -- levelbots 25
	SendToServerConsole("dota_bot_give_item item_blink") -- givebots item_blink
end

function CagsGameMode:PrintModifiers(playerID)
	local player = PlayerResource:GetPlayer(playerID)
	local playerHero = player:GetAssignedHero()
	local playerName = playerHero:GetUnitName()
	local allModfiers = playerHero:FindAllModifiers()
	for k,ent in pairs(allModfiers) do
		print(ent:GetName())
	end
	--local modifer = playerHero:FindModifierByName("modifier_item_moon_shard_consumed")
	--if modifer then print(tmp:GetName()) else print(nil) end
	--modifier_item_moon_shard, modifier_item_moon_shard_consumed
	print("")
end

function CagsGameMode:AbandonReimburseThink()
	GameState = GameRules:State_Get()
	if ((GameState == DOTA_GAMERULES_STATE_PRE_GAME or GameState == DOTA_GAMERULES_STATE_GAME_IN_PROGRESS) and not(GameRules:IsGamePaused())) then
		--print(PlayerResource:GetGold(0))
		--print(PlayerResource:GetGoldSpentOnItems(0))
		--print(PlayerResource:GetConnectionState(0))
		RadiantGoldReim = 0
		DireGoldReim = 0
		for i = 0, 31 do
			if PlayerTeam[i+1]==2 then
				if GameState == DOTA_GAMERULES_STATE_GAME_IN_PROGRESS and not(PlayerAbandon[i+1]) and PlayerSelect[i+1] then
					PlayerResource:ModifyGold(i,math.floor(10*RadiantGC^3), false, 0)
				end
				if PlayerAbandon[i+1] then
					RadiantGoldReim = RadiantGoldReim + PlayerResource:GetGold(i)
					PlayerResource:SetGold(i,0,false)
					PlayerResource:SetGold(i,0,true)
				end
			end
			if PlayerTeam[i+1]==3 then
				if GameState == DOTA_GAMERULES_STATE_GAME_IN_PROGRESS and not(PlayerAbandon[i+1]) and PlayerSelect[i+1] then
					PlayerResource:ModifyGold(i,math.floor(10*DireGC^3), false, 0)
				end
				if PlayerAbandon[i+1] then
					DireGoldReim = DireGoldReim + PlayerResource:GetGold(i)
					PlayerResource:SetGold(i,0,false)
					PlayerResource:SetGold(i,0,true)
				end
			end	
		end
		if RadiantPlayersNow>0 then
			RadiantGoldReim = math.floor(RadiantGoldReim / RadiantPlayersNow)
			for i = 0, 31 do
				if ((PlayerTeam[i+1]==2)and not(PlayerAbandon[i+1]) and PlayerSelect[i+1]) then
					PlayerResource:ModifyGold(i, RadiantGoldReim, false, 0)
				end
			end
		end
		if DirePlayersNow>0 then
			DireGoldReim = math.floor(DireGoldReim / DirePlayersNow)
			for i = 0, 31 do
				if ((PlayerTeam[i+1]==3)and not(PlayerAbandon[i+1]) and PlayerSelect[i+1]) then
					PlayerResource:ModifyGold(i, DireGoldReim, false, 0)
				end
			end
		end
	end
	return 6
end

function CagsGameMode:OnPlayerConnect( event )
	--DeepPrintTable(event)
end

function CagsGameMode:OnStateChange( event )
	--print(GameRules:State_Get())
	if GameRules:State_Get() == DOTA_GAMERULES_STATE_HERO_SELECTION then
		CustomUI:DynamicHud_Create(-1,nil,"file://{resources}/layout/custom_game/barebones_notifications.xml",nil)
		--CustomUI:DynamicHud_Create(-1,"MyUIButton","file://{resources}/layout/custom_game/rank_info.xml",nil)
		for i = 0, 31 do
			PlayerTeam[i+1] = PlayerResource:GetTeam(i)
			--print(PlayerTeam[i+1])
			if (PlayerTeam[i+1]== 2) then
				RadiantPlayers = RadiantPlayers + 1
				CagsGameMode:StorageGet(i)
			end
			if (PlayerTeam[i+1]== 3) then
				DirePlayers = DirePlayers + 1
				CagsGameMode:StorageGet(i)
			end	
		end
		RadiantPlayersNow = RadiantPlayers
		DirePlayersNow = DirePlayers
		
		GameRules:GetGameModeEntity():SetThink("NewPlayerHintThink", self, "NPHT", 5)	
		GameRules:SetGoldTickTime(6)
		--GameRules:SetGoldPerTick(math.floor(10*(10/(RadiantPlayers+DirePlayers))^1.5))
		GameRules:SetGoldPerTick(0)	
		if RadiantPlayers==0 then
			RadiantGC = 5
		else
			RadiantGC = (5/RadiantPlayers)^0.5
		end
		if DirePlayers==0 then
			DireGC = 5
		else
			DireGC = (5/DirePlayers)^0.5
		end
		
		if ((RadiantPlayers+DirePlayers)<10) then
			FewPlayer=true
			FewPlayerBroadcast=true
		else
			WinStreakRecord=true
		end
		if ((RadiantPlayers+DirePlayers)>3) then
			HostRecord=true
		end
		--WinStreakRecord=true
		--HostRecord=true
		--print(RadiantPlayers)
		--print(DirePlayers)
		--print(FewPlayer)
	end
	if GameRules:State_Get() == DOTA_GAMERULES_STATE_PRE_GAME then
		--CagsGameMode:FountainChange()
		if (WinStreakRecord) then
			CagsGameMode:EloCalc()
			for i = 0,31 do
				if (PlayerTeam[i+1]==2) or (PlayerTeam[i+1]==3) then
					CagsGameMode:WinStreakBC(i)
				end
			end
			CagsGameMode:EloOverallBC()
		end
	end
	if GameRules:State_Get() == DOTA_GAMERULES_STATE_GAME_IN_PROGRESS then
		
		CagsGameMode:FountainChange()
		
		if IsDedicatedServer() == false then
			for i = 0, 31 do
				if PlayerResource:IsValidPlayerID(i) then
					if GameRules:PlayerHasCustomGameHostPrivileges(PlayerResource:GetPlayer(i)) then 
						
						PlayerHost = i
						PlayerHostTeam = PlayerTeam[i+1]
						
						if HostRecord then						
							CagsGameMode:HostQualityBC()
						end
						
						if WinStreakRecord then
							if PlayerStorage[PlayerHost+1] then
								Notifications:TopToAll({text="#addon_host_hint_10players", duration=20.0, style={color="orange", ["font-size"]="30px"}})
							end
							RadiantEloDeltaSav = RadiantEloDelta
							DireEloDeltaSav = DireEloDelta
							if PlayerHostTeam==2 then
								CagsGameMode:EloChange(PlayerHost,-DireEloDeltaSav*5)
								--DeepPrintTable(PlayerStorage[PlayerHost+1])
								for j = 0, 31 do
									if PlayerTeam[j+1]==3 then
										CagsGameMode:EloChange(j,DireEloDeltaSav)	
										CagsGameMode:StoragePut(j)
									end			
								end		
							elseif PlayerHostTeam==3 then
								CagsGameMode:EloChange(PlayerHost,-RadiantEloDeltaSav*5)
								for j = 0, 31 do
									if PlayerTeam[j+1]==2 then
										CagsGameMode:EloChange(j,RadiantEloDeltaSav)	
										CagsGameMode:StoragePut(j)
									end			
								end		
							end
						
						end
						
						if HostRecord or WinStreakRecord then
							CagsGameMode:StoragePut(PlayerHost)
						end
						
					end
				end
			end		
		end
		
	end
	if GameRules:State_Get() == DOTA_GAMERULES_STATE_POST_GAME then


	end
end

function CagsGameMode:HostQualityBC()
	if PlayerStorage[PlayerHost+1]==nil then
		return nil
	end
	Notifications:TopToAll({text=PlayerResource:GetPlayerName(PlayerHost).." ", duration=20.0, style={color="orange", ["font-size"]="30px"}})		
	Notifications:TopToAll({text="#addon_host_hint", duration=20.0, style={color="orange", ["font-size"]="30px"}})
	Notifications:TopToAll({text="#addon_host_quality", duration=20.0, style={color="orange", ["font-size"]="30px"}})
	Notifications:TopToAll({text=string.char(65+PlayerStorage[PlayerHost+1]["HostQuality"]), continue=true, style={color="orange", ["font-size"]="30px"}})
	
	if PlayerStorage[PlayerHost+1]["HostQuality"]==3 then
		Notifications:TopToAll({text="#addon_host_quality_punish", duration=20.0, style={color="orange", ["font-size"]="30px"}})
		HostQualityPunish = true
		PlayerResource:GetSelectedHeroEntity(PlayerHost):ForceKill(false)
		PlayerResource:SetBuybackCooldownTime(PlayerHost,360)
	end
	HostQualityOrigin = PlayerStorage[PlayerHost+1]["HostQuality"]
	if PlayerStorage[PlayerHost+1]["HostQuality"]<3 then
		PlayerStorage[PlayerHost+1]["HostQuality"] = PlayerStorage[PlayerHost+1]["HostQuality"] + 1
	end
	if PlayerStorage[PlayerHost+1]["HostQuality"]<3 then
		PlayerStorage[PlayerHost+1]["HostQuality"] = PlayerStorage[PlayerHost+1]["HostQuality"] + 1
	end
end

function CagsGameMode:FountainChange()
  --Entities:FindAllByClassname("ent_dota_fountain")
	Fountain=Entities:FindAllByName("ent_dota_fountain_good")
	for k,ent in pairs(Fountain) do
		ent:SetInvulnCount(0)
		ent:SetBaseMaxHealth(50000)
		ent:SetMaxHealth(50000)
		ent:SetHealth(50000)
		--if ent:GetMaxHealth() ~= 50000 then
		--	ent:SetInvulnCount(10)
		--end
   	--ent:AddAbility("fountain_health")  
 		--ent:FindAbilityByName("fountain_health"):ApplyDataDrivenModifier(ent,ent,"modifier_fountain_health",nil)
   	--ent:RemoveAbility("fountain_health")  
	end
	Fountain=Entities:FindAllByName("ent_dota_fountain_bad")
	for k,ent in pairs(Fountain) do
		ent:SetInvulnCount(0)
		ent:SetHullRadius(288)
		ent:SetBaseMaxHealth(50000)
		ent:SetMaxHealth(50000)
		ent:SetHealth(50000)
		--if ent:GetMaxHealth() ~= 50000 then
		--	ent:SetInvulnCount(10)
		--end
   	--ent:AddAbility("fountain_health")  
 		--ent:FindAbilityByName("fountain_health"):ApplyDataDrivenModifier(ent,ent,"modifier_fountain_health",nil)
   	--ent:RemoveAbility("fountain_health")  
	end
end

function CagsGameMode:EloCalc()
		RadiantElo = 0
		DireElo = 0
		local radiantPlayers = 0
		local direPlayers = 0
		
		for i = 0, 31 do
			if (PlayerTeam[i+1] == 2) and (PlayerStorage[i+1]) then
				RadiantElo = RadiantElo + PlayerStorage[i+1]["Elo"]^2
				radiantPlayers = radiantPlayers + 1
			end
			if (PlayerTeam[i+1] == 3) and (PlayerStorage[i+1]) then
				DireElo = DireElo + PlayerStorage[i+1]["Elo"]^2
				direPlayers = direPlayers + 1
			end	
		end
		if radiantPlayers==0 then
			RadiantElo = 0
		else
			RadiantElo = (RadiantElo/radiantPlayers)^0.5
		end
		if direPlayers==0 then
			DireElo = 0
		else
			DireElo = (DireElo/direPlayers)^0.5
		end
		RadiantEXWin = 1/(1+10^((DireElo-RadiantElo)/1000))
		DireEXWin = 1/(1+10^((RadiantElo-DireElo)/1000))	
		RadiantEloDelta = EloVar * (1-RadiantEXWin)
		DireEloDelta = EloVar * (1-DireEXWin)		
end

function CagsGameMode:EloOverallBC()
	if	RadiantElo == 0 or DireElo == 0 then
		return nil
	end
	Say(nil, "Radiant avg rank: "..math.floor(RadiantElo).."; Dire avg rank: "..math.floor(DireElo).."; Radiant Winrate: "..(math.floor(RadiantEXWin*1000)/10).."%; Dire Winrate: "..(math.floor(DireEXWin*1000)/10).."%; Rank change if Radiant win: "..(math.floor(RadiantEloDelta*10)/10).."; Rank change if Dire win: "..(math.floor(DireEloDelta*10)/10), false)
	
	Notifications:TopToAll({text="#addon_radiant_avg_rank", duration=20.0, style={color="white", ["font-size"]="20px"}})		
	Notifications:TopToAll({text=math.floor(RadiantElo), continue=true, style={color="white", ["font-size"]="20px"}})
	Notifications:TopToAll({text="#addon_dire_avg_rank", continue=true, style={color="white", ["font-size"]="20px"}})
	Notifications:TopToAll({text=math.floor(DireElo), continue=true, style={color="white", ["font-size"]="20px"}})
	
	Notifications:TopToAll({text="#addon_radiant_exp_winrate", continue=true, style={color="white", ["font-size"]="20px"}})
	Notifications:TopToAll({text=(math.floor(RadiantEXWin*1000)/10).."%", continue=true, style={color="white", ["font-size"]="20px"}})
	Notifications:TopToAll({text="#addon_dire_exp_winrate", continue=true, style={color="white", ["font-size"]="20px"}})
	Notifications:TopToAll({text=(math.floor(DireEXWin*1000)/10).."%", continue=true, style={color="white", ["font-size"]="20px"}})
	
	Notifications:TopToAll({text="#addon_radiant_rank_change", continue=true, style={color="white", ["font-size"]="20px"}})
	Notifications:TopToAll({text=(math.floor(RadiantEloDelta*10)/10).."", continue=true, style={color="white", ["font-size"]="20px"}})
	Notifications:TopToAll({text="#addon_dire_rank_change", continue=true, style={color="white", ["font-size"]="20px"}})
	Notifications:TopToAll({text=(math.floor(DireEloDelta*10)/10).."", continue=true, style={color="white", ["font-size"]="20px"}})
end

function CagsGameMode:StorageGet(i)
	--Storage:Get(90021, function( resultTable, successBool )
	Storage:Get(PlayerResource:GetSteamAccountID(i), function( resultTable, successBool )
		--print(successBool)
		--DeepPrintTable(resultTable)
		if successBool then
			PlayerStorage[i+1] = resultTable
		elseif resultTable["error_code"]==5 then
			PlayerStorage[i+1] = {}
		else
			return nil
		end
		if PlayerStorage[i+1]==nil then
			return nil
		end

		--DeepPrintTable(PlayerStorage[i+1])
		if PlayerStorage[i+1]["WinStreak"] == nil then
			PlayerStorage[i+1]["WinStreak"] = 0
			--print("WinStreak init")
		end
		if PlayerStorage[i+1]["WinStreakHistory"] == nil then
			PlayerStorage[i+1]["WinStreakHistory"] = 0
			--print("WinStreakHistory init")
		end
		if PlayerStorage[i+1]["TotalWins"] == nil then
			PlayerStorage[i+1]["TotalWins"] = 0
		end
		if PlayerStorage[i+1]["TotalMatches"] == nil then
			PlayerStorage[i+1]["TotalMatches"] = 0
		end		
		if PlayerStorage[i+1]["LastMatch10"] == nil then
			PlayerStorage[i+1]["LastMatch10"] = {0,0,0,0,0,0,0,0,0,0} -- 0:null 1:win 2:lose
			--print("LastMatch10 init")
		end
		if PlayerStorage[i+1]["LastMatch10Point"] == nil then
			PlayerStorage[i+1]["LastMatch10Point"] = 1
			--print("LastMatch10Point init")
		end
		if PlayerStorage[i+1]["EloType"] == nil then
			PlayerStorage[i+1]["EloType"] = 1 --new type: 3000 base, 50 variation; old type without label: 1000 base, 20 variation
			if PlayerStorage[i+1]["Elo"] ~= nil then
				PlayerStorage[i+1]["Elo"] = 3*PlayerStorage[i+1]["Elo"]
				--print("Elo init")
			end
			--print("Elo type init")
		end
		if PlayerStorage[i+1]["Elo"] == nil then
			PlayerStorage[i+1]["Elo"] = BaseElo
			--print("Elo init")
		end
		if PlayerStorage[i+1]["HostQuality"] == nil then
			PlayerStorage[i+1]["HostQuality"] = 0 -- 0:A,1:B,2:C
			--print("HostQ init")
		end
		if PlayerStorage[i+1]["NewPlayerHint"] == nil then
			PlayerStorage[i+1]["NewPlayerHint"] = 0 -- 0: true; 1: false
			--print("NewPlayerHint init")
		end
		--DeepPrintTable(PlayerStorage[i+1])
	end)
end
		
function CagsGameMode:StoragePut(i)
	if PlayerStorage[i+1]==nil then
		return nil
	end
	--DeepPrintTable(PlayerStorage[i+1])
	--Storage:Put( 90021, PlayerStorage[i+1], function( resultTable, successBool )
	Storage:Put( PlayerResource:GetSteamAccountID(i), PlayerStorage[i+1], function( resultTable, successBool )
    if successBool then
       --print("Successfully put data in storage")
    end
  end)
end

function CagsGameMode:StorageClear(i)
	Storage:Put( PlayerResource:GetSteamAccountID(i), {}, function( resultTable, successBool )
    if successBool then
       --print("Successfully put data in storage")
    end
	end)
end

function CagsGameMode:WinStreakBC(i)
	if PlayerStorage[i+1]==nil then
		return nil
	end
	LastMatch10String = ""
	for j = PlayerStorage[i+1]["LastMatch10Point"], (PlayerStorage[i+1]["LastMatch10Point"]+9) do
		k = (j-1) % 10 +1
		if PlayerStorage[i+1]["LastMatch10"][k] == 1 then
			LastMatch10String = LastMatch10String.."W"
		elseif PlayerStorage[i+1]["LastMatch10"][k] == 2 then
			LastMatch10String = LastMatch10String.."L"
		end
	end
	if LastMatch10String == "" then
		LastMatch10String = "No Record"
	end
	--GameRules:SendCustomMessage("%s1 WinStreak: "..PlayerStorage[i+1]["WinStreak"].."; HighestHistoryWinStreak: "..PlayerStorage[i+1]["WinStreakHistory"], i, 0)
	--Say(PlayerResource:GetPlayer(i),"Win streak: "..PlayerStorage[i+1]["WinStreak"].."; History streak: "..PlayerStorage[i+1]["WinStreakHistory"].."; Last 10 games: "..LastMatch10String, false)     
	Say(PlayerResource:GetPlayer(i),"_"..PlayerResource:GetPlayerName(i).." Rank: "..math.floor(PlayerStorage[i+1]["Elo"]).."; Matches: "..PlayerStorage[i+1]["TotalMatches"].."; Wins: "..PlayerStorage[i+1]["TotalWins"].."; Streak: "..PlayerStorage[i+1]["WinStreak"].."; History stk: "..PlayerStorage[i+1]["WinStreakHistory"].."; Last 10: "..LastMatch10String, false)     
  
  Notifications:TopToAll({hero=PlayerResource:GetSelectedHeroName(i), duration=20.0, style={["font-size"]="20px"}})
  Notifications:TopToAll({text=PlayerResource:GetPlayerName(i).." ", continue=true, style={["font-size"]="20px"}})
  
  Notifications:TopToAll({text="#addon_rank", continue=true, style={["font-size"]="20px"}})
  Notifications:TopToAll({text=(math.floor(PlayerStorage[i+1]["Elo"])).."", continue=true, style={["font-size"]="20px"}})
  
  Notifications:TopToAll({text="#addon_total_matches", continue=true, style={["font-size"]="20px"}})
  Notifications:TopToAll({text=PlayerStorage[i+1]["TotalMatches"].."", continue=true, style={["font-size"]="20px"}})
  
  Notifications:TopToAll({text="#addon_total_wins", continue=true, style={["font-size"]="20px"}})
  Notifications:TopToAll({text=PlayerStorage[i+1]["TotalWins"].."", continue=true, style={["font-size"]="20px"}})

  Notifications:TopToAll({text="#addon_winstreak", continue=true, style={["font-size"]="20px"}})
  Notifications:TopToAll({text=PlayerStorage[i+1]["WinStreak"].."", continue=true, style={["font-size"]="20px"}})
  
  Notifications:TopToAll({text="#addon_winstreak_history", continue=true, style={["font-size"]="20px"}})
  Notifications:TopToAll({text=PlayerStorage[i+1]["WinStreakHistory"].."", continue=true, style={["font-size"]="20px"}})
  
  Notifications:TopToAll({text="#addon_last_ten_games", continue=true, style={["font-size"]="20px"}})
  Notifications:TopToAll({text=LastMatch10String, continue=true, style={["font-size"]="20px"}})

end

function CagsGameMode:WinStreakChange(i,flag)
	if PlayerStorage[i+1]==nil then
		return nil
	end
	PlayerStorage[i+1]["TotalMatches"] = PlayerStorage[i+1]["TotalMatches"] + 1
	if flag then
		PlayerStorage[i+1]["WinStreak"] = PlayerStorage[i+1]["WinStreak"] + 1
		if PlayerStorage[i+1]["WinStreak"] > PlayerStorage[i+1]["WinStreakHistory"] then
			PlayerStorage[i+1]["WinStreakHistory"] = PlayerStorage[i+1]["WinStreak"]
		end
		PlayerStorage[i+1]["TotalWins"] = PlayerStorage[i+1]["TotalWins"] + 1
		PlayerStorage[i+1]["LastMatch10"][PlayerStorage[i+1]["LastMatch10Point"]] = 1
		PlayerStorage[i+1]["LastMatch10Point"] = PlayerStorage[i+1]["LastMatch10Point"] % 10 + 1
	else
		PlayerStorage[i+1]["WinStreak"] = 0
		PlayerStorage[i+1]["LastMatch10"][PlayerStorage[i+1]["LastMatch10Point"]] = 2
		PlayerStorage[i+1]["LastMatch10Point"] = PlayerStorage[i+1]["LastMatch10Point"] % 10 + 1
	end
	--DeepPrintTable(PlayerStorage[i+1])
end

function CagsGameMode:EloChange(i,delta)
	if PlayerStorage[i+1]==nil then
		return nil
	end
	PlayerStorage[i+1]["Elo"] = PlayerStorage[i+1]["Elo"] + delta
end

function CagsGameMode:OnHeroPicked( event )
	--DeepPrintTable(event)
	local heroString = event.hero
	--print(heroString)
	local playerHero = EntIndexToHScript(event.heroindex)
	local playerID = playerHero:GetPlayerID()
	PlayerIDtoHeroIndex[playerID+1] = event.heroindex
	--print(playerHero:GetPlayerID())
	--print(PlayerResource:GetTeam(playerID))
	--print(playerHero:GetUnitName())
	--print(PlayerResource:HasRandomed(playerID))
	--print(PlayerResource:HasRepicked(playerID))
	--print((playerHero:GetUnitName()):sub(15,string.len(heroString)))
	PlayerSelect[playerID+1] = true
	if (PlayerResource:HasRandomed(playerID) and not(PlayerResource:HasRepicked(playerID))) then
		PlayerResource:ModifyGold(playerID, 175, false, 0)
	end
	if PlayerTeam[playerID+1] == 2 then
		PlayerResource:ModifyGold(playerID, PlayerResource:GetGold(playerID)*(RadiantGC-1)+625*RadiantGC*(5-RadiantPlayers)/RadiantPlayers, false, 0)
	end
	if PlayerTeam[playerID+1] == 3 then
		PlayerResource:ModifyGold(playerID, PlayerResource:GetGold(playerID)*(DireGC-1)+625*DireGC*(5-DirePlayers)/DirePlayers, false, 0)
	end
	--[[
	if heroString =="npc_dota_hero_ursa" then
		spawnedAbility = playerHero:FindAbilityByName("sniper_take_aim")
		spawnedAbility:SetLevel(4)
	end	
	]]
	if heroString =="npc_dota_hero_lone_druid" then
		DruidExist = true
		DruidHero = playerHero
		playerHero:AddItemByName("item_ultimate_scepter")
		Druid_Scepter=playerHero:GetItemInSlot(0)
		playerHero:SetCanSellItems(false)
		GameRules:GetGameModeEntity():SetThink( "DruidSellableThink", self, "DST", 12)	
		--print(DruidExist)
	end
	if heroString =="npc_dota_hero_pudge" then
		PudgeExist = true
		PudgeHero = playerHero
		PudgeHookSum = 0
		PudgeHookSuccess = 0
		MeatHookDead = false
		PudgeMpSet = true
	end
	if heroString =="npc_dota_hero_mirana" then
		MiranaExist = true
		MiranaHero = playerHero
		MiranaArrowSum = 0
		MiranaArrowSuccess = 0
	end
end

function CagsGameMode:DruidSellableThink()
	if DruidExist then
		--print("Druid can sell")
		DruidHero:SetCanSellItems(true)
	end
	return nil
end

function CagsGameMode:NewPlayerHintThink()
	for i = 0,31 do
		if (PlayerTeam[i+1]==2) or (PlayerTeam[i+1]==3) then
			--print(PlayerStorage[i+1]["NewPlayerHint"])
			if PlayerStorage[i+1] then
				if PlayerStorage[i+1]["NewPlayerHint"]==0 then
					ShowGenericPopupToPlayer(PlayerResource:GetPlayer(i), "#addon_credit_newplayer_01", "#addon_credit_newplayer_02", "", "", 1)
				end
			end
		end
	end
	return nil
end

function CagsGameMode:OnNpcSpawned( event )
	local spawnedUnit = EntIndexToHScript( event.entindex )
	local spawendUnitName = spawnedUnit:GetUnitName()
	--print(event.entindex,spawendUnitName, " spawned")
	--[[
	if spawendUnitName == "npc_dota_lone_druid_bear1" then
		if spawnedUnit:HasAbility("sniper_take_aim")==false then spawnedUnit:AddAbility("sniper_take_aim") end
		spawnedAbility = spawnedUnit:FindAbilityByName("sniper_take_aim")
		spawnedAbility:SetLevel(4)
		return
	end
	if spawendUnitName == "npc_dota_lone_druid_bear2" then
		if spawnedUnit:HasAbility("sniper_take_aim")==false then spawnedUnit:AddAbility("sniper_take_aim") end
		spawnedAbility = spawnedUnit:FindAbilityByName("sniper_take_aim")
		spawnedAbility:SetLevel(4)
		return
	end
	if spawendUnitName == "npc_dota_lone_druid_bear3" then
		if spawnedUnit:HasAbility("sniper_take_aim")==false then spawnedUnit:AddAbility("sniper_take_aim") end
		spawnedAbility = spawnedUnit:FindAbilityByName("sniper_take_aim")
		spawnedAbility:SetLevel(4)
		return
	end
	if spawendUnitName == "npc_dota_lone_druid_bear4" then
		if spawnedUnit:HasAbility("sniper_take_aim")==false then spawnedUnit:AddAbility("sniper_take_aim") end
		spawnedAbility = spawnedUnit:FindAbilityByName("sniper_take_aim")
		spawnedAbility:SetLevel(4)
		return
	end
	]]
	if (spawendUnitName == "npc_dota_hero_pudge") and (MeatHookDead == true) then
		--SendToServerConsole("stopsound")
		MeatHookDead = false
		PudgeHero:SetOrigin(PudgeLocation)
		PudgeHero:SetForwardVector(PudgeForward)
		PudgeHero:SetHealth(PudgeHp)
		return
	end
end

function CagsGameMode:PudgeSuicideThink()
	PudgeHero:SetMana(PudgeMp)
	return nil
end

function CagsGameMode:PudgeCancelBackswingThink()
	local modifer = PudgeHero:FindModifierByName("modifier_followthrough")
	modifer:Destroy()
	return nil
end

function CagsGameMode:OnPlayerUseAbility( event )

	local abilityName = event.abilityname
	local player = PlayerResource:GetPlayer(event.PlayerID)
	local playerHero = player:GetAssignedHero()
	local playerName = playerHero:GetUnitName()

--[[	--Abandon simulation
	PlayerTeam[2+CountN]=2
	AbandonTest[2+CountN]=true
	if CountN == 0 then RadiantPlayers=5 RadiantPlayersNow=5 RadiantGC=1 end
	CountN = CountN + 1
]]
--[[	--Storage test
	TableUpload={CountN}
	--TableUpload={PlayerResource:GetSteamAccountID(0)}
	--print(TableUpload[1])
	Storage:Put( PlayerResource:GetSteamAccountID(0), TableUpload, function( resultTable, successBool )
    if successBool then
        print("Successfully put data in storage")
    end
	end)
	Storage:Get( PlayerResource:GetSteamAccountID(0), function( resultTable, successBool )
    if successBool then
        DeepPrintTable(resultTable)
    end
	end)
	CountN = CountN + 1
	]]
--[[	--Win Streak Storage test
	--CagsGameMode:StorageClear(0)
	--CagsGameMode:WinStreakBC(0)
	--CagsGameMode:WinStreakChange(0,true)
	--CagsGameMode:WinStreakChange(0,false)
	]]
	
	--player:GetAssignedHero():AddNewModifier(player,nil,"MODIFIER_PROPERTY_IS_ILLUSION",{30})
	--player:SetMusicStatus(DOTA_MUSIC_STATUS_BATTLE,10000)

--[[ --legacy
	if (abilityName=="pudge_meat_hook") and (playerName=="npc_dota_hero_pudge") and not(PudgeAbandon) then
		PudgeHookSum = PudgeHookSum + 1
		_G.PUDGE_HOOK_SUM = PudgeHookSum
		--GameRules:SendCustomMessage("Pudge's No."..PudgeHookSum.." suicide hook is on the way!", 0, 1)
		--Say(PudgeHero,"Pudge's No."..PudgeHookSum.." suicide hook is coming!", false)
  	Notifications:BottomToAll({text="#addon_pudge_hook", duration=5.0, style={color="red", ["font-size"]="30px"}})				
		PudgeLocation = PudgeHero:GetOrigin()
		PudgeForward = PudgeHero:GetForwardVector()
		PudgeHp = PudgeHero:GetHealth()
		PudgeMp = PudgeHero:GetMana()
		--Hook = PudgeHero:FindAbilityByName("pudge_meat_hook")
		--HookLevel = Hook:GetLevel()
		MeatHookDead = true
		PudgeHero:ForceKill(false)
		GameRules:GetGameModeEntity():SetThink( "PudgeSuicideThink", self, "PST", 0.2)
	end
	]]
	
	if (abilityName=="pudge_meat_hook") and (playerName=="npc_dota_hero_pudge") and not(PudgeAbandon) then
		PudgeHookSum = PudgeHookSum + 1
  	Notifications:BottomToAll({text="#addon_pudge_hook", duration=5.0, style={color="red", ["font-size"]="30px"}})				
		GameRules:GetGameModeEntity():SetThink( "PudgeCancelBackswingThink", self, "PST", 0.4)
	end
	
	if (abilityName=="mirana_arrow") and (playerName=="npc_dota_hero_mirana") and not(MiranaAbandon) then
		MiranaArrowSum = MiranaArrowSum + 1
		--Say(MiranaHero,"Mirana's No."..MiranaArrowSum.." Arrow is coming!", false)
  	Notifications:BottomToAll({text="#addon_mirana_arrow", duration=5.0, style={color="blue", ["font-size"]="30px"}})				
	end
	if (abilityName=="techies_suicide") and (playerName=="npc_dota_hero_techies") then
		TechiesSuicide = true
	end
end

function CagsGameMode:OnEntityHurt( event )
  --print(event.entindex_inflictor)
	local killed = EntIndexToHScript(event.entindex_killed)
	local attack = EntIndexToHScript(event.entindex_attacker)
	--print(attack:GetName())
	if event.entindex_inflictor ~= nil then
		local inflict = EntIndexToHScript(event.entindex_inflictor)
		--print(killed:GetName(),attack:GetName(),inflict:GetName())
  	if (attack:GetName()=="npc_dota_hero_pudge") and (inflict:GetName() == "pudge_meat_hook") and (killed:IsRealHero() == true) and not(PudgeAbandon) then
			PudgeHookSuccess = PudgeHookSuccess + 1
			--Say(PudgeHero,"Pudge hooks accuracy: "..PudgeHookSuccess.."/"..PudgeHookSum.."="..(math.floor((PudgeHookSuccess/PudgeHookSum)*1000)/10).."%"., false)
  		Notifications:BottomToAll({text="#addon_pudge_hook_accuracy", duration=5.0, style={["font-size"]="30px"}})				
  		Notifications:BottomToAll({text=PudgeHookSuccess.."/"..PudgeHookSum.."="..(math.floor((PudgeHookSuccess/PudgeHookSum)*1000)/10).."%", duration=5.0, continue=true, style={["font-size"]="30px"}})				
  	end
  	if (attack:GetName()=="npc_dota_hero_mirana") and (inflict:GetName() == "mirana_arrow") and (killed:IsRealHero() == true) and not(MiranaAbandon) then
			MiranaArrowSuccess = MiranaArrowSuccess + 1
			--Say(MiranaHero,"Mirana arrows accuracy: "..MiranaArrowSuccess.."/"..MiranaArrowSum.."="..(math.floor((MiranaArrowSuccess/MiranaArrowSum)*1000)/10).."%.", false)
  		Notifications:BottomToAll({text="#addon_mirana_arrow_accuracy", duration=5.0, style={["font-size"]="30px"}})				
  		Notifications:BottomToAll({text=MiranaArrowSuccess.."/"..MiranaArrowSum.."="..(math.floor((MiranaArrowSuccess/MiranaArrowSum)*1000)/10).."%", duration=5.0, continue=true, style={["font-size"]="30px"}})				
  	end
  end
  --print(killed:GetUnitName())
  --print(killed:GetHealthPercent())
  if (((killed:GetUnitName()=="npc_dota_badguys_fort")or(killed:GetUnitName()=="npc_dota_goodguys_fort"))and(killed:GetHealthPercent()<100)and(FinalNotice==false)) then
  	FinalNotice = true
  	for i = 0, 31 do
			if (PlayerTeam[i+1]== 2)or(PlayerTeam[i+1]== 3) then
			
				CagsGameMode:StorageGet(i)
				if PlayerResource:GetPlayer(i) then
					if PlayerResource:GetPlayer(i):GetAssignedHero() then
						if PlayerResource:GetPlayer(i):GetAssignedHero():FindModifierByName("modifier_item_moon_shard_consumed") then
							_G.MoonShardBuff[i+1]=1
						end
					end
				end
				
			end	
		end
  end
end

function CagsGameMode:OnEntityKilled( event )
	--DeepPrintTable(event)
	--print (event.entindex_attacker:GetName())
	local killedUnit = EntIndexToHScript( event.entindex_killed )
	local killedUnitName = killedUnit:GetUnitName()
	local killedUnitTeam = killedUnit:GetTeam()
	local attackUnit = EntIndexToHScript( event.entindex_attacker )
	local attackUnitName = attackUnit:GetUnitName()
	local attackUnitTeam = attackUnit:GetTeam()
	local inflictName = "wtf"
	--print(killedUnitTeam, killedUnitName, "killed",attackUnitTeam, attackUnitName, "attack")
	if event.entindex_inflictor~=void then
		inflictName = EntIndexToHScript( event.entindex_inflictor ):GetName()
		--print (inflictName)
	end
	if killedUnit:IsRealHero() then
		--print("Hero has been killed")
		if killedUnit:IsReincarnating() == false then
			--print("Setting time for respawn")

			local respawnTime = killedUnit:GetLevel()*2	
			local playerID = killedUnit:GetPlayerID()

			if (killedUnitTeam==DOTA_TEAM_GOODGUYS) and (attackUnitTeam==DOTA_TEAM_BADGUYS) then
				DireScore = DireScore+1
				GameRules:GetGameModeEntity():SetTopBarTeamValue(DOTA_TEAM_BADGUYS,DireScore)
				RespawnPenalty[playerID+1] = RespawnPenalty[playerID+1] + 0.5
			end
			if (killedUnitTeam==DOTA_TEAM_BADGUYS) and (attackUnitTeam==DOTA_TEAM_GOODGUYS) then
				RadiantScore = RadiantScore+1
				GameRules:GetGameModeEntity():SetTopBarTeamValue(DOTA_TEAM_GOODGUYS,RadiantScore)
				RespawnPenalty[playerID+1] = RespawnPenalty[playerID+1] + 0.5
			end
			if killedUnitName=="npc_dota_hero_meepo" then
				respawnTime = respawnTime + killedUnit:GetDeaths()*0.5
			else
				respawnTime = respawnTime + RespawnPenalty[playerID+1]
			end
			respawnTime = respawnTime + killedUnit:GetKills()*0.5

			if inflictName=="necrolyte_reapers_scythe" then
				respawnTime = respawnTime + 15
			end

			if (TechiesSuicide == true) and (killedUnitName == "npc_dota_hero_techies") then
					respawnTime = respawnTime / 2
					TechiesSuicide = false
			end

			if killedUnitTeam==DOTA_TEAM_GOODGUYS then
				respawnTime = respawnTime*(RadiantPlayersNow/5)^0.5			
			end
			if killedUnitTeam==DOTA_TEAM_BADGUYS then
				respawnTime = respawnTime*(DirePlayersNow/5)^0.5			
			end
			respawnTime = math.floor(respawnTime)
			if respawnTime ==0 then
				respawnTime = 1
			end
			if PlayerAbandon[playerID+1]==false then
				killedUnit:SetTimeUntilRespawn(respawnTime)
			else
				killedUnit:SetTimeUntilRespawn(300)		
			end
			if _G.AbandonTest[playerID+1] then
  			Notifications:BottomToAll({hero=PlayerResource:GetSelectedHeroName(playerID), imagestyle="landscape", duration=10.0})
  			Notifications:BottomToAll({text="#addon_abandon_and_spectate", continue=true, style={["font-size"]="30px"}})
				killedUnit:SetTimeUntilRespawn(9999)
			end
			
			if HostQualityPunish and (playerID==PlayerHost)then
				killedUnit:SetTimeUntilRespawn(120)
				HostQualityPunish = false
			end
			if (MeatHookDead)and(killedUnitName == "npc_dota_hero_pudge") then
				killedUnit:SetTimeUntilRespawn(0)
			end
		end
	end
	
	if killedUnitName=="npc_dota_badguys_fort" then
		--print("radiant win")
		_G.GAME_WINNER_TEAM = "Radiant"
		if WinStreakRecord then

			if PlayerHostTeam==2 then
				CagsGameMode:EloChange(PlayerHost,DireEloDeltaSav*5)
				--DeepPrintTable(PlayerStorage[PlayerHost+1])
				for j = 0, 31 do
					if PlayerTeam[j+1]==3 then
						CagsGameMode:EloChange(j,-DireEloDeltaSav)	
					end			
				end		
			elseif PlayerHostTeam==3 then
				CagsGameMode:EloChange(PlayerHost,RadiantEloDeltaSav*5)
				--DeepPrintTable(PlayerStorage[PlayerHost+1])
				for j = 0, 31 do
					if PlayerTeam[j+1]==2 then
						CagsGameMode:EloChange(j,-RadiantEloDeltaSav)	
					end			
				end		
			end
			
			CagsGameMode:EloCalc()

			for i = 0,31 do
				if PlayerTeam[i+1]==2 then
					CagsGameMode:WinStreakChange(i,true)
					CagsGameMode:EloChange(i,RadiantEloDelta)
				elseif PlayerTeam[i+1]==3 then
					CagsGameMode:WinStreakChange(i,false)
					CagsGameMode:EloChange(i,-RadiantEloDelta)
				end
			end
			--WinStreakRecord = false
		end
	elseif killedUnitName=="npc_dota_goodguys_fort" then
		--print("dire win")
		_G.GAME_WINNER_TEAM = "Dire"																										
		if WinStreakRecord then

			if PlayerHostTeam==2 then
				CagsGameMode:EloChange(PlayerHost,DireEloDeltaSav*5)
				--DeepPrintTable(PlayerStorage[PlayerHost+1])
				for j = 0, 31 do
					if PlayerTeam[j+1]==3 then
						CagsGameMode:EloChange(j,-DireEloDeltaSav)	
					end			
				end		
			elseif PlayerHostTeam==3 then
				CagsGameMode:EloChange(PlayerHost,RadiantEloDeltaSav*5)
				--DeepPrintTable(PlayerStorage[PlayerHost+1])
				for j = 0, 31 do
					if PlayerTeam[j+1]==2 then
						CagsGameMode:EloChange(j,-RadiantEloDeltaSav)	
					end			
				end		
			end
			
			CagsGameMode:EloCalc()

			for i = 0,31 do
				if PlayerTeam[i+1]==2 then
					CagsGameMode:WinStreakChange(i,false)
					CagsGameMode:EloChange(i,-DireEloDelta)
				elseif PlayerTeam[i+1]==3 then
					CagsGameMode:WinStreakChange(i,true)
					CagsGameMode:EloChange(i,DireEloDelta)
				end
			end
			--WinStreakRecord = false
		end
	end

	if ((killedUnitName=="npc_dota_badguys_fort") or (killedUnitName=="npc_dota_goodguys_fort")) then
		
		if PlayerHost then
			if HostRecord then
				CagsGameMode:HostQualityIncrease()
			end
		end
		
		CagsGameMode:NewPlayerHintChange()	
		
		for i = 0, 31 do
			if (PlayerTeam[i+1]==2) or (PlayerTeam[i+1]==3) then
				CagsGameMode:StoragePut(i)
				--DeepPrintTable(PlayerStorage[i+1])
				if WinStreakRecord then
					CagsGameMode:WinStreakBC(i)
				end
			end
		end

		if PudgeExist then
			--Say(PudgeHero,"Pudge hooks accuracy: "..PudgeHookSuccess.."/"..PudgeHookSum.."="..(math.floor((PudgeHookSuccess/PudgeHookSum)*1000)/10).."%".." (on scoreboard deduct "..PudgeHookSum.." from pudge's deaths)", false) 
			Notifications:BottomToAll({text="#addon_pudge_hook_accuracy", duration=20.0, style={["font-size"]="30px"}})				
			Notifications:BottomToAll({text=PudgeHookSuccess.."/"..PudgeHookSum.."="..(math.floor((PudgeHookSuccess/PudgeHookSum)*1000)/10).."% ", continue=true, style={["font-size"]="30px"}})				
			--Notifications:BottomToAll({text="#addon_pudge_death_deduct_03", continue=true, style={["font-size"]="30px"}})				
			--Notifications:BottomToAll({text=(PudgeHero:GetDeaths()-PudgeHookSum).."", continue=true, style={["font-size"]="30px"}})				
			--Notifications:BottomToAll({text="#addon_pudge_death_deduct_04", continue=true, style={["font-size"]="30px"}})
		end
		if MiranaExist then
			--Say(MiranaHero,"Mirana arrows accuracy: "..MiranaArrowSuccess.."/"..MiranaArrowSum.."="..(math.floor((MiranaArrowSuccess/MiranaArrowSum)*1000)/10).."%", false)
			Notifications:BottomToAll({text="#addon_mirana_arrow_accuracy", duration=20.0, style={["font-size"]="30px"}})				
			Notifications:BottomToAll({text=MiranaArrowSuccess.."/"..MiranaArrowSum.."="..(math.floor((MiranaArrowSuccess/MiranaArrowSum)*1000)/10).."%", continue=true, style={["font-size"]="30px"}})					
		end
		if PudgeExist then
			GameRules:SendCustomMessage("Pudge hooks accuracy: "..PudgeHookSuccess.."/"..PudgeHookSum.."="..(math.floor((PudgeHookSuccess/PudgeHookSum)*1000)/10).."%", 0, 1)
			--GameRules:SendCustomMessage("Pudge's actual deaths: "..(PudgeHero:GetDeaths()-PudgeHookSum), 0, 1)
			--Say(PudgeHero,"Pudge hooks accuracy: "..PudgeHookSuccess.."/"..PudgeHookSum.."="..(math.floor((PudgeHookSuccess/PudgeHookSum)*1000)/10).."%".." (on scoreboard deduct "..PudgeHookSum.." from pudge's deaths)", false)
		end
		if MiranaExist then
			GameRules:SendCustomMessage("Mirana arrows accuracy: "..MiranaArrowSuccess.."/"..MiranaArrowSum.."="..(math.floor((MiranaArrowSuccess/MiranaArrowSum)*1000)/10).."%", 0, 1)
			--Say(MiranaHero,"Mirana arrows accuracy: "..MiranaArrowSuccess.."/"..MiranaArrowSum.."="..(math.floor((MiranaArrowSuccess/MiranaArrowSum)*1000)/10).."%", false)
		end
		
	end
	
	
end

function CagsGameMode:HostQualityIncrease()
	if PlayerStorage[PlayerHost+1] == nil then
		return nil
	end
	PlayerStorage[PlayerHost+1]["HostQuality"] = HostQualityOrigin		
	if PlayerStorage[PlayerHost+1]["HostQuality"]>0 then
		PlayerStorage[PlayerHost+1]["HostQuality"] = PlayerStorage[PlayerHost+1]["HostQuality"] - 1
	end
end

function CagsGameMode:NewPlayerHintChange()
	for i=0,31 do
		if (PlayerTeam[i+1]==2)or(PlayerTeam[i+1]==3) then
			if PlayerStorage[i+1] then
				if PlayerStorage[i+1]["NewPlayerHint"]==0 then
					PlayerStorage[i+1]["NewPlayerHint"] = 1
				end
			end
		end
	end
end

function CagsGameMode:OnPlayerSay( event )
	--DeepPrintTable(event)
	--print(PlayerResource:GetPlayerName(event.userid-1))
	--GameRules:SendCustomMessage("debug: "..event.userid,0,0)
	if event.text=="-abandon" then
		
	end
end

function CagsGameMode:OnScoreChanged(event)
end

function CagsGameMode:OnPlayerDisconnect( event )
	--DeepPrintTable(event)
end

function CagsGameMode:OnPlayerReconnect( event )
	--DeepPrintTable(event)
end

function CagsGameMode:OnGameEnd( event )
end