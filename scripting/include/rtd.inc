const g_numRTD = 19;

enum RTD
{
    Nothing = 0,
    AutoBhop,
    LowGrav,
    Turtle,
    RandomHealth,
    Drug,
    Blind,
    SpeedIncrease,
    Smoke,
    Flash,
    Nade,
    StripKnife,
    Slap,
    RickRoll,
    ThreeRolls,
    DoubleJump,
    Sunglasses,
    Earthquake,
    InvertedCommands,
};

stock bool IsClientOnTeam(int client)
{
    return GetClientTeam(client) == CS_TEAM_CT || GetClientTeam(client) == CS_TEAM_T;
}

stock bool IsValidClient(int client)
{
    if(client <= 0 || client > MaxClients)
        return false;
    if(!IsClientConnected(client))
        return false;
    if(!IsClientInGame(client))
        return false;
    return true;
}
