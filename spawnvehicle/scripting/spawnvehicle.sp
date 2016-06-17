//  Spawn a Vehicle (C) 2009 Jonah Hirsch, 2014-2016 Sarabveer Singh <me@sarabveer.me>
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
#tryinclude <updater>

#define PLUGIN_VERSION "1.5.3"
#define UPDATE_URL    "https://raw.githubusercontent.com/Sarabveer/SM-Plugins/master/spawnvehicle/updater.txt"

new String:spawncommand[128]
new commandFlag

public Plugin:myinfo = 
{
	name = "Spawn a vehicle",
	author = "Crazydog, Sarabveer(VEER™)",
	description = "Spawns a vehicle where someone is looking in Synergy",
	version = PLUGIN_VERSION,
	url = "http://theelders.net"
}


public OnPluginStart(){
	RegConsoleCmd("sm_spawnvehicle", Command_SpawnVehicle, "spawn a vehicle")

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

public Action:Command_SpawnVehicle(client, args){
	new String:name[128], String:vehicle[32], String:command[256]
	GetCmdArg(1, name, sizeof(name))
	GetCmdArg(2, vehicle, sizeof(vehicle))
	if (strcmp(vehicle, "van") == 0){
		spawncommand = "ch_createvehicle"
		commandFlag = GetCommandFlags(spawncommand)
		SetCommandFlags(spawncommand, (commandFlag & ~FCVAR_CHEAT))
		Format(command, sizeof(command),"sm_fexec \"%s\" \"ch_createvehicle prop_vehicle_mp models/vehicles/7seatvan.mdl scripts/vehicles/van.txt\"", name)
	}
	if (strcmp(vehicle, "truck") == 0){
		spawncommand = "ch_createvehicle"
		commandFlag = GetCommandFlags(spawncommand)
	   	SetCommandFlags(spawncommand, (commandFlag & ~FCVAR_CHEAT))
		Format(command, sizeof(command),"sm_fexec \"%s\" \"ch_createvehicle prop_vehicle_mp models/vehicles/8seattruck.mdl scripts/vehicles/truck.txt\"", name)
	}
	if (strcmp(vehicle, "jeep") == 0){
		spawncommand = "ch_createvehicle"
		commandFlag = GetCommandFlags(spawncommand)
		SetCommandFlags(spawncommand, (commandFlag & ~FCVAR_CHEAT))
		Format(command, sizeof(command),"sm_fexec \"%s\" \"ch_createvehicle prop_vehicle_jeep models/vehicles/buggy_p2.mdl scripts/vehicles/jeep_test.txt\"", name)
	}
	if (strcmp(vehicle, "airboat") == 0){
		spawncommand = "ch_createairboat"
		commandFlag = GetCommandFlags(spawncommand)
		SetCommandFlags(spawncommand, (commandFlag & ~FCVAR_CHEAT))
		Format(command, sizeof(command),"sm_fexec \"%s\" ch_createairboat", name)
	}
	if (strcmp(vehicle, "jalopy") == 0){
		spawncommand = "ch_createjalopy"
		commandFlag = GetCommandFlags(spawncommand)
		SetCommandFlags(spawncommand, (commandFlag & ~FCVAR_CHEAT))
		Format(command, sizeof(command),"sm_fexec \"%s\" ch_createjalopy", name)
	}
	ServerCommand(command)
	CreateTimer(0.5, returnFlag)
	return Plugin_Handled
}

public Action:returnFlag(Handle:timer){
	PrintToChatAll("returning flags")
	SetCommandFlags(spawncommand, (GetCommandFlags(spawncommand)|FCVAR_CHEAT))
}