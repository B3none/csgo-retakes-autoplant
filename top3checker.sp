#include <sourcemod>
#include <sdktools>
#include <cstrike>

#pragma newdecls required
#pragma semicolon 1

int topScores[3];

public Plugin myinfo =
{
	name = "Top 3 Kevlar",
	author = "B3none",
	description = "Give the top 3 players in the server kevlar",
	version = "1.0.0",
	url = "https://forums.alliedmods.net/showthread.php?t=298124"
};

public void OnPluginStart()
{
	if (GetEngineVersion() != Engine_CSGO) {
		SetFailState("This plugin is only for CS:GO !");
	}

	HookEvent("round_start", onRoundStart);
}

public void onRoundStart(Handle event, const char[] name, bool dontBroadcast)
{
	for (int i = 0; i <= 2; i++) {
		topScores[i] = 0;
	}
	
	for (int i = 1; i <= MAXPLAYERS+1; i++) {
		if (topScores[0] != 0 && topScores[1] != 0 && topScores[2] != 0) {
			
			for (int j = 0; j <= 2; j++) {
				if (CS_GetClientContributionScore(i) > topScores[j]) {
					topScores[j] = CS_GetClientContributionScore(i);
				}
			}
		} else {
			for (int j = 0; j <= 2; j++) {
				if(topScores[j] == 0) {
					topScores[j] = CS_GetClientContributionScore(i);	
				}
			}
		}
	}
	
	for (int i = 1; i <= MAXPLAYERS+1; i++) {
		if (isClientTop3(i)) {
			if (IsPlayerAlive(i)) {
				givePlayerKevlar(i);
			}
		}
	}
}

stock bool isClientTop3(int client)
{
	if (CS_GetClientContributionScore(client) == topScores[0] || CS_GetClientContributionScore(client) == topScores[1] || CS_GetClientContributionScore(client) == topScores[2]) {
		return true;
	} else {
		return false;
	}
}

public Action givePlayerKevlar(int client)
{
	if (IsValidClient(client)) {
		GivePlayerItem(client, "item_kevlar");
	}
}

stock bool IsValidClient(int client)
{
	if (client <= 0 || client > MAXPLAYERS+1) {
		return false;
	}
	
	if (!IsClientInGame(client)) {
		return false;
	}
	
	return true;
}
