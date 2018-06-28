//  Synergy Model Menu (C) 2014-2017 Sarabveer Singh <me@sarabveer.me>
//  
//  Synergy Model Menu is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, per version 3 of the License.
//  
//  Synergy Model Menu is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//  
//  You should have received a copy of the GNU General Public License
//  along with Model Menu. If not, see <http://www.gnu.org/licenses/>.

#include <sourcemod>
#include <sdktools>
#include <clientprefs>

#undef REQUIRE_PLUGIN
#include <updater>
#define REQUIRE_PLUGIN

new Handle:mainmenu
new Handle:kv
new Handle:g_hClientCookie

new String:authid[MAXPLAYERS+1][35]

#define PLUGIN_VERSION "2.0"

#define UPDATE_URL    "https://raw.githubusercontent.com/Sarabveer/SM-Plugins/master/modelmenu/updater.txt"

public Plugin:myinfo = 
{
	name = "Synergy Model Menu",
	author = "Sabertooth13",
	description = "Menu to Select Player Models",
	version = PLUGIN_VERSION,
	url = "http://game.sarabveer.me"
};

public OnPluginStart() {
	RegConsoleCmd("sm_models", Command_Model)
	CreateConVar("sm_modelmenu_version", PLUGIN_VERSION, "Synergy Model Menu Version", FCVAR_SPONLY | FCVAR_REPLICATED | FCVAR_NOTIFY)
	HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Post)
	
	g_hClientCookie = RegClientCookie("UserPlayerModel", "Store Player Chosen Model", CookieAccess_Protected)
	
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

public OnMapStart() {
	mainmenu = BuildMainMenu()
}

Handle:BuildMainMenu()
{
	/* Create the menu Handle */
	new Handle:menu = CreateMenu(Menu_Group)
	kv = CreateKeyValues("Commands")
	new String:file[256]
	BuildPath(Path_SM, file, 255, "configs/models.ini")
	FileToKeyValues(kv, file)
	if (!KvGotoFirstSubKey(kv)) {
		return INVALID_HANDLE
	}
	decl String:buffer[30]
	decl String:path[100]
	do {
		KvGetSectionName(kv, buffer, sizeof(buffer))
		AddMenuItem(menu, buffer, buffer)
		KvGotoFirstSubKey(kv)
		do {
			KvGetString(kv, "path", path, sizeof(path),"")
			if (FileExists(path)) {
				PrecacheModel(path, true)
			}
		} while (
			KvGotoNextKey(kv)
		)
		KvGoBack(kv)
	} while (
		KvGotoNextKey(kv)
	)
	KvRewind(kv)
	SetMenuTitle(menu, "Choose a Model")
	return menu
}

public OnMapEnd() {
	CloseHandle(kv)
	CloseHandle(mainmenu)
}

public OnClientPutInServer(client) {
	GetClientAuthId(client, AuthId_Steam2, authid[client], sizeof(authid[]))
}

public Action:Command_Model(client,args) {
	if (mainmenu == INVALID_HANDLE) {
		PrintToConsole(client, "There was an error generating the menu. Check your models.ini file.")
		return Plugin_Handled
	}
	DisplayMenu(mainmenu, client, MENU_TIME_FOREVER)
	return Plugin_Handled
}

public Menu_Group(Handle:menu, MenuAction:action, param1, param2) {
	// user has selected a model group
	if (action == MenuAction_Select) {
		new String:info[30]
		/* Get item info */
		new bool:found = GetMenuItem(menu, param2, info, sizeof(info))
		if (!found) {
			return
		}
		// user selected a group
		// advance kv to this group
		KvJumpToKey(kv, info)
		// build menu
		// name - path
		KvGotoFirstSubKey(kv)
		new Handle:tempmenu = CreateMenu(Menu_Model)
		decl String:buffer[30]
		decl String:path[256]
		do {
			KvGetSectionName(kv, buffer, sizeof(buffer))
			KvGetString(kv, "path", path, sizeof(path),"")
			AddMenuItem(tempmenu, path, buffer)
		} while (
			KvGotoNextKey(kv)
		)
		SetMenuTitle(tempmenu, "Choose a Model")
		KvRewind(kv)
		DisplayMenu(tempmenu, param1, MENU_TIME_FOREVER)
	}
}

public Menu_Model(Handle:menu, MenuAction:action, param1, param2) {
	//user choose a model
	if (action == MenuAction_Select) {
		new String:info[256]
		/* Get item info */
		new bool:found = GetMenuItem(menu, param2, info, sizeof(info))	
		if (!found) {
			return
		}
		// set users model
		// insert magic here.
		if (!StrEqual(info, "") && IsModelPrecached(info) && IsClientConnected(param1)) {
			if (StrContains(info, "models/player/rebel", false) == 0) {
				new String:tmpmdl[64]
				Format(tmpmdl,sizeof(tmpmdl), info)
				ReplaceString(tmpmdl, sizeof(tmpmdl), "models/player/rebel", "models/player/normal", false);
				ClientCommand(param1, "cl_playermodel \"%s\"", tmpmdl);
			} else {
				ClientCommand(param1, "cl_playermodel \"%s\"", info)
			}
			SetEntityModel(param1, info)
			SetClientCookie(param1, g_hClientCookie, info);
		}
	}
	if (action == MenuAction_End) {
		CloseHandle(menu)
	}
}

public Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast) {
	new clientId = GetEventInt(event, "userid")
	new client = GetClientOfUserId(clientId)
	new String:model[512]
	GetClientCookie(client, g_hClientCookie, model, sizeof(model))
	if (!StrEqual(model, "") && IsModelPrecached(model)) {
		if (StrContains(model, "models/player/rebel", false) == 0) {
			new String:tmpmdl[64]
			Format(tmpmdl, sizeof(tmpmdl), model)
			ReplaceString(tmpmdl, sizeof(tmpmdl), "models/player/rebel", "models/player/normal", false)
			ClientCommand(client, "cl_playermodel \"%s\"", tmpmdl)
		} else {
			ClientCommand(client, "cl_playermodel \"%s\"", model)
		}
		CreateTimer(2.0, modelspawn, client)
	}
}

public Action:modelspawn(Handle timer, any client) {
	if (IsClientInGame(client) && IsPlayerAlive(client) && !IsFakeClient(client)) {
		new String:model[512]
		GetClientCookie(client, g_hClientCookie, model, sizeof(model))
		SetEntityModel(client, model);
	} else if (IsClientConnected(client)) {
		CreateTimer(1.0, modelspawn, client)
	}
}
