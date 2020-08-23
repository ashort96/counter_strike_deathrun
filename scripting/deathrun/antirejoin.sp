///////////////////////////////////////////////////////////////////////////////
// Prevent people from rejoining (@Jordi)
///////////////////////////////////////////////////////////////////////////////

#include <adt_array>
#include <cstrike>
#include <sourcemod>

#define ARPREFIX "\x07A221DE[Deathrun Anti-Rejoin]\x07FFFFFF"

ArrayList g_LeftAID;

public AntiRejoin_OnPluginStart()
{
    g_LeftAID = new ArrayList(64);
    HookEvent("round_start", Event_AntiRejoinRoundStart, EventHookMode_PostNoCopy);
    HookEvent("player_disconnect", Event_AntiRejoinPlayerDisconnect);
    RegConsoleCmd("jointeam", AntiRejoinTeamJoin);
}

public Action Event_AntiRejoinRoundStart(Handle event, const char[] name, bool dontBroadcast)
{
    ClearArray(g_LeftAID);
}

public Action Event_AntiRejoinPlayerDisconnect(Handle event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(GetEventInt(event, "userid"));
    char buf[64];
    GetClientAuthId(client, AuthId_Steam3, buf, sizeof(buf));
    PushArrayString(g_LeftAID, buf);
}

public Action AntiRejoinTeamJoin(int client, int args)
{
    char teamString[3];
    GetCmdArg(1, teamString, sizeof(teamString));
    int newTeam = StringToInt(teamString);
    if(!((newTeam == CS_TEAM_T) || newTeam == CS_TEAM_CT))
    {
        return Plugin_Continue;
    }
    char buf[64];
    GetClientAuthId(client, AuthId_Steam3, buf, sizeof(buf));
    if(FindStringInArray(g_LeftAID, buf) != -1)
    {
        CreateTimer(2.0, AntiRejoinSlay, client);

    }
    return Plugin_Continue;
}

public Action AntiRejoinSlay(Handle timer, int client)
{
    if(IsPlayerAlive(client))
    {
        PrintToChat(client, "%s Nice try.", ARPREFIX);
        ForcePlayerSuicide(client);
    }
}