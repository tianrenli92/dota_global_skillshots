function AttrBonus(keys)
	caster = keys.caster
	ability = keys.ability
	attr = keys.Attr
	cost = keys.Cost
	modifier = keys.Modifier_apply
	if caster:IsRealHero() then
		--caster:ModifyStrength(attr)
		--caster:ModifyAgility(attr)
		--caster:ModifyIntellect(attr)
		if caster:HasModifier(modifier)==false then
			ability:ApplyDataDrivenModifier(caster, caster, modifier, {})
			caster:SetModifierStackCount(modifier, ability, 1)		
			_G.AttrBonusStacks[caster:GetPlayerOwnerID()+1] = 1
		else
			stacks = caster:GetModifierStackCount(modifier, ability)
			caster:SetModifierStackCount(modifier, ability, stacks + 1)
			_G.AttrBonusStacks[caster:GetPlayerOwnerID()+1] = stacks + 1
		end
	else
		PlayerResource:ModifyGold(caster:GetPlayerOwnerID(),cost, false, 0)
	end
end