function SpectateAndAbandon(keys)
	caster = keys.caster
	if caster:IsRealHero() then		
		i = caster:GetPlayerOwnerID()
		_G.AbandonTest[i+1]=true
		hero = PlayerResource:GetSelectedHeroEntity(i)
		itemCost = 0
		for k = 0, 11 do
			if hero:GetItemInSlot(k) then
				itemCost = itemCost + hero:GetItemInSlot(k):GetCost()
				hero:RemoveItem(hero:GetItemInSlot(k))
			end
		end
		PlayerResource:ModifyGold(i,math.floor(itemCost)+100, false, 0)
		PlayerResource:SetBuybackCooldownTime(i,9999)
		hero:SetMana(0)
		hero:ForceKill(false)
	end
end