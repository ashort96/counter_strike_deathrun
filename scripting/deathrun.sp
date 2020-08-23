#pragma semicolon 1

#define PLUGIN_NAME         "CS:S Deathrun"
#define PLUGIN_AUTHOR       "Dunder"
#define PLUGIN_DESCRIPTION  "Bring Deathrun Back"
#define PLUGIN_VERSION      "1.0.0"
#define PLUGIN_URL          "https://www.youtube.com/watch?v=dQw4w9WgXcQ"

#include <cstrike>
#include <sdktools>
#include <sourcemod>

#include "deathrun/antirejoin.sp"
#include "deathrun/noblock.sp"
#include "deathrun/rtd.sp"
#include "deathrun/teambalance.sp"

public Plugin:myinfo =
{
    name = PLUGIN_NAME,
    author = PLUGIN_AUTHOR,
    description = PLUGIN_DESCRIPTION,
    version = PLUGIN_VERSION,
    url = PLUGIN_URL
}

public OnPluginStart()
{
    EngineVersion g_Game;
    g_Game = GetEngineVersion();
    if(g_Game != Engine_CSS)
    {
        SetFailState("This plugin is for CS:S only!");
    }

    // Load Modules
    AntiRejoin_OnPluginStart();
    NoBlock_OnPluginStart();
    RTD_OnPluginStart();
    TeamBalance_OnPluginStart();

}

public OnMapStart()
{
    PrecacheModel("models/props/de_tides/vending_turtle.mdl");
    PrecacheSound("music/rickroll.mp3");

    AddFileToDownloadsTable("sound/music/rickroll.mp3"); 
}