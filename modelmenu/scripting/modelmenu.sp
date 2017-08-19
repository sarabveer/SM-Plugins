//  Model Menu (C) 2014-2016 Sarabveer Singh <me@sarabveer.me>
//  
//  Model Menu is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, per version 3 of the License.
//  
//  Model Menu is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//  
//  You should have received a copy of the GNU General Public License
//  along with Model Menu. If not, see <http://www.gnu.org/licenses/>.

#include <sourcemod>
#include <sdktools>
#tryinclude <updater>

#define UPDATE_URL    "https://raw.githubusercontent.com/Sarabveer/SM-Plugins/master/modelmenu/updater.txt"

public Plugin:myinfo =
{
	name = "Model Menu",
	author = "Sarabveer(VEER™)",
	description = "Simple Model Menu",
	version = "0.4",
	url = "https://www.sarabveer.me"
}

new Handle:model_name;
new Handle:model_path;

public OnPluginStart()
{
	new String:file[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, file, sizeof(file), "configs/models.txt");

	if(!FileExists(file))
	{
		SetFailState("[ModelMenu] Unable to Load File: %s", file);
	}

	model_name = CreateArray(ByteCountToCells(MAX_NAME_LENGTH));
	model_path = CreateArray(ByteCountToCells(PLATFORM_MAX_PATH));

	new Handle:smc = SMC_CreateParser();
	SMC_SetReaders(smc, ns, kv, es);
	SMC_ParseFile(smc, file);

	RegConsoleCmd("sm_models", modelmenu);
	
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

public SMCResult:ns(Handle:smc, const String:name[], bool:opt_quotes){}
public SMCResult:kv(Handle:smc, const String:key[], const String:value[], bool:key_quotes, bool:value_quotes)
{
	new dot = FindCharInString(value, '.', true);

	if(StrEqual(value[dot], ".mdl", false) && FileExists(value, true))
	{
		PushArrayString(model_name, key);
		PushArrayString(model_path, value);
		//PrintToServer("%s %s", key, value)
	}
}
public SMCResult:es(Handle:smc){}

public Action:modelmenu(client, args)
{

	new Handle:menu = CreateMenu(menu_handler);
	SetMenuTitle(menu, "Models");

	new array_size = GetArraySize(model_name);
	new String:name[MAX_NAME_LENGTH];
	new String:path[PLATFORM_MAX_PATH];

	for(new a = 0; a < array_size; a++)
	{
		GetArrayString(model_name, a, name, sizeof(name));
		GetArrayString(model_path, a, path, sizeof(path));

		AddMenuItem(menu, path, name);
	}
	DisplayMenu(menu, client, 60);
	return Plugin_Handled;
}

public menu_handler(Handle:menu, MenuAction:action, client, modelt)
{
	switch(action)
	{
		case MenuAction_End:
		{
			CloseHandle(menu);
		}
		case MenuAction_Select:
		{
			new String:model[PLATFORM_MAX_PATH];
			GetMenuItem(menu, modelt, model, sizeof(model));
			PrecacheModel(model);
			SetEntityModel(client, model);
			ClientCommand(client, "cl_playermodel %s", model);
			modelmenu(client, 0);
		}
	}
}
