#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <cstrike>

#pragma newdecls required
#pragma semicolon 1

Handle bombTimer;

ConVar isPluginEnabled;
ConVar freezeTime;

enum //Bombsites
{
    BOMBSITE_INVALID = -1,
    BOMBSITE_A = 0,
    BOMBSITE_B = 1
}

public Plugin myinfo =
{
    name = "[Retakes] Autoplant",
    author = "B3none, _domino",
    description = "Automatically plant the bomb at the start of the round. This will work with all versions of the retakes plugin.",
    version = "3.0.0",
    url = "https://github.com/b3none"
};

public void OnPluginStart()
{
    isPluginEnabled = CreateConVar("sm_autoplant_enabled", "1", "Should the autoplant plugin be enabled", _, true, 0.0, true, 1.0);
    
    freezeTime = FindConVar("mp_freezetime");
    
    HookEvent("round_start", OnRoundStart, EventHookMode_PostNoCopy);
    HookEvent("round_end", OnRoundEnd, EventHookMode_PostNoCopy);
}

public Action OnRoundStart(Event eEvent, const char[] sName, bool bDontBroadcast)
{
    if (!isPluginEnabled.BoolValue)
    {
        return Plugin_Continue;
    }
    
    int bomber = GetBomber();
    
    if (IsValidClient(bomber))
    {
        delete bombTimer;
        
        bombTimer = CreateTimer(freezeTime.FloatValue, PlantBomb, bomber);
    }
    
    return Plugin_Continue;
}

public void OnRoundEnd(Event event, const char[] sName, bool bDontBroadcast)
{
    delete bombTimer;

    GameRules_SetProp("m_bBombPlanted", 0);
}

public Action PlantBomb(Handle timer, int bomber)
{
    delete bombTimer;
    
    if (IsValidClient(bomber))
    {
        int bomb = GetPlayerWeaponSlot(bomber, 4);
        SetEntPropEnt(bomber, Prop_Send, "m_hActiveWeapon", bomb);
        
        GameRules_SetProp("m_fArmedTime", GetGameTime() - 3.0);
    } 
    else
    {
        CS_TerminateRound(1.0, CSRoundEnd_Draw);
    }
}

public Action OnPlayerRunCmd(int client, int& buttons)
{
    if(!(buttons & IN_ATTACK))
    {
        buttons |= IN_ATTACK;
        return Plugin_Changed;
    }
    
    return Plugin_Continue;
}

stock int GetBomber()
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
    return GetPlayerWeaponSlot(client, 4) != -1;
}


stock bool IsWarmup()
{
    return GameRules_GetProp("m_bWarmupPeriod") == 1;
}

stock bool IsValidClient(int client)
{
    return client > 0 && client <= MaxClients && IsClientConnected(client) && IsClientInGame(client);
}
