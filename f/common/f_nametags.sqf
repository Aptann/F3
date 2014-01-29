// F3 - Nametags
// Credits: Please see the F3 online manual (http://www.ferstaberinde.com/f3/en/)
// ====================================================================================

// JIP CHECK
// Prevents the script executing until the player has synchronised correctly:

#include "f_waitForJIP.sqf"

// ====================================================================================

// SET GLOBAL VARIABLES

// MODIFYABLE
F_SHOWDISTANCE_NAMETAGS = false; // Show distance to player
F_SHOWVEHICLE_NAMETAGS = false; // Show vehicle player is in

F_SIZE_NAMETAGS = 0.04; // The size the names are displayed in
F_HEIGHT_NAMETAGS = 0; // The height of the name tags for infantry (0 = hovering over unit, -1 = about belt height)
F_VHEIGHT_NAMETAGS = 0; // The height of the name tags for units in vehicles (0 = hovering over vehicle)

F_COLOR_NAMETAGS =  [1,1,1,0.9]; // The color for infantry and units in vehicle cargo (in [red,green, blue, opacity])
F_COLOR_NAMETAGS_GROUP = [0,1,0.7,0.9];
F_COLOR2_NAMETAGS = [0.5,0.1,0.2,0.9]; // The color for units in driver, gunner and other vehicle positions positions

F_FONT_NAMETAGS = "EtelkaMonospaceProBold"; // Font for the names
F_KEY_NAMETAGS =  "TeamSwitch"; // The action key that will be used to toggle the name tags. See possible keys here: http://community.bistudio.com/wiki/Category:Key_Actions

// SCRIPTSIDE
F_DIST_NAMETAGS = _this select 0;
F_DRAW_NAMETAGS = false;
F_ACTIONKEY_NAMETAGS = (actionKeys F_KEY_NAMETAGS) select 0;
F_KEYNAME_NAMETAGS = actionKeysNames F_KEY_NAMETAGS;
if (isNil "F_ACTIONKEY_NAMETAGS") then {F_ACTIONKEY_NAMETAGS = 20; F_KEYNAME_NAMETAGS = 'T';}; // If the user has not bound 'TeamSwitch' to a key we default to 'T' to toggle the tags

waitUntil {isNull (findDisplay 46)}; // some misc functions for toggleing nametags
F_KEYUP_NAMETAG = {
	_key = _this select 1;
	_handeld = false;
	if(_key == F_ACTIONKEY_NAMETAGS) then
	{
		_handeld = true;
	};
	_handeld;
};

F_KEYDOWN_NAMETAG = {
	_key = _this select 1;
	_handeld = false;
	if(_key == F_ACTIONKEY_NAMETAGS) then
	{
		F_DRAW_NAMETAGS = !F_DRAW_NAMETAGS;
		_handeld = true;
	};
	_handeld;
};
// ====================================================================================

// ADD BRIEFING SECTION
// A section is added to the player's briefing to inform them about name tags being available.

[] spawn {
waitUntil {scriptDone f_script_briefing};

_bstr = format ["<br/>You can toggle name tags for friendly units on and off by pressing %1. This will display all player names in a distance of %3 m.<br/><br/>

If you do not have an key bound for %2 this will be 'T' by default. If you want to bind the toggle to a different key bind your %2 key and click
<execute expression=""
F_ACTIONKEY_NAMETAGS = (actionKeys F_KEY_NAMETAGS) select 0;
F_KEYNAME_NAMETAGS = actionKeysNames F_KEY_NAMETAGS;
if (isNil 'F_ACTIONKEY_NAMETAGS') then {F_ACTIONKEY_NAMETAGS = 20; F_KEYNAME_NAMETAGS = 'T';};
hintsilent 'Team switch key rebound!';
"">here</execute>.
",F_KEYNAME_NAMETAGS, F_KEY_NAMETAGS,F_DIST_NAMETAGS];

if (F_SHOWDISTANCE_NAMETAGS) then {
_bstr = _bstr + "<br/><br/>Units will display the relative distance to the player next to their name. To toggle this behaviour click <execute expression=""
if (F_SHOWDISTANCE_NAMETAGS) then {hintsilent 'Distance display deactivated!';F_SHOWDISTANCE_NAMETAGS= false} else {F_SHOWDISTANCE_NAMETAGS = true;hintsilent 'Distance display activated!'};""
>here</execute>."
};

if (F_SHOWVEHICLE_NAMETAGS) then {
_bstr = _bstr + "<br/><br/>Mounted units will display their vehicle next to their name. To toggle this behaviour click <execute expression=""
if (F_SHOWVEHICLE_NAMETAGS) then {hintsilent 'Display of vehicle type deactivated!';F_SHOWVEHICLE_NAMETAGS= false} else {F_SHOWVEHICLE_NAMETAGS = true;hintsilent 'Display of vehicle typ activated!'};""
>here</execute>."
};

player createDiaryRecord ["Diary", ["NameTags",_bstr]];

// NOTIFY PLAYER ABOUT NAMETAGS VIA HINT
sleep 5;
hintsilent format ["Press %1 to toggle name tags", F_KEYNAME_NAMETAGS ];
};

// ====================================================================================

// ADD EVENTHANDLERS
// After the mission has initialized eventhandlers are added to the register keypresses.

sleep 0.1;

(findDisplay 46) displayAddEventHandler   ["keyup", "_this call F_KEYUP_NAMETAG"];
(findDisplay 46) displayAddEventHandler   ["keydown", "_this call F_KEYDOWN_NAMETAG"];

// ====================================================================================
// the real code.

addMissionEventHandler ["Draw3D", {

// A function to create the string for the name tags on demand
_fnc_createString = {
	private ["_u","_prefix","_cargo","_str"];
	_u = _this select 0;
	_prefix = "";
	_cargo = "";
	if (count _this > 1) then {_prefix = _this select 1};
	if (count _this > 2) then {_cargo = _this select 2};

	_str = name _u;

	if (F_SHOWDISTANCE_NAMETAGS) then {_str = _str + format [" (%1 m)",round (_pos distance player)]};
	if (F_SHOWVEHICLE_NAMETAGS && !(typeOf (vehicle _u) isKindof "Man")) then {_str = _str + format [" (%1)",getText (configFile >> "CfgVehicles" >> (typeOf _veh) >> "displayname")]};

	if (_prefix != "") then {_str = _prefix + _str};
	if (_cargo != "") then {_str = _str + _cargo};

	_str
};

if(F_DRAW_NAMETAGS) then
{

_ents = (position player) nearEntities [["CAManBase","LandVehicle","Helicopter","Plane","Ship_F"], F_DIST_NAMETAGS];
{
	if(side _x == side player && _x != player) then
	{
		if(typeof _x iskindof "Man") then
		{

				_pos = visiblePosition _x;

				_color = F_COLOR_NAMETAGS;
				if(_x in units player) then { _color = F_COLOR_NAMETAGS_GROUP };

				drawIcon3D ["", _color, [_pos select 0,_pos select 1,(getPosATL _x select 2) + 2 + F_HEIGHT_NAMETAGS], 0, 0, 0, [_x] call _fnc_createString, 0,F_SIZE_NAMETAGS, F_FONT_NAMETAGS];
		}
		else
		{
			_veh = _x;
			_inc = 1;
			_alternate = 0;
			_prefix = "";

			{
			  _prefix = "P: ";
				_color = F_COLOR_NAMETAGS;
				if(driver _veh == _x) then
				{
					_prefix = "D: ";
					_color = F_COLOR2_NAMETAGS;
				};
				if(gunner _veh == _x) then
				{
				_prefix = "G: ";
					_color = F_COLOR2_NAMETAGS;
				};
				if(commander _veh == _x) then
				{
					_prefix = "C: ";
					_color = F_COLOR2_NAMETAGS;
				};
				if(assignedVehicleRole _x select 0 == "Turret" && commander _veh != _x && gunner _veh != _x && driver _veh != _x) then
				{
					_prefix = "G: ";
					_color = F_COLOR2_NAMETAGS;
				};

				_pos = visiblePosition _x;


				if(_pos distance (visiblePosition (driver _veh)) > 0.1 || driver _veh == _x) then
				{
					if(driver _veh == _x) then
					{
						_maxSlots = getNumber(configfile >> "CfgVehicles" >> typeof _veh >> "transportSoldier");
						_freeSlots = _veh emptyPositions "cargo";

						if (_maxSlots != 0) then {

							drawIcon3D ["", _color, [_pos select 0,_pos select 1,(_pos select 2) + 2 + F_VHEIGHT_NAMETAGS], 0, 0, 0, [_x,_prefix,format [" (%1/%2)",(_maxSlots-_freeSlots),_maxSlots]] call _fnc_createString, 0, F_SIZE_NAMETAGS, F_FONT_NAMETAGS];
						} else {
							drawIcon3D ["", _color, [_pos select 0,_pos select 1,(_pos select 2) + 2 + F_VHEIGHT_NAMETAGS], 0, 0, 0,  [_x,_prefix] call _fnc_createString, 0, F_SIZE_NAMETAGS, F_FONT_NAMETAGS];
						};
					}
					else
					{

						drawIcon3D ["", _color, [_pos select 0,_pos select 1,(_pos select 2) + 2 + F_VHEIGHT_NAMETAGS], 0, 0, 0,  [_x,_prefix] call _fnc_createString, 0, F_SIZE_NAMETAGS, F_FONT_NAMETAGS];
					};
				}
				else
				{
					if(_x == gunner _veh) then
					{
						_pos = _veh modeltoworld (_veh selectionPosition "gunnerview");

						_visPos = visiblePosition _x;
						drawIcon3D ["", _color, [_pos select 0,_pos select 1,(_visPos select 2) + 2 + F_VHEIGHT_NAMETAGS], 0, 0, 0,  [_x,_prefix] call _fnc_createString, 0, F_SIZE_NAMETAGS, F_FONT_NAMETAGS];
					}
					else
					{
						_pos = visiblePosition _x;

						_angle = (getdir _veh)+180;
						_pos = [((_pos select 0) + sin(_angle)*(0.6*_inc)) , (_pos select 1) + cos(_angle)*(0.6*_inc),_pos select 2 + F_VHEIGHT_NAMETAGS];
						drawIcon3D ["", _color, [_pos select 0,_pos select 1,(_pos select 2) + 1.5 + F_VHEIGHT_NAMETAGS], 0, 0, 0,  [_x,_prefix] call _fnc_createString, 0, F_SIZE_NAMETAGS, F_FONT_NAMETAGS];
						_inc = _inc + 1;
					};
				};

			} foreach crew _veh;
		};
	};
} foreach _ents;
};
}
];

