//  Spawn a Vehicle (C) 2009 Jonah Hirsch, 2014-2017 Sarabveer Singh <me@sarabveer.me>
//  
//  Spawn a Vehicle is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, per version 3 of the License.
//  
//  Spawn a Vehicle is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//  
//  You should have received a copy of the GNU General Public License
//  along with Spawn a Vehicle. If not, see <http://www.gnu.org/licenses/>.

#include <sourcemod>
#include <sdktools>

#undef REQUIRE_PLUGIN
#include <updater>
#define REQUIRE_PLUGIN

#define PLUGIN_VERSION "1.6"
#define UPDATE_URL    "https://raw.githubusercontent.com/Sarabveer/SM-Plugins/master/spawnvehicle/updater.txt"

new String:spawncommand[128]
new commandFlag

public Plugin:myinfo = 
{
	name = "Spawn a vehicle",
	author = "Crazydog, Sabertooth13",
	description = "Spawns a vehicle where someone is looking in Synergy",
	version = PLUGIN_VERSION,
	url = "http://game.sarabveer.me"
}

public OnPluginStart() {
	RegConsoleCmd("sm_spawnvehicle", Command_SpawnVehicle, "Spawn a Vehicle")
	LoadTranslations("common.phrases")
	if (LibraryExists("updater"))
	{
		Updater_AddPlugin(UPDATE_URL)
	}
}

public OnLibraryAdded(const String:name[]) {
	if (StrEqual(name, "updater"))
	{
		Updater_AddPlugin(UPDATE_URL)
	}
}

public Action:Command_SpawnVehicle(client, args) {
	new String:arg[128], String:vehicle[32], String:command[256]
	GetCmdArg(1, arg, sizeof(arg))
	GetCmdArg(2, vehicle, sizeof(vehicle))
	new target = FindTarget(client, arg)
	if (target == -1) {
		return Plugin_Handled;
	}
	if (strcmp(vehicle, "van") == 0) {
		spawncommand = "ch_createvehicle"
		commandFlag = GetCommandFlags(spawncommand)
		SetCommandFlags(spawncommand, (commandFlag & ~FCVAR_CHEAT))
		Format(command, sizeof(command), "ch_createvehicle prop_vehicle_mp models/vehicles/7seatvan.mdl scripts/vehicles/van.txt")
	}
	if (strcmp(vehicle, "truck") == 0) {
		spawncommand = "ch_createvehicle"
		commandFlag = GetCommandFlags(spawncommand)
	   	SetCommandFlags(spawncommand, (commandFlag & ~FCVAR_CHEAT))
		Format(command, sizeof(command), "ch_createvehicle prop_vehicle_mp models/vehicles/8seattruck.mdl scripts/vehicles/truck.txt")
	}
	if (strcmp(vehicle, "jeep") == 0) {
		spawncommand = "ch_createvehicle"
		commandFlag = GetCommandFlags(spawncommand)
		SetCommandFlags(spawncommand, (commandFlag & ~FCVAR_CHEAT))
		Format(command, sizeof(command), "ch_createvehicle prop_vehicle_jeep models/vehicles/buggy_p2.mdl scripts/vehicles/jeep_test.txt")
	}
	if (strcmp(vehicle, "jeep_elite") == 0) {
		spawncommand = "ch_createvehicle"
		commandFlag = GetCommandFlags(spawncommand)
	   	SetCommandFlags(spawncommand, (commandFlag & ~FCVAR_CHEAT))
		Format(command, sizeof(command), "ch_createvehicle prop_vehicle_mp models/vehicles/buggy_elite.mdl scripts/vehicles/jeep_elite.txt")
	}
	if (strcmp(vehicle, "airboat") == 0) {
		spawncommand = "ent_create"
		commandFlag = GetCommandFlags(spawncommand)
		SetCommandFlags(spawncommand, (commandFlag & ~FCVAR_CHEAT))
		Format(command, sizeof(command), "ent_create prop_vehicle_airboat model models/airboat.mdl vehiclescript scripts/vehicles/airboat.txt EnableGun 1")
	}
	if (strcmp(vehicle, "jalopy") == 0) {
		char curmap[32]
		GetCurrentMap(curmap, sizeof(curmap))
		if (StrContains(curmap, "ep2_", false) == -1) {
			PrintToChat(client, "[ERROR] Not In HL2: Episode 2")
			return Plugin_Handled;
		} else {
			spawncommand = "ch_createjalopy"
			commandFlag = GetCommandFlags(spawncommand)
			SetCommandFlags(spawncommand, (commandFlag & ~FCVAR_CHEAT))
			Format(command, sizeof(command), "ch_createjalopy")
		}
	}
	FakeClientCommandEx(target, command)
	CreateTimer(0.5, returnFlag)
	return Plugin_Handled;
}

public Action:returnFlag(Handle:timer) {
	PrintToChatAll("[INFO] Spawning Car...")
	SetCommandFlags(spawncommand, (GetCommandFlags(spawncommand) | FCVAR_CHEAT))
}
