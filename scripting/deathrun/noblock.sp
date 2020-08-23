///////////////////////////////////////////////////////////////////////////////
// Disable Block Upon Spawn
///////////////////////////////////////////////////////////////////////////////

#include <SetCollisionGroup>


public NoBlock_OnPluginStart()
{
    HookEvent("player_spawn", NoBlock_PlayerSpawn);
}

public NoBlock_PlayerSpawn(Handle event, const char[] name, bool dontBroadcast)
{
    new client = GetClientOfUserId(GetEventInt(event, "userid"));
    if(1 <= client < MaxClients)
        SetEntityCollisionGroup(client, COLLISION_GROUP_DEBRIS_TRIGGER);
}