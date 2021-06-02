// Includes
#pragma tabsize 0
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <tf2>
#include <tf2_stocks>
#include <tf2attributes>
#include <tf2_isPlayerInSpawn>
#include <dhooks>
#include <clientprefs>

// Plugin Info
public Plugin:myinfo =
{
	name = "0.98 Armor System",
	author = "Razor",
	description = "Plugin for handling 0.98 sytle armor.",
	version = "1.0",
	url = "go fuck yourself",
}
/* Variables */

//Floats
new Float:fl_MaxArmor[MAXPLAYERS+1] = 300.0;
new Float:fl_CurrentArmor[MAXPLAYERS+1] = 300.0;
new Float:g_flLastAttackTime[MAXPLAYERS + 1];
//Bools
new bool:b_Hooked[MAXPLAYERS+1] = false;
//Integers
int g_iOffset;
//Stocks
stock int GetHealingTarget(const int client)
{
    int medigun = GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);
    if (!IsValidEdict(medigun) || !IsValidEntity(medigun))
        return -1;

    char s[32]; GetEdictClassname(medigun, s, sizeof(s));
    if ( !strcmp(s, "tf_weapon_medigun", false) ) {
        if ( GetEntProp(medigun, Prop_Send, "m_bHealing") )
            return GetEntPropEnt( medigun, Prop_Send, "m_hHealingTarget" );
    }
    return -1;
}
stock bool IsNearSpencer(const int client)
{
    int medics = 0;
    for ( int i=MaxClients ; i ; --i ) {
        if (!IsClientInGame(i))
            continue;
        if ( GetHealingTarget(i) == client )
            medics++;
    }
    return (GetEntProp(client, Prop_Send, "m_nNumHealers") > medics);
}  
stock TF2_GetMaxHealth(iClient)
{
    new maxhealth = GetEntProp(GetPlayerResourceEntity(), Prop_Send, "m_iMaxHealth", _, iClient);
    return ((maxhealth == -1 || maxhealth == 80896) ? GetEntProp(iClient, Prop_Data, "m_iMaxHealth") : maxhealth);
}
stock TF2_IsPlayerCritBuffed(client)
{
   if ( TF2_IsPlayerInCondition( client, TFCond_Kritzkrieged ) || TF2_IsPlayerInCondition( client, TFCond_HalloweenCritCandy )
        || TF2_IsPlayerInCondition( client, TFCond_CritCanteen ) || TF2_IsPlayerInCondition( client, TFCond_CritDemoCharge )
        || TF2_IsPlayerInCondition( client, TFCond_CritOnFirstBlood ) || TF2_IsPlayerInCondition( client, TFCond_CritOnWin )
        || TF2_IsPlayerInCondition( client, TFCond_CritOnFlagCapture ) || TF2_IsPlayerInCondition( client, TFCond_CritOnKill )
        || TF2_IsPlayerInCondition( client, TFCond_CritMmmph ) || TF2_IsPlayerInCondition( client, TFCond_CritOnDamage )
        || TF2_IsPlayerInCondition( client, TFCond_CritRuneTemp ) )
    {
        return true; 
    }
    return false; 
}
stock TF2_IsPlayerMinicritBuffed(client)
{
   if ( TF2_IsPlayerInCondition( client, TFCond_Buffed ) || TF2_IsPlayerInCondition( client, TFCond_CritCola )
		|| TF2_IsPlayerInCondition( client, TFCond_NoHealingDamageBuff ) || TF2_IsPlayerInCondition( client, TFCond_MiniCritOnKill ))
    {
        return true; 
    }
    return false; 
}
stock TF2_IsPlayerMinicritDebuffed(client)
{
   if ( TF2_IsPlayerInCondition( client, TFCond_MarkedForDeath ) || TF2_IsPlayerInCondition( client, TFCond_MarkedForDeathSilent )
		|| TF2_IsPlayerInCondition( client, TFCond_PasstimePenaltyDebuff ) || TF2_IsPlayerInCondition( client, TFCond_Jarated ))
    {
        return true; 
    }
    return false; 
}
stock TF2_IsPlayerCritImmune(client)
{
   if ( TF2_IsPlayerInCondition( client, TFCond_UberBulletResist ) || TF2_IsPlayerInCondition( client, TFCond_UberBlastResist )
		|| TF2_IsPlayerInCondition( client, TFCond_UberFireResist ) || TF2_IsPlayerInCondition( client, TFCond_DefenseBuffed ))
    {
        return true; 
    }
    return false; 
}
stock int TF2_GetPlayerMaxHealth(int client) {
	return GetEntProp(GetPlayerResourceEntity(), Prop_Send, "m_iMaxHealth", _, client);
}

//======== [  CLIENT STOCKS ] =========
stock bool:IsValidClient( client, bool:replaycheck = true )
{
    if ( client <= 0 || client > MaxClients ) return false; 
    if ( !IsClientInGame( client ) ) return false; 
    if ( !IsClientConnected( client ) ) return false; 
    if ( GetEntProp( client, Prop_Send, "m_bIsCoaching" ) ) return false; 
    if ( replaycheck )
    {
        if ( IsClientSourceTV( client ) || IsClientReplay( client ) ) return false; 
    }
    return true; 
}
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////Actual Hooks & Functions////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

public void TF2_OnConditionAdded(client, TFCond:cond)
{
	if (IsValidClient(client))
	{
		switch(cond)
		{
			case TFCond_OnFire:
			{
				new Address:attribute1 = TF2Attrib_GetByName(client, "absorb damage while cloaked");//Chance to remove fire on hit.
				if(TF2_GetPlayerClass(client) == TFClass_Pyro)
				{
					TF2_RemoveCondition(client, TFCond_OnFire);
					TF2_RemoveCondition(client, TFCond_HealingDebuff);
				}
				else if(attribute1 != Address_Null && GetRandomFloat(0.0,1.0) <= TF2Attrib_GetValue(attribute1))
				{
					TF2_RemoveCondition(client, TFCond_OnFire)
					TF2_RemoveCondition(client, TFCond_HealingDebuff)
				}
			}
			case TFCond_Bleeding:
			{
				new Address:attribute2 = TF2Attrib_GetByName(client, "always_transmit_so");//Chance to remove bleed on hit.
				if(attribute2 != Address_Null && GetRandomFloat(0.0,1.0) <= TF2Attrib_GetValue(attribute2))
				{
					TF2_RemoveCondition(client, TFCond_Bleeding)
				}
			}
			case TFCond_Slowed:
			{
				new Address:attribute3 = TF2Attrib_GetByName(client, "jarate description");
				if(attribute3 != Address_Null && GetRandomFloat(0.0,1.0) <= TF2Attrib_GetValue(attribute3))
				{
					TF2_RemoveCondition(client, TFCond_Slowed);
				}
			}
			case TFCond_Dazed:
			{
				new Address:attribute3 = TF2Attrib_GetByName(client, "jarate description");
				if(attribute3 != Address_Null && GetRandomFloat(0.0,1.0) <= TF2Attrib_GetValue(attribute3))
				{
					TF2_RemoveCondition(client, TFCond_Dazed);
				}
			}
			case TFCond_Bonked:
			{
				TF2_AddCondition(client, TFCond_HalloweenQuickHeal, 1.0);
			}
			case TFCond_Taunting:
			{
				new Address:TauntSpeedActive = TF2Attrib_GetByName(client, "gesture speed increase");
				if(TauntSpeedActive != Address_Null)
				{
					SetTauntAttackSpeed(client, TF2Attrib_GetValue(TauntSpeedActive));
				}
				/*new CWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
				if(IsValidEntity(CWeapon))
				{
					new String:classname[64];
					GetEdictClassname(CWeapon, classname, sizeof(classname)); 
					if(StrContains(classname, "tf_weapon_lunchbox",false) == 0)
					{
						
					}
				}*///Potentially add something for lunchboxes?
			}
		}
	}
}
// On Plugin Start
public OnPluginStart()
{
	for(new i=0; i<=MaxClients; i++)
	{
		if(!IsValidClient(i)){continue;}
		fl_MaxArmor[i] = 300.0;
		fl_CurrentArmor[i] = 300.0;
		if(b_Hooked[i] == false)
		{
			b_Hooked[i] = true;
			SDKHook(i, SDKHook_OnTakeDamageAlive, OnTakeDamage);
			SDKHook(i, SDKHook_TraceAttack, TraceAttack);
		}
	}
	HookEvent("player_hurt", Event_Playerhurt)
	HookEvent("player_changeclass", Event_PlayerreSpawn);
	HookEvent("player_spawn", Event_PlayerreSpawn)
	HookEvent("player_death", Event_PlayerreSpawn)
	HookEvent("post_inventory_application", Event_PlayerreSpawn)
	CreateTimer(0.1, Timer_GiveHealth, _, TIMER_REPEAT);
	CreateTimer(1.0, Timer_Second, _, TIMER_REPEAT);
	
	//Offsets
	Handle hConf = LoadGameConfigFile("tf2.uberupgrades");
	if (LookupOffset(g_iOffset, "CTFPlayer", "m_iSpawnCounter"))
	g_iOffset -= GameConfGetOffset(hConf, "m_flTauntAttackTime");
}
public Action:Timer_Second(Handle:timer)
{
	for(new client = 1; client < MaxClients; client++)
	{
		if (IsValidClient(client))
		{
			new Address:armorActive = TF2Attrib_GetByName(client, "obsolete ammo penalty")
			if(armorActive != Address_Null)
			{
				new Float:armorAmount = TF2Attrib_GetValue(armorActive);
				fl_MaxArmor[client] = armorAmount+300.0;
			}
			else
			{
				fl_MaxArmor[client] = 300.0;
			}
			/*new Address:capActive = TF2Attrib_GetByName(client, "tool escrow until date")
			new Address:Defense = TF2Attrib_GetByName(client, "is throwable chargeable");
			fl_ArmorCap[client] = 1.0;
			if(capActive != Address_Null)
			{
				if(!TF2_IsPlayerInCondition(client, TFCond_NoTaunting_DEPRECATED))
				{
					fl_ArmorCap[client] += Pow(TF2Attrib_GetValue(capActive), 1.65) + 1.0;
				}
				else
				{
					fl_ArmorCap[client] += Pow(TF2Attrib_GetValue(capActive)-1.0, 1.65) + 1.0;
				}
			}
			if(Defense != Address_Null)
			{
				fl_ArmorCap[client] *= Pow(TF2Attrib_GetValue(Defense), 0.85)
			}*/
		}
	}
}
bool LookupOffset(int &iOffset, const char[] strClass, const char[] strProp)
{
	iOffset = FindSendPropInfo(strClass, strProp);
	if (iOffset <= 0)
	{
		SetFailState("Could not locate offset for %s::%s", strClass, strProp);
	}
	return true;
}
public OnPluginEnd()
{
	for(new i=0; i<=MaxClients; i++)
	{
		if(!IsValidClient(i)){continue;}
		fl_MaxArmor[i] = 300.0;
		fl_CurrentArmor[i] = 300.0;
		if(b_Hooked[i] == true)
		{
			b_Hooked[i] = false;
			SDKUnhook(i, SDKHook_OnTakeDamageAlive, OnTakeDamage);
			SDKUnhook(i, SDKHook_TraceAttack, TraceAttack);
		}
	}
	UnhookEvent("player_hurt", Event_Playerhurt)
	UnhookEvent("player_changeclass", Event_PlayerreSpawn);
	UnhookEvent("player_spawn", Event_PlayerreSpawn)
	UnhookEvent("player_death", Event_PlayerreSpawn)
	UnhookEvent("post_inventory_application", Event_PlayerreSpawn)
}
// On Map Start
public OnMapStart()
{
	for(new i=0; i<=MaxClients; i++)
	{
		if(!IsValidClient(i)){continue;}
		fl_MaxArmor[i] = 300.0;
		fl_CurrentArmor[i] = 300.0;
		if(b_Hooked[i] == false)
		{
			b_Hooked[i] = true;
			SDKHook(i, SDKHook_OnTakeDamageAlive, OnTakeDamage);
			SDKHook(i, SDKHook_TraceAttack, TraceAttack);
		}
	}
}
public Action:Timer_GiveHealth(Handle:timer)//give health every 0.1 seconds
{
	for(new client = 0; client < MaxClients; client++)
	{
		if (IsValidClient(client))
		{
			new Address:RegenActive = TF2Attrib_GetByName(client, "disguise on backstab");
			if(RegenActive != Address_Null)
			{
				
				new Float:RegenPerSecond = TF2Attrib_GetValue(RegenActive);
				new Float:RegenPerTick = RegenPerSecond/10;
				new Address:HealingReductionActive = TF2Attrib_GetByName(client, "health from healers reduced");
				if(HealingReductionActive != Address_Null)
				{
					RegenPerTick *= TF2Attrib_GetValue(HealingReductionActive);
				}
				new clientHealth = GetEntProp(client, Prop_Data, "m_iHealth");
				new clientMaxHealth = TF2_GetPlayerMaxHealth(client);
				if(!IsValidClient(client))
				{
					RegenPerTick = RegenPerTick/10;
				}
				if(clientHealth < clientMaxHealth)
				{
					if(float(clientHealth) + RegenPerTick < clientMaxHealth)
					{
						SetEntProp(client, Prop_Data, "m_iHealth", clientHealth+RoundToNearest(RegenPerTick));
					}
					else
					{
						SetEntProp(client, Prop_Data, "m_iHealth", clientMaxHealth);
					}
				}
			}
			decl String:ArmorLeft[32]
			Format(ArmorLeft, sizeof(ArmorLeft), "%.0f / %.0f", fl_CurrentArmor[client], fl_MaxArmor[client]); 
			new Float:pctArmor =  fl_CurrentArmor[client]/fl_MaxArmor[client];
			if(pctArmor > 0.5)
			{
				SetHudTextParams(-0.65, -0.2, 0.5, 0, 255, 0, 255, 0, 0.0, 0.0, 0.0);
				ShowHudText(client, 0, ArmorLeft);
			}
			else if(pctArmor <= 0.5 && pctArmor > 0.25)
			{
				SetHudTextParams(-0.65, -0.2, 0.5, 255, 255, 0, 255, 0, 0.0, 0.0, 0.0);
				ShowHudText(client, 0, ArmorLeft);				
			}
			else
			{
				SetHudTextParams(-0.65, -0.2, 0.5, 255, 0, 0, 255, 0, 0.0, 0.0, 0.0);
				ShowHudText(client, 0, ArmorLeft);				
			}
			
			//Resistances
			new Address:FireResistanceActive = TF2Attrib_GetByName(client, "referenced item id low");
			new Address:CritResistanceActive = TF2Attrib_GetByName(client, "referenced item id high");
			new Address:BlastResistanceActive = TF2Attrib_GetByName(client, "referenced item def UPDATED");
			new Address:BulletResistanceActive = TF2Attrib_GetByName(client, "always tradable");
			new Address:MeleeResistanceActive = TF2Attrib_GetByName(client, "noise maker");
			new Address:SentryResistanceActive = TF2Attrib_GetByName(client, "collection bits DEPRECATED");
			
			if(FireResistanceActive != Address_Null)
			{
				new Float:Resistance = TF2Attrib_GetValue(FireResistanceActive);
				TF2Attrib_SetByName(client, "dmg taken from fire reduced", ((1-Resistance)-((1-Resistance)*pctArmor) + Resistance));
			}
			if(CritResistanceActive != Address_Null)
			{
				new Float:Resistance = TF2Attrib_GetValue(CritResistanceActive);
				TF2Attrib_SetByName(client, "dmg taken from crit reduced", ((1-Resistance)-((1-Resistance)*pctArmor) + Resistance));
			}
			if(BlastResistanceActive != Address_Null)
			{
				new Float:Resistance = TF2Attrib_GetValue(BlastResistanceActive);
				TF2Attrib_SetByName(client, "dmg taken from blast reduced", ((1-Resistance)-((1-Resistance)*pctArmor) + Resistance));
			}
			if(BulletResistanceActive != Address_Null)
			{
				new Float:Resistance = TF2Attrib_GetValue(BulletResistanceActive);
				TF2Attrib_SetByName(client, "dmg taken from bullets reduced", ((1-Resistance)-((1-Resistance)*pctArmor) + Resistance));
			}
			if(MeleeResistanceActive != Address_Null)
			{
				new Float:Resistance = TF2Attrib_GetValue(MeleeResistanceActive);
				TF2Attrib_SetByName(client, "dmg from melee increased", ((1-Resistance)-((1-Resistance)*pctArmor) + Resistance));
			}
			if(SentryResistanceActive != Address_Null)
			{
				new Float:Resistance = TF2Attrib_GetValue(SentryResistanceActive);
				TF2Attrib_SetByName(client, "SET BONUS: dmg from sentry reduced", ((1-Resistance)-((1-Resistance)*pctArmor) + Resistance));
			}
		}
	}
}
public Event_PlayerreSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(IsValidClient(client) && !IsFakeClient(client))
	{
		fl_CurrentArmor[client] = fl_MaxArmor[client];
	}
}
// On Client Put In Server
public OnClientPutInServer(client)
{
	fl_MaxArmor[client] = 300.0;
	fl_CurrentArmor[client] = 300.0;
	if(b_Hooked[client] == false)
	{
		b_Hooked[client] = true;
		SDKHook(client, SDKHook_OnTakeDamageAlive, OnTakeDamage);
		SDKHook(client, SDKHook_TraceAttack, TraceAttack);
	}
}

// On Client Disconnect
public OnClientDisconnect(client)
{
	if(IsClientInGame(client))
	{
		fl_MaxArmor[client] = 300.0;
		fl_CurrentArmor[client] = 300.0;
		if(b_Hooked[client] == true)
		{
			b_Hooked[client] = false;
			SDKUnhook(client, SDKHook_OnTakeDamageAlive, OnTakeDamage);
			SDKUnhook(client, SDKHook_TraceAttack, TraceAttack);
		}
	}
}
public Action OnPlayerRunCmd(int client, int& buttons, int& impulse, float vel[3], float angles[3], int& weapon, int& subtype, int& cmdnum, int& tickcount, int& seed, int mouse[2])
{
	if(IsValidClient(client) && !IsFakeClient(client))
	{
		new HealingTarget = GetHealingTarget(client);
		new Address:armorRecharge = TF2Attrib_GetByName(client, "tmp dmgbuff on hit");
		new Float:ArmorRechargeMult = 1.0;
		if(IsValidClient(HealingTarget))
		{
			new Address:Healrate1 = TF2Attrib_GetByName(client, "heal rate bonus");
			if(Healrate1 != Address_Null)
			{
				new Float:Healratepct = TF2Attrib_GetValue(Healrate1);
				ArmorRechargeMult *= Healratepct
			}
			new Address:Healrate2 = TF2Attrib_GetByName(client, "heal rate penalty");
			if(Healrate2 != Address_Null)
			{
				new Float:Healratepct2 = TF2Attrib_GetValue(Healrate2);
				ArmorRechargeMult *= Healratepct2
			}
			new Address:Healrate3 = TF2Attrib_GetByName(client, "overheal fill rate reduced");
			if(Healrate3 != Address_Null)
			{
				new Float:Healratepct3 = TF2Attrib_GetValue(Healrate3);
				ArmorRechargeMult *= Healratepct3
			}
		}
		if(IsNearSpencer(client) == true)
		{
			ArmorRechargeMult *= 2.0
		}
		new Address:HealingReductionActive = TF2Attrib_GetByName(client, "health from healers reduced");
		if(HealingReductionActive != Address_Null)
		{
			ArmorRechargeMult *= TF2Attrib_GetValue(HealingReductionActive);
		}
		if(!TF2_IsPlayerInCondition(client,TFCond_Reprogrammed) && (fl_CurrentArmor[client] += fl_MaxArmor[client]*0.0004) < fl_MaxArmor[client])
		{
			fl_CurrentArmor[client] += fl_MaxArmor[client]*0.00004;
			if(IsValidClient(HealingTarget))
			{
				fl_CurrentArmor[client] += fl_MaxArmor[client]*0.00004*ArmorRechargeMult;
			}
			if(armorRecharge != Address_Null)
			{
				new Float:rechargepct = TF2Attrib_GetValue(armorRecharge);
				fl_CurrentArmor[client] += fl_MaxArmor[client]*0.00004*rechargepct;
				if(IsValidClient(HealingTarget))
				{
					fl_CurrentArmor[client] += fl_MaxArmor[client]*0.00004*ArmorRechargeMult*rechargepct;
				}
			}
		}
		else if(fl_CurrentArmor[client] != fl_MaxArmor[client] && !TF2_IsPlayerInCondition(client,TFCond_Reprogrammed))
		{
			fl_CurrentArmor[client] = fl_MaxArmor[client];
		}
		if(fl_CurrentArmor[client] > fl_MaxArmor[client])
		{
			fl_CurrentArmor[client] = fl_MaxArmor[client];
		}
		if(fl_CurrentArmor[client] < 0.0)
		{
			fl_CurrentArmor[client] = 0.0;
		}
	}
}
public Event_Playerhurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	new Float:damage = GetEventFloat(event, "damageamount");
	
	fl_CurrentArmor[client] -= (3.0+damage);
	if(fl_CurrentArmor[client] < 0.0)
	{
		fl_CurrentArmor[client] = 0.0;
	}
	new Address:armorDelay = TF2Attrib_GetByName(client, "tmp dmgbuff on hit");
	if(armorDelay != Address_Null)
	{
		new Float:DelayAmount = TF2Attrib_GetValue(armorDelay) + 1.0;
		if(DelayAmount < 25.0)
		{
			TF2_AddCondition(client, TFCond_Reprogrammed, 1.0-(DelayAmount/25.0));
		}
	}
	else
	{
		TF2_AddCondition(client, TFCond_Reprogrammed, 1.0);
	}
	if(IsValidClient(attacker) && !IsFakeClient(attacker))
	{
		if(client != attacker && attacker != 0 && damage >= 1.0)
		{
			PrintToConsole(attacker, "%.1f post damage dealt.", damage);
		}
	}
}
public Action TraceAttack(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &ammotype, int hitbox, int hitgroup)
{
    return Plugin_Continue;
}
// On Take Damage
public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePosition[3], damagecustom)
{
	if(IsValidClient(victim) && !IsFakeClient(victim))
	{
		//damage /= ((1-fl_ArmorCap[victim])-((1-fl_ArmorCap[victim])*pctArmor) + fl_ArmorCap[victim]); 
		if(TF2Spawn_IsClientInSpawn(victim) && victim != attacker)
		{
			if(IsValidClient(attacker) && TF2_IsPlayerInCondition(attacker, TFCond_CritOnWin))
			{
				return Plugin_Changed;
			}
			damage *= 0.0;
		}
	}
	if(damage < 0.0)
	{
		damage = 0.0;
	}
	return Plugin_Changed;
}
public OnEntityCreated(entity, const char[] classname)
{
	if(StrEqual(classname, "obj_sentrygun"))
    {
		SDKHook(entity, SDKHook_OnTakeDamage, OnTakeDamagePre_Sentry); 
		CreateTimer(0.35, BuildingRegeneration, EntIndexToEntRef(entity), TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	}
	else if(StrEqual(classname, "obj_dispenser"))
    {
		SDKHook(entity, SDKHook_OnTakeDamage, OnTakeDamagePre_Sentry); 
		CreateTimer(0.35, BuildingRegeneration, EntIndexToEntRef(entity), TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	}
	else if(StrEqual(classname, "obj_teleporter"))
    {
		SDKHook(entity, SDKHook_OnTakeDamage, OnTakeDamagePre_Sentry); 
		CreateTimer(0.35, BuildingRegeneration, EntIndexToEntRef(entity), TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	}
}
GetEntLevel(entity)
{
    return GetEntProp(entity, Prop_Send, "m_iUpgradeLevel", 1);
}
AddEntHealth(entity, amount)
{
    SetVariantInt(amount);
    AcceptEntityInput(entity, "AddHealth");
}
public Action:BuildingRegeneration(Handle:timer, any:entity) 
{
	if(!IsValidEntity(entity) || !IsValidEdict(entity))
	{
		return;
	}
	new owner = GetEntPropEnt(entity, Prop_Send, "m_hBuilder"); 
	if(!IsValidEntity(owner) || !IsValidEdict(owner))
	{
		return;
	}
	if(!IsClientInGame(owner))
	{
		return;
	}
	if(GetEntProp(entity, Prop_Send, "m_bDisabled") == 1)
	{
		return;
	}
	new BuildingMaxHealth = GetEntProp(entity, Prop_Send, "m_iMaxHealth");
	new BuildingHealth = GetEntProp(entity, Prop_Send, "m_iHealth");
	if(BuildingMaxHealth != BuildingHealth)
	{
		new mode = 1;
		if(mode == 1)
		{
			new melee = (GetPlayerWeaponSlot(owner,2));
			new Address:BuildingRegen = TF2Attrib_GetByName(melee, "Projectile speed decreased");
			if(BuildingRegen != Address_Null)
			{
				new Float:buildingHPRegen = TF2Attrib_GetValue(BuildingRegen);
				new Regeneration = RoundToNearest(((buildingHPRegen*BuildingMaxHealth)/100.0)/7.5);
				if(BuildingHealth < BuildingMaxHealth)
				{
					if((Regeneration + BuildingHealth) > BuildingMaxHealth)
					{
						AddEntHealth(entity, BuildingMaxHealth - BuildingHealth)
					}
					else
					{
						AddEntHealth(entity, Regeneration)
					}
				}
			}
		}
		if(mode == 2)
		{
			new Address:BuildingRegen = TF2Attrib_GetByName(owner, "disguise on backstab");
			if(BuildingRegen != Address_Null)
			{
				new Regeneration = RoundToNearest(TF2Attrib_GetValue(BuildingRegen)/3);
				if(BuildingHealth < BuildingMaxHealth)
				{
					if((Regeneration + BuildingHealth) > BuildingMaxHealth)
					{
						AddEntHealth(entity, BuildingMaxHealth - BuildingHealth)
					}
					else
					{
						AddEntHealth(entity, Regeneration)
					}
				}
			}
		}
	}
	new sentrynumber = EntRefToEntIndex(entity)
	new String:SentryObject[128];
	GetEdictClassname(sentrynumber, SentryObject, sizeof(SentryObject));
	if (StrEqual(SentryObject, "obj_sentrygun"))
	{
		new melee = (GetPlayerWeaponSlot(owner,2));
		new sentryLevel = GetEntLevel(entity);
		new shells = GetEntProp(entity, Prop_Send, "m_iAmmoShells");
		new rockets = GetEntProp(entity, Prop_Send, "m_iAmmoRockets");
		new Address:AmmoRegen = TF2Attrib_GetByName(melee, "disguise on backstab");
		if(AmmoRegen != Address_Null)
		{
			new AmmoRegeneration = RoundToNearest(TF2Attrib_GetValue(AmmoRegen)/5.0);
			
			if(sentryLevel != 1)
			{
				if((shells + AmmoRegeneration) < 200)
				{
					SetEntProp(entity, Prop_Send, "m_iAmmoShells", shells + AmmoRegeneration);
				}
				else
				{
					SetEntProp(entity, Prop_Send, "m_iAmmoShells", 200);
				}
			}
			else
			{
				if((shells + AmmoRegeneration) < 150)
				{
					SetEntProp(entity, Prop_Send, "m_iAmmoShells", shells + AmmoRegeneration);
				}
				else
				{
					SetEntProp(entity, Prop_Send, "m_iAmmoShells", 150);
				}
			}
			if(sentryLevel == 3)
			{
				if((rockets + (AmmoRegeneration/10)) < 20)
				{
					SetEntProp(entity, Prop_Send, "m_iAmmoRockets", rockets + (AmmoRegeneration/10));
				}
				else
				{
					SetEntProp(entity, Prop_Send, "m_iAmmoRockets", 20);
				}				
			}
		}
	}
} 
public Action:OnTakeDamagePre_Sentry(victim, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePosition[3], damagecustom) 
{
	new hClientWeapon = GetEntPropEnt(attacker, Prop_Send, "m_hActiveWeapon");
	//Bullet to Projectile Fix
	if(IsValidEntity(hClientWeapon))
	{
		new Address:overrideproj = TF2Attrib_GetByName(hClientWeapon, "override projectile type");
		new Address:bulletspershot = TF2Attrib_GetByName(hClientWeapon, "bullets per shot bonus");
		new Address:accscales = TF2Attrib_GetByName(hClientWeapon, "accuracy scales damage");
		if(overrideproj != Address_Null && bulletspershot != Address_Null)
		{
			new Float:override = TF2Attrib_GetValue(overrideproj);
			new Float:bps = TF2Attrib_GetValue(bulletspershot);
			if(accscales != Address_Null)
			{
				new Float:accuracyScales = TF2Attrib_GetValue(accscales);
				if(override == 2.0 || override == 6.0)
				{
					damage *= Pow(accuracyScales,0.95);
				}
			}
			if(override == 2.0 || override == 6.0)
			{
				damage *= bps;
			}
		}
	}
	return Plugin_Changed;
}
//pasted from https://github.com/xcalvinsz/tauntspeed/blob/master/addons/sourcemod/scripting/tauntspeed.sp
public void SetTauntAttackSpeed(int client, float speed)
{
	float flTauntAttackTime = GetEntDataFloat(client, g_iOffset);
	float flCurrentTime = GetGameTime();
	float flNextTauntAttackTime = flCurrentTime + ((flTauntAttackTime - flCurrentTime) / speed);
	if (flTauntAttackTime > 0.0)
	{
		SetEntDataFloat(client, g_iOffset, flNextTauntAttackTime, true);
		g_flLastAttackTime[client] = flNextTauntAttackTime;
		//This is to set the next attack time for taunts like spies knife where it attack 3 times
		//or sniper huntsman taunt where it daze the opponent then attacks
		DataPack hPack;
		CreateDataTimer(0.1, Timer_SetNextAttackTime, hPack, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
		hPack.WriteCell(GetClientUserId(client));
		hPack.WriteFloat(speed);
	}
}

public Action Timer_SetNextAttackTime(Handle timer, DataPack hPack)
{
	hPack.Reset();
	int client = GetClientOfUserId(hPack.ReadCell());
	float flTauntAttackTime = GetEntDataFloat(client, g_iOffset);
	
	if (g_flLastAttackTime[client] == flTauntAttackTime)
	{
		return Plugin_Continue;
	}
	else if (g_flLastAttackTime[client] > 0.0 && flTauntAttackTime == 0.0)
	{
		g_flLastAttackTime[client] = 0.0;
		return Plugin_Stop;
	}
	else
	{
		float speed = hPack.ReadFloat();
		float flCurrentTime = GetGameTime();
		float flNextTauntAttackTime = flCurrentTime + ((flTauntAttackTime - flCurrentTime) / speed);
		SetEntDataFloat(client, g_iOffset, flNextTauntAttackTime, true);
		g_flLastAttackTime[client] = flNextTauntAttackTime;
	}
	return Plugin_Continue;
}