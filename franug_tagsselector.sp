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

enum
{
 	Color_Default = 0,
	Color_Darkred,
	Color_Green,
	Color_Lightgreen,
	Color_Red,
	Color_Blue,
	Color_Olive,
	Color_Lime,
	Color_Lightred,
	Color_Purple,
	Color_Grey,
	Color_Yellow,
	Color_Orange,
	Color_Bluegrey,
	Color_Lightblue,
	Color_Darkblue,
	Color_Grey2,
	Color_Orchid,
	Color_Lightred2
}

char C_Tag[][] = {"none","rainbow", "{darkred}", "{green}", "{lightgreen}", "{red}", "{blue}", "{olive}", "{lime}", "{lightred}", "{purple}", "{grey}", "{yellow}", "{orange}", "{bluegrey}", "{lightblue}", "{darkblue}", "{grey2}", "{orchid}", "{lightred2}"};

#define IDAYS 26

#define VERSION "0.4.1"

char g_sClantag[MAXPLAYERS + 1][128], g_sChattag[MAXPLAYERS + 1][128],
	g_sColorChattag[MAXPLAYERS + 1][128];

bool g_bChecked[MAXPLAYERS + 1];

char g_sSQLBuffer[3096];

bool g_bIsMySQl;

char _temp[MAXPLAYERS + 1][128];

// DB handle
Handle g_hDB = INVALID_HANDLE;

Handle _blacklist;

public void OnPluginStart()
{
	RegConsoleCmd("sm_setmyclantag", Command_Clantag);
	RegConsoleCmd("sm_setmychattag", Command_Chattag);
	RegConsoleCmd("sm_setmycolorchattag", Command_ColorChattag);
	
	SQL_TConnect(OnSQLConnect, "franug_tagsselector");
	
	_blacklist = CreateArray(128);
}

public void OnMapStart()
{
	LoadList();
}

public Action Command_ColorChattag(int client, int args)
{
	Menu_Colors(client);
	
		
	return Plugin_Handled;
}

public int MenuHandler1(Menu menu, MenuAction action, int client, int param2)
{
    /* If an option was selected, tell the client about the item. */
    if (action == MenuAction_Select)
    {
		char color[64];
		menu.GetItem(param2, color, sizeof(color));
        
		strcopy(g_sColorChattag[client], 64, color);
        
		if(!StrEqual(g_sChattag[client], "none") && !StrEqual(g_sColorChattag[client], "rainbow"))
        	ChatProcessor_SetTagColor(client, g_sChattag[client], g_sColorChattag[client]);
    
    }
    /* If the menu has ended, destroy it */
    else if (action == MenuAction_End)
    {
        delete menu;
    }
}
 
public Action Menu_Colors(int client)
{
    Menu menu = new Menu(MenuHandler1);
    menu.SetTitle("Select your chattag color");
    char name[64];
    for (int i = 0; i < sizeof(C_Tag); i++)
    {
    	Format(name, 64, C_Tag[i]);
    	ReplaceString(name, 64, "{", "");
    	ReplaceString(name, 64, "}", "");
    	
    	menu.AddItem(C_Tag[i], name);
    }
    //menu.AddItem("yes", "Yes");
    menu.ExitButton = false;
    menu.Display(client, 0);
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
	
	int blacklistsize = GetArraySize(_blacklist);
	
	if(blacklistsize > 0)
	{
		char word[128];
		for (int i = 0; i < blacklistsize; i++)
		{
			GetArrayString(_blacklist, i, word, 128);
			
			if(StrContains(SayText, word, false) != -1)
			{
				ReplyToCommand(client, "You tried to use a disallowed word");
				return Plugin_Handled;
			}
		}
	}
	
	if(!StrEqual(g_sChattag[client], "none"))
		ChatProcessor_RemoveClientTag(client, g_sChattag[client]);
		
	//strcopy(g_sChattag[client], 128, SayText);
	
	Format(g_sChattag[client], 128, " %s ", SayText);
	
	ChatProcessor_AddClientTag(client, g_sChattag[client]);
	
	if(!StrEqual(g_sColorChattag[client], "none"))
	{
		if(!StrEqual(g_sColorChattag[client], "rainbow"))
			ChatProcessor_SetTagColor(client, g_sChattag[client], g_sColorChattag[client]);
	}
	
	ReplyToCommand(client, "Chattag changed to %s", SayText);
		
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
	
	int blacklistsize = GetArraySize(_blacklist);
	
	if(blacklistsize > 0)
	{
		char word[128];
		for (int i = 0; i < blacklistsize; i++)
		{
			GetArrayString(_blacklist, i, word, 128);
			
			if(StrContains(SayText, word, false) != -1)
			{
				ReplyToCommand(client, "You tried to use a disallowed word");
				return Plugin_Handled;
			}
		}
	}
		
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
		
	if(!StrEqual(g_sColorChattag[client], "none") && !StrEqual(g_sColorChattag[client], "rainbow"))
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
	
	strcopy(_temp[client], 128, "");
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

public LoadList()
{
	ClearArray(_blacklist);
	
	char path[PLATFORM_MAX_PATH];
	BuildPath(PathType:Path_SM, path, sizeof(path), "configs/tagsselector_blacklist.txt");
	
	Handle file = OpenFile(path, "r");
	if(file == INVALID_HANDLE)
	{
		PrintToServer("Unable to read file %s", path);
		return;
	}
	
	char line[128];
	while(!IsEndOfFile(file) && ReadFileLine(file, line, sizeof(line)))
	{
		if (line[0] == ';' || !IsCharAlpha(line[0]))
		{
			continue;
		}
		int len = strlen(line);
		for (int i; i < len; i++)
		{
			if (IsCharSpace(line[i]) || line[i] == ';')
			{
				line[i] = '\0';
				break;
			}
		}
		PushArrayString(_blacklist, line);
	}
	
	CloseHandle(file);
}

void String_Rainbow(const char[] input, char[] output, int maxLen)
{
	int bytes, buffs;
	int size = strlen(input)+1;
	char[] copy = new char [size];

	for(int x = 0; x < size; ++x)
	{
		if(input[x] == '\0')
			break;
		
		if(buffs == 2)
		{
			strcopy(copy, size, input);
			copy[x+1] = '\0';
			output[bytes] = RandomColor();
			bytes++;
			bytes += StrCat(output, maxLen, copy[x-buffs]);
			buffs = 0;
			continue;
		}

		if(!IsChar(input[x]))
		{
			buffs++;
			continue;
		}

		strcopy(copy, size, input);
		copy[x+1] = '\0';
		output[bytes] = RandomColor();
		bytes++;
		bytes += StrCat(output, maxLen, copy[x]);
	}

	output[++bytes] = '\0';
}

bool IsChar(char c)
{
	if(0 <= c <= 126)
		return true;
	
	return false;
}

int RandomColor()
{
	switch(GetRandomInt(1, 16))
	{
		case  1: return '\x01';
		case  2: return '\x02';
		case  3: return '\x03';
		case  4: return '\x03';
		case  5: return '\x04';
		case  6: return '\x05';
		case  7: return '\x06';
		case  8: return '\x07';
		case  9: return '\x08';
		case 10: return '\x09';
		case 11: return '\x10';
		case 12: return '\x0A';
		case 13: return '\x0B';
		case 14: return '\x0C';
		case 15: return '\x0E';
		case 16: return '\x0F';
	}

	return '\x01';
}

////////////////////
// Chat hook
public Action OnClientSayCommand(int client, const char[] command, const char[] sArgs)
{
	if (StrContains(command, "say") == -1)return;
	
	if(StrEqual(g_sColorChattag[client], "rainbow") && !StrEqual(g_sChattag[client], "none"))
	{
		ChatProcessor_RemoveClientTag(client, g_sChattag[client]);
		
		char newbuffer[128];
		String_Rainbow(g_sChattag[client], newbuffer, 128);
		strcopy(_temp[client], 128, newbuffer);
		
		ChatProcessor_AddClientTag(client, _temp[client]);
		
	}
}

public void OnClientSayCommand_Post(int client, const char[] command, const char[] sArgs)
{
	if (StrContains(command, "say") == -1)return;
	
	if(StrEqual(g_sColorChattag[client], "rainbow") && !StrEqual(g_sChattag[client], "none"))
	{
		ChatProcessor_RemoveClientTag(client, _temp[client]);
		
		ChatProcessor_AddClientTag(client, g_sChattag[client]);
		
	}
}