#include <tf2>
#include <sourcemod>
#include <functions>
#include <sdktools>
#include <tf2_stocks>
#include <tf2items>
#include <tf2attributes>
#include <tf2itemsinfo>
#include <keyvalues>
#include <sdkhooks>

#define UU_VERSION "0.9.4"

#define RED 0
#define BLUE 1

#define NB_B_WEAPONS 1

#define NB_SLOTS_UED 5

#define MAX_ATTRIBUTES 3000

#define MAX_ATTRIBUTES_ITEM 65

#define _NUMBER_DEFINELISTS 630

#define _NUMBER_DEFINELISTS_CAT 9

#define WCNAMELISTSIZE 700

#define _NB_SP_TWEAKS 60
#define MAXLEVEL_D 500

new Handle:up_menus[MAXPLAYERS + 1];
new Handle:menuBuy;
new Handle:BuyNWmenu;

new BuyNWmenu_enabled;


new Handle:cvar_uu_version;

new Handle:cvar_TimerMoneyGive_BlueTeam;
new Float:TimerMoneyGive_BlueTeam;
new Handle:cvar_TimerMoneyGive_RedTeam;
new Float:TimerMoneyGive_RedTeam;
new Handle:cvar_MoneyBonusKill;
new MoneyBonusKill;
//new Handle:cvar_MoneyForTeamRatioRed
new Handle:cvar_AutoMoneyForTeamRatio;
new Float:MoneyForTeamRatio[2];
new Float:MoneyTotalFlow[2];

new Handle:Timers_[3];


new clientLevels[MAXPLAYERS + 1];
new String:clientBaseName[MAXPLAYERS + 1][255];
new moneyLevels[MAXLEVEL_D + 1];

new given_upgrd_list_nb[_NUMBER_DEFINELISTS];
new given_upgrd_list[_NUMBER_DEFINELISTS][_NUMBER_DEFINELISTS_CAT][64];
new String:given_upgrd_classnames[_NUMBER_DEFINELISTS][_NUMBER_DEFINELISTS_CAT][64];
new given_upgrd_classnames_tweak_idx[_NUMBER_DEFINELISTS];
new given_upgrd_classnames_tweak_nb[_NUMBER_DEFINELISTS];

new String:wcnamelist[WCNAMELISTSIZE][64];
new wcname_l_idx[WCNAMELISTSIZE];
new current_w_list_id[MAXPLAYERS + 1];
new current_w_c_list_id[MAXPLAYERS + 1];

new _:current_class[MAXPLAYERS + 1];


new String:current_slot_name[6][32];
new current_slot_used[MAXPLAYERS + 1];
new currentupgrades_idx[MAXPLAYERS + 1][6][MAX_ATTRIBUTES_ITEM];
new Float:currentupgrades_val[MAXPLAYERS + 1][6][MAX_ATTRIBUTES_ITEM];
//new currentupgrades_special_ratio[MAXPLAYERS + 1][6][MAX_ATTRIBUTES_ITEM]
new currentupgrades_number[MAXPLAYERS + 1][6];

new currentitem_level[MAXPLAYERS + 1][6];
new currentitem_idx[MAXPLAYERS + 1][6];
new currentitem_ent_idx[MAXPLAYERS + 1][6];
new currentitem_catidx[MAXPLAYERS + 1][6];

new String:currentitem_classname[MAXPLAYERS + 1][6][64];

new upgrades_ref_to_idx[MAXPLAYERS + 1][6][MAX_ATTRIBUTES];
new currentupgrades_idx_mvm_chkp[MAXPLAYERS + 1][6][MAX_ATTRIBUTES_ITEM];
new Float:currentupgrades_val_mvm_chkp[MAXPLAYERS + 1][6][MAX_ATTRIBUTES_ITEM];
new currentupgrades_number_mvm_chkp[MAXPLAYERS + 1][6];

new _u_id;
new client_spent_money[MAXPLAYERS + 1][6];
new client_new_weapon_ent_id[MAXPLAYERS + 1];
new client_spent_money_mvm_chkp[MAXPLAYERS + 1][6];
new client_last_up_slot[MAXPLAYERS + 1];
new client_last_up_idx[MAXPLAYERS + 1];
new client_iCash[MAXPLAYERS + 1];


new client_respawn_handled[MAXPLAYERS + 1];
new client_respawn_checkpoint[MAXPLAYERS + 1];

new client_no_d_name[MAXPLAYERS + 1] = 1;
new client_no_d_team_upgrade[MAXPLAYERS + 1];
new client_no_d_menubuy_respawn[MAXPLAYERS + 1];

new Handle:_upg_names;
new Handle:_weaponlist_names;
new Handle:_spetweaks_names;

new String:upgradesNames[MAX_ATTRIBUTES][64];
new String:upgradesWorkNames[MAX_ATTRIBUTES][96];
new upgrades_to_a_id[MAX_ATTRIBUTES];
new upgrades_costs[MAX_ATTRIBUTES];
new Float:upgrades_ratio[MAX_ATTRIBUTES];
new Float:upgrades_i_val[MAX_ATTRIBUTES];
new Float:upgrades_m_val[MAX_ATTRIBUTES];
new Float:upgrades_costs_inc_ratio[MAX_ATTRIBUTES];
new String:upgrades_tweaks[_NB_SP_TWEAKS][64];
new upgrades_tweaks_nb_att[_NB_SP_TWEAKS];
new upgrades_tweaks_att_idx[_NB_SP_TWEAKS][10];
new Float:upgrades_tweaks_att_ratio[_NB_SP_TWEAKS][10];

new newweaponidx[128];
new String:newweaponcn[64][64];
new String:newweaponmenudesc[64][64];

new Float:CurrencyOwned[MAXPLAYERS + 1]
new Float:RealStartMoney = 0.0;

new Float:CurrencySaved[MAXPLAYERS + 1];
new Float:StartMoneySaved;
new Float:MenuTimer[MAXPLAYERS + 1];

stock bool:IsMvM(bool:forceRecalc = false)
{
	static bool:found = false;
	static bool:ismvm = false;
	if (forceRecalc)
	{
		found = false;
		ismvm = false;
	}
	if (!found)
	{
		new i = FindEntityByClassname(-1, "tf_logic_mann_vs_machine");
		if (i > MaxClients && IsValidEntity(i)) ismvm = true;
		found = true;
	}
	return ismvm;
}

public Action:Timer_WaitForTF2II(Handle:timer)
{
	new i = 0;
	if (TF2II_IsValidAttribID(1))
	{
		for (i = 1; i < 3000; i++)
		{
			if (TF2II_IsValidAttribID(i))
			{
				TF2II_GetAttributeNameByID( i, upgradesWorkNames[i], 128 );
			//	PrintToServer("%s\n", upgradesWorkNames[i]);
			}
			else
			{
			//	PrintToServer("unvalid attrib %d\n", i);
			}
		}
		for (i = 0; i < MAX_ATTRIBUTES; i++)
		{
			upgrades_ratio[i] = 0.0;
			upgrades_i_val[i] = 0.0;
			upgrades_costs[i] = 0;
			upgrades_costs_inc_ratio[i] = 0.25;
			upgrades_m_val[i] = 0.0;
		}
		for (i = 1; i < _NUMBER_DEFINELISTS; i++)
		{
			given_upgrd_classnames_tweak_idx[i] = -1;
			given_upgrd_list_nb[i] = 0;
		}
		_load_cfg_files();
		KillTimer(timer);
	}

}

public UberShopDefineUpgradeTabs()
{
	new i = 0;
	while (i < MaxClients)
	{
		client_respawn_handled[i] = 0;
		client_respawn_checkpoint[i] = 0;
		clientLevels[i] = 0;
		up_menus[i] = INVALID_HANDLE;
		new j = 0;
		while (j < NB_SLOTS_UED)
		{
			currentupgrades_number[i][j] = 0;
			currentitem_level[i][j] = 0;
			currentitem_idx[i][j] = 9999;
			client_spent_money[i][j] = 0;
			new k = 0;
			while (k < MAX_ATTRIBUTES)
			{
				upgrades_ref_to_idx[i][j][k] = 9999;
				k++;
			}
			j++;
		}
		i++;

	}

	current_slot_name[0] = "Primary Weapon";
	current_slot_name[1] = "Secondary Weapon";
	current_slot_name[2] = "Melee Weapon";
	current_slot_name[3] = "Special Weapon";
	current_slot_name[4] = "Body";
	upgradesNames[0] = "";
	CreateTimer(0.1, Timer_WaitForTF2II, _);
}

public TF2_OnConditionAdded(client, TFCond:condition)
{
	if(TF2_GetPlayerClass(client) == TFClass_Pyro && condition == TFCond_OnFire)
	{
		TF2_RemoveCondition(client, TFCond_OnFire);
	}
}
public TF2Items_OnGiveNamedItem_Post(client, String:classname[], itemDefinitionIndex, itemLevel, itemQuality, entityIndex)
{
	if (!IsFakeClient(client) && IsValidClient(client) && !TF2_IsPlayerInCondition(client, TFCond_Disguised))
	{
		if (itemLevel == 242)
		{
			new slot = 3;
			current_class[client] = _:TF2_GetPlayerClass(client);
			currentitem_ent_idx[client][slot] = entityIndex;
			if (!currentupgrades_number[client][slot])
			{
				currentitem_idx[client][slot] = 9999;
			}
			DefineAttributesTab(client, itemDefinitionIndex, slot);
			GetEntityClassname(entityIndex, currentitem_classname[client][slot], 64);
			currentitem_catidx[client][slot] = GetUpgrade_CatList(classname);

			GiveNewUpgradedWeapon_(client, slot);
			//PrintToChatAll("OGiveItem slot %d: [%s] #%d CAT[%d] qual%d", slot, classname, itemDefinitionIndex, currentitem_catidx[client][slot], itemLevel)
		}
		else
		{
			new slot = _:TF2II_GetItemSlot(itemDefinitionIndex);
			current_class[client] = _:TF2_GetPlayerClass(client);
			if (TF2_GetPlayerClass(client) == TFClass_Soldier || TF2_GetPlayerClass(client) == TFClass_Pyro || TF2_GetPlayerClass(client) == TFClass_Heavy)
			{
				if (!strcmp(classname, "tf_weapon_shotgun"))
				{
					if (itemDefinitionIndex == 199
					|| itemDefinitionIndex == 1153
					|| itemDefinitionIndex == 15003
					|| itemDefinitionIndex == 15016
					|| itemDefinitionIndex == 15044
					|| itemDefinitionIndex == 15047
					|| itemDefinitionIndex == 15085
					|| itemDefinitionIndex == 15109
					|| itemDefinitionIndex == 15132
					|| itemDefinitionIndex == 15133
					|| itemDefinitionIndex == 15152)
					{
						slot = 1;
					}
				}
			}
			if (TF2_GetPlayerClass(client) == TFClass_DemoMan)
			{
				if (!strcmp(classname, "tf_weapon_parachute"))
				{
					slot = 0;
				}
			}
			//PrintToChatAll("OGiveItem slot %d: [%s] #%d CAT[%d] qual%d", slot, classname, itemDefinitionIndex, currentitem_catidx[client][slot], itemLevel)
			currentitem_catidx[client][4] = _:TF2_GetPlayerClass(client) - 1;
			if (slot < 3)
			{
				GetEntityClassname(entityIndex, currentitem_classname[client][slot], 64);
				currentitem_ent_idx[client][slot] = entityIndex;
				current_class[client] = _:TF2_GetPlayerClass(client);
				//currentitem_idx[client][slot] = itemDefinitionIndex
				DefineAttributesTab(client, itemDefinitionIndex, slot);
				//if (current_class[client] == )
				if (current_class[client] == _:TFClass_DemoMan)
				{
					if (!strcmp(classname, "tf_wearable"))
					{
						if (itemDefinitionIndex == 405
						|| itemDefinitionIndex == 608)
						{
							currentitem_catidx[client][slot] = GetUpgrade_CatList("tf_wear_alishoes");
						}
					}
					else
					{
						currentitem_catidx[client][slot] = GetUpgrade_CatList(classname);
					}

				}
				else if (current_class[client] == _:TFClass_Medic)
				{
					if (!strcmp(classname, "tf_weapon_medigun"))
					{
						if (itemDefinitionIndex == 998)
						{
							currentitem_catidx[client][slot] = GetUpgrade_CatList("vaccinator");
						}
						else
						{
							currentitem_catidx[client][slot] = GetUpgrade_CatList(classname);
						}
					}
					else
					{
						currentitem_catidx[client][slot] = GetUpgrade_CatList(classname);
					}
				}
				else if (current_class[client] == _:TFClass_Pyro)
				{
					if (!strcmp(classname, "tf_weapon_flamethrower") && itemDefinitionIndex == 594)
					{
						currentitem_catidx[client][slot] = GetUpgrade_CatList("tf_weapon_phlog");
					}
					else
					{
						currentitem_catidx[client][slot] = GetUpgrade_CatList(classname);
					}
				}
				else if (current_class[client] == _:TFClass_Engineer)
				{
					if (!strcmp(classname, "tf_weapon_shotgun"))
					{
						currentitem_catidx[client][0] = GetUpgrade_CatList("tf_weapon_shotgun_primary");
					}
					else if (!strcmp(classname, "tf_weapon_shotgun_primary"))
					{
						if (itemDefinitionIndex == 527)
						currentitem_catidx[client][0] = GetUpgrade_CatList("tf_weapon_shotgun_primary_widow");
					}
					else if (!strcmp(classname, "saxxy"))
					{
						currentitem_catidx[client][2] = GetUpgrade_CatList("tf_weapon_wrench");
					}
					else
					{
						currentitem_catidx[client][slot] = GetUpgrade_CatList(classname);
					}
				}
				else if (current_class[client] == _:TFClass_Scout)
				{
					if (!strcmp(classname, "tf_weapon_scattergun"))
					{
						if (itemDefinitionIndex == 13
						|| itemDefinitionIndex == 200
						|| itemDefinitionIndex == 669
						|| itemDefinitionIndex == 799
						|| itemDefinitionIndex == 808
						|| itemDefinitionIndex == 880
						|| itemDefinitionIndex == 888
						|| itemDefinitionIndex == 897
						|| itemDefinitionIndex == 906
						|| itemDefinitionIndex == 915
						|| itemDefinitionIndex == 964
						|| itemDefinitionIndex == 973)
						{
							currentitem_catidx[client][slot] = GetUpgrade_CatList("tf_weapon_scattergun_");
						}
						else
						{
							currentitem_catidx[client][slot] = GetUpgrade_CatList("tf_weapon_scattergun");
						}
					}
					else if (!strcmp(classname, "saxxy"))
					{
						currentitem_catidx[client][2] = GetUpgrade_CatList("tf_weapon_bat");
					}
					else
					{
						currentitem_catidx[client][slot] = GetUpgrade_CatList(classname);
					}
				}
				else if (current_class[client] == _:TFClass_Spy)
				{
					if (!strcmp(classname, "saxxy"))
					{
						currentitem_catidx[client][2] = GetUpgrade_CatList("tf_weapon_knife");
					}
					else if (!strcmp(classname, "tf_weapon_revolver"))
					{
						currentitem_catidx[client][slot] = GetUpgrade_CatList("tf_weapon_revolver")
					}
					else
					{
						currentitem_catidx[client][slot] = GetUpgrade_CatList(classname);
					}
				}
				else
				{
					currentitem_catidx[client][slot] = GetUpgrade_CatList(classname);
				}
				GiveNewUpgradedWeapon_(client, slot);
			}
			if (current_class[client] == _:TFClass_Spy)
			{
				if (!strcmp(classname, "tf_weapon_pda_spy"))
				{
					currentitem_classname[client][1] = "tf_weapon_pda_spy"
					currentitem_ent_idx[client][1] = GetPlayerWeaponSlot(client, 1);
					current_class[client] = _:TF2_GetPlayerClass(client)
					DefineAttributesTab(client, 735, 1)
					currentitem_catidx[client][1] = GetUpgrade_CatList("tf_weapon_pda_spy")
					GiveNewUpgradedWeapon_(client, 1)
				}
			}
			//PrintToChatAll("OGiveItem slot %d: [%s] #%d CAT[%d] qual%d", slot, classname, itemDefinitionIndex, currentitem_catidx[client][slot], itemLevel)
		}
	}
}

public Event_PlayerChangeClass(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (IsValidClient(client))
	{
		current_class[client] = _:TF2_GetPlayerClass(client);
		ResetClientUpgrades(client);
		TF2Attrib_RemoveAll(client);
		RespawnEffect(client);
		CurrencyOwned[client] = RealStartMoney;
		//PrintToChat(client, "client changeclass");
		if (!client_respawn_handled[client])
		{
			CreateTimer(0.1, ClChangeClassTimer, GetClientUserId(client));
		}
		FakeClientCommand(client,"menuselect 0");
		ChangeClassEffect(client);
	}
}

public Event_PlayerreSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
//	new team = GetClientOfUserId(GetEventInt(event, "team"));
	if (!client_respawn_handled[client])
	{
		client_respawn_handled[client] = 1;
		//PrintToChat(client, "TEAM #%d", team)

		if (client_respawn_checkpoint[client])
		{
			//PrintToChatAll("cash readjust")
			CreateTimer(0.2, mvm_CheckPointAdjustCash, GetClientUserId(client));
		}
		else
		{
			CreateTimer(0.2, WeaponReGiveUpgrades, GetClientUserId(client));
		}
	}
	FakeClientCommand(client,"menuselect 0");
	RespawnEffect(client);
}
public Action:Timer_GetConVars(Handle:timer)//Reload con_vars into vars
{
	new entityP = FindEntityByClassname(-1, "func_upgradestation");
	if (entityP > -1)
	{
		//	SetVariantString(buffer);
			AcceptEntityInput(entityP, "Kill");
	//		PrintToServer("kill sent to funcupstat")
	}
	else
	{
	//	PrintToServer("no funcupstat found")
	}

	//CostIncrease_ratio_default  = GetConVarFloat(cvar_CostIncrease_ratio_default)
	MoneyBonusKill = GetConVarInt(cvar_MoneyBonusKill);
	//MoneyForTeamRatio[RED]  = GetConVarFloat(cvar_MoneyForTeamRatioRed)
	//MoneyForTeamRatio[BLUE]  = GetConVarFloat(cvar_MoneyForTeamRatioBlue)
	TimerMoneyGive_BlueTeam = GetConVarFloat(cvar_TimerMoneyGive_BlueTeam);
	TimerMoneyGive_RedTeam = GetConVarFloat(cvar_TimerMoneyGive_RedTeam);

	//if (CostIncrease_ratio_default) //quick compile warning bypass // TODO INCLUDE CostIncrease_ratio_default
	//{
	//}
}

public Action:Timer_GiveSomeMoney(Handle:timer)//GIVE MONEY EVRY 5s
{
	new Float:iCashtmp;
	new Float:HighestMoney;
	for (new client_id = 1; client_id < MaxClients; client_id++)
	{
		if (IsValidClient(client_id) && (GetClientTeam(client_id) > 1))
		{
			iCashtmp = CurrencyOwned[client_id];
			//iCashtmp = 0
			iCashtmp += float(client_spent_money[client_id][0]
						   +client_spent_money[client_id][1]
						   +client_spent_money[client_id][2]
						   +client_spent_money[client_id][3]);
			if (GetClientTeam(client_id) == 3)
			{
				MoneyTotalFlow[BLUE] += iCashtmp;
			}
			else
			{
				MoneyTotalFlow[RED] += iCashtmp;
			}
			if(HighestMoney <= iCashtmp)
			{
				HighestMoney = iCashtmp;
				RealStartMoney = iCashtmp;
			}
		}
	}

	if (MoneyTotalFlow[RED])
	{
		MoneyForTeamRatio[RED] = MoneyTotalFlow[BLUE] / MoneyTotalFlow[RED];
	}
	if (MoneyTotalFlow[BLUE])
	{
		MoneyForTeamRatio[BLUE] = MoneyTotalFlow[RED] / MoneyTotalFlow[BLUE];
	}
	if (MoneyForTeamRatio[RED] > 3.0)
	{
		MoneyForTeamRatio[RED] = 3.0;
	}
	if (MoneyForTeamRatio[BLUE] > 3.0)
	{
		MoneyForTeamRatio[BLUE] = 3.0;
	}
	MoneyForTeamRatio[BLUE] *= MoneyForTeamRatio[BLUE];
	MoneyForTeamRatio[RED] *= MoneyForTeamRatio[RED];
	for (new client_id = 1; client_id < MaxClients; client_id++)
	{
		if (IsValidClient(client_id))
		{
			iCashtmp = CurrencyOwned[client_id];
			if (GetClientTeam(client_id) == 3)//BLUE TEAM
			{
				if (GetConVarInt(cvar_AutoMoneyForTeamRatio))
				{
					CurrencyOwned[client_id] += (TimerMoneyGive_BlueTeam * MoneyForTeamRatio[BLUE]);
				}
				else
				{
					CurrencyOwned[client_id] += TimerMoneyGive_BlueTeam;
				}
			}
			else if (GetClientTeam(client_id) == 2)//RED TEAM
			{
				if (GetConVarInt(cvar_AutoMoneyForTeamRatio))
				{
					CurrencyOwned[client_id] += (TimerMoneyGive_RedTeam * MoneyForTeamRatio[RED]);
				}
				else
				{
					CurrencyOwned[client_id] += TimerMoneyGive_RedTeam;
				}
			}
		}
	}
	TimerMoneyGive_BlueTeam = GetConVarFloat(cvar_TimerMoneyGive_BlueTeam);
	TimerMoneyGive_RedTeam = GetConVarFloat(cvar_TimerMoneyGive_RedTeam);

}

public Action:Timer_Resetupgrades(Handle:timer, any:userid)
{
	new client = GetClientOfUserId(userid);
	if (IsValidClient(client))
	{
		SetEntProp(client, Prop_Send, "m_nCurrency", RealStartMoney);
		for (new slot = 0; slot < NB_SLOTS_UED; slot++)
		{
			client_spent_money[client][slot] = 0;
			client_spent_money_mvm_chkp[client][slot] = 0;
		}
		ResetClientUpgrades(client);
		if (!client_respawn_handled[client])
		{
			CreateTimer(0.2, ClChangeClassTimer, GetClientUserId(client));
		}
	}
}


public Action:ClChangeClassTimer(Handle:timer, any:userid)
{
	new client = GetClientOfUserId(userid);

	if (IsValidClient(client) && IsPlayerAlive(client))
	{
		client_respawn_checkpoint[client] = 0;
	}
}

public Action:WeaponReGiveUpgrades(Handle:timer, any:userid)
{
	new client = GetClientOfUserId(userid);

	if (IsValidClient(client) && IsPlayerAlive(client))
	{
	//	if (current_class[client] == _:TFClass_Spy)
	//	{
	//			PrintToChat(client, "shpiee");
	//	}
		client_respawn_handled[client] = 1;
		for (new slot = 0; slot < NB_SLOTS_UED; slot++)
		{
			//PrintToChat(client, "money spent on slot  %d -- %d$", slot, client_spent_money[client][slot]);
			if (client_spent_money[client][slot] > 0)
			{
				if (slot == 3 && client_new_weapon_ent_id[client])
				{
					GiveNewWeapon(client, 3);
				}
				GiveNewUpgradedWeapon_(client, slot);
			//	PrintToChat(client, "player's upgrad!!");
			}
		}
	}
	client_respawn_handled[client] = 0;
}

public OnClientDisconnect(client)
{
	PrintToServer("putoutserver #%d", client);

	if(!IsValidClient(client))
	{
		return;
	}
}

public OnClientPutInServer(client)
{
	decl String:clname[255];
	GetClientName(client, clname, sizeof(clname));
	clientBaseName[client] = clname;
	//PrintToChatAll("putinserver #%d", client);
	PrintToServer("putinserver #%d", client);
	//current_class[client] = TF2_GetPlayerClass(client)
	clientLevels[client] = 0;
	client_no_d_team_upgrade[client] = 1;
	client_no_d_name[client] = 1;
	ResetClientUpgrades(client);
	current_class[client] = _:TF2_GetPlayerClass(client);
	if (!client_respawn_handled[client])
	{
		CreateTimer(0.2, ClChangeClassTimer, GetClientUserId(client));
	}
	PrintToServer("realstartmoney = %f", RealStartMoney);
	CurrencyOwned[client] = RealStartMoney
}//
public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)//Every single server tick.  GetTickInterval() for the seconds per tick.
{
	if (IsValidClient(client))
	{
		new Float:tickRate = GetTickInterval();
		if(MenuTimer[client] > 0.0){
		MenuTimer[client] -= tickRate; }
		if ((buttons & IN_SCORE) && MenuTimer[client] <= 0.0)//Menu's are expensive as fuck...
		{
			Menu_BuyUpgrade(client, 0);
			MenuTimer[client] = 0.5;
		}
		if(CurrencyOwned[client] >= 300000000000.0)
		{
			CurrencyOwned[client] = 300000000000.0;
		}
		else if(CurrencyOwned[client] < 0.0)
		{
			CurrencyOwned[client] = 0.0;
		}
		if (IsValidClient(client))
		{
			TF2_AddCondition(client, TFCond_SpeedBuffAlly, 0.0);
			SetEntProp(client, Prop_Send, "m_nCurrency", RoundFloat(CurrencyOwned[client]));
		}
	}
}
public Action:Event_PlayerCollectMoney(Handle:event, const String:name[], bool:dontBroadcast)
{
	new money = GetEventInt(event, "currency");
	RealStartMoney += money;
	for (new i = 1; i <= MaxClients; i++) 
	{ 
		if (IsClientInGame(i) && IsValidClient(i)) 
		{
			CurrencyOwned[i] += money;
		} 
	}
	SetEventInt(event, "currency", 0);
}
public Action:TF2_CalcIsAttackCritical(client, weapon, String:weaponname[], &bool:result) // Called whenever you shoot. 
{
	if(IsValidClient(client) && IsPlayerAlive(client))
	{
	}
	return Plugin_Handled;
}

new Float:playerpos[3];

public Action:Resspawnn(Handle:timer, any:client)
{
		new Float:nulVec[3];
		nulVec[0] = 0.0;
		nulVec[1] = 0.0;
		nulVec[2] = 0.0;
		//new Handle:event2 = CreateEvent("player_spawn")
		//if (event == INVALID_HANDLE)
		//{
		//	return
		//}

		//PrintToChatAll("Timer user id : %d", client )
	//	SetEventInt(event2, "userid", client)
	//	FireEvent(event2)
		//SetEntityHealth(client, 50)
		//TF2_RespawnPlayer(client);
		TF2_AddCondition(client, TFCond_OnFire, 50.0, 0);
		TeleportEntity(client, playerpos, nulVec, nulVec);
		//TF2_AddCondition(client, TFCond_UberchargeFading, 30.0, 0)
		//TF2_AddCondition(client, TFCond_Overhealed, 30.0, 0)

		CloseHandle(timer);
}
public Event_Playerhurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));

	new Float:damage = GetEventFloat(event, "damageamount");

	if(IsValidClient(attacker) && attacker != client)
	{
		PrintToConsole(attacker, "%0.f post-damage dealt", damage);
	}
}

public Action:Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(!IsValidClient(client))
	{
		return Plugin_Continue;
	}
	FakeClientCommand(client, "menuselect 0");
	//if (isValidVIP(client))
	//{
	//	PrintToChat(client, "AhhhA Vip death client#%d", client)
	//	GetEntPropVector(client, Prop_Send, "m_vecOrigin", playerpos);
//		TF2_RespawnPlayer(client);
	//	CreateTimer(6.5, Resspawnn, client);
	//	CreateTimer(4.0, Resspawnn, GetClientUserId(client));

	//}
	new attack = GetClientOfUserId(GetEventInt(event, "attacker"));
	if(!IsMvM())
	{
		new Float:BotMoneyKill = 100.0+((SquareRoot(MoneyBonusKill + Pow(RealStartMoney, 0.9))) * 0.5) * 3.0
		new Float:PlayerMoneyKill = 100.0+((SquareRoot(MoneyBonusKill + Pow(RealStartMoney, 0.95))) * 0.7) * 3.0
		
		if (IsValidClient(attack, false) && IsValidClient(client) && attack != client)
		{
			for (new i = 1; i <= MaxClients; i++) 
			{ 
				if (IsClientInGame(i) && IsValidClient(i)) 
				{
					CurrencyOwned[i] += PlayerMoneyKill
					PrintToChat(i, "+%.0f$",  PlayerMoneyKill)
				} 
			}  
			RealStartMoney += PlayerMoneyKill;
		}
		if(!IsValidClient(client) && attack != client)
		{
			for (new i = 1; i <= MaxClients; i++) 
			{ 
				if (IsClientInGame(i) && IsValidClient(i)) 
				{
					CurrencyOwned[i] += BotMoneyKill
					PrintToChat(i, "+%.0f$", BotMoneyKill);
				} 
			}  
			RealStartMoney += BotMoneyKill
		}
	}
	return Plugin_Continue;
}
public Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	MoneyForTeamRatio[RED] = 0.9;
	MoneyForTeamRatio[BLUE] = 0.9;
}

public Event_teamplay_round_win(Handle:event, const String:name[], bool:dontBroadcast)
{
	new slot, i;
	new team = GetEventInt(event, "team");
	if (IsMvM() && team == 3)
	{
		//PrintToChatAll("bot TEAM wins!")
		for (new client_id = 1; client_id < MaxClients; client_id++)
		{
			if (IsValidClient(client_id))
			{

				client_respawn_checkpoint[client_id] = 1;
				client_spent_money[client_id] = client_spent_money_mvm_chkp[client_id];
				for (slot = 0; slot < 5; slot++)
				{
					for (i = 0; i < currentupgrades_number[client_id][slot]; i++)
					{
						upgrades_ref_to_idx[client_id][slot][currentupgrades_idx[client_id][slot][i]] = 9999;
					}
					currentupgrades_idx[client_id][slot] = currentupgrades_idx_mvm_chkp[client_id][slot];
					currentupgrades_val[client_id][slot] = currentupgrades_val_mvm_chkp[client_id][slot];
					currentupgrades_number[client_id][slot] = currentupgrades_number_mvm_chkp[client_id][slot];
					for (i = 0; i < currentupgrades_number[client_id][slot]; i++)
					{
						upgrades_ref_to_idx[client_id][slot][currentupgrades_idx[client_id][slot][i]] = i;
					}
				}
			}
		}
	}
	else
	{
		//PrintToChatAll("hmuan TEAM wins!")
	}
}

public Event_mvm_wave_begin(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client_id, slot
	PrintToServer("mvm wave begin")
	for (client_id = 0; client_id < MaxClients; client_id++)
	{
		if (IsValidClient(client_id))
		{
			client_spent_money_mvm_chkp[client_id] = client_spent_money[client_id]
			CurrencySaved[client_id] = CurrencyOwned[client_id];
			StartMoneySaved = RealStartMoney;
			for (slot = 0; slot < 5; slot++)
			{
				currentupgrades_number_mvm_chkp[client_id][slot] = currentupgrades_number[client_id][slot]
				currentupgrades_idx_mvm_chkp[client_id][slot] = currentupgrades_idx[client_id][slot]
				currentupgrades_val_mvm_chkp[client_id][slot] = currentupgrades_val[client_id][slot]
			}
			//PrintToChat(client_id, "Current checkpoint money: %d", client_spent_money_mvm_chkp[client_id])
		}
	}
}

public Event_mvm_wave_complete(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client_id, slot;

	//PrintToChatAll("EVENT MVM WAVE COMPLETE")
	for (client_id = 1; client_id < MaxClients; client_id++)
	{
		if (IsValidClient(client_id))
		{

			client_spent_money_mvm_chkp[client_id] = client_spent_money[client_id];
			for (slot = 0; slot < 5; slot++)
			{
				currentupgrades_number_mvm_chkp[client_id][slot] = currentupgrades_number[client_id][slot];
				currentupgrades_idx_mvm_chkp[client_id][slot] = currentupgrades_idx[client_id][slot];
				currentupgrades_val_mvm_chkp[client_id][slot] = currentupgrades_val[client_id][slot];
			}
			//PrintToChat(client_id, "Current checkpoint money: %d", client_spent_money_mvm_chkp[client_id])
		}
	}
}
public Event_mvm_wave_failed(Handle:event, const String:name[], bool:dontBroadcast)
{
	for (new client = 0; client < MaxClients; client++)
	{
		if (IsValidClient(client))
		{
			if (!client_respawn_handled[client])
			{
				CreateTimer(0.2, ClChangeClassTimer, GetClientUserId(client));
			}
		}	
	}
	new slot,i
	for (new client_id = 0; client_id < MaxClients; client_id++)
	{
		if (IsValidClient(client_id))
		{
			TF2Attrib_RemoveAll(client_id);
			CurrencyOwned[client_id] = CurrencySaved[client_id];
			RealStartMoney = StartMoneySaved;
			client_respawn_checkpoint[client_id] = 1
			client_spent_money[client_id] = client_spent_money_mvm_chkp[client_id]
			for (slot = 0; slot < 5; slot++)
			{
				for (i = 0; i < currentupgrades_number[client_id][slot]; i++)
				{
					upgrades_ref_to_idx[client_id][slot][currentupgrades_idx[client_id][slot][i]] = 20000
				}			
				currentupgrades_idx[client_id][slot] = currentupgrades_idx_mvm_chkp[client_id][slot]
				currentupgrades_val[client_id][slot] = currentupgrades_val_mvm_chkp[client_id][slot]
				currentupgrades_number[client_id][slot] = currentupgrades_number_mvm_chkp[client_id][slot]
				for (i = 0; i < currentupgrades_number[client_id][slot]; i++)
				{
					upgrades_ref_to_idx[client_id][slot][currentupgrades_idx[client_id][slot][i]] = i
				}
				new weaponinSlot = GetPlayerWeaponSlot(client_id,slot);
				if(IsValidEntity(weaponinSlot))
				{
					TF2Attrib_RemoveAll(weaponinSlot);
					GiveNewUpgradedWeapon_(client_id, slot);
					TF2Attrib_ClearCache(weaponinSlot);
					//PrintToServer("Slot #%i was refreshed for client #%i",slot,client_id);
				}
			}
			TF2Attrib_ClearCache(client_id);
		}
	}
	PrintToServer("MvM Mission Failed");
}
 public Event_ResetStats(Handle:event, const String:name[], bool:dontBroadcast)
{
	for (new client = 0; client < MaxClients; client++)
	{
		if (IsValidClient(client))
		{
			new primary = (GetPlayerWeaponSlot(client,0));
			new secondary = (GetPlayerWeaponSlot(client,1));
			new melee = (GetPlayerWeaponSlot(client,2));
			TF2Attrib_RemoveAll(client);
			TF2Attrib_RemoveAll(primary);
			TF2Attrib_RemoveAll(secondary);
			TF2Attrib_RemoveAll(melee);
			current_class[client] = _:TF2_GetPlayerClass(client)
			ResetClientUpgrades(client)
			if (!client_respawn_handled[client])
			{
				CreateTimer(0.05, ClChangeClassTimer, GetClientUserId(client));
			}
			FakeClientCommandEx(client, "menuselect 0");
			Menu_BuyUpgrade(client, 0);
			CurrencyOwned[client] = 1400.0
			RealStartMoney = 1400.0
		}
	}
}
public Action:mvm_CheckPointAdjustCash(Handle:timer, any:userid)
{
	new client = GetClientOfUserId(userid);
	//PrintToChatAll("ckpoint adjust")

	if (IsValidClient(client) && client_respawn_checkpoint[client])
	{
		new iCash = GetEntProp(client, Prop_Send, "m_nCurrency", iCash);
		SetEntProp(client, Prop_Send, "m_nCurrency", iCash -
				(client_spent_money_mvm_chkp[client][0]
				+ client_spent_money_mvm_chkp[client][1]
				+ client_spent_money_mvm_chkp[client][2]
				+ client_spent_money_mvm_chkp[client][3]) );
		client_respawn_checkpoint[client] = 0;
		CreateTimer(0.1, WeaponReGiveUpgrades, GetClientUserId(client));
	}
}


public Event_PlayerChangeTeam(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new disconnected = view_as<bool>(GetEventInt(event, "disconnect"));

	if(disconnected)
	{
		return;
	}

	if (IsValidClient(client))
	{
		//current_class[client] = TF2_GetPlayerClass(client)
		//PrintToChat(client, "client changeteam");
		if (!client_respawn_handled[client])
		{
			CreateTimer(0.2, ClChangeClassTimer, GetClientUserId(client));
		}
		ChangeClassEffect(client);
	}
}

public Action:jointeam_callback(client, const String:command[], argc) //protection from spectators
{
	decl String:arg[16];
	arg[0] = '\0';
	PrintToServer("jointeam callback #%d", client);
	GetCmdArg(1, arg, sizeof(arg));
	ResetClientUpgrades(client);
	for(new yeah = 0; yeah < 5; yeah++)
	{
		if(IsValidClient(client))
		{
			new Weapon = GetPlayerWeaponSlot(client,yeah);
			if(IsValidEntity(Weapon))
			{
				TF2Attrib_RemoveAll(Weapon);
			}
		}
	}
	if(IsValidClient(client))
	{
		TF2Attrib_RemoveAll(client);
	}
	//current_class[client] = TF2_GetPlayerClass(client)
	//PrintToChat(client, "client changeteam");
	if (!client_respawn_handled[client])
	{
		CreateTimer(0.2, ClChangeClassTimer, GetClientUserId(client));
	}
	if (!IsMvM())
	{
		PrintToServer("give to client %.0f startmoney",RealStartMoney);
		//iCashtmp = GetEntProp(client, Prop_Send, "m_nCurrency", iCashtmp);
		SetEntProp(client, Prop_Send, "m_nCurrency",RealStartMoney);
	}		
	FakeClientCommand(client, "menuselect 0");
}

//!uusteamup -> toggle shows team upgrades in chat for a client
public Action:Toggl_DispTeamUpgrades(client, args)
{
	new String:arg1[32];
	new arg;

	client_no_d_team_upgrade[client] = 0;
	if (GetCmdArg(1, arg1, sizeof(arg1)))
	{
		arg = StringToInt(arg1);
		if (arg == 0)
		{
			client_no_d_team_upgrade[client] = 1;
		}
	}
}
public Action:Toggl_NameLevel(client, args)
{
	new String:arg1[32];
	new arg;

	client_no_d_name[client] = 0;
	if (GetCmdArg(1, arg1, sizeof(arg1)))
	{
		arg = StringToInt(arg1);
		if (arg == 0)
		{
			client_no_d_name[client] = 1;
		}
		else if(arg == 5)
		{
			client_no_d_team_upgrade[client] = 5;
		}
	}
}
//!uurspwn -> toggle shows buymenu when a client respawn
public Action:Toggl_DispMenuRespawn(client, args)
{
	new String:arg1[32];
	new arg;

	client_no_d_menubuy_respawn[client] = 0;
	if (GetCmdArg(1, arg1, sizeof(arg1)))
	{
		arg = StringToInt(arg1);
		if (arg == 0)
		{
			client_no_d_menubuy_respawn[client] = 1;
		}
	}
}


public Action:ShowSpentMoney(admid, args)
{
	for(new i = 0; i < MaxClients; i++)
	{
		if (IsValidClient(i))
		{
			decl String:cstr[255];
			GetClientName(i, cstr, 255);
			PrintToChat(admid, "**%s**\n**", cstr);
			for (new s = 0; s < 5; s++)
			{
				PrintToChat(admid, "%s : %d$ of upgrades", current_slot_name[s], client_spent_money[i][s]);
			}
		}
	}
}

public Action:ShowTeamMoneyRatio(admid, args)
{
	for(new i = 0; i < MaxClients; i++)
	{
		if (IsValidClient(i))
		{
			decl String:cstr[255];
			GetClientName(i, cstr, 255);
			PrintToChat(admid, "**%s**\n**", cstr);
			for (new s = 0; s < 5; s++)
			{
				PrintToChat(admid, "%s : %d$ of upgrades", current_slot_name[s], client_spent_money[i][s]);
			}
		}
	}
}

public Action:ReloadCfgFiles(client, args)
{
	CreateTimer(0.1, Timer_WaitForTF2II, _);
	for (new cl = 0; cl < MaxClients; cl++)
	{
		if (IsValidClient(cl))
		{
			ResetClientUpgrades(cl);
			current_class[cl] = _:TF2_GetPlayerClass(client);
			//PrintToChat(cl, "client changeclass");
			if (!client_respawn_handled[cl])
			{
				CreateTimer(0.2, ClChangeClassTimer, GetClientUserId(cl));
			}
		}
	}
	return Plugin_Handled;
}


//admin cmd: enable/disable menu "buy an additional weapon"
public Action:EnableBuyNewWeapon(client, args)
{
	new String:arg1[32];
	new arg;

	BuyNWmenu_enabled = 0;
	if (GetCmdArg(1, arg1, sizeof(arg1)))
	{
		arg = StringToInt(arg1);
		if (arg == 1)
		{
			BuyNWmenu_enabled = 1;
		}
	}
	return Plugin_Handled;
}
public Action:Menu_QuickBuyUpgrade(mclient, args)
{
	new String:arg1[32];
	new arg1_ = -1;
	new String:arg2[32];
	new arg2_ = -1;
	new String:arg3[32];
	new arg3_ = -1;
	new String:arg4[32];
	new arg4_ = 0;
	new	bool:flag = false
	if (IsValidClient(mclient) && IsPlayerAlive(mclient))
	{
		if (GetCmdArg(1, arg1, sizeof(arg1)))
		{
			arg2_ = -1
			arg3_ = -1
			if(!strcmp("1", arg1)){
			arg1_ = 4;
			}
			if(!strcmp("2", arg1)){
			arg1_ = 0;
			}
			if(!strcmp("3", arg1)){
			arg1_ = 1;
			}
			if(!strcmp("4", arg1)){
			arg1_ = 2;
			}
			if(!strcmp("5", arg1)){
			arg1_ = 5;
			}
			if (arg1_ > -1 && arg1_ < 6 && GetCmdArg(2, arg2, sizeof(arg2)))
			{
				new w_id = currentitem_catidx[mclient][arg1_]
				arg2_ = StringToInt(arg2)-1;
				if (GetCmdArg(3, arg3, sizeof(arg3)))
				{
					arg3_ = StringToInt(arg3)-1;
					arg4_ = 1
					if (GetCmdArg(4, arg4, sizeof(arg4)))
					{
						arg4_ = StringToInt(arg4);
						if (arg4_ >= 100000)
						{
							arg4_ = 100000
						}
						if (arg4_ < 1)
						{
							arg4_ = 1
						}
					}
					
					if(w_id != -1 && arg2_ == given_upgrd_classnames_tweak_idx[w_id])
					{
						new loopBroke = 0;
						new got_req = 1
						for(new timesUpgraded = 0; timesUpgraded < arg4_ && loopBroke == 0; timesUpgraded++)
						{
							new spTweak = given_upgrd_list[w_id][arg2_][arg3_]
							for (new i = 0; i < upgrades_tweaks_nb_att[spTweak]; i++)
							{
								new upgrade_choice = upgrades_tweaks_att_idx[spTweak][i]
								new inum = upgrades_ref_to_idx[mclient][arg1_][upgrade_choice]
								if (inum != 9999)
								{
									if (currentupgrades_val[mclient][arg1_][inum] == upgrades_m_val[upgrade_choice])
									{
										got_req = 0;
										loopBroke = 1;
									}
								}
								else
								{
									if (currentupgrades_number[mclient][arg1_] + upgrades_tweaks_nb_att[spTweak] >= MAX_ATTRIBUTES_ITEM)
									{
										got_req = 0;
										loopBroke = 1;
									}
								}
							}
							if (got_req)
							{
								current_slot_used[mclient] = arg1_;
								for (new i = 0; i < upgrades_tweaks_nb_att[spTweak]; i++)
								{
									new upgrade_choice = upgrades_tweaks_att_idx[spTweak][i]
									UpgradeItem(mclient, upgrade_choice, upgrades_ref_to_idx[mclient][arg1_][upgrade_choice], upgrades_tweaks_att_ratio[spTweak][i])
								}
								GiveNewUpgradedWeapon_(mclient, arg1_)
							}
						}
						if(got_req)
						{
							PrintToChat(mclient, "Qbuy successful.")
						}
						else
						{
							PrintToChat(mclient, "Hit maximum for attribute.")
						}
						return Plugin_Handled;
					}
					if(arg1_ == 5)
					{
						if (arg3_ >= 0)
						{
							new u = currentupgrades_idx[mclient][arg2_][arg3_]
							if (u != 9999)
							{
								if (upgrades_costs[u] < -0.0001)
								{
									new nb_time_upgraded = RoundToNearest((upgrades_i_val[u] - currentupgrades_val[mclient][arg2_][arg3_]) / upgrades_ratio[u])
									new Float:up_cost = upgrades_costs[u] * nb_time_upgraded * 3.0
									if (CurrencyOwned[mclient] >= up_cost)
									{
										remove_attribute(mclient, arg3_)
										CurrencyOwned[mclient] -= up_cost;
										client_spent_money[mclient][arg2_] += up_cost
										PrintToChat(mclient, "Attribute removed.")
									}
									else
									{
										PrintToChat(mclient, "You don't have enough money.");
									}
								}
							}
						}
						return Plugin_Handled;
					}
					if (arg2_ > -1 && arg2_ < given_upgrd_list_nb[w_id] && given_upgrd_list[w_id][arg2_][arg3_])
					{
						new upgrade_choice = given_upgrd_list[w_id][arg2_][arg3_]
						new inum = upgrades_ref_to_idx[mclient][arg1_][upgrade_choice]
						if (inum == 9999)
						{
							inum = currentupgrades_number[mclient][arg1_]
							currentupgrades_number[mclient][arg1_]++
							upgrades_ref_to_idx[mclient][arg1_][upgrade_choice] = inum;
							currentupgrades_idx[mclient][arg1_][inum] = upgrade_choice 
							currentupgrades_val[mclient][arg1_][inum] = upgrades_i_val[upgrade_choice];
						}
						new idx_currentupgrades_val = RoundToNearest((currentupgrades_val[mclient][arg1_][inum] - upgrades_i_val[upgrade_choice])/ upgrades_ratio[upgrade_choice])
						new Float:upgrades_val = currentupgrades_val[mclient][arg1_][inum]
						new up_cost = upgrades_costs[upgrade_choice]
						up_cost /= 2
						if (arg1_ == 1)
						{
							up_cost = RoundFloat((up_cost * 1.0) * 0.9)
						}
						if (inum != 9999 && upgrades_ratio[upgrade_choice])
						{
							new t_up_cost = 0
							for (new idx = 0; idx < arg4_; idx++)
							{
								if(upgrades_ratio[upgrade_choice] > 0.0 && upgrades_val < upgrades_m_val[upgrade_choice])
								{
									t_up_cost += up_cost + RoundFloat(up_cost * (
																idx_currentupgrades_val
																	* upgrades_costs_inc_ratio[upgrade_choice]))
									idx_currentupgrades_val++		
									upgrades_val += upgrades_ratio[upgrade_choice]
								}
								if(upgrades_ratio[upgrade_choice] < 0.0 && upgrades_val > upgrades_m_val[upgrade_choice])
								{
									t_up_cost += up_cost + RoundFloat(up_cost * (
																idx_currentupgrades_val
																	* upgrades_costs_inc_ratio[upgrade_choice]))
									idx_currentupgrades_val++		
									upgrades_val += upgrades_ratio[upgrade_choice]
								}
							}
												
							if (t_up_cost < 0.0)
							{
								t_up_cost *= -1;
								if (t_up_cost < (upgrades_costs[upgrade_choice] / 2))
								{
									t_up_cost = upgrades_costs[upgrade_choice] / 2
								}
							}
							if (CurrencyOwned[mclient] < t_up_cost)
							{
								new String:buffer[128]
								Format(buffer, sizeof(buffer), "%T", "You have not enough money!!", mclient);
								PrintToChat(mclient, buffer);
							}
							else
							{
								if ((upgrades_ratio[upgrade_choice] > 0.0 && upgrades_val > upgrades_m_val[upgrade_choice])
								|| (upgrades_ratio[upgrade_choice] < 0.0 && upgrades_val < upgrades_m_val[upgrade_choice]))
								{
									PrintToChat(mclient, "Maximum upgrade value reached for this category.");
									flag = true
									currentupgrades_val[mclient][arg1_][inum] = upgrades_val
									CurrencyOwned[mclient] -= t_up_cost;
									check_apply_maxvalue(mclient, arg1_, inum, upgrade_choice)
									client_spent_money[mclient][arg1_] += t_up_cost;
									new totalmoney = 0
								
									for (new s = 0; s < 5; s++)
									{
										totalmoney += client_spent_money[mclient][s]
									}
									GiveNewUpgradedWeapon_(mclient, arg1_)									
								}
								else
								{
									flag = true
									CurrencyOwned[mclient] -= t_up_cost;
									currentupgrades_val[mclient][arg1_][inum] = upgrades_val
									check_apply_maxvalue(mclient, arg1_, inum, upgrade_choice)
									client_spent_money[mclient][arg1_] += t_up_cost
									new totalmoney = 0
								
									for (new s = 0; s < 5; s++)
									{
										totalmoney += client_spent_money[mclient][s]
									}
									GiveNewUpgradedWeapon_(mclient, arg1_)
									PrintToChat(mclient, "yep");
								}
							}
						}
					}
				}
			}
		}
		if (!flag)
		{
			ReplyToCommand(mclient, "Usage: /qbuy [Slot buy #] [Category #] [Upgrade #] [# to buy]");
			ReplyToCommand(mclient, "Example : /qbuy 1 1 1 100 = buy health 100 times");
		}
	}
	else
	{
		ReplyToCommand(mclient, "You cannot quick-buy while dead.");
	}
	return Plugin_Handled;
}
GetWeaponsCatKVSize(Handle:kv)
{
	new siz = 0;
	do
	{
		if (!KvGotoFirstSubKey(kv, false))
		{
			// Current key is a regular key, or an empty section.
			if (KvGetDataType(kv, NULL_STRING) != KvData_None)
			{
				siz++;
			}
		}
	}
	while (KvGotoNextKey(kv, false));
	return siz;
}

BrowseWeaponsCatKV(Handle:kv)
{
	new u_id = 0;
	new t_idx = 0;
	SetTrieValue(_weaponlist_names, "body_scout" , t_idx++, false);
	SetTrieValue(_weaponlist_names, "body_sniper" , t_idx++, false);
	SetTrieValue(_weaponlist_names, "body_soldier" , t_idx++, false);
	SetTrieValue(_weaponlist_names, "body_demoman" , t_idx++, false);
	SetTrieValue(_weaponlist_names, "body_medic" , t_idx++, false);
	SetTrieValue(_weaponlist_names, "body_heavy" , t_idx++, false);
	SetTrieValue(_weaponlist_names, "body_pyro" , t_idx++, false);
	SetTrieValue(_weaponlist_names, "body_spy" , t_idx++, false);
	SetTrieValue(_weaponlist_names, "body_engie" , t_idx++, false);
	decl String:Buf[64];
	do
	{
		if (KvGotoFirstSubKey(kv, false))
		{
			BrowseWeaponsCatKV(kv);
			KvGoBack(kv);
		}
		else
		{
			if (KvGetDataType(kv, NULL_STRING) != KvData_None)
			{
				KvGetSectionName(kv, Buf, sizeof(Buf));
				wcnamelist[u_id] = Buf;
				KvGetString(kv, "", Buf, 64);
				if (SetTrieValue(_weaponlist_names, Buf, t_idx, false))
				{
					t_idx++;
				}
				GetTrieValue(_weaponlist_names, Buf, wcname_l_idx[u_id]);
				//PrintToServer("weapon list %d: %s - %s(%d)", u_id,wcnamelist[u_id], Buf, wcname_l_idx[u_id])
				u_id++;
				//PrintToServer("%s linked : %s->%d",  wcnamelist[u_id], Buf,wcname_l_idx[u_id])
				//PrintToServer("value:%s", Buf)
			}
		}
	}
	while (KvGotoNextKey(kv, false));
}

BrowseAttributesKV(Handle:kv)
{
	decl String:Buf[64];
	do
	{
		if (KvGotoFirstSubKey(kv, false))
		{
			//PrintToServer("\nAttribute #%d", _u_id)
			BrowseAttributesKV(kv);
			KvGoBack(kv);
		}
		else
		{
			// Current key is a regular key, or an empty section.
			if (KvGetDataType(kv, NULL_STRING) != KvData_None)
			{
				KvGetSectionName(kv, Buf, sizeof(Buf));
				if (!strcmp(Buf,"ref"))
				{
					KvGetString(kv, "", Buf, 64);
					upgradesNames[_u_id] = Buf;
					SetTrieValue(_upg_names, Buf, _u_id, true);
				//	PrintToServer("ref:%s --uid:%d", Buf, _u_id)
				}
				if (!strcmp(Buf,"name"))
				{
					KvGetString(kv, "", Buf, 64);
					if (strcmp(Buf,""))
					{
						//PrintToServer("Name:%s-", Buf)
						//new _:att_id = TF2II_GetAttributeIDByName(Buf)
						for (new i_ = 1; i_ < MAX_ATTRIBUTES; i_++)
						{
							if (!strcmp(upgradesWorkNames[i_], Buf))
							{
								upgrades_to_a_id[_u_id] = i_;
							//	PrintToServer("up_ref/id[%d]:%s/%d", _u_id, Buf, upgrades_to_a_id[_u_id])
								break;
							}
						}
					}
				}
				if (!strcmp(Buf,"cost"))
				{
					KvGetString(kv, "", Buf, 64);
					upgrades_costs[_u_id] = StringToInt(Buf);
					//PrintToServer("cost:%d", upgrades_costs[_u_id])
				}
				if (!strcmp(Buf,"increase_ratio"))
				{
					KvGetString(kv, "", Buf, 64);
					upgrades_costs_inc_ratio[_u_id] = StringToFloat(Buf);
					//PrintToServer("increase rate:%f", upgrades_costs_inc_ratio[_u_id])
				}
				if (!strcmp(Buf,"value"))
				{
					KvGetString(kv, "", Buf, 64);
					upgrades_ratio[_u_id] = StringToFloat(Buf);
					//PrintToServer("val:%f", upgrades_ratio[_u_id])
				}
				if (!strcmp(Buf,"init"))
				{
					KvGetString(kv, "", Buf, 64);
					upgrades_i_val[_u_id] = StringToFloat(Buf);
					//PrintToServer("init:%f", upgrades_i_val[_u_id])
				}
				if (!strcmp(Buf,"max"))
				{
					KvGetString(kv, "", Buf, 64);
					upgrades_m_val[_u_id] = StringToFloat(Buf);
					//PrintToServer("max:%f", upgrades_m_val[_u_id])
					_u_id++;
				}

			}
		}
	}
	while (KvGotoNextKey(kv, false));
	return (_u_id);
}


BrowseAttListKV(Handle:kv, &w_id = -1, &w_sub_id = -1, w_sub_att_idx = -1, level = 0)
{
	decl String:Buf[64];
	do
	{
		KvGetSectionName(kv, Buf, sizeof(Buf));
		if (level == 1)
		{
			if (!GetTrieValue(_weaponlist_names, Buf, w_id))
			{
				PrintToServer("[uu_lists] Malformated uu_lists | uu_weapon.txt file?: %s was not found", Buf);
			}
			w_sub_id = -1;
			given_upgrd_classnames_tweak_nb[w_id] = 0;
		}
		if (level == 2)
		{
			KvGetSectionName(kv, Buf, sizeof(Buf));
			if (!strcmp(Buf, "special_tweaks_listid"))
			{

				KvGetString(kv, "", Buf, 64);
				//PrintToServer("  ->Sublist/#%s -- #%d", Buf, w_id)
				given_upgrd_classnames_tweak_idx[w_id] = StringToInt(Buf);
			}
			else
			{
				w_sub_id++;
			//	PrintToServer("section #%s", Buf)
				given_upgrd_classnames[w_id][w_sub_id] = Buf;
				given_upgrd_list_nb[w_id]++;
				w_sub_att_idx = 0;
			}
		}
		if (KvGotoFirstSubKey(kv, false))
		{
			KvGetSectionName(kv, Buf, sizeof(Buf));
			BrowseAttListKV(kv, w_id, w_sub_id, w_sub_att_idx, level + 1);
			KvGoBack(kv);
		}
		else
		{
			if (KvGetDataType(kv, NULL_STRING) != KvData_None)
			{
				new attr_id;
				KvGetSectionName(kv, Buf, sizeof(Buf));
			//	PrintToServer("section:%s", Buf)
				if (strcmp(Buf, "special_tweaks_listid"))
				{
					KvGetString(kv, "", Buf, 64);
					if (w_sub_id == given_upgrd_classnames_tweak_idx[w_id])
					{
						given_upgrd_classnames_tweak_nb[w_id]++;
						if (!GetTrieValue(_spetweaks_names, Buf, attr_id))
						{
							PrintToServer("[uu_lists] Malformated uu_lists | uu_specialtweaks.txt file?: %s was not found", Buf);
						}
					}
					else
					{
						if (!GetTrieValue(_upg_names, Buf, attr_id))
						{
							PrintToServer("[uu_lists] Malformated uu_lists | uu_attributes.txt file?: %s was not found", Buf);
						}
					}
			//		PrintToServer("             **list%d sublist%d %d :%s(%d)", w_sub_att_idx, w_id, w_sub_id, Buf, attr_id)
					given_upgrd_list[w_id][w_sub_id][w_sub_att_idx] = attr_id;
					w_sub_att_idx++;
				}
			}
		}
	}
	while (KvGotoNextKey(kv, false));
}


BrowseSpeTweaksKV(Handle:kv, &u_id = -1, att_id = -1, level = 0)
{
	decl String:Buf[64];
	new attr_ref;
	do
	{
		if (level == 2)
		{
			KvGetSectionName(kv, Buf, sizeof(Buf));
			u_id++;
			SetTrieValue(_spetweaks_names, Buf, u_id);
			upgrades_tweaks[u_id] = Buf;
			upgrades_tweaks_nb_att[u_id] = 0;
			att_id = 0;
		}
		if (level == 3)
		{
			KvGetSectionName(kv, Buf, sizeof(Buf));
			if (!GetTrieValue(_upg_names, Buf, attr_ref))
			{
				PrintToServer("[spetw_lists] Malformated uu_specialtweaks | uu_attribute.txt file?: %s was not found", Buf);
			}
		//	PrintToServer("Adding Special tweak [%s] attribute %s(%d)", upgrades_tweaks[u_id], Buf, attr_ref)
			upgrades_tweaks_att_idx[u_id][att_id] = attr_ref;
			KvGetString(kv, "", Buf, 64);
			upgrades_tweaks_att_ratio[u_id][att_id] = StringToFloat(Buf);
		//	PrintToServer("               ratio => %f)", upgrades_tweaks_att_ratio[u_id][att_id])
			upgrades_tweaks_nb_att[u_id]++;
			att_id++;
		}
		if (KvGotoFirstSubKey(kv, false))
		{
			BrowseSpeTweaksKV(kv, u_id, att_id, level + 1);
			KvGoBack(kv);
		}
	}
	while (KvGotoNextKey(kv, false));
	return (u_id);
}

//public TF2II_OnItemSchemaUpdated()
//{
//	_load_cfg_files()
//}

public _load_cfg_files()
{


	_upg_names = CreateTrie();
	_weaponlist_names = CreateTrie();
	_spetweaks_names = CreateTrie();

	new Handle:kv = CreateKeyValues("uu_weapons");
	kv = CreateKeyValues("weapons");
	FileToKeyValues(kv, "addons/sourcemod/configs/uu_weapons.txt");
	if (!KvGotoFirstSubKey(kv))
	{
		return false;
	}
	new siz = GetWeaponsCatKVSize(kv);
	PrintToServer("[UberUpgrades] %d weapons loaded", siz);
	KvRewind(kv);
	BrowseWeaponsCatKV(kv);
	CloseHandle(kv);


	kv = CreateKeyValues("attribs");
	FileToKeyValues(kv, "addons/sourcemod/configs/uu_attributes.txt");
	_u_id = 0;
	PrintToServer("browsin uu attribs (kvh:%d)", kv);
	BrowseAttributesKV(kv);
	PrintToServer("[UberUpgrades] %d attributes loaded", _u_id);
	CloseHandle(kv);



	new static_uid = -1;
	kv = CreateKeyValues("special_tweaks");
	FileToKeyValues(kv, "addons/sourcemod/configs/uu_specialtweaks.txt");
	BrowseSpeTweaksKV(kv, static_uid);
	PrintToServer("[UberUpgrades] %d special tweaks loaded", static_uid);
	CloseHandle(kv);

	static_uid = -1;
	kv = CreateKeyValues("lists");
	FileToKeyValues(kv, "addons/sourcemod/configs/uu_lists.txt");
	BrowseAttListKV(kv, static_uid);
	PrintToServer("[UberUpgrades] %d lists loaded", static_uid);
	CloseHandle(kv);

	// new Handle:fi = OpenFile("yepyep2.txt", "w");
	// new Handle:_tmptmptmp = CreateTrie();
	// for (new i = 0; i < siz; i++)
	// {
		// for (j = 0; j < given_upgrd_list_nb[i]; j++)
		// {
			// new _:k
			// if (GetTrieValue(_tmptmptmp, given_upgrd_classnames[i][j], k) == false)
			// {
				// SetTrieValue(_tmptmptmp, given_upgrd_classnames[i][j], 1)
				// new String:tmp[256]
				// Format(tmp, sizeof(tmp), "\t\"%s\"",given_upgrd_classnames[i][j])
				// WriteFileLine(fi, tmp)
				// WriteFileLine(fi,"\t{")
				// Format(tmp, sizeof(tmp), "\t\t\"en\"\t\t\"%s\"",given_upgrd_classnames[i][j])
				// WriteFileLine(fi,tmp)
				// WriteFileLine(fi,"\t}")
			// }
		// }
	// }
	// ClearTrie(_tmptmptmp)
	// CloseHandle(fi)
	//TODO -> buyweapons.cfg
	newweaponidx[0] = 13;
	newweaponcn[0] = "tf_weapon_scattergun";
	newweaponmenudesc[0] = "Scattergun";

	CreateBuyNewWeaponMenu();
	return true;
}
stock bool:IsValidClient(client, bool:nobots = true)
{
    if (client <= 0 || client > MaxClients || !IsClientConnected(client))
    {
        return false;
    }
    return (IsClientInGame(client));
}
stock TF2_IsPlayerCritBuffed(client)
{
	return (TF2_IsPlayerInCondition(client, TFCond_Kritzkrieged) || TF2_IsPlayerInCondition(client, TFCond_HalloweenCritCandy) || TF2_IsPlayerInCondition(client, TFCond:34)
	|| TF2_IsPlayerInCondition(client, TFCond:35) || TF2_IsPlayerInCondition(client, TFCond_CritOnFirstBlood) || TF2_IsPlayerInCondition(client, TFCond_CritOnWin)
	|| TF2_IsPlayerInCondition(client, TFCond_CritOnFlagCapture) || TF2_IsPlayerInCondition(client, TFCond_CritOnKill) || TF2_IsPlayerInCondition(client, TFCond_CritMmmph));
}

//Initialize New Weapon menu
public CreateBuyNewWeaponMenu()
{
	BuyNWmenu = CreateMenu(MenuHandler_BuyNewWeapon);

	SetMenuTitle(BuyNWmenu, "***Choose additional weapon for 200$:");

	for (new i=0; i < NB_B_WEAPONS; i++)
	{
		AddMenuItem(BuyNWmenu, "tweak", newweaponmenudesc[i]);
	}
	SetMenuExitButton(BuyNWmenu, true);
}

//Initialize menus , CVARs, con cmds and timers handlers on plugin load
public UberShopinitMenusHandlers()
{
	LoadTranslations("tf2items_uu.phrases.txt");
	LoadTranslations("common.phrases.txt");
	BuyNWmenu_enabled = true;

	cvar_uu_version = CreateConVar("uberupgrades_version", UU_VERSION, "The Plugin Version. Don't change.", FCVAR_NOTIFY);
	//cvar_CostIncrease_ratio_default = 	CreateConVar("sm_uu_costincrease_ratio_defaut", "0.5", "Each time an upgrade is bought, next one will be increased by this ratio if not defined in uu_attributes.txt(Not yet implemented): default 0.5");
	cvar_MoneyBonusKill = 				CreateConVar("sm_uu_moneybonuskill", "100", "Sets the money bonus a client gets for killing: default 100");
	cvar_AutoMoneyForTeamRatio = 			CreateConVar("sm_uu_automoneyforteam_ratio", "1", "If set to 1, the plugin will manage money balancing");
	////cvar_MoneyForTeamRatioRed = 			CreateConVar("sm_uu_moneyforteam_ratio", "1.00", "Sets the ratio of (money + money spent on upgrades) from a client that the team gets when killing him: default 0.05");
	//cvar_MoneyForTeamRatioBlue = 			CreateConVar("sm_uu_moneyforteam_ratio", "1.00", "Sets the ratio of (money + money spent on upgrades) from a client that the team gets when killing him: default 0.05");
	cvar_TimerMoneyGive_BlueTeam = 		CreateConVar("sm_uu_timermoneygive_blueteam", "100.0", "Sets the money blue team get every timermoney event: default 100.0");
	cvar_TimerMoneyGive_RedTeam =  		CreateConVar("sm_uu_timermoneygive_redteam", "100.0", "Sets the money blue team get every timermoney event: default 80.0");
	if (cvar_uu_version) //Compile warning fast bypass
	{
	}
	//CostIncrease_ratio_default  = GetConVarFloat(cvar_CostIncrease_ratio_default)
	MoneyBonusKill = GetConVarInt(cvar_MoneyBonusKill);
	MoneyForTeamRatio[RED]  =  0.9;
	MoneyForTeamRatio[BLUE]  = 0.9;
	TimerMoneyGive_BlueTeam = GetConVarFloat(cvar_TimerMoneyGive_BlueTeam);
	TimerMoneyGive_RedTeam = GetConVarFloat(cvar_TimerMoneyGive_RedTeam);

	RegAdminCmd("sm_uu_enable_buy_new_weapon", EnableBuyNewWeapon, ADMFLAG_GENERIC);
	RegAdminCmd("sm_setcash", Command_SetCash, ADMFLAG_GENERIC, "Sets cash of selected target/targets.");
	RegAdminCmd("sm_addcash", Command_AddCash, ADMFLAG_GENERIC, "Adds cash of selected target/targets.");
	RegAdminCmd("sm_removecash", Command_RemoveCash, ADMFLAG_GENERIC, "Removes cash of selected target/targets.");
	//RegConsoleCmd("sm_spentmoney", ShowSpentMoney);
	RegAdminCmd("sm_reload_cfg", ReloadCfgFiles, ADMFLAG_GENERIC);//
	RegConsoleCmd("sm_uudteamup", Toggl_DispTeamUpgrades);
	RegConsoleCmd("sm_uurspwn", Toggl_DispMenuRespawn);
	RegConsoleCmd("sm_uunoname", Toggl_NameLevel);
	//Please don't change this, it's for cross compat binds.
	RegConsoleCmd("sm_buy", Menu_BuyUpgrade);
	RegConsoleCmd("buy", Menu_BuyUpgrade);
	RegConsoleCmd("qbuy", Menu_QuickBuyUpgrade);
	RegConsoleCmd("sm_qbuy", Menu_QuickBuyUpgrade);
	RegConsoleCmd("sm_upgrade", Menu_BuyUpgrade);
	HookEvent("post_inventory_application", Event_PlayerreSpawn);
	HookEvent("player_spawn", Event_PlayerreSpawn);
	HookEvent("teamplay_round_start", Event_RoundStart);
	HookEventEx("player_hurt", Event_Playerhurt, EventHookMode_Pre);
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Pre);
	HookEvent("player_changeclass", Event_PlayerChangeClass);
	HookEvent("player_class", Event_PlayerChangeClass);
	HookEvent("player_team", Event_PlayerChangeTeam);
	//MVM
	HookEvent("mvm_pickup_currency", Event_PlayerCollectMoney, EventHookMode_Pre)
	HookEvent("mvm_wave_complete", Event_mvm_wave_complete);
	HookEvent("mvm_begin_wave", Event_mvm_wave_begin);
	HookEvent("mvm_wave_complete", Event_mvm_wave_complete);
	HookEvent("teamplay_round_win", Event_teamplay_round_win);
	AddCommandListener(jointeam_callback, "jointeam");

	Timers_[0] = CreateTimer(20.0, Timer_GetConVars, _, TIMER_REPEAT);
	Timers_[1] = CreateTimer(5.0, Timer_GiveSomeMoney, _, TIMER_REPEAT);
	Timers_[2] = CreateTimer(1.0, Timer_PrintMoneyHud, _, TIMER_REPEAT);

	moneyLevels[0] = 125;
	for (new level = 1; level < MAXLEVEL_D; level++)
	{
		moneyLevels[level] = (125 + ((level + 1) * 50)) + moneyLevels[level - 1];
	}
}

//Initialize menus , CVARs, con cmds and timers handlers on plugin load
public UberShopUnhooks()
{

	UnhookEvent("post_inventory_application", Event_PlayerreSpawn);
	UnhookEvent("player_spawn", Event_PlayerreSpawn);
	UnhookEvent("teamplay_round_start", Event_RoundStart);

	UnhookEvent("player_changeclass", Event_PlayerChangeClass);
	UnhookEvent("player_class", Event_PlayerChangeClass);
	UnhookEvent("player_team", Event_PlayerChangeTeam);

	UnhookEvent("mvm_begin_wave", Event_mvm_wave_begin);

	UnhookEvent("mvm_wave_complete", Event_mvm_wave_complete);
	UnhookEvent("teamplay_round_win", Event_teamplay_round_win);

	KillTimer(Timers_[0]);
	KillTimer(Timers_[1]);
	KillTimer(Timers_[2]);
}

public GetUpgrade_CatList(String:WCName[])
{
	new i, wis, w_id;

	wis = 0;// wcname_idx_start[cl_class]
	//PrintToChatAll("Class: %d; WCname:%s", cl_class, WCName);
	for (i = wis, w_id = -1; i < WCNAMELISTSIZE; i++)
	{
		if (!strcmp(wcnamelist[i], WCName, false))
		{
			w_id = wcname_l_idx[i];
			//PrintToChatAll("wid found; %d", w_id)
			return w_id;
		}
	}
	if (w_id < -1)
	{
		PrintToServer("UberUpgrade error: #%s# was not a valid weapon classname..", WCName);
	}
	return w_id;
}

public void OnPluginStart()
{
	//TODO CVARS cvar_StartMoney = CreateConVar("sm_uu_moneystart", "300", "Sets the starting currency used for upgrades. Default: 500");
	//cvar_TimerMoneyGiven_BlueTeam = CreateConVar("sm_uu_timermoneygive_blueteam", "25", "Sets the currency you obtain on kill. Default: 25");
	//cvar_KillMoneyRatioForTeam = CreateConVar("sm_uu_moneyonkill", "", "Sets the currency you obtain on kill. Default: 25");
	//ConnectDB();
	UberShopinitMenusHandlers();

	UberShopDefineUpgradeTabs();
	SetConVarFloat(FindConVar("sv_maxvelocity"), 10000000.0, true, false); //Up the cap for the speed of projectiles
	SetConVarInt(FindConVar("tf_weapon_criticals"), 0, true, false); //Disables random crits
	RealStartMoney = 1400.0
	for (new client = 0; client < MaxClients; client++)
	{
		if (IsValidClient(client))
		{
			client_no_d_team_upgrade[client] = 1;
			ResetClientUpgrades(client);
			current_class[client] = _:TF2_GetPlayerClass(client);
			//PrintToChat(client, "client changeclass");
			if (!client_respawn_handled[client])
			{
				CreateTimer(0.2, ClChangeClassTimer, GetClientUserId(client));
			}
			CurrencyOwned[client] = 1400.0;
		}
	}
	CreateTimer(10.0, MoneyFlowTimer,_,TIMER_REPEAT);
	return;
}

public OnPluginEnd()
{
	PrintToServer("Plugin ends.");
	UberShopUnhooks();
	PrintToServer("Plugin ends -- Unload complete.");
}

public Action:MoneyFlowTimer(Handle:timer)
{
	for (new i = 1; i < MaxClients + 1; i++)
	{
		if (IsValidClient(i))
		{
			CurrencyOwned[i] += 100.0;
		}
	}
	RealStartMoney += 100.0;
}
public Action:Timer_PrintMoneyHud(Handle:timer)
{
	for (new i = 1; i < MaxClients; i++)
	{
		if (IsValidClient(i))
		{
			decl String:Buffer[12];
			Format(Buffer, sizeof(Buffer), "%d$", CurrencyOwned[i]);
			SetHudTextParams(0.85, 0.8, 1.0, 255,0,0,255);
			ShowHudText(i, -1, Buffer);
		}
	}
}

/*player_spawn
Scout, Soldier, Pyro, DemoMan, Heavy, Medic, Sniper:
[code]0 - Primary 1 - Secondary 2 - Melee[/code]
Engineer:
[code]0 - Primary 1 - Secondary 2 - Melee 3 - Construction PDA 4 - Destruction PDA 5 - Building[/code]
Spy:
[code]0 - Secondary 1 - Sapper 2 - Melee 3 - Disguise Kit 4 - Invisibility Watch[/code]
*/
public Action:Command_SetCash(client, args)
{
	if(args != 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_setcash \"target\" \"amount\"");
		return Plugin_Handled;
	}

	new String:strTarget[MAX_TARGET_LENGTH], String:strCash[128], Float:GivenCash, String:target_name[MAX_TARGET_LENGTH],target_list[MAXPLAYERS], target_count, bool:tn_is_ml;
	GetCmdArg(1, strTarget, sizeof(strTarget));
	if((target_count = ProcessTargetString(strTarget, client, target_list, MAXPLAYERS, COMMAND_FILTER_NO_BOTS, target_name, sizeof(target_name), tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}

	GetCmdArg(2, strCash, sizeof(strCash));
	GivenCash = StringToFloat(strCash);

	for(new i = 0; i < target_count; i++)
	{
		CurrencyOwned[target_list[i]] = GivenCash;
	}
	return Plugin_Handled;
}
public Action:Command_AddCash(client, args)
{
	if(args != 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_addcash \"target\" \"amount\"");
		return Plugin_Handled;
	}
	new String:strTarget[MAX_TARGET_LENGTH], String:strCash[128], Float:GivenCash, String:target_name[MAX_TARGET_LENGTH],target_list[MAXPLAYERS], target_count, bool:tn_is_ml;
	GetCmdArg(1, strTarget, sizeof(strTarget));
	if((target_count = ProcessTargetString(strTarget, client, target_list, MAXPLAYERS, COMMAND_FILTER_NO_BOTS, target_name, sizeof(target_name), tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	GetCmdArg(2, strCash, sizeof(strCash));
	GivenCash = StringToFloat(strCash);
	for(new i = 0; i < target_count; i++)
	{
		CurrencyOwned[target_list[i]] += GivenCash;
	}
	return Plugin_Handled;
}
public Action:Command_RemoveCash(client, args)
{
	if(args != 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_removecash \"target\" \"amount\"");
		return Plugin_Handled;
	}
	
	new String:strTarget[MAX_TARGET_LENGTH], String:strCash[128], Float:GivenCash, String:target_name[MAX_TARGET_LENGTH],target_list[MAXPLAYERS], target_count, bool:tn_is_ml;
	GetCmdArg(1, strTarget, sizeof(strTarget));
	if((target_count = ProcessTargetString(strTarget, client, target_list, MAXPLAYERS, COMMAND_FILTER_NO_BOTS, target_name, sizeof(target_name), tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}

	GetCmdArg(2, strCash, sizeof(strCash));
	GivenCash = StringToFloat(strCash);

	for(new i = 0; i < target_count; i++)
	{
		CurrencyOwned[target_list[i]] -= GivenCash;
	}
	return Plugin_Handled;
}
public bool:GiveNewWeapon(client, slot)
{
	new Handle:newItem = TF2Items_CreateItem(OVERRIDE_ALL);
	new Flags = 0;

	new itemDefinitionIndex = currentitem_idx[client][slot];
	TF2Items_SetItemIndex(newItem, itemDefinitionIndex);
	currentitem_level[client][slot] = 242;

	TF2Items_SetLevel(newItem, 242);

	Flags |= PRESERVE_ATTRIBUTES;

	TF2Items_SetFlags(newItem, Flags);

	TF2Items_SetClassname(newItem, currentitem_classname[client][slot]);

	slot = 6;
	new weaponIndextorem_ = GetPlayerWeaponSlot(client, slot);
	new weaponIndextorem = weaponIndextorem_;


	new entity = TF2Items_GiveNamedItem(client, newItem);
	if (IsValidEntity(entity))
	{
		TF2Attrib_SetByDefIndex(entity,825 ,1.0);
		while ((weaponIndextorem = GetPlayerWeaponSlot(client, slot)) != -1)
		{
			RemovePlayerItem(client, weaponIndextorem);
			RemoveEdict(weaponIndextorem);
		}
		client_new_weapon_ent_id[client] = entity;
		EquipPlayerWeapon(client, entity);
		return true;
	}
	else
	{
		return false;
	}
}

public GiveNewUpgrade(client, slot, uid, a)
{
	//new itemDefinitionIndex = currentitem_idx[client][slot]

//	PrintToChatAll("--Give new upgrade", slot);
	new iEnt;
	if (slot == 4 && IsValidEntity(client))
	{
		iEnt = client;
	}
	else if (currentitem_level[client][slot] != 242)
	{
		iEnt = currentitem_ent_idx[client][slot];
	}
	else
	{
		slot = 3;
		iEnt = client_new_weapon_ent_id[client];
	}
	if (IsValidEntity(iEnt) && strcmp(upgradesWorkNames[upgrades_to_a_id[uid]], ""))
	{
		//PrintToChatAll("trytoremov slot %d", slot);
		TF2Attrib_SetByName(iEnt, upgradesWorkNames[upgrades_to_a_id[uid]],
								  currentupgrades_val[client][slot][a]);

		//TF2Attrib_ClearCache(iEnt)
	}
}

public GiveNewUpgradedWeapon_(client, slot)
{
	TF2_AddCondition(client, TFCond_SpeedBuffAlly, 0.001);
	new a, iNumAttributes;
	new iEnt;
	iNumAttributes = currentupgrades_number[client][slot];
	if(currentitem_ent_idx[client][0] == 1101)
	{
		iEnt = currentitem_ent_idx[client][0];
	}
	if (slot == 4 && IsValidEntity(client))
	{
		iEnt = client;
	}
	else if (currentitem_level[client][slot] != 242)
	{
		iEnt = currentitem_ent_idx[client][slot];
	}
	else
	{
		slot = 3;
		iEnt = client_new_weapon_ent_id[client];
	}
	if (IsValidEntity(iEnt))
	{
		//PrintToChatAll("trytoremov slot %d", slot);
		if( iNumAttributes > 0 )
		{
			for( a = 0; a < 42 && a < iNumAttributes ; a++ )
			{
				new uuid = upgrades_to_a_id[currentupgrades_idx[client][slot][a]];
				if (strcmp(upgradesWorkNames[uuid], ""))
				{
					TF2Attrib_SetByName(iEnt, upgradesWorkNames[uuid], currentupgrades_val[client][slot][a]);
				}
			}
		}
		TF2Attrib_ClearCache(iEnt);
	}
}






public	is_client_got_req(mclient, upgrade_choice, slot, inum)
{
	new iCash = GetEntProp(mclient, Prop_Send, "m_nCurrency", iCash);
	new up_cost = upgrades_costs[upgrade_choice];
	new max_ups = currentupgrades_number[mclient][slot];
	up_cost /= 2;
	client_iCash[mclient] = iCash;
	if (slot == 1)
	{
		up_cost = RoundFloat((up_cost * 1.0) * 0.75); //-25% cost reduction on secondary weapons.
	}
	if (inum != 9999 && upgrades_ratio[upgrade_choice])
	{
		up_cost += RoundFloat(up_cost * (
											(currentupgrades_val[mclient][slot][inum] - upgrades_i_val[upgrade_choice])
												/ upgrades_ratio[upgrade_choice])
											* upgrades_costs_inc_ratio[upgrade_choice]);
		if (up_cost < 0.0)
		{
			up_cost *= -1;
			if (up_cost < (upgrades_costs[upgrade_choice] / 2))
			{
				up_cost = upgrades_costs[upgrade_choice] / 2;
			}
		}
	}
	if (CurrencyOwned[mclient] < up_cost)
	{
		new String:buffer[128]
		Format(buffer, sizeof(buffer), "%T", "You have not enough money!!", mclient);
		PrintToChat(mclient, buffer);
		return 0
	}
	else
	{
		if (inum != 9999)
		{
			if (currentupgrades_val[mclient][slot][inum] == upgrades_m_val[upgrade_choice])
			{
				PrintToChat(mclient, "You already have reached the maximum upgrade for this category.");
				return 0;
			}
		}
		else
		{
			if (max_ups >= MAX_ATTRIBUTES_ITEM)
			{
				PrintToChat(mclient, "You have reached the maximum number of upgrade category for this item.");
				return 0;
			}
		}

		CurrencyOwned[mclient] -= up_cost
		client_spent_money[mclient][slot] += up_cost;
		new totalmoney = 0;
		for (new s = 0; s < 5; s++)
		{
			totalmoney += client_spent_money[mclient][s];
		}
		new ctr_m = clientLevels[mclient];

		while (ctr_m < MAXLEVEL_D && totalmoney > moneyLevels[ctr_m])
		{
			ctr_m++;
		}
		if (ctr_m != clientLevels[mclient])
		{
			clientLevels[mclient] = ctr_m;
			decl String:clname[255];
			new String:strsn[12];
			if (ctr_m == MAXLEVEL_D)
			{
				strsn = "[_Over9000]";
			}
			else
			{
				Format(strsn, sizeof(strsn), "[Lvl %d]", ctr_m + 1);
			}
			Format(clname, sizeof(clname), "%s%s", strsn, clientBaseName[mclient]);
			if(client_no_d_name[mclient] == 1)
			{
				SetClientInfo(mclient, "name", clname);
			}
		}
		return 1;
	}
}

public	check_apply_maxvalue(mclient, slot, inum, upgrade_choice)
{
	if ((upgrades_ratio[upgrade_choice] > 0.0
		 && currentupgrades_val[mclient][slot][inum] > upgrades_m_val[upgrade_choice])
		|| (upgrades_ratio[upgrade_choice] < 0.0
			&& currentupgrades_val[mclient][slot][inum] < upgrades_m_val[upgrade_choice]))
		{
			currentupgrades_val[mclient][slot][inum] = upgrades_m_val[upgrade_choice];
		}
}

public UpgradeItem(mclient, upgrade_choice, inum, Float:ratio)
{
	new slot = current_slot_used[mclient];
	//PrintToChat(mclient, "Entering #upprimary");


	if (inum == 9999)
	{
		inum = currentupgrades_number[mclient][slot];
		upgrades_ref_to_idx[mclient][slot][upgrade_choice] = inum;
		currentupgrades_idx[mclient][slot][inum] = upgrade_choice;
		currentupgrades_val[mclient][slot][inum] = upgrades_i_val[upgrade_choice];
		currentupgrades_number[mclient][slot] = currentupgrades_number[mclient][slot] + 1;
		//PrintToChat(mclient, "#upprimary Adding New Upgrade uslot(%d) [%s]", inum, upgradesNames[upgrade_choice]);
		currentupgrades_val[mclient][slot][inum] += (upgrades_ratio[upgrade_choice] * ratio);
	}
	else
	{
	//	PrintToChat(mclient, "#upprimary existin attr: %d", inum)
	//	PrintToChat(mclient, "#upprimary ++ Existing Upgrade(%d) %d[%s]", inum, currentupgrades_idx[mclient][slot][inum], upgradesNames[upgrade_choice]);
		currentupgrades_val[mclient][slot][inum] += (upgrades_ratio[upgrade_choice] * ratio);
		check_apply_maxvalue(mclient, slot, inum, upgrade_choice);
	}
		//PrintToChat(mclient, "#upprimary Entering givenew to slot %d", slot);
	client_last_up_idx[mclient] = upgrade_choice;
	client_last_up_slot[mclient] = slot;
	//PrintToChat(mclient, "exit ...#upprimary");
}

public ResetClientUpgrade_slot(client, slot)
{
	new i;
	new iNumAttributes = currentupgrades_number[client][slot];

	//PrintToChat(client, "#resetupgrade monweyspend-> %d", client_spent_money[client][slot]);
	if (client_spent_money[client][slot])
	{
		CurrencyOwned[client] += client_spent_money[client][slot];
	}
	currentitem_level[client][slot] = 0;
	client_spent_money[client][slot] = 0;
	client_spent_money_mvm_chkp[client][slot] = 0;
	currentupgrades_number[client][slot] = 0;
//	PrintToChat(client, "enter ...#resetupgradeslot %d, resetting values for %d attributes", slot, iNumAttributes);

	for (i = 0; i < iNumAttributes; i++)
	{
	//	PrintToChat(client, "enter ...#resetupgrade [%d][%d] -> ref(%d)[%s]", slot, i,
		//		upgrades_ref_to_idx[client][slot][currentupgrades_idx[client][slot][i]],
		//		upgradesNames[currentupgrades_idx[client][slot][i]])
		upgrades_ref_to_idx[client][slot][currentupgrades_idx[client][slot][i]] = 9999;
		//currentupgrades_idx[client][slot][i] = 9999
	}

	if (slot != 4 && currentitem_idx[client][slot])
	{
		currentitem_idx[client][slot] = 9999;
		GiveNewUpgradedWeapon_(client, slot);

		//
		//currentitem_ent_idx[client][slot] = -1
	}
	//client_last_up_idx[client] = -1
//	client_last_up_slot[client] = -1
	if (slot == 3 && client_new_weapon_ent_id[client])
	{
		currentitem_idx[client][3] = 9999;
		currentitem_ent_idx[client][3] = -1;
		GiveNewUpgradedWeapon_(client, slot);
		client_new_weapon_ent_id[client] = 0;
	}
	if (slot == 4)
	{
		GiveNewUpgradedWeapon_(client, slot);
	}
	new totalmoney = 0;
	for (new s = 0; s < 5; s++)
	{
		totalmoney += client_spent_money[client][s];
	}
	new ctr_m = clientLevels[client];

	while (ctr_m && totalmoney < moneyLevels[ctr_m])
	{
		ctr_m--;
	}
	if (ctr_m != clientLevels[client])
	{
		clientLevels[client] = ctr_m;
		new String:strsn[12];
		new String:clname[255];
		if (ctr_m == MAXLEVEL_D)
		{
			strsn = "[_Over9000]";
		}
		else
		{
			Format(strsn, sizeof(strsn), "[Lvl %d]", ctr_m + 1);
		}
		Format(clname, sizeof(clname), "%s%s", strsn, clientBaseName[client]);
		if(client_no_d_name[client] == 1)
		{
			SetClientInfo(client, "name", clname);
		}
	}
}

public ResetClientUpgrades(client)
{
	new slot;

	client_respawn_handled[client] = 0;
	for (slot = 0; slot < NB_SLOTS_UED; slot++)
	{
		ResetClientUpgrade_slot(client, slot);
		//PrintToChatAll("reste all upgrade slot %d", slot)
	}
}


public DefineAttributesTab(client, itemidx, slot)
{
	//PrintToChat(client, "Entering Def attr tab, ent id: %d", itemidx);
	//PrintToChat(client, "  #dattrtab item carried: %d - item_buff: %d", itemidx, currentitem_idx[client][slot]);
	if (currentitem_idx[client][slot] == 9999)
	{
		new a, a2, i, a_i;

		currentitem_idx[client][slot] = itemidx;
		new inumAttr = TF2II_GetItemNumAttributes( itemidx );
		for( a = 0, a2 = 0; a < inumAttr && a < 42; a++ )
		{
			decl String:Buf[64];
			a_i = TF2II_GetItemAttributeID( itemidx, a);
			TF2II_GetAttribName( a_i, Buf, 64);
		//	if (!GetTrieValue(_upg_names, Buf, i))
		//	{
		//		i = _u_id
		//		upgradesNames[i] = Buf
		//		upgrades_costs[i] = 1
		//		SetTrieValue(_upg_names, Buf, _u_id++)
		//		upgrades_to_a_id[i] = a_i
		//	}
			if (GetTrieValue(_upg_names, Buf, i))
			{
				currentupgrades_idx[client][slot][a2] = i;

				upgrades_ref_to_idx[client][slot][i] = a2;
				currentupgrades_val[client][slot][a2] = TF2II_GetItemAttributeValue( itemidx, a );
				//PrintToChat(client, "init-attribute-[%s]%d [%d ; %f]",
			//	upgradesNames[currentupgrades_idx[client][slot][a2]],
			//	itemidx, i, currentupgrades_val[client][slot][a]);
				a2++;
			}
		}
		currentupgrades_number[client][slot] = a2;
	}
	else
	{
		if (itemidx > 0 && itemidx != currentitem_idx[client][slot])
		{
			ResetClientUpgrade_slot(client, slot);
			new a, a2, i, a_i;

			currentitem_idx[client][slot] = itemidx;
			new inumAttr = TF2II_GetItemNumAttributes( itemidx );
			for( a = 0, a2 = 0; a < inumAttr && a < 42; a++ )
			{
				decl String:Buf[64];
				a_i = TF2II_GetItemAttributeID( itemidx, a);
				TF2II_GetAttribName( a_i, Buf, 64);
		//	if (!GetTrieValue(_upg_names, Buf, i))
		//	{
		//		i = _u_id
		//		upgradesNames[i] = Buf
		//		upgrades_costs[i] = 1
		//		SetTrieValue(_upg_names, Buf, _u_id++)
		//		upgrades_to_a_id[i] = a_i
		//	}
				if (GetTrieValue(_upg_names, Buf, i))
				{
					currentupgrades_idx[client][slot][a2] = i;

					upgrades_ref_to_idx[client][slot][i] = a2;
					currentupgrades_val[client][slot][a2] = TF2II_GetItemAttributeValue( itemidx, a );
					//PrintToChat(client, "init-attribute-%d [%d ; %f]", itemidx, i, currentupgrades_val[client][slot][a]);
					a2++;
				}
			}
			currentupgrades_number[client][slot] = a2;
		}
	}
	//PrintToChat(client, "..finish #dattrtab ");
}


public	Menu_TweakUpgrades(mclient)
{
	new Handle:menu = CreateMenu(MenuHandler_AttributesTweak);
	new s;

	SetMenuTitle(menu, "Remove downgrades or Display Upgrades");
	for (s = 0; s < 5; s++)
	{
		decl String:fstr[100];
		Format(fstr, sizeof(fstr), "%d$ of upgrades | Modify or Remove my %s attributes", client_spent_money[mclient][s], current_slot_name[s]);
		AddMenuItem(menu, "tweak", fstr);
	}
	if (IsValidClient(mclient) && IsPlayerAlive(mclient))
	{
		DisplayMenu(menu, mclient, 20);
	}
}

public	Menu_TweakUpgrades_slot(mclient, arg, page)
{
	if (arg > -1 && arg < 5
	&& IsValidClient(mclient) 
	&& IsPlayerAlive(mclient))
	{
		new Handle:menu = CreateMenu(MenuHandler_AttributesTweak_action);
		new i, s
			
		s = arg;
		current_slot_used[mclient] = s;
		SetMenuTitle(menu, "%.0f$ ***%s - Choose attribute:", CurrencyOwned[mclient], current_slot_name[s]);
		decl String:buf[128]
		decl String:fstr[255]
		for (i = 0; i < currentupgrades_number[mclient][s]; i++)
		{
			new u = currentupgrades_idx[mclient][s][i]
			Format(buf, sizeof(buf), "%T", upgradesNames[u], mclient)
			if (upgrades_costs[u] < -0.0001)
			{
				new nb_time_upgraded = RoundFloat((upgrades_i_val[u] - currentupgrades_val[mclient][s][i]) / upgrades_ratio[u]);
				new up_cost = upgrades_costs[u] * nb_time_upgraded * 3;
				Format(fstr, sizeof(fstr), "[%s] :\n\t\t%10.2f\n%d", buf, currentupgrades_val[mclient][s][i],up_cost)
			}
			else
			{
				Format(fstr, sizeof(fstr), "[%s] :\n\t\t%10.2f", buf, currentupgrades_val[mclient][s][i])
			}
			AddMenuItem(menu, "yep", fstr);
		}
		if (IsValidClient(mclient) && IsPlayerAlive(mclient))
		{
			DisplayMenu(menu, mclient, 20);
		}
		DisplayMenuAtItem(menu, mclient, page, MENU_TIME_FOREVER);
	}
}

public remove_attribute(client, inum)
{
	new slot = current_slot_used[client];
	//new nb = currentupgrades_number[client][slot]

	//new tmpswap1, Float:tmpswap2
	currentupgrades_val[client][slot][inum] = upgrades_i_val[currentupgrades_idx[client][slot][inum]];

	// if ((nb - 1) != inum)
	// {
		// tmpswap1 = currentupgrades_idx[client][slot][nb - 1]
		// currentupgrades_idx[client][slot][inum] = tmpswap1
		// tmpswap2 = currentupgrades_val[client][slot][nb - 1]
		// currentupgrades_val[client][slot][inum] = tmpswap2
		// upgrades_ref_to_idx[client][slot][tmpswap1] = inum
	// }
	// currentupgrades_idx[client][slot][nb - 1] = 9999;
	// currentupgrades_val[client][slot][nb - 1] = 0.0;

	GiveNewUpgradedWeapon_(client, slot);
}



//menubuy 3- choose the upgrade
public Action:Menu_SpecialUpgradeChoice(client, cat_choice, String:TitleStr[100], selectidx)
{
	//PrintToChat(client, "Entering menu_upchose");
	new i, j;


	new Handle:menu = CreateMenu(MenuHandler_SpecialUpgradeChoice);
	SetMenuPagination(menu, 2);
	//PrintToChat(client, "Entering menu_upchose [%d] wid%d", cat_choice, current_w_list_id[client]);
	if (cat_choice != -1)
	{
		decl String:desc_str[512];
		new w_id = current_w_list_id[client];
		new tmp_up_idx;
		new tmp_spe_up_idx;
		new tmp_ref_idx;
		new Float:tmp_val;
		new Float:tmp_ratio;
		new slot;
		decl String:plus_sign[1];
		new String:buft[64];

		current_w_c_list_id[client] = cat_choice;
		slot = current_slot_used[client];
		for (i = 0; i < given_upgrd_classnames_tweak_nb[w_id]; i++)
		{
			tmp_spe_up_idx = given_upgrd_list[w_id][cat_choice][i];
			Format(buft, sizeof(buft), "%T",  upgrades_tweaks[tmp_spe_up_idx], client);
			//PrintToChat(client, "--->special ID", tmp_spe_up_idx);
			desc_str = buft;
			for (j = 0; j < upgrades_tweaks_nb_att[tmp_spe_up_idx]; j++)
			{
				tmp_up_idx = upgrades_tweaks_att_idx[tmp_spe_up_idx][j];
				tmp_ref_idx = upgrades_ref_to_idx[client][slot][tmp_up_idx];
				if (tmp_ref_idx != 9999)
				{
					tmp_val = currentupgrades_val[client][slot][tmp_ref_idx] - upgrades_i_val[tmp_up_idx];
				}
				else
				{
					tmp_val = 0.0;
				}
				tmp_ratio = upgrades_ratio[tmp_up_idx];
				if (tmp_ratio > 0.0)
				{
					plus_sign = "+";
				}
				else
				{
					tmp_ratio *= -1.0;
					plus_sign = "-";
				}
				new String:buf[64];
				Format(buf, sizeof(buf), "%T", upgradesNames[tmp_up_idx], client);
				if (tmp_ratio < 0.99)
				{
					tmp_ratio *= upgrades_tweaks_att_ratio[tmp_spe_up_idx][j];
					Format(desc_str, sizeof(desc_str), "%s\n%\t-%s\n\t\t\t%s%i%%\t(%i%%)",
						desc_str, buf,
						plus_sign, RoundFloat(tmp_ratio * 100), RoundFloat(tmp_val * 100));
				}
				else
				{
					tmp_ratio *= upgrades_tweaks_att_ratio[tmp_spe_up_idx][j];
					Format(desc_str, sizeof(desc_str), "%s\n\t-%s\n\t\t\t%s%3i\t(%i)",
						desc_str, buf,
						plus_sign, RoundFloat(tmp_ratio), RoundFloat(tmp_val));
				}
			}
			AddMenuItem(menu, "upgrade", desc_str);
		}
	}
	SetMenuTitle(menu, TitleStr);
	SetMenuExitButton(menu, true);
	DisplayMenuAtItem(menu, client, selectidx, 30);

//	return Plugin_Handled;
}



public MenuHandler_SpecialUpgradeChoice(Handle:menu, MenuAction:action, mclient, param2)
{
	if (action == MenuAction_Select)
	{
		client_respawn_handled[mclient] = 0;
		new String:fstr[100];
		new got_req = 1;
		new slot = current_slot_used[mclient];
		new w_id = current_w_list_id[mclient];
		new cat_id = current_w_c_list_id[mclient];
		new spTweak = given_upgrd_list[w_id][cat_id][param2];
		for (new i = 0; i < upgrades_tweaks_nb_att[spTweak]; i++)
		{
			new upgrade_choice = upgrades_tweaks_att_idx[spTweak][i];
			new inum = upgrades_ref_to_idx[mclient][slot][upgrade_choice];
			if (inum != 9999)
				{
					if (currentupgrades_val[mclient][slot][inum] == upgrades_m_val[upgrade_choice])
					{
						PrintToChat(mclient, "You already have reached the maximum upgrade for this tweak.");
						got_req = 0;
					}
				}
				else
				{
					if (currentupgrades_number[mclient][slot] + upgrades_tweaks_nb_att[spTweak] >= MAX_ATTRIBUTES_ITEM)
					{
						PrintToChat(mclient, "You have not enough upgrade category slots for this tweak.");
						got_req = 0;
					}
				}


		}
		if (got_req)
		{
			decl String:clname[255];
			GetClientName(mclient, clname, sizeof(clname));
			for (new i = 1; i < MaxClients; i++)
			{
				if (IsValidClient(i) && !client_no_d_team_upgrade[i])
				{
					PrintToChat(i,"%s : [%s tweak] - %s!",
					clname, upgrades_tweaks[spTweak], current_slot_name[slot]);
				}
			}
			for (new i = 0; i < upgrades_tweaks_nb_att[spTweak]; i++)
			{
				new upgrade_choice = upgrades_tweaks_att_idx[spTweak][i];
				UpgradeItem(mclient, upgrade_choice, upgrades_ref_to_idx[mclient][slot][upgrade_choice],
					upgrades_tweaks_att_ratio[spTweak][i]);
			}
			GiveNewUpgradedWeapon_(mclient, slot);
			new String:buf[32];
			Format(buf, sizeof(buf), "%T", current_slot_name[slot], mclient);
			Format(fstr, sizeof(fstr), "%.0f$ [%s] - %s", CurrencyOwned[mclient], buf, 
					given_upgrd_classnames[w_id][cat_id])
			Menu_SpecialUpgradeChoice(mclient, cat_id, fstr, GetMenuSelectionPosition());
		}
			//PrintToChat(mclient, "#MENU UPC FSTR=%s", fstr);
	}

	
}


public MenuHandler_AttributesTweak_action(Handle:menu, MenuAction:action, client, param2)
{
	if (IsValidClient(client) && IsPlayerAlive(client) && !client_respawn_checkpoint[client])
	{
		new s = current_slot_used[client];
		if (s >= 0 && s < 4 && param2 < MAX_ATTRIBUTES_ITEM)
		{
			if (param2 >= 0)
			{
				new u = currentupgrades_idx[client][s][param2]
				if (u != 20000)
				{
					if (upgrades_costs[u] < -0.0001)
					{
						new nb_time_upgraded = RoundFloat((upgrades_i_val[u] - currentupgrades_val[client][s][param2]) / upgrades_ratio[u])
						new up_cost = upgrades_costs[u] * nb_time_upgraded * 3
						if (CurrencyOwned[client] >= up_cost)
						{
							remove_attribute(client, param2)
							CurrencyOwned[client] -= up_cost;
							client_spent_money[client][s] += up_cost
						}
						else
						{
							new String:buffer[128]
							Format(buffer, sizeof(buffer), "%T", "You have not enough money!!", client);
							PrintToChat(client, buffer);
						}
					}
					else
					{
						PrintToChat(client,"Attribute is Unremovable")
					}
					Menu_TweakUpgrades_slot(client, s, GetMenuSelectionPosition())
				}
			}
		}
	}
}



//menubuy 1-chose the item attribute to tweak
public MenuHandler_AttributesTweak(Handle:menu, MenuAction:action, client, param2)
{
	if (IsValidClient(client) && IsPlayerAlive(client) && !client_respawn_checkpoint[client])
	{
		Menu_TweakUpgrades_slot(client, param2, 0);
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
	//return Plugin_Handled;
}

//cl command to display current item attributes tables
public	DisplayCurrentUps(mclient)
{
	new i, s;
	PrintToChat(mclient, "***Current attributes:");
	for (s = 0; s < 4; s++)
	{
		PrintToChat(mclient, "[%s]:", current_slot_name[s]);
		for (i = 0; i < currentupgrades_number[mclient][s]; i++)
		{
			PrintToChat(mclient, "%s: %10.2f", upgradesNames[currentupgrades_idx[mclient][s][i]], currentupgrades_val[mclient][s][i]);
		}
	}
}


public	Menu_BuyNewWeapon(mclient)
{

	if (IsValidClient(mclient) && IsPlayerAlive(mclient))
	{
		DisplayMenu(BuyNWmenu, mclient, 20);
	}
}



//menubuy 2- choose the category of upgrades
public Action:Menu_ChooseCategory(client, String:TitleStr[64])
{
//	PrintToChat(client, "Entering menu_chscat");
	new i;
	new w_id;

	new Handle:menu = CreateMenu(MenuHandler_Choosecat);
	new slot = current_slot_used[client];
	if (slot != 4)
	{
		w_id = currentitem_catidx[client][slot];
	}
	else
	{
		w_id = current_class[client] - 1;
	}
	if (w_id >= 0)
	{
		current_w_list_id[client] = w_id;
		new String:buf[64];
		for (i = 0; i < given_upgrd_list_nb[w_id]; i++)
		{
			Format(buf, sizeof(buf), "%T", given_upgrd_classnames[w_id][i], client);
			AddMenuItem(menu, "upgrade", buf);
		}
	}
	SetMenuTitle(menu, TitleStr);
	SetMenuExitButton(menu, true);
	if (IsValidClient(client) && IsPlayerAlive(client))
//	&& !TF2_IsPlayerInCondition(client, TFCond_Disguised))
	{
		DisplayMenu(menu, client, 20);
	}
	//return Plugin_Handled;
}

public isValidVIP(client)
{
	new flags = GetUserFlagBits (client);
	return (flags & ADMFLAG_CUSTOM1 );
}

//menubuy 3- choose the upgrade
public Action:Menu_UpgradeChoice(client, cat_choice, String:TitleStr[100])
{
	new i;

	new Handle:menu = CreateMenu(MenuHandler_UpgradeChoice);
	if (cat_choice != -1)
	{
		new w_id = current_w_list_id[client];

		decl String:desc_str[255];
		new tmp_up_idx;
		new tmp_ref_idx;
		new up_cost;
		new Float:tmp_val;
		new Float:tmp_ratio;
		new slot;
		decl String:plus_sign[1];
		current_w_c_list_id[client] = cat_choice;
		slot = current_slot_used[client];
		for (i = 0; (tmp_up_idx = given_upgrd_list[w_id][cat_choice][i]); i++)
		{
			up_cost = upgrades_costs[tmp_up_idx] / 2;
			if (slot == 1)
			{
				up_cost = RoundFloat((up_cost * 1.0) * 0.75); // -25% cost reduction on secondaries
			}
			tmp_ref_idx = upgrades_ref_to_idx[client][slot][tmp_up_idx];
			if (tmp_ref_idx != 9999)
			{
			//	PrintToChat(client, "menuexisting att:%d", tmp_ref_idx)
				tmp_val = currentupgrades_val[client][slot][tmp_ref_idx] - upgrades_i_val[tmp_up_idx];
			}
			else
			{
				tmp_val = 0.0;
			}
			tmp_ratio = upgrades_ratio[tmp_up_idx];
			if (tmp_val && tmp_ratio)
			{
				up_cost += RoundFloat(up_cost * (tmp_val / tmp_ratio) * upgrades_costs_inc_ratio[tmp_up_idx]);
				if (up_cost < 0.0)
				{
					up_cost *= -1;
					if (up_cost < (upgrades_costs[tmp_up_idx] / 2))
					{
						up_cost = upgrades_costs[tmp_up_idx] / 2;
					}
				}
			}
			if (tmp_ratio > 0.0)
			{
				plus_sign = "+";
			}
			else
			{
				tmp_ratio *= -1.0;
				plus_sign = "-";
			}
			new String:buf[64];
			Format(buf, sizeof(buf), "%T", upgradesNames[tmp_up_idx], client);
			if (tmp_ratio < 0.99)
			{
				Format(desc_str, sizeof(desc_str), "%5d$ -%s\n\t\t\t%s%i%%\t(%i%%)",
					up_cost, buf,
					plus_sign, RoundFloat(tmp_ratio * 100), RoundFloat(tmp_val * 100));
			}
			else
			{
				Format(desc_str, sizeof(desc_str), "%5d$ -%s\n\t\t\t%s%3i\t(%i)",
					up_cost, buf,
					plus_sign, RoundFloat(tmp_ratio), RoundFloat(tmp_val));
			}

			AddMenuItem(menu, "upgrade", desc_str);
		}
	}
	SetMenuTitle(menu, TitleStr);
	SetMenuExitButton(menu, true);

	DisplayMenu(menu, client, 20);

	//return Plugin_Handled;
}


//menubuy 1-chose the item category of upgrade
public Action:Menu_BuyUpgrade(client, args)
{
	 if (IsValidClient(client) && IsPlayerAlive(client) && !client_respawn_checkpoint[client])
//		&& !TF2_IsPlayerInCondition(client, TFCond_Disguised) )
	 {
			new String:buffer[64];
			menuBuy = CreateMenu(MenuHandler_BuyUpgrade);
			SetMenuTitle(menuBuy, "Uber Upgrades - /buy or +reload & +showscores");
			AddMenuItem(menuBuy, "upgrade_player", "Body upgrades");

			AddMenuItem(menuBuy, "upgrade_primary", "Primary weapon upgrades");

			AddMenuItem(menuBuy, "upgrade_secondary", "Secondary weapon upgrades");

			AddMenuItem(menuBuy, "upgrade_melee", "Melee weapon upgrades");

			//Format(buffer, sizeof(buffer), "%T", "Display Upgrades/Remove downgrades", client);
			AddMenuItem(menuBuy, "upgrade_dispcurrups", "Remove downgrades & Display Upgrades");
			if (!BuyNWmenu_enabled)
			{
				Format(buffer, sizeof(buffer), "%T", "Buy another weapon", client);
				AddMenuItem(menuBuy, "upgrade_buyoneweap", buffer);
				if (currentitem_level[client][3] == 242)
				{
					Format(buffer, sizeof(buffer), "%T", "Upgrade bought weapon", client);
					AddMenuItem(menuBuy, "upgrade_buyoneweap", buffer);
				}
			}
			SetMenuExitButton(menuBuy, true);
			DisplayMenu(menuBuy, client, 20);
	}
	//return Plugin_Handled;
}


//menubuy 3-Handler
public MenuHandler_BuyNewWeapon(Handle:menu, MenuAction:action, mclient, param2)
{
	if (action == MenuAction_Select)
	{
		new iCash = GetEntProp(mclient, Prop_Send, "m_nCurrency", iCash);
		if (iCash > 200)
		{
			if (currentitem_idx[mclient][3])
			{
				PrintToChat(mclient, "You already have");
			}
			ResetClientUpgrade_slot(mclient, 3);
			currentitem_idx[mclient][3] = newweaponidx[param2];
			currentitem_classname[mclient][3] = newweaponcn[param2];
			SetEntProp(mclient, Prop_Send, "m_nCurrency", iCash - 200);
			client_spent_money[mclient][3] = 200;
			//PrintToChat(mclient, "You will have it next spawn.")
			GiveNewWeapon(mclient, 3);
		}
		else
		{
			new String:buffer[64];
			Format(buffer, sizeof(buffer), "%T", "You have not enough money!!", mclient);
			PrintToChat(mclient, buffer);
		}
	}
}


public MenuHandler_AccessDenied(Handle:menu, MenuAction:action, mclient, param2)
{
	if (action == MenuAction_Select)
	{
		PrintToChat(mclient, "This feature is donators/VIPs only");
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

//menubuy 3-Handler
public MenuHandler_UpgradeChoice(Handle:menu, MenuAction:action, mclient, param2)
{
	if (action == MenuAction_Select)
	{
		client_respawn_handled[mclient] = 0;
		new slot = current_slot_used[mclient];
		new w_id = current_w_list_id[mclient];
		new cat_id = current_w_c_list_id[mclient];
		new upgrade_choice = given_upgrd_list[w_id][cat_id][param2];
		new inum = upgrades_ref_to_idx[mclient][slot][upgrade_choice];

		if (is_client_got_req(mclient, upgrade_choice, slot, inum))
		{
			UpgradeItem(mclient, upgrade_choice, inum, 1.0);
			GiveNewUpgradedWeapon_(mclient, slot);
		}
		decl String:fstr2[100];
		decl String:fstr[40];
		decl String:fstr3[20];
		if (slot != 4)
		{
			Format(fstr, sizeof(fstr), "%t", given_upgrd_classnames[w_id][cat_id], 
					mclient)
			Format(fstr3, sizeof(fstr3), "%T", current_slot_name[slot], mclient)
			Format(fstr2, sizeof(fstr2), "%.0f$ [%s] - %s", CurrencyOwned[mclient], fstr3,
				fstr)
		}
		else
		{
			Format(fstr, sizeof(fstr), "%t", given_upgrd_classnames[current_class[mclient] - 1][cat_id], 
					mclient)
			Format(fstr3, sizeof(fstr3), "%T", "Body upgrade", mclient)
			Format(fstr2, sizeof(fstr2), "%.0f$ [%s] - %s", CurrencyOwned[mclient], fstr3,
				fstr)
		}
		SetMenuTitle(menu, fstr2);
		decl String:desc_str[255];
		new tmp_up_idx;
		new tmp_ref_idx;
		new up_cost;
		new Float:tmp_val;
		new Float:tmp_ratio;
		decl String:plus_sign[1];

		tmp_up_idx = given_upgrd_list[w_id][cat_id][param2];
		up_cost = upgrades_costs[tmp_up_idx] / 2;
		if (slot == 1)
		{
			up_cost = RoundFloat((up_cost * 1.0) * 0.75); // -25% cost reduction on secondaries
		}
		tmp_ref_idx = upgrades_ref_to_idx[mclient][slot][tmp_up_idx];
		if (tmp_ref_idx != 9999)
		{
			tmp_val = currentupgrades_val[mclient][slot][tmp_ref_idx] - upgrades_i_val[tmp_up_idx];
		}
		else
		{
			tmp_val = 0.0;
		}
		tmp_ratio = upgrades_ratio[tmp_up_idx];
		if (tmp_val && tmp_ratio)
		{
			up_cost += RoundFloat(up_cost * (tmp_val / tmp_ratio) * upgrades_costs_inc_ratio[tmp_up_idx]);
			if (up_cost < 0.0)
			{
				up_cost *= -1;
				if (up_cost < (upgrades_costs[tmp_up_idx] / 2))
				{
					up_cost = upgrades_costs[tmp_up_idx] / 2;
				}
			}
		}
		if (tmp_ratio > 0.0)
		{
			plus_sign = "+";
		}
		else
		{
			tmp_ratio *= -1.0;
			plus_sign = "-";
		}
		new String:buf[64];
		Format(buf, sizeof(buf), "%T", upgradesNames[tmp_up_idx], mclient);
		if (tmp_ratio < 0.99)
		{
			Format(desc_str, sizeof(desc_str), "%5d$ -%s\n\t\t\t%s%i%%\t(%i%%)",
				up_cost, buf,
				plus_sign, RoundFloat(tmp_ratio * 100), RoundFloat(tmp_val * 100));
		}
		else
		{
			Format(desc_str, sizeof(desc_str), "%5d$ -%s\n\t\t\t%s%3i\t(%i)",
				up_cost, buf,
				plus_sign, RoundFloat(tmp_ratio), RoundFloat(tmp_val));
		}


		InsertMenuItem(menu, param2, "upgrade", desc_str);
		RemoveMenuItem(menu, param2 + 1);
		DisplayMenuAtItem(menu, mclient, GetMenuSelectionPosition(), 20);

	}
	//else if (action == MenuAction_End)
	//{
		//CloseHandle(menu);
	//}
}


//menubuy 2- Handler
public MenuHandler_BodyUpgrades(Handle:menu, MenuAction:action, mclient, param2)
{
	if (action == MenuAction_Select)
	{
		decl String:fstr2[100];
		decl String:fstr[40];
		decl String:fstr3[20];

		Format(fstr, sizeof(fstr), "%T", given_upgrd_classnames[current_class[mclient] - 1][param2],
					mclient);
		Format(fstr3, sizeof(fstr3), "%T", "Body upgrade", mclient);
		Format(fstr2, sizeof(fstr2), "%.0f$ [%s] - %s", CurrencyOwned[mclient], fstr3,
				fstr)

		Menu_UpgradeChoice(mclient, param2, fstr2);
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

public MenuHandler_SpeMenubuy(Handle:menu, MenuAction:action, mclient, param2)
{

	CloseHandle(menu);
	//return Plugin_Handled;
}

public MenuHandler_Choosecat(Handle:menu, MenuAction:action, mclient, param2)
{
//	PrintToChatAll("exitbutton  %d", param2)
	if (action == MenuAction_Select)
	{
		decl String:fstr2[100];
		decl String:fstr[40];
		decl String:fstr3[20];
		new slot = current_slot_used[mclient]
		new cat_id = currentitem_catidx[mclient][slot]
		if (slot != 4)
		{
			Format(fstr, sizeof(fstr), "%T", given_upgrd_classnames[cat_id][param2], mclient)
			Format(fstr3, sizeof(fstr3), "%T", current_slot_name[slot], mclient)
			Format(fstr2, sizeof(fstr2), "%.0f$ [%s] - %s", CurrencyOwned[mclient],fstr3,fstr)
			Menu_UpgradeChoice(mclient, param2, fstr2)
			if (param2 == given_upgrd_classnames_tweak_idx[cat_id])
			{
				Menu_SpecialUpgradeChoice(mclient, param2, fstr2,0)
			}
			else
			{
				Menu_UpgradeChoice(mclient, param2, fstr2)
			}
		}
		else
		{
			Format(fstr, sizeof(fstr), "%T", given_upgrd_classnames[cat_id][param2], mclient)
			Format(fstr3, sizeof(fstr3), "%T", "Body upgrade", mclient)
			Format(fstr2, sizeof(fstr2), "%.0f$ [%s] - %s", CurrencyOwned[mclient], fstr3, fstr)
			if (param2 == given_upgrd_classnames_tweak_idx[cat_id])
			{
				Menu_SpecialUpgradeChoice(mclient, param2, fstr2,0)
			}
			else
			{
				Menu_UpgradeChoice(mclient, param2, fstr2)
			}
		}
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}


public MenuHandler_BuyUpgrade(Handle:menu, MenuAction:action, mclient, param2)
{
	/* If an option was selected, tell the client about the item. */
	if (action == MenuAction_Select)
	{
		if (param2 == 0)
		{
			decl String:fstr[30];
			decl String:fstr2[64];
			current_slot_used[mclient] = 4;
			client_iCash[mclient] = GetEntProp(mclient, Prop_Send, "m_nCurrency", client_iCash[mclient]);
			Format(fstr, sizeof(fstr), "%T", "Body upgrade", mclient);
			Format(fstr2, sizeof(fstr2), "%.0f$ [ - %s - ]", CurrencyOwned[mclient], fstr)
			Menu_ChooseCategory(mclient, fstr2);
			//DisplayCurrentUps(mclient);
		}
		else if (param2 == 4)
		{
			Menu_TweakUpgrades(mclient);
			//DisplayCurrentUps(mclient);
		}
		else if (param2 == 5)
		{
			Menu_BuyNewWeapon(mclient);
			//DisplayCurrentUps(mclient);
		}
		else if (param2 == 6)
		{
			decl String:fstr[30];
			decl String:fstr2[64];
			current_slot_used[mclient] = 3;

			Format(fstr, sizeof(fstr), "%T", "Body upgrade", mclient);
			client_iCash[mclient] = GetEntProp(mclient, Prop_Send, "m_nCurrency", client_iCash[mclient]);
			Format(fstr2, sizeof(fstr2), "%.0f$ [ - Upgrade %s - ]", CurrencyOwned[mclient]
															  ,fstr)
			Menu_ChooseCategory(mclient, fstr2);
		}
		else
		{
			decl String:fstr[30];
			decl String:fstr2[64];
			param2 -= 1;
			current_slot_used[mclient] = param2;
			Format(fstr, sizeof(fstr), "%T", current_slot_name[param2], mclient);
			client_iCash[mclient] = GetEntProp(mclient, Prop_Send, "m_nCurrency", client_iCash[mclient]);
			Format(fstr2, sizeof(fstr2), "%.0f$ [ - Upgrade %s - ]", CurrencyOwned[mclient]
															  ,fstr)
			Menu_ChooseCategory(mclient, fstr2);

		}
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
	//return Plugin_Handled;
}

stock int TF2_GetPlayerMaxHealth(int client) {
	return GetEntProp(GetPlayerResourceEntity(), Prop_Send, "m_iMaxHealth", _, client);
}
public OnClientPostAdminCheck(client)
{
	if(IsValidClient(client))
	{
		CurrencyOwned[client] = RealStartMoney;
	}
} 
RespawnEffect(client)
{
	current_class[client] = _:TF2_GetPlayerClass(client);
	TF2Attrib_SetByName(client,"afterburn immunity", 1.0);//fix afterburn
	TF2Attrib_SetByName(client,"weapon burn time increased", 15.0);//fix afterburn
	if(current_class[client] == _:TFClass_Pyro)
	{
		TF2Attrib_SetByName(client,"airblast_pushback_no_stun", 1.0);//Make airblast less annoying...
	}
}
ChangeClassEffect(client)
{
	current_class[client] = _:TF2_GetPlayerClass(client);
	TF2_RemoveAllWeapons(client);
	if(IsPlayerAlive(client))
	{
		TF2_RespawnPlayer(client);
	}
	TF2Attrib_RemoveAll(client);
}