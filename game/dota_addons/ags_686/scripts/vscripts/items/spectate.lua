function SpectateAndAbandon(keys)
	caster = keys.caster
	if caster:IsRealHero() then		
		i = caster:GetPlayerOwnerID()
		_G.AbandonTest[i+1]=true
		hero = PlayerResource:GetSelectedHeroEntity(i)
		itemCost = 0
		for k = 0, 14 do
			if hero:GetItemInSlot(k) then
				itemCost = itemCost + hero:GetItemInSlot(k):GetCost()
				hero:RemoveItem(hero:GetItemInSlot(k))
			end
		end
		if(PlayerResource:GetSelectedHeroName(i)=="npc_dota_hero_lone_druid") then
			itemCost = itemCost - 4200
		end
		PlayerResource:ModifyGold(i,math.floor(itemCost), false, 0)
		hero:SetMana(0)
		hero:ForceKill(false)
	end
end