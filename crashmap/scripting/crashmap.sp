//  CrashMap (C) 2014-2016 Sarabveer Singh <me@sarabveer.me>
//  
//  CrashMap is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, per version 3 of the License.
//  
//  CrashMap is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//  
//  You should have received a copy of the GNU General Public License
//  along with CrashMap. If not, see <http://www.gnu.org/licenses/>.

#include <sourcemod>
#tryinclude <updater>

#define UPDATE_URL    "https://raw.githubusercontent.com/Sarabveer/SM-Plugins/master/crashmap/updater.txt"

#define PLUGIN_VERSION "0.3"

public Plugin:myinfo = 
{
	name = "Crashed Map Recovery", 
	author = "Sarabveer(VEER™)", 
	description = "Restores the Map Running before Server crash", 
	version = PLUGIN_VERSION, 
	url = "https://www.sarabveer.me"
}

new Handle:g_hDB;
new Handle:g_hStatement;

public OnPluginStart()
{
	CreateConVar("sm_crashedmap_version", PLUGIN_VERSION, "CrashMap Plugin Version", FCVAR_SPONLY | FCVAR_NOTIFY | FCVAR_DONTRECORD);
	SQL_TConnect(TConnect, "storage-local");
	
	if (LibraryExists("updater"))
	{
		Updater_AddPlugin(UPDATE_URL)
	}
}

public OnLibraryAdded(const String:name[])
{
	if (StrEqual(name, "updater"))
	{
		Updater_AddPlugin(UPDATE_URL)
	}
}

public TConnect(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if (hndl == INVALID_HANDLE)
	{
		SetFailState("error: %s", error);
	}
	
	g_hDB = hndl;
	
	/* 
CREATE  TABLE  IF NOT EXISTS 'maps' ('map' VARCHAR PRIMARY KEY  NOT NULL , 'time' DATETIME DEFAULT CURRENT_TIMESTAMP, 'loaded' BOOL) 
*/
	SQL_LockDatabase(g_hDB);
	SQL_FastQuery(g_hDB, "CREATE  TABLE  IF NOT EXISTS 'maps' ('map' VARCHAR PRIMARY KEY  NOT NULL , 'time' DATETIME DEFAULT CURRENT_TIMESTAMP, 'loaded' BOOL)");
	SQL_UnlockDatabase(g_hDB);
	
	/* 
INSERT OR REPLACE INTO 'maps' ('map','loaded') VALUES ('d1_trainstation_01' , 1) 
*/
	new String:buffer[256];
	g_hStatement = SQL_PrepareQuery(g_hDB, "INSERT OR REPLACE INTO 'maps' ('map','loaded') VALUES (? , ?)", buffer, sizeof(buffer));
	
	if (g_hStatement == INVALID_HANDLE)
	{
		//PrintToServer("g_hStatement error: %s", buffer); 
	}
	
	//PrintToServer("connect"); 
	/* SELECT * FROM maps ORDER BY time DESC LIMIT 0 , 2*/
	SQL_TQuery(g_hDB, TQuery, "SELECT map, loaded FROM maps ORDER BY time DESC LIMIT 0 , 2");
}

public TQuery(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	new String:buffer[MAX_NAME_LENGTH], loaded;
	while (SQL_FetchRow(hndl))
	{
		SQL_FetchString(hndl, 0, buffer, sizeof(buffer));
		loaded = SQL_FetchInt(hndl, 1);
		//PrintToServer("buffer %s %i", buffer, loaded); 
		
		if (loaded)
		{
			ServerCommand("changelevel %s", buffer);
			LogMessage("[CrashMap] Changed map to %s after crash!", buffer);
			break;
		}
	}
}

public OnMapStart()
{
	if (g_hDB == INVALID_HANDLE)
	{
		return;
	}
	
	new String:query[256];
	GetCurrentMap(query, sizeof(query));
	SQL_BindParamString(g_hStatement, 0, query, false);
	SQL_BindParamInt(g_hStatement, 1, 0);
	
	SQL_LockDatabase(g_hDB);
	SQL_Execute(g_hStatement);
	SQL_UnlockDatabase(g_hDB);
	
	CreateTimer(30.0, update, _, TIMER_FLAG_NO_MAPCHANGE);
	//PrintToServer("insert %s", query); 
}

public Action:update(Handle:timer)
{
	new String:query[256];
	GetCurrentMap(query, sizeof(query));
	SQL_BindParamString(g_hStatement, 0, query, false);
	SQL_BindParamInt(g_hStatement, 1, 1);
	
	SQL_LockDatabase(g_hDB);
	SQL_Execute(g_hStatement);
	SQL_UnlockDatabase(g_hDB);
	//PrintToServer("update %s", query); 
} 