//	HyperSpawn Beta (C) 2014 PsychoProject, 2014-2016 Sarabveer Singh <me@sarabveer.me>
//  
//  HyperSpawn Beta is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, per version 3 of the License.
//  
//  HyperSpawn Beta is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//  
//  You should have received a copy of the GNU General Public License
//  along with HyperSpawn Beta. If not, see <http://www.gnu.org/licenses/>.

#include <sourcemod>
#include <sdktools>
#undef REQUIRE_PLUGIN
#include <updater>
#define REQUIRE_PLUGIN

#define PLUGIN_VERSION  "1.9.4"
#define UPDATE_URL    "https://raw.githubusercontent.com/Sarabveer/SM-Plugins/master/hyperspawn/updater.txt"

public Plugin:myinfo =
{
	name = "HyperSpawn Beta",
	author = "PsychoNightmare, Sarabveer(VEER™)",
	description ="Instant respawn with teleporting to random players",
	version = PLUGIN_VERSION,
	url = "http://steamcommunity.com/profiles/76561198002438403"
}

new Handle:hyperspawn
new Handle:hyperspawn_time
new Handle:hyperspawn_teleport
new Handle:hyperspawn_carcheck
new Handle:hyperspawn_duckcheck
new Handle:hyperspawn_mustbealive
new bool:canSpawn[MAXPLAYERS+1]
new Handle:equiparr


public OnPluginStart()
{
	CreateConVar("sm_hyperspawn_version", PLUGIN_VERSION, "HyperSpawn Plugin Version", FCVAR_SPONLY | FCVAR_NOTIFY | FCVAR_DONTRECORD);
	hyperspawn = CreateConVar("hyperspawn","1","Enables instant player respawn [hyperspawn_time] second(s) after death.",_,true,0.0,true,1.0)
	hyperspawn_time = CreateConVar("hyperspawn_time","3","Set's how long a player needs to wait before respawning.",_,true,0.1,true,5.0)
	hyperspawn_teleport = CreateConVar("hyperspawn_teleport", "1", "Automatically teleports players to another player on respawn.", _, true, 0.0, true, 1.0)
	hyperspawn_carcheck = CreateConVar("hyperspawn_carcheck", "1", "Checks if the client is in a car, and denies teleporting if they are.", _, true, 0.0, true, 1.0)
	hyperspawn_duckcheck = CreateConVar("hyperspawn_duckcheck", "0", "Checks if the client is ducked, and denies teleporting if they are.(only use if needed)", _, true, 0.0, true, 1.0)
	hyperspawn_mustbealive = CreateConVar("hyperspawn_one_alive", "0", "Requires a single player to be alive to allow respawning", _, true, 0.0 ,true, 1.0)
	AutoExecConfig(true)
	HookEvent("player_death", Event_Death)
	HookEvent("player_spawn", Event_Spawn)
	equiparr = CreateArray(32)
	
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

public Action:Event_Spawn (Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"))
	canSpawn[client]=false
	return Plugin_Continue
}

public Action:OnPlayerRunCmd(client, &Buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	if(canSpawn[client] && IsClientInGame(client) && GetConVarBool(hyperspawn))
	{
		if(Buttons & IN_FORWARD||Buttons & IN_MOVELEFT||Buttons & IN_BACK||Buttons & IN_MOVERIGHT)
		{
			if(GetConVarBool(hyperspawn_teleport)==true  && !IsPlayerAlive(client))
			{
				Hyperspawn(client)
			}
			else
			{
				RapidSpawn(client)

			}
		}
	}	
	return Plugin_Continue
}


public Action:Event_Death(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"))
	// Players have userids, if person with specific userid is still in game, we get rigth client index, otherwise 0 error
	if(client != 0)
	{
		CreateTimer(GetConVarFloat(hyperspawn_time),AllowSpawn,client)
	}
	return Plugin_Continue
}

public Action:AllowSpawn(Handle:timer, any:client)
{
	canSpawn[client]=true
}

Hyperspawn(client)
{
	if(ArePlayersAlive(client) || GetConVarBool(hyperspawn_mustbealive)==false)
	{
		new target = TargetCheck(client)
		
		RapidSpawn(client)
		if(target == -1)
		{
			return
		}
		if (GetEntProp(target, Prop_Data, "m_bDucked", 1) == 1) //Checks if target is ducked
		{
			SetEntProp(client, Prop_Send, "m_bDucking", 1, 1) //Sets client in ducked position
		}
		
		new String:tname[64]
		GetClientName(target, tname, sizeof(tname))
		PrintToChat(client, "[HyperSpawn] Spawned on %s", tname)
		new Float:origin[3]
		GetEntPropVector(target, Prop_Send, "m_vecOrigin", origin)
		TeleportEntity(client, origin, NULL_VECTOR, NULL_VECTOR)
		findent(MaxClients+1, "info_player_equip")
		for (int j; j < GetArraySize(equiparr); j++)
		{
			int jtmp = GetArrayCell(equiparr, j);
			if (IsValidEntity(jtmp)) {
				AcceptEntityInput(jtmp, "EquipPlayer", client)
			}
		}
		ClearArray(equiparr)
	}
	return
}

findent(int ent, char[] clsname)
{
	int thisent = FindEntityByClassname(ent, clsname)
	if ((IsValidEntity(thisent)) && (thisent >= MaxClients+1) && (thisent != -1))
	{
		PushArrayCell(equiparr, ent)
		findent(thisent++, clsname)
	}
}

RapidSpawn(client)
{
	if(ArePlayersAlive(client) || GetConVarBool(hyperspawn_mustbealive)==false)
	{
		canSpawn[client]=false
		DispatchSpawn(client)
	}
	return
}

TargetCheck(client)
{
	new target
	new duckcheck = 0
	new carcheck = 0

	new runcount
	runcount = 0
	do
	{
		runcount++
		//grab random player
		new AllPlayers = GetClientCount(true)
		target = GetRandomInt(1, AllPlayers)
						
		//check for self targeting // I'm not sure what you are going to accomplish here  :D
		if(client != target && IsClientInGame(target) && IsPlayerAlive(target))
		{
			//car checking
			if(GetConVarBool(hyperspawn_carcheck)==true && GetEntPropEnt(target, Prop_Send, "m_hVehicle") != -1)
			{
				carcheck = 1
			}
			else							
			{
				carcheck = 0
			}
			//duck checking
			if(GetConVarBool(hyperspawn_duckcheck)==true && GetEntProp(target, Prop_Data, "m_bDucked", 1) == 1)
			{
				duckcheck = 1
			}
			else
			{
				duckcheck = 0
			}
		}
		if(runcount >= 50)
		{
			PrintToChat(client, "[CAUTION] All Player(s) are Non-Targetable For Spawn")
			return -1
		}
	}
	while(client==target || !IsClientInGame(target) || !IsPlayerAlive(target) || target == -1 || carcheck == 1 || duckcheck == 1)
	return target
}

stock bool:ArePlayersAlive(client)
{
	new count

	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && IsPlayerAlive(i))
		{
			count++
		}
	}

	return (count > 0)
}
