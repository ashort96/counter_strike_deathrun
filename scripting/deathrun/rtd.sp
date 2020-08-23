///////////////////////////////////////////////////////////////////////////////
// RTD Functionality
// Decided to rewrite this because someone was charging $50 for a plugin for
// a dead game.
// Credits:
//      - NAME (CONTACT) [PLUGIN]
//      - Farbror Godis [sm_curse]
//      - linux_lover (abkowald@gmail.com) [TF2: Roll the Dice]
//      - FrozDark [Anti-Flash]
//      - destoer
//      - Jordi
//      - Original SM Plugins
///////////////////////////////////////////////////////////////////////////////
#pragma semicolon 1

#include <cstrike>
#include <entity>
#include <rtd>
#include <sdktools>
#include <sourcemod>

#define RTDPREFIX "\x07A221DE[Deathrun RTD]\x07FFFFFF"

///////////////////////////////////////////////////////////////////////////////
// Globals
///////////////////////////////////////////////////////////////////////////////
Handle g_DrugTimers[MAXPLAYERS + 1];
Handle g_EarthquakeTimers[MAXPLAYERS + 1];
Handle g_SlapTimers[MAXPLAYERS + 1];

UserMsg g_FadeUserMsgId;

bool g_AutoBhop[MAXPLAYERS + 1] = {false, ...};
bool g_CanBeBlinded[MAXPLAYERS + 1] = {true, ...};
bool g_CanJumpAgain[MAXPLAYERS + 1] = {true, ...};
bool g_DoubleJump[MAXPLAYERS + 1] = {false, ...};
bool g_InvertedCommands[MAXPLAYERS + 1] = {false, ...};

int g_RTDUses[MAXPLAYERS + 1] = {1, ...};
int g_LastButtons[MAXPLAYERS + 1];
int g_LastFlags[MAXPLAYERS + 1];
int g_Jumps[MAXPLAYERS + 1] = {0, ...};

///////////////////////////////////////////////////////////////////////////////
// Plugin Start; register commands, hook events, etc.
///////////////////////////////////////////////////////////////////////////////
//public OnPluginStart()
public RTD_OnPluginStart()
{
    g_FadeUserMsgId = GetUserMessageId("Fade");

    RegAdminCmd("sm_forcebhop", CommandForceBhop, ADMFLAG_BAN);
    RegAdminCmd("sm_forcegrav", CommandForceGrav, ADMFLAG_BAN);
    RegAdminCmd("sm_forcertd", CommandForceRTD, ADMFLAG_BAN);

    RegConsoleCmd("sm_rtd", CommandRTD, "Roll the dice!");
    RegConsoleCmd("sm_rollthedice", CommandRTD, "Roll the dice!");

    HookEvent("player_blind", Event_RTDPlayerBlind);
    HookEvent("player_death", Event_RTDPlayerDeath);
    HookEvent("player_disconnect", Event_RTDPlayerDisconnect, EventHookMode_Pre);
    HookEvent("round_start", Event_RTDRoundStart, EventHookMode_PostNoCopy);

}

///////////////////////////////////////////////////////////////////////////////
// Command handler for sm_forcertd
// ADMIN COMMAND
///////////////////////////////////////////////////////////////////////////////
public Action CommandForceRTD(int client, int args)
{
    g_RTDUses[client]++;
    CommandRTD(client, args);
    return Plugin_Handled;
}

public Action CommandForceBhop(int client, int args)
{
    g_AutoBhop[client] = true;
    PrintToChat(client, "%s Auto-bhop enabled!", RTDPREFIX);
    return Plugin_Handled;
}

public Action CommandForceGrav(int client, int args)
{
    SetEntityGravity(client, 0.6);
    PrintToChat(client, "%s Low Gravity enabled!", RTDPREFIX);
    return Plugin_Handled;
}

///////////////////////////////////////////////////////////////////////////////
// Command handler for sm_rtd / sm_rollthedice
///////////////////////////////////////////////////////////////////////////////
public Action CommandRTD(int client, int args)
{
    if(g_RTDUses[client] < 1)
    {
        PrintToChat(client, "%s You have already used RTD this round!", RTDPREFIX);
        return Plugin_Handled;
    }
    if(IsValidClient(client) && !IsPlayerAlive(client))
    {
        PrintToChat(client, "%s You must be on a team and alive to use this command!", RTDPREFIX);
        return Plugin_Handled;
    }

    g_RTDUses[client]--;
    RTD randomNumber = view_as<RTD>(GetRandomInt(0, g_numRTD - 1));

    switch(randomNumber)
    {
        case Nothing:
        {
            PrintToChat(client, "%s You didn't get anything on this roll!", RTDPREFIX);
        }
        case AutoBhop:
        {
            g_AutoBhop[client] = true;
            PrintToChat(client, "%s You rolled Auto-Bhop!", RTDPREFIX);
        }
        case LowGrav:
        {
            SetEntityGravity(client, 0.6);
            PrintToChat(client, "%s You rolled Low Gravity!", RTDPREFIX);
        }
        case Turtle:
        {
            SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 0.5);
            SetEntityModel(client, "models/props/de_tides/vending_turtle.mdl");
            int knife = GetPlayerWeaponSlot(client, CS_SLOT_KNIFE);
            if(knife != -1)
            {
                RemovePlayerItem(client, knife);
                AcceptEntityInput(knife, "Kill");
            }
            PrintToChat(client, "%s You rolled Turtle!", RTDPREFIX);
        }
        case RandomHealth:
        {
            int randomHealthValue = GetRandomInt(1, 200);
            SetEntityHealth(client, randomHealthValue);
            PrintToChat(client, "%s You rolled Random Health! You have been set to %i health!", RTDPREFIX, randomHealthValue);
        }
        case Drug:
        {
            CreateDrug(client);
            PrintToChat(client, "%s You rolled Drugs!", RTDPREFIX);
        }
        case Blind:
        {
            int randomBlindness = GetRandomInt(200, 255);
            PerformBlind(client, randomBlindness);
            PrintToChat(client, "%s You rolled Random Blindness!", RTDPREFIX, randomBlindness);
        }
        case SpeedIncrease:
        {
            SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 2.0);
            PrintToChat(client, "%s You rolled Speed Boost!", RTDPREFIX);
        }
        case Smoke:
        {
            GivePlayerItem(client, "weapon_smokegrenade");
            PrintToChat(client, "%s You rolled a Smoke Grenade!", RTDPREFIX);
        }
        case Flash:
        {
            GivePlayerItem(client, "weapon_flashbang");
            PrintToChat(client, "%s You rolled a Flashbang!", RTDPREFIX);
        }
        case Nade:
        {
            GivePlayerItem(client, "weapon_hegrenade");
            PrintToChat(client, "%s You have rolled a Grenade!", RTDPREFIX);
        }
        case StripKnife:
        {
            int knife = GetPlayerWeaponSlot(client, CS_SLOT_KNIFE);
            if(knife != -1)
            {
                RemovePlayerItem(client, knife);
                AcceptEntityInput(knife, "Kill");
            }
            PrintToChat(client, "%s You have lost your knife!", RTDPREFIX);
        }
        case Slap:
        {
            CreateSlap(client);
            PrintToChat(client, "%s You rolled Slap!", RTDPREFIX);
        }
        case RickRoll:
        {
            EmitSoundToClient(client, "music/rickroll.mp3");
            PrintToChat(client, "%s You have been Rick-Rolled!", RTDPREFIX);
        }
        case ThreeRolls:
        {
            g_RTDUses[client] += 3;
            PrintToChat(client, "%s You get three more rolls!", RTDPREFIX);
        }
        case DoubleJump:
        {
            g_DoubleJump[client] = true;
            PrintToChat(client, "%s You have rolled Double Jump!", RTDPREFIX);
        }
        case Sunglasses:
        {
            g_CanBeBlinded[client] = false;
            PrintToChat(client, "%s You rolled Sunglasses!", RTDPREFIX);
            PrintToChat(client, "%s (Unfortunately, no ear plugs...)", RTDPREFIX);
            // TODO: Figure out how to disable sound...
        }
        case Earthquake:
        {
            CreateEarthquake(client);
            PrintToChat(client, "%s You have rolled Earthquake!", RTDPREFIX);
        }
        case InvertedCommands:
        {
            g_InvertedCommands[client] = true;
            PrintToChat(client, "%s Your commands have been inverted!", RTDPREFIX);
        }
        default:
        {
            PrintToChat(client, "%s You somehow rolled something out of bounds: %i", RTDPREFIX, randomNumber);  
            PrintToChat(client, "%s Please report this error with the number rolled to Dunder.", RTDPREFIX);
        }

    }

    return Plugin_Handled;
}

///////////////////////////////////////////////////////////////////////////////
// Events we need to hook into
///////////////////////////////////////////////////////////////////////////////
public Action Event_RTDPlayerDeath(Handle event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(GetEventInt(event, "userid"));
    Cleanup(client);
}

public Action Event_RTDPlayerDisconnect(Handle event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(GetEventInt(event, "userid"));
    Cleanup(client);

}

public Action Event_RTDRoundStart(Handle event, const char[] name, bool dontBroadcast)
{
    for(int i = 1; i < MaxClients; i++)
    {
        if(IsValidClient(i))
            Cleanup(i);
    }
}

public Action Event_RTDPlayerBlind(Handle event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(GetEventInt(event, "userid"));
    if(!g_CanBeBlinded[client])
    {
        SetEntPropFloat(client, Prop_Send, "m_flFlashMaxAlpha", 0.5);
    }
}

void Cleanup(int client)
{
    g_AutoBhop[client] = false;
    g_CanBeBlinded[client] = true;
    g_DoubleJump[client] = false;
    g_InvertedCommands[client] = false;
    g_RTDUses[client] = 1;
    if(g_DrugTimers[client] != null)
        KillDrugTimer(client);
    if(g_SlapTimers[client] != null)
        KillSlapTimer(client);
    if(g_EarthquakeTimers[client] != null)
        KillEarthquakeTimer(client);
    if(client > 0 && client < MaxClients && IsPlayerAlive(client))
    {
        PerformBlind(client, 0);
        SetEntityGravity(client, 1.0);
    }

}

///////////////////////////////////////////////////////////////////////////////
// Used for the auto-bhop RTD
///////////////////////////////////////////////////////////////////////////////
public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon)
{
    if(g_AutoBhop[client])
    {
        if(IsPlayerAlive(client) && buttons & IN_JUMP)
        {
            if(!(GetEntityMoveType(client) & MOVETYPE_LADDER) && !(GetEntityFlags(client) & FL_ONGROUND))
            {
                int waterIndex = GetEntProp(client, Prop_Data, "m_nWaterLevel");
                if(waterIndex < 1)
                {
                    buttons &= ~IN_JUMP;
                }
            }
        }
    }
    if(g_InvertedCommands[client])
    {
        vel[0] = -vel[0];
        vel[1] = -vel[1];
        if(buttons & IN_MOVELEFT)
        {
            buttons &= ~IN_MOVELEFT;
            buttons |= IN_MOVERIGHT;
        }
        else if(buttons & IN_MOVERIGHT)
        {
            buttons &= ~IN_MOVERIGHT;
            buttons &= IN_MOVELEFT;
        }
        if(buttons & IN_FORWARD)
        {
            buttons &= ~IN_FORWARD;
            buttons |= IN_BACK;
        }
        else if(buttons & IN_BACK)
        {
            buttons &= ~IN_BACK;
            buttons |= IN_FORWARD;
        }
    }
    return Plugin_Continue;
}

///////////////////////////////////////////////////////////////////////////////
// Used for the double-jump RTD
///////////////////////////////////////////////////////////////////////////////
public OnGameFrame()
{
    for(int i = 1; i < MaxClients; i++)
    {
        if(IsValidClient(i) && g_DoubleJump[i])
        {
            PerformDoubleJump(i);
        }
    }
}

///////////////////////////////////////////////////////////////////////////////
// Functions for drugging; copied from drugs.sp
// Modified for this plugin
///////////////////////////////////////////////////////////////////////////////
void CreateDrug(int client)
{
    if(g_DrugTimers[client] == null)
        g_DrugTimers[client] = CreateTimer(1.0, Timer_Drug, client, TIMER_REPEAT);    
}

public Action Timer_Drug(Handle timer, int client)
{
    float drugAngles[20] = {0.0, 5.0, 10.0, 15.0, 20.0, 25.0, 20.0, 15.0, 10.0, 5.0, 0.0, -5.0, -10.0, -15.0, -20.0, -25.0, -20.0, -15.0, -10.0, -5.0};

    if(!IsValidClient(client) && !IsPlayerAlive(client))
    {
        KillDrugTimer(client);
        return Plugin_Handled;
    }
    
    float angs[3];
    GetClientEyeAngles(client, angs);

    angs[2] = drugAngles[GetRandomInt(0,100) % 20];
    
    TeleportEntity(client, NULL_VECTOR, angs, NULL_VECTOR);
    
    int clients[2];
    clients[0] = client;    

    int duration = 255;
    int holdtime = 255;
    int flags = 0x0002;
    int color[4] = { 0, 0, 0, 128 };
    color[0] = GetRandomInt(0,255);
    color[1] = GetRandomInt(0,255);
    color[2] = GetRandomInt(0,255);

    Handle message = StartMessageEx(g_FadeUserMsgId, clients, 1);
    if (GetUserMessageType() == UM_Protobuf)
    {
        Protobuf pb = UserMessageToProtobuf(message);
        pb.SetInt("duration", duration);
        pb.SetInt("hold_time", holdtime);
        pb.SetInt("flags", flags);
        pb.SetColor("clr", color);
    }
    else
    {
        BfWriteShort(message, duration);
        BfWriteShort(message, holdtime);
        BfWriteShort(message, flags);
        BfWriteByte(message, color[0]);
        BfWriteByte(message, color[1]);
        BfWriteByte(message, color[2]);
        BfWriteByte(message, color[3]);
    }
    
    EndMessage();
        
    return Plugin_Handled;
}

void KillDrugTimer(int client)
{
    KillTimer(g_DrugTimers[client]);
    g_DrugTimers[client] = null;    
}

///////////////////////////////////////////////////////////////////////////////
// Functions for blinding; copied from blind.sp
// Modified for this plugin
///////////////////////////////////////////////////////////////////////////////
void PerformBlind(int client, int amount)
{
    int targets[2];
    targets[0] = client;
    
    int duration = 1536;
    int holdtime = 1536;
    int flags;
    if (amount == 0)
    {
        flags = (0x0001 | 0x0010);
    }
    else
    {
        flags = (0x0002 | 0x0008);
    }
    
    int color[4] = { 0, 0, 0, 0 };
    color[3] = amount;
    
    Handle message = StartMessageEx(g_FadeUserMsgId, targets, 1);
    if (GetUserMessageType() == UM_Protobuf)
    {
        Protobuf pb = UserMessageToProtobuf(message);
        pb.SetInt("duration", duration);
        pb.SetInt("hold_time", holdtime);
        pb.SetInt("flags", flags);
        pb.SetColor("clr", color);
    }
    else
    {
        BfWrite bf = UserMessageToBfWrite(message);
        bf.WriteShort(duration);
        bf.WriteShort(holdtime);
        bf.WriteShort(flags);        
        bf.WriteByte(color[0]);
        bf.WriteByte(color[1]);
        bf.WriteByte(color[2]);
        bf.WriteByte(color[3]);
    }
    
    EndMessage();
}

///////////////////////////////////////////////////////////////////////////////
// Functions for slapping; copied from slap.sp
// Modified for this plugin
///////////////////////////////////////////////////////////////////////////////
void CreateSlap(int client)
{
    if(g_SlapTimers[client] == null)
        g_SlapTimers[client] = CreateTimer(4.0, Timer_Slap, client, _);
}

public Action Timer_Slap(Handle timer, int client)
{
    if((IsValidClient(client) && !IsPlayerAlive(client)) || g_SlapTimers[client] == null)
    {
        KillSlapTimer(client);
        return;
    }
    else
    {
        SlapPlayer(client, 0, true);
        float randomTime = GetRandomFloat(1.0, 5.0);
        g_SlapTimers[client] = CreateTimer(randomTime, Timer_Slap, client, _);
    }
}

void KillSlapTimer(int client)
{
    g_SlapTimers[client] = null;    
}

///////////////////////////////////////////////////////////////////////////////
// Functions for double jump
///////////////////////////////////////////////////////////////////////////////
stock void PerformDoubleJump(int client)
{
    int flags = GetEntityFlags(client);
    int buttons = GetClientButtons(client);
    if(g_LastFlags[client] & FL_ONGROUND)
    {
        //Initial Jump
        if(!(flags & FL_ONGROUND) && (buttons & IN_JUMP))
        {
            g_Jumps[client]++;
            g_CanJumpAgain[client] = false;
            CreateTimer(0.2, AllowJumpAgain, client, _);

        }
    }
    // Reset back to 0
    else if(flags & FL_ONGROUND && (g_Jumps[client] != 0))
    {
        g_Jumps[client] = 0;
    }
    // If they didn't press jump on last frame and are pressing it now
    else if((buttons & IN_JUMP) && g_CanJumpAgain[client])
    {
        if(g_Jumps[client] < 2)
        {
            g_Jumps[client]++;
            float vel[3];
            GetEntPropVector(client, Prop_Data, "m_vecVelocity", vel);
            vel[2] = 250.0;
            TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, vel);
            g_CanJumpAgain[client] = false;
            CreateTimer(0.2, AllowJumpAgain, client, _);
        }
    }

    g_LastFlags[client] = flags;
    g_LastButtons[client] = buttons;
    
}

public Action AllowJumpAgain(Handle timer, int client)
{
    g_CanJumpAgain[client] = true;
}

///////////////////////////////////////////////////////////////////////////////
// Functions for earthquake
///////////////////////////////////////////////////////////////////////////////
void CreateEarthquake(int client)
{
    if(g_EarthquakeTimers[client] == null)
        g_EarthquakeTimers[client] = CreateTimer(0.25, Timer_Earthquake, client, TIMER_REPEAT);
}

public Action Timer_Earthquake(Handle timer, int client)
{
    if(!IsValidClient(client) && !IsPlayerAlive(client))
    {
        KillEarthquakeTimer(client);
    }
    float drugAngles[20] = {0.0, 5.0, 10.0, 15.0, 20.0, 25.0, 20.0, 15.0, 10.0, 5.0, 0.0, -5.0, -10.0, -15.0, -20.0, -25.0, -20.0, -15.0, -10.0, -5.0};
    float angs[3];
    GetClientEyeAngles(client, angs);

    angs[2] = drugAngles[GetRandomInt(0,100) % 20];
    
    TeleportEntity(client, NULL_VECTOR, angs, NULL_VECTOR);
}

void KillEarthquakeTimer(int client)
{
    KillTimer(g_EarthquakeTimers[client]);
    g_EarthquakeTimers[client] = null;
}