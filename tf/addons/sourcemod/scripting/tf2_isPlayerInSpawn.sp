#pragma semicolon 1
#define CONVAR_PREFIX "sm_isPlayerInSpawn"
#define DEFAULT_UPDATE_SETTING "2"
#define UPD_LIBFUNC
#include <ddhoward_updater>
#pragma newdecls required;
#include <sdktools>
#include <sdkhooks>

bool isInSpawn[MAXPLAYERS + 1];

ConVar cvar_checkNewEnts;

public Plugin myinfo = {
	name = "[TF2] Is Player In Spawn",
	author = "Derek D. Howard (ddhoward)",
	description = "Provides simple natives and forwards about whether players are in their spawn.",
	version = "18.0121.0",
	url = "https://forums.alliedmods.net/showthread.php?t=247950"
};

Handle hfwd_EnterSpawn;
Handle hfwd_LeaveSpawn;

public APLRes AskPluginLoad2(Handle hMyself, bool bLate, char[] strError, int iErr_Max) {
	CreateNative("TF2Spawn_IsClientInSpawn2", Native_CheckIfInSpawn);
	RegPluginLibrary("tf2_isPlayerInSpawn");
	return APLRes_Success;
}

public void OnPluginStart() {
	hfwd_EnterSpawn = CreateGlobalForward("TF2Spawn_EnterSpawn", ET_Ignore, Param_Cell, Param_Cell);
	hfwd_LeaveSpawn = CreateGlobalForward("TF2Spawn_LeaveSpawn", ET_Ignore, Param_Cell, Param_Cell);
	cvar_checkNewEnts = CreateConVar("sm_tf2_isPlayerInSpawn_checknewents", "0", "(0/1) Check all new entities to see if they are spawnrooms?", _, true, 0.0, true, 1.0);
	HookEvent("teamplay_round_start", Round_Start);

	int ent = -1;
	while ((ent = FindEntityByClassname(ent, "func_respawnroom")) != -1) {
		HookThisRoom(ent);
	}
}

void HookThisRoom(int room) {
	SDKUnhook(room, SDKHook_StartTouch, SpawnStartTouch);
	SDKUnhook(room, SDKHook_Touch, SpawnTouch);
	SDKUnhook(room, SDKHook_EndTouch, SpawnEndTouch);
	SDKHook(room, SDKHook_StartTouch, SpawnStartTouch);
	SDKHook(room, SDKHook_Touch, SpawnTouch);
	SDKHook(room, SDKHook_EndTouch, SpawnEndTouch);
}

public void OnClientDisconnect(int client) {
	isInSpawn[client] = false;
}

public int Native_CheckIfInSpawn(Handle plugin, int numParams) {
	int param1 = GetNativeCell(1);
	int client = param1;
	if (client < 0 || client > MaxClients) {
		client = GetClientOfUserId(client);
		if (client < 0 || client > MaxClients) {
			client = EntRefToEntIndex(param1);
			if (client < 0 || client > MaxClients) {
				ThrowNativeError(SP_ERROR_PARAM, "%i is not a valid player index!", param1);
				return false;
			}
		}
	}
	return isInSpawn[client];
}

public Action Round_Start(Handle event, const char[] name, bool dontBroadcast) {
	if (!cvar_checkNewEnts.BoolValue) {
		int ent = -1;
		while ((ent = FindEntityByClassname(ent, "func_respawnroom")) != -1) {
			HookThisRoom(ent);
		}
	}
}

public void OnEntityCreated(int entity, const char[] classname) {
	if (cvar_checkNewEnts.BoolValue && StrEqual(classname, "func_respawnroom", false)) {
		HookThisRoom(entity);
	}
}

public Action SpawnStartTouch(int spawn, int client) {
	if (client > 0 && client <= MaxClients && IsClientInGame(client)
	&& GetEntProp(spawn, Prop_Send, "m_iTeamNum") == GetClientTeam(client)) {
		isInSpawn[client] = true;
		if (GetForwardFunctionCount(hfwd_EnterSpawn) > 0) {
			Call_StartForward(hfwd_EnterSpawn);
			Call_PushCell(client);
			Call_PushCell(spawn);
			Call_Finish();
		}
	}
	return Plugin_Continue;
}

public Action SpawnTouch(int spawn, int client) {
	if (client > 0 && client <= MaxClients && IsClientInGame(client)
	&& GetEntProp(spawn, Prop_Send, "m_iTeamNum") == GetClientTeam(client)) {
		isInSpawn[client] = true;
	}
	return Plugin_Continue;
}

public Action SpawnEndTouch(int spawn, int client) {
	if (client > 0 && client <= MaxClients
	&& GetEntProp(spawn, Prop_Send, "m_iTeamNum") == GetClientTeam(client)) {	
		isInSpawn[client] = false;
		if (GetForwardFunctionCount(hfwd_LeaveSpawn) > 0) {
			Call_StartForward(hfwd_LeaveSpawn);
			Call_PushCell(client);
			Call_PushCell(spawn);
			Call_Finish();
		}
	}
	return Plugin_Continue;
}