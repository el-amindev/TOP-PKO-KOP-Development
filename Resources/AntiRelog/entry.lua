-- Declare a global variable (for the gameserver) storing the list
-- of people currently in CA.
local charactersInCA = { }

-- Declare the delay in seconds before somene can re-enter after
-- leaving it
local CA_SUSPENSION_TIME = 300

-- Define additionnal punishments for loggers
local CA_POINT_LOSSES = 5             -- Amount of CA point lost on logout
local HONOR_POINT_LOSSES = 5          -- Amount of Honor point lost on logout
local REPUTATION_POINT_LOSSES = 100   -- Amount of Reputation point lost on logout

function config_entry(entry) 
    SetMapEntryEntiID(entry,2492,1) --ÉèÖÃµØÍ¼Èë¿ÚÊµÌåµÄ±àºÅ£¨¸Ã±àºÅ¶ÔÓ¦ÓÚcharacterinfo.txtµÄË÷Òý£©

end 

function after_create_entry(entry) 
    local copy_mgr = GetMapEntryCopyObj(entry, 0) --´´½¨¸±±¾¹ÜÀí¶ÔÏó£¬´Ëº¯ÊýÔÚÓÐÏÔÊ½Èë¿ÚµÄµØÍ¼ÖÐ±ØÐëµ÷ÓÃ£¬¶ÔÓÚÒþÊ½Èë¿ÚµÄµØÍ¼£¨Èç¶ÓÎéÌôÕ½£©ÎÞÒªµ÷ÓÃ¸Ã½Ó¿Ú
    local EntryName = "Chaos Argent"
    SetMapEntryEventName( entry, EntryName )
    
    map_name, posx, posy, tmap_name = GetMapEntryPosInfo(entry) --È¡µØÍ¼Èë¿ÚµÄÎ»ÖÃÐÅÏ¢£¨µØÍ¼Ãû£¬×ø±ê£¬Ä¿±êµØÍ¼Ãû£©
    Notice("Announcement: According to reports, near Ascaron at ["..posx..","..posy.."] appears a portal to Chaos Argent. Please check it out.") --Í¨Öª±¾×é·þÎñÆ÷µÄËùÓÐÍæ¼Ò

end

function after_destroy_entry_garner2(entry)
    map_name, posx, posy, tmap_name = GetMapEntryPosInfo(entry) 
    Notice("Announcement: According to reports, portal to [Chaos Argent] has vanished. Check announcement for more details. Enjoy!") 

end

function after_player_login_garner2(entry, player_name)
    map_name, posx, posy, tmap_name = GetMapEntryPosInfo(entry) --È¡µØÍ¼Èë¿ÚµÄÎ»ÖÃÐÅÏ¢£¨µØÍ¼Ãû£¬×ø±ê£¬Ä¿±êµØÍ¼Ãû£©
    ChaNotice(player_name, "Announcement: According to reports, near Ascaron at ["..posx..","..posy.."] appears a portal to Chaos Argent. Please check it out.") --Í¨Öª±¾×é·þÎñÆ÷µÄËùÓÐÍæ¼Ò

end






function check_can_enter_garner2( role, copy_mgr )
	local FightingBook_Num = 0
	FightingBook_Num = CheckBagItem( role,3849 )
	local Team_In = IsInTeam(role)
	if Team_In == 1 then
		SystemNotice ( role , "Cannot Enter in Party to Chaos Argent" )
		return 0
		
	end
	if FightingBook_Num <= 0 then
		SystemNotice ( role , "Non hai la Medal of Valor. Non puoi entrare in Chaos Argent" )
		return 0
	elseif FightingBook_Num > 1 then
		LG("RYZ_PK","Non hai la Medal of Valor. Non puoi entrare in Chaos Argent")
		return 0
	end
	local role_RY = GetChaItem2 ( role , 2 , 3849 )
	local HonorPoint = GetItemAttr ( role_RY , ITEMATTR_VAL_STR)

	if HonorPoint < 20 then
		SystemNotice ( role , "Servono almeno 20 honor points per entrare a Chaos Argent" )
		return 0
	end

	if HonorPoint >30000 then
		SystemNotice ( role , "Too much Honor Points unable to participate" )
		return 0
	end
	local characterName = GetChaDefaultName(role)
	if (charactersInCA[characterName] ~= null) then
	local timeToWait = charactersInCA[characterName].timeToReEnter - os.time()
	if (timeToWait > 0) then
		SystemNotice ( role , "If you want to be in Chaos Argent, stay in Chaos Argent. You wont be allowed in for another "..timeToWait.."seconds." )
		return 0
		end
	end 

--local Credit_Garner2 = GetCredit(role)
--if Credit_Garner2 < 30 then 
--	SystemNotice ( role , "You need 30 Reputation to enter Chaos Argent" )
--	return 0
	--else
--	DelCredit(role,30)
--end

	if Lv(role) < 20 then
	SystemNotice(role, "Solo i giocatori Lv 20 o più possono entrare a Chaos Argent")
		return 0    
	end
	local Has_money = check_HasMoney(role)
	if Has_money == 1 then
		
		return 1
		
	else
		SystemNotice(role,"Non hai abbastanza soldi...")
		return 0
	end
				
end

function check_HasMoney(role)
	local lv= GetChaAttr(role, ATTR_LV)
	local Money_Need = lv*50
	local Money_Have = GetChaAttr ( role , ATTR_GD )
		if Money_Have >= Money_Need then
			return 1
		end

end


function begin_enter_garner2(role, copy_mgr) 
	local	Money_Have = GetChaAttr ( role , ATTR_GD )
	local lv= GetChaAttr(role, ATTR_LV)
	local Money_Need = lv*50
	local	Money_Now = Money_Have - Money_Need
	SetChaAttrI( role , ATTR_GD , Money_Now )
		SystemNotice(role,"Entrare in [Chaos Argent] costa "..Money_Need.." ") 
		MoveCity(role, "Chaos Argent")
	Money_all = Money_all + Money_Need * 0.8
	local characterName = GetChaDefaultName(role)
	charactersInCA[characterName] = { timeToReEnter=os.time() } 
end


function before_leave_garner2 ( role )
	local characterName = GetChaDefaultName(role)

	hp = Hp(role)
	if (hp > 0) then
		Notice(characterName.." is still too weak and had to flee the battle. Go back training lad !")
		charactersInCA[characterName] = { timeToReEnter=(os.time()+CA_SUSPENSION_TIME) }
	if ((CA_POINT_LOSSES > 0) or (HONOR_POINT_LOSSES > 0)) then
		local medalOfValor = GetChaItem2 ( role , 2 , 3849 )

	if (CA_POINT_LOSSES > 0) then
		local caPoints = GetItemAttr ( medalOfValor , ITEMATTR_MAXENERGY)
		local newCaPoints = math.max((caPoints - CA_POINT_LOSSES),0)
		SetItemAttr( medalOfValor, ITEMATTR_MAXENERGY, newCaPoints )     
	end

	if (HONOR_POINT_LOSSES > 0) then
		local honor = GetItemAttr ( medalOfValor , ITEMATTR_VAL_STR)
		local newHonor = math.max((honor - HONOR_POINT_LOSSES),0)
		SetItemAttr( medalOfValor, ITEMATTR_VAL_STR, newHonor )
		end
	end

	if (REPUTATION_POINT_LOSSES > 0) then
	local reputation = GetCredit(role)
	local newReputation = math.max((reputation - REPUTATION_POINT_LOSSES),0)
	DelCredit(role,newReputation)
		end
	end
	end
end






