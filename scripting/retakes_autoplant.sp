#include <sourcemod>
#include <sdktools>
#include <cstrike>

#pragma newdecls required
#pragma semicolon 1

int bomber;
int bombsite;
bool hasBombBeenDeleted;

ConVar isPluginEnabled;
ConVar freezeTime;

float bombPosition[3];

Handle bombTimer;

int bombTicking;

enum //Bombsites
{
    BOMBSITE_INVALID = -1,
    BOMBSITE_A = 0,
    BOMBSITE_B = 1
}

public Plugin myinfo =
{
    name = "[Retakes] Autoplant",
    author = "b3none",
    description = "Autoplant the bomb for CS:GO Retakes.",
    version = "2.0.0",
    url = "https://github.com/b3none"
};

public void OnPluginStart()
{
    isPluginEnabled = CreateConVar("sm_autoplant_enabled", "1", "Should the autoplant plugin be enabled", _, true, 0.0, true, 1.0);

    freezeTime = FindConVar("mp_freezetime");

    bombTicking = FindSendPropInfo("CPlantedC4", "m_bBombTicking");

    HookEvent("round_start", OnRoundStart, EventHookMode_PostNoCopy);
    HookEvent("round_end", OnRoundEnd, EventHookMode_PostNoCopy);
}

public Action OnRoundStart(Event eEvent, const char[] sName, bool bDontBroadcast)
{
    hasBombBeenDeleted = false;
    
    bomber = GetClientWithBomb();
    bombsite = GetNearestBombsite(bomber);

    if (isPluginEnabled.BoolValue) {
	    for (int client = 1; client <= MaxClients; client++) {
	        if (IsClientInGame(client) && IsPlayerAlive(client) && GetPlayerWeaponSlot(client, 4) > 0) {
	            int bomb = GetPlayerWeaponSlot(client, 4);
	
	            hasBombBeenDeleted = SafeRemoveWeapon(client, bomb);
	
	            GetClientAbsOrigin(client, bombPosition);
	
	            delete bombTimer;
	
	            bombTimer = CreateTimer(freezeTime.FloatValue, PlantBomb, client);
	        }
	    }
    }

    return Plugin_Continue;
}

public void OnRoundEnd(Event event, const char[] sName, bool bDontBroadcast)
{
    delete bombTimer;

    GameRules_SetProp("m_bBombPlanted", 0);
}

public Action PlantBomb(Handle timer, int client)
{
    bombTimer = INVALID_HANDLE;

    if (IsValidClient(client) || !hasBombBeenDeleted) {
        if (hasBombBeenDeleted) {
            int bombEntity = CreateEntityByName("planted_c4");

            GameRules_SetProp("m_bBombPlanted", 1);
            SetEntData(bombEntity, bombTicking, 1, 1, true);
            SendBombPlanted(client);

            if (DispatchSpawn(bombEntity)) {
                ActivateEntity(bombEntity);
                TeleportEntity(bombEntity, bombPosition, NULL_VECTOR, NULL_VECTOR);

                if (!(GetEntityFlags(bombEntity) & FL_ONGROUND)) {
                    float direction[3];
                    float floor[3];

                    Handle trace;

                    direction[0] = 89.0;

                    TR_TraceRay(bombPosition, direction, MASK_PLAYERSOLID_BRUSHONLY, RayType_Infinite);

                    if (TR_DidHit(trace)) {
                        TR_GetEndPosition(floor, trace);
                        TeleportEntity(bombEntity, floor, NULL_VECTOR, NULL_VECTOR);
                    }
                }
            }
        }
    } else {
        CS_TerminateRound(1.0, CSRoundEnd_Draw);
    }
}

public void SendBombPlanted(int client)
{
    Event event = CreateEvent("bomb_planted");

    if (event != null) {
	    event.SetInt("userid", GetClientUserId(client));
	    event.SetInt("site", bombsite);
	    event.Fire();
    }
}

stock bool SafeRemoveWeapon(int client, int weapon)
{
    if (!IsValidEntity(weapon) || !IsValidEdict(weapon) || !HasEntProp(weapon, Prop_Send, "m_hOwnerEntity")) {
        return false;
    }

    int ownerEntity = GetEntPropEnt(weapon, Prop_Send, "m_hOwnerEntity");

    if (ownerEntity != client) {
        SetEntPropEnt(weapon, Prop_Send, "m_hOwnerEntity", client);
    }

    CS_DropWeapon(client, weapon, false);

    if (HasEntProp(weapon, Prop_Send, "m_hWeaponWorldModel")) {
        int worldModel = GetEntPropEnt(weapon, Prop_Send, "m_hWeaponWorldModel");

        if (IsValidEdict(worldModel) && IsValidEntity(worldModel)) {
            if (!AcceptEntityInput(worldModel, "Kill")) {
                return false;
            }
        }
    }

    return AcceptEntityInput(weapon, "Kill");
}

stock int GetClientWithBomb()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i) && HasBomb(i))
		{
			return i;
		}
	}
	
	return -1;
}

stock bool HasBomb(int client)
{
    return GetClientTeam(client) == CS_TEAM_T && GetPlayerWeaponSlot(client, 5) != -1;
}

stock bool IsWarmup()
{
    return GameRules_GetProp("m_bWarmupPeriod") == 1;
}

stock int GetNearestBombsite(int client)
{
	float pos[3];
	GetClientAbsOrigin(client, pos);
	
	int playerManager = FindEntityByClassname(INVALID_ENT_REFERENCE, "cs_player_manager");
	if (playerManager == INVALID_ENT_REFERENCE)
	{
		return INVALID_ENT_REFERENCE;
	}
	
	float aCenter[3], bCenter[3];
	GetEntPropVector(playerManager, Prop_Send, "m_bombsiteCenterA", aCenter);
	GetEntPropVector(playerManager, Prop_Send, "m_bombsiteCenterB", bCenter);
	
	float aDist = GetVectorDistance(aCenter, pos, true);
	float bDist = GetVectorDistance(bCenter, pos, true);
	
	if (aDist < bDist)
	{
		return BOMBSITE_A;
	}
	
	return BOMBSITE_B;
}

stock bool IsValidClient(int client)
{
    return client > 0 && client <= MaxClients && IsClientConnected(client) && IsClientInGame(client);
}
