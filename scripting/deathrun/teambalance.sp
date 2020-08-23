///////////////////////////////////////////////////////////////////////////////
// Team Balancer
///////////////////////////////////////////////////////////////////////////////

#define TBPREFIX "\x07A221DE[Deathrun Team Balancer]\x07FFFFFF"

public TeamBalance_OnPluginStart()
{
    RegConsoleCmd("jointeam", TeamBalance);
}

public Action TeamBalance(int client, int args)
{
    char teamString[3];
    GetCmdArg(1, teamString, sizeof(teamString));
    int newTeam = StringToInt(teamString);
    int oldTeam = GetClientTeam(client);

    if(!((newTeam == CS_TEAM_T) || (newTeam == CS_TEAM_CT) || (newTeam == CS_TEAM_SPECTATOR)))
    {
        PrintCenterText(client, "Auto-Join is Disabled!");
        PrintToChat(client, "%s Auto-Join is Disabled!", TBPREFIX);
        
        CreateTimer(2.0, Timer_DisplayTeamMenu, client, _);
        return Plugin_Handled;
    }

    if(newTeam == CS_TEAM_T && oldTeam != CS_TEAM_T)
    {
        int countTs = 0;
        int countCTs = 0;
        for(int i = 1; i < MaxClients; i++)
        {
            if(IsClientInGame(i))
            {
                if(GetClientTeam(i) == CS_TEAM_T)
                    countTs++;
                else if(GetClientTeam(i) == CS_TEAM_CT)
                    countCTs++;
            }
        }

        if((countTs < (countCTs / 4.0)) || !countTs)
        {
            return Plugin_Continue;
        }
        ClientCommand(client, "play ui/freeze_cam.wav");
        PrintToChat(client, "%s Transfer denied, there are enough Ts!", TBPREFIX);
        return Plugin_Handled;
    }

    return Plugin_Continue;
}

public Action Timer_DisplayTeamMenu(Handle timer, int client)
{
    new clients[1];
    new Handle:bf;
    clients[0] = client;
    bf = StartMessage("VGUIMenu", clients, 1);

    if (GetUserMessageType() == UM_Protobuf)
    {
        PbSetString(bf, "name", "team");
        PbSetBool(bf, "show", true);
    }
    else
    {
        BfWriteString(bf, "team");
        BfWriteByte(bf, 1);
        BfWriteByte(bf, 0);
    }
    
    EndMessage();
}
