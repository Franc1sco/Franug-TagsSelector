/*  SM Franug Tags Selector
 *
 *  Copyright (C) 2020 Francisco 'Franc1sco' García
 * 
 * This program is free software: you can redistribute it and/or modify it
 * under the terms of the GNU General Public License as published by the Free
 * Software Foundation, either version 3 of the License, or (at your option) 
 * any later version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT 
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS 
 * FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along with 
 * this program. If not, see http://www.gnu.org/licenses/.
 */

#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <chat-processor>

#define IDAYS 26

#define VERSION "0.1.2"

char g_sClantag[MAXPLAYERS + 1][128], g_sChattag[MAXPLAYERS + 1][128],
	g_sColorChattag[MAXPLAYERS + 1][128];

bool g_bChecked[MAXPLAYERS + 1];

char g_sSQLBuffer[3096];

bool g_bIsMySQl;

// DB handle
Handle g_hDB = INVALID_HANDLE;

public void OnPluginStart()
{
	RegConsoleCmd("sm_setmyclantag", Command_Clantag);
	RegConsoleCmd("sm_setmychattag", Command_Chattag);
	
	SQL_TConnect(OnSQLConnect, "franug_tagsselector");
}

public Action Command_Chattag(int client, int args)
{
	decl String:SayText[512];
	GetCmdArgString(SayText,sizeof(SayText));
	
	StripQuotes(SayText);
	
	if(strlen(SayText) > 32)
	{
		ReplyToCommand(client, "Chattag too large");
		return Plugin_Handled;
	}
	if(strlen(SayText) < 1)
	{
		ReplyToCommand(client, "Chattag too small");
		return Plugin_Handled;
	}
	
	// todo block disallowed works
	
	if(!StrEqual(g_sChattag[client], "none"))
		ChatProcessor_RemoveClientTag(client, g_sChattag[client]);
		
	//strcopy(g_sChattag[client], 128, SayText);
	
	Format(g_sChattag[client], 128, " %s", SayText);
	
	ChatProcessor_AddClientTag(client, g_sChattag[client]);
	
	ReplyToCommand(client, "Chattag changed to %s", g_sChattag[client]);
		
	return Plugin_Handled;
}

public Action Command_Clantag(int client, int args)
{
	decl String:SayText[512];
	GetCmdArgString(SayText,sizeof(SayText));
	
	StripQuotes(SayText);
	
	if(strlen(SayText) > 32)
	{
		ReplyToCommand(client, "Clantag too large");
		return Plugin_Handled;
	}
	if(strlen(SayText) < 1)
	{
		ReplyToCommand(client, "Clantag too small");
		return Plugin_Handled;
	}
	
	// todo block disallowed works
		
	strcopy(g_sClantag[client], 128, SayText);
	
	CS_SetClientClanTag(client, g_sClantag[client]);
	
	ReplyToCommand(client, "Clantag changed to %s", g_sClantag[client]);
		
	return Plugin_Handled;
}

public void OnClientSettingsChanged(int client)
{
	if (!IsClientInGame(client) || IsFakeClient(client))return;
	
	if(!StrEqual(g_sClantag[client], "none"))
		CS_SetClientClanTag(client, g_sClantag[client]);
}


public int OnSQLConnect(Handle owner, Handle hndl, char [] error, any data)
{
	if(hndl == INVALID_HANDLE)
	{
		LogError("Database failure: %s", error);
		
		SetFailState("Databases dont work");
	}
	else
	{
		g_hDB = hndl;
		
		SQL_GetDriverIdent(SQL_ReadDriver(g_hDB), g_sSQLBuffer, sizeof(g_sSQLBuffer));
		g_bIsMySQl = StrEqual(g_sSQLBuffer,"mysql", false) ? true : false;
		
		if(g_bIsMySQl)
		{
			Format(g_sSQLBuffer, sizeof(g_sSQLBuffer), "CREATE TABLE IF NOT EXISTS `franug_tagsselector` (`playername` varchar(128) NOT NULL, `steamid` varchar(32) PRIMARY KEY NOT NULL,`last_accountuse` int(64) NOT NULL, `clantag` varchar(128) NOT NULL, `chattag` varchar(128) NOT NULL, `colorchattag` varchar(128) NOT NULL)");
			
			SQL_TQuery(g_hDB, OnSQLConnectCallback, g_sSQLBuffer);
		}
		else
		{
			Format(g_sSQLBuffer, sizeof(g_sSQLBuffer), "CREATE TABLE IF NOT EXISTS franug_tagsselector (playername varchar(128) NOT NULL, steamid varchar(32) PRIMARY KEY NOT NULL,last_accountuse int(64) NOT NULL, clantag varchar(128) NOT NULL, chattag varchar(128) NOT NULL, colorchattag varchar(128) NOT NULL)");
			
			SQL_TQuery(g_hDB, OnSQLConnectCallback, g_sSQLBuffer);
		}
		PruneDatabase();
	}
}

public int OnSQLConnectCallback(Handle owner, Handle hndl, char [] error, any data)
{
	if(hndl == INVALID_HANDLE)
	{
		LogError("Query failure: %s", error);
		return;
	}
	
	for(int client = 1; client <= MaxClients; client++)
	{
		if(IsClientInGame(client))
		{
			OnClientPostAdminCheck(client);
		}
	}
}

public void InsertSQLNewPlayer(int client)
{
	char query[255], steamid[32];
	GetClientAuthId(client, AuthId_Steam2,steamid, sizeof(steamid));
	int userid = GetClientUserId(client);
	
	char Name[MAX_NAME_LENGTH+1];
	char SafeName[(sizeof(Name)*2)+1];
	if(!GetClientName(client, Name, sizeof(Name)))
		Format(SafeName, sizeof(SafeName), "<noname>");
	else
	{
		TrimString(Name);
		SQL_EscapeString(g_hDB, Name, SafeName, sizeof(SafeName));
	}
	
	Format(query, sizeof(query), "INSERT INTO franug_tagsselector(playername, steamid, last_accountuse, clantag, chattag, colorchattag) VALUES('%s', '%s', '%d', 'none', 'none', 'none');", SafeName, steamid, GetTime());
	SQL_TQuery(g_hDB, SaveSQLPlayerCallback, query, userid);
	g_sClantag[client] = "none";
	g_sColorChattag[client] = "none";
	g_sChattag[client] = "none";
	
	g_bChecked[client] = true;
}

public int SaveSQLPlayerCallback(Handle owner, Handle hndl, char [] error, any data)
{
	if(hndl == INVALID_HANDLE)
	{
		LogError("Query failure: %s", error);
	}
}

public void CheckSQLSteamID(int client)
{
	char query[255], steamid[32];
	GetClientAuthId(client, AuthId_Steam2,steamid, sizeof(steamid) );
	
	Format(query, sizeof(query), "SELECT clantag, chattag, colorchattag FROM franug_tagsselector WHERE steamid = '%s'", steamid);
	SQL_TQuery(g_hDB, CheckSQLSteamIDCallback, query, GetClientUserId(client));
}

public int CheckSQLSteamIDCallback(Handle owner, Handle hndl, char [] error, any data)
{
	int client;
	
	/* Make sure the client didn't disconnect while the thread was running */
	
	if((client = GetClientOfUserId(data)) == 0)
	{
		return;
	}
	
	if(hndl == INVALID_HANDLE)
	{
		LogError("Query failure: %s", error);
		return;
	}
	if(!SQL_GetRowCount(hndl) || !SQL_FetchRow(hndl)) 
	{
		InsertSQLNewPlayer(client);
		return;
	}
	
	SQL_FetchString(hndl, 0, g_sClantag[client], 128);
	SQL_FetchString(hndl, 1, g_sChattag[client], 128);
	SQL_FetchString(hndl, 2, g_sColorChattag[client], 128);
	
	if(!StrEqual(g_sClantag[client], "none") && IsClientInGame(client))
		CS_SetClientClanTag(client, g_sClantag[client]);
	
	if(!StrEqual(g_sChattag[client], "none"))
		ChatProcessor_AddClientTag(client, g_sChattag[client]);
		
	if(!StrEqual(g_sColorChattag[client], "none"))
		ChatProcessor_SetTagColor(client, g_sChattag[client], g_sColorChattag[client]);
	
	g_bChecked[client] = true;
}

public void SaveSQLCookies(int client)
{
	char steamid[32];
	GetClientAuthId(client, AuthId_Steam2,steamid, sizeof(steamid) );
	char Name[MAX_NAME_LENGTH+1];
	char SafeName[(sizeof(Name)*2)+1];
	if(!GetClientName(client, Name, sizeof(Name)))
		Format(SafeName, sizeof(SafeName), "<noname>");
	else
	{
		TrimString(Name);
		SQL_EscapeString(g_hDB, Name, SafeName, sizeof(SafeName));
	}	

	char buffer[3096];
	Format(buffer, sizeof(buffer), "UPDATE franug_tagsselector SET last_accountuse = %d, playername = '%s',clantag = '%s',chattag = '%s', colorchattag = '%s' WHERE steamid = '%s';",GetTime(), SafeName, g_sClantag[client],g_sChattag[client],g_sColorChattag[client], steamid);
	SQL_TQuery(g_hDB, SaveSQLPlayerCallback, buffer);
	g_bChecked[client] = false;
}

public void OnPluginEnd()
{
	for(int client = 1; client <= MaxClients; client++)
	{
		if(IsClientInGame(client))
		{
			OnClientDisconnect(client);
		}
	}
}

public void OnClientDisconnect(int client)
{
	if(!IsFakeClient(client) && g_bChecked[client]) SaveSQLCookies(client);
	
	g_sClantag[client] = "none";
	g_sColorChattag[client] = "none";
	g_sChattag[client] = "none";
}

public void OnClientPostAdminCheck(int client)
{
	g_sClantag[client] = "none";
	g_sColorChattag[client] = "none";
	g_sChattag[client] = "none";
	
	if(!IsFakeClient(client)) CheckSQLSteamID(client);
}

public void PruneDatabase()
{
	if(g_hDB == INVALID_HANDLE)
	{
		return;
	}

	int maxlastaccuse;
	maxlastaccuse = GetTime() - (IDAYS * 86400);

	char buffer[1024];

	if(g_bIsMySQl)
		Format(buffer, sizeof(buffer), "DELETE FROM `franug_tagsselector` WHERE `last_accountuse`<'%d' AND `last_accountuse`>'0';", maxlastaccuse);
	else
		Format(buffer, sizeof(buffer), "DELETE FROM franug_tagsselector WHERE last_accountuse<'%d' AND last_accountuse>'0';", maxlastaccuse);
		
	SQL_TQuery(g_hDB, PruneDatabaseCallback, buffer);
}

public int PruneDatabaseCallback(Handle owner, Handle hndl, char [] error, any data)
{

}