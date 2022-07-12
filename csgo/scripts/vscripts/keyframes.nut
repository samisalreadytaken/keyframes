//-----------------------------------------------------------------------
//------------------- Copyright (c) samisalreadytaken -------------------
//                       github.com/samisalreadytaken
//-----------------------------------------------------------------------
local VERSION = "1.2.11";

IncludeScript("vs_library");

if ( !("_KF_" in getroottable()) )
	::_KF_ <- { version = "" };;

_KF_.version = VERSION;

local _ = function(){

SendToConsole("alias kf_add\"script _KF_.AddKeyframe()\"");
SendToConsole("alias kf_remove\"script _KF_.RemoveKeyframe()\"");
SendToConsole("alias kf_clear\"script _KF_.RemoveAllKeyframes()\"");
SendToConsole("alias kf_insert\"script _KF_.InsertKeyframe()\"");
SendToConsole("alias kf_copy\"script _KF_.CopyKeyframe()\"");
SendToConsole("alias kf_replace\"script _KF_.ReplaceKeyframe()\"");
SendToConsole("alias kf_removefov\"script _KF_.RemoveFOV()\"");
SendToConsole("alias kf_undo\"script _KF_.Undo()\"");
SendToConsole("alias kf_redo\"script _KF_.Redo()\"");
SendToConsole("alias kf_undo_history\"script _KF_.PrintUndoStack()\"");
SendToConsole("alias kf_compile\"script _KF_.Compile()\"");
SendToConsole("alias kf_smooth_angles\"script _KF_.SmoothAngles()\"");
SendToConsole("alias kf_smooth_angles_exp\"script _KF_.SmoothAngles(1)\"");
SendToConsole("alias kf_smooth_origin\"script _KF_.SmoothOrigin()\"");
SendToConsole("alias kf_play\"script _KF_.Play(KF_PLAY_DEFAULT)\"");
SendToConsole("alias kf_play_loop\"script _KF_.Play(KF_PLAY_LOOP)\"");
SendToConsole("alias kf_preview\"script _KF_.Play(KF_PLAY_PREVIEW)\"");
SendToConsole("alias kf_stop\"script _KF_.Stop()\"");
SendToConsole("alias kf_savepath\"script _KF_.Save(KF_DATA_TYPE_PATH)\"");
SendToConsole("alias kf_savekeys\"script _KF_.Save(KF_DATA_TYPE_KEYFRAMES)\"");
SendToConsole("alias kf_mode_angles\"script _KF_.SetAngleInterp()\"");
SendToConsole("alias kf_mode_origin\"script _KF_.SetOriginInterp()\"");
SendToConsole("alias kf_auto_fill_boundaries\"script _KF_.SetAutoFillBoundaries()\"");
SendToConsole("alias kf_edit\"script _KF_.SetEditMode()\"");
SendToConsole("alias kf_translate\"script _KF_.ShowGizmo()\"");
SendToConsole("alias kf_select_path\"script _KF_.SelectPath()\"");
SendToConsole("alias kf_see\"script _KF_.SeeKeyframe()\"");
SendToConsole("alias kf_next\"script _KF_.NextKeyframe()\"");
SendToConsole("alias kf_prev\"script _KF_.PrevKeyframe()\"");
SendToConsole("alias kf_showkeys\"script _KF_.ShowToggle(0)\"");
SendToConsole("alias kf_showpath\"script _KF_.ShowToggle(1)\"");
SendToConsole("alias kf_trim_undo\"script _KF_.UndoTrim()\"");
SendToConsole("alias kf_cmd\"script _KF_.PrintCmd()\"");
SendToConsole("alias kf_loadfile\"script _KF_.LoadFile()\"");
SendToConsole("alias +kf_moveup\"script _KF_.IN_Move(1)\"");
SendToConsole("alias +kf_movedown\"script _KF_.IN_Move(2)\"");
SendToConsole("alias -kf_moveup\"script _KF_.IN_Move(0)\"");
SendToConsole("alias -kf_movedown\"script _KF_.IN_Move(0)\"");

// deprecated
SendToConsole("alias kf_select\"script _KF_.SelectKeyframe()\"");
SendToConsole("alias kf_save\"script _KF_.Save()\"");
SendToConsole("alias kf_load\"script _KF_.LoadFileError()\"");

//--------------------------------------------------------------

SendToConsole("script _KF_.PostSpawn()");

// prevent OOB access `closure->_defaultparams[(uint32)-1]`
const KF_NOPARAM = 0xfffffac7;


const FLT_EPSILON = 1.192092896e-7;
const KF_SAMPLE_COUNT_DEFAULT = 100;

local vec3_origin = Vector();
local s_flDisplayTime = FrameTime() * 6;
local HELPER_EF =
{
	ON  = (1<<4)|(1<<6)|(1<<3)|0,
	OFF = (1<<4)|(1<<6)|(1<<3)|(1<<5)
}


if ( !("_Process" in this) )
{
	g_FrameTime <- 1.0 / 64.0;
	g_szMapName <- split( GetMapName(), "/" ).top().tolower();
	MAX_COORD_VEC <- Vector(MAX_COORD_FLOAT-1,MAX_COORD_FLOAT-1,MAX_COORD_FLOAT-1);

	SND_BUTTON					<- "UIPanorama.container_countdown";
	SND_EXPORT_SUCCESS			<- "Survival.TabletUpgradeSuccess";
	SND_ERROR					<- "Bot.Stuck2";
	SND_FAILURE					<- "UIPanorama.buymenu_failure";
	SND_TICKER					<- "UIPanorama.store_item_rollover";
	SND_FILE_LOAD_SUCCESS		<- "Player.PickupGrenade";
	SND_TRANSLATOR_MOVED		<- "UI.StickerSelect";
	SND_TRANSLATOR_MOUSEOVER	<- "UI.PageScroll";
	SND_COUNTDOWN_BEEP			<- "UI.CounterBeep";
	SND_PLAY_END				<- "UI.RankDown";
	SND_SPAWN					<- "Player.DrownStart";


	_Process <- delegate this : {}

	_Save <- delegate this :
	{
		Add = VS.Log.Add.weakref()
	}

	_Load <- delegate this : {}

	m_KeyFrames <- [];
	m_PathData <- [];
	m_TrimData <- null;
	m_pSaveData <- null;
	m_pLoadData <- null;
	m_pLoadInput <- null;
	m_pUndoLoad <- null;
	m_pUndoTranslation <- null;

	m_nSaveType <- 0;
	m_nLoadType <- 0;
	m_nLoadVer <- 0;
	m_bSaveInProgress <- false;

	m_LoadedData <- {}
	m_FileBuffer <-
	{
		// for b/w compat
		V = Vector,
		Q = Quaternion
	}

	m_UndoStack <- [];
	m_nUndoLevel <- 0;
	m_nMaxUndoDepth <- 256;

	m_bDirty <- false;
	m_bCompiling <- false;
	m_bInPlayback <- false;
	m_bInEditMode <- true;
	m_bPlaybackPending <- false;
	m_bPlaybackLoop <- false;
	m_bTrimDirection <- true;
	m_bSmoothExponential <- false;
	m_pSquadErrors <- null;
	m_AnglesRestore <- null;

	m_Selection <- [0,0];
	m_nCurPathSelection <- 0;
	m_fPathSelection <- 0;

	m_nInterpolatorAngle <- null;
	m_nInterpolatorOrigin <- null;
	m_szInterpDescAngle <- null;
	m_szInterpDescOrigin <- null;

	m_bAutoFillBoundaries <- false;

	m_nMouseOver <- 0;
	m_bGizmoEnabled <- false;
	m_bMouseDown <- false;
	m_bMouseForceUp <- false;
	m_nTranslation <- 0;
	m_bDuckFixup <- false;

	m_vecLastForwardFrame <- null;
	m_vecCameraOffset <- null;
	m_vecOffset <- null;
	m_vecLastKeyOrigin <- Vector();
	m_vecLastOrigin <- null;
	m_vecLastDeltaOrigin <- null;
	m_vecLastForward <- null;
	m_vecLastUp <- null;
	m_vecLastRight <- null;
	m_vecPivotPoint <- null;

	m_nSelectedKeyframe <- -1;
	m_nCurKeyframe <- 0;
	m_nPlaybackIdx <- -1;
	m_nPlaybackTarget <- -1;

	m_bPreview <- false;
	m_flPreviewFrac <- 0.0;

	m_bShowPath <- true;
	m_bShowKeys <- true;
	m_bSeeing <- false;
	m_bReplaceOnClick <- false;
	m_bInsertOnClick <- false;

	in_moveup <- false;
	in_movedown <- false;
	in_forward <- false;
	in_back <- false;
	in_moveleft <- false;
	in_moveright <- false;

	m_iLastFOV <- 90;
	m_vecRollLastAngle <- null;

	m_nAnimKeyframeTime <- 0.0;
	m_nAnimKeyframeIdx <- -1;
	m_nAnimPathIdx <- 0;

	m_pLerpTransform <- null;
	m_flLerpTransformAnim <- null;

	m_pLerpFrustum <- null;
	m_hLerpKeyframe <- null;
	m_flLerpKeyAnim <- null;

	m_nPathInitialFOV <- 0;

	AddEvent <- VS.EventQueue.AddEvent.weakref();
	Msg <- print;
	Fmt <- format;
	clamp <- clamp;
	EntFireByHandle <- EntFireByHandle;
	DrawLine <- DebugDrawLine;
	DrawBox <- DebugDrawBox;
	DrawBoxAnglesFilled <- DebugDrawBoxAngles;
};

player <- ToExtendedPlayer( VS.GetPlayerByIndex(1) );

if ( !("m_hThinkCam" in this) )
{
	m_hThinkCam <- VS.Timer( true, g_FrameTime, null, null, false, true ).weakref();
	m_hThinkEdit <- VS.Timer( true, s_flDisplayTime-FrameTime(), null, null, false, true ).weakref();
	m_hThinkAnim <- VS.Timer( true, 0.5-FrameTime(), null, null, false, true ).weakref();
	m_hThinkKeys <- VS.Timer( true, FrameTime()*2.5, null, null, false, true ).weakref();
	m_hThinkFrame <- VS.Timer( true, FrameTime(), null, null, false, true ).weakref();

	m_hGameText <- VS.CreateEntity("game_text",
	{
		channel = 5,
		color = Vector(255,120,0),
		holdtime = s_flDisplayTime,
		x = 0.475,
		y = 0.5625
	},true).weakref();

	m_hGameText2 <- VS.CreateEntity("game_text",
	{
		channel = 6,
		color = Vector(255,120,0),
		holdtime = s_flDisplayTime,
		x = 0.575,
		y = 0.485
	},true).weakref();

	m_hGameText3 <- VS.CreateEntity("game_text",
	{
		channel = 4,
		color = Vector(255,120,0),
		holdtime = s_flDisplayTime,
		x = 0.575,
		y = 0.505
	},true).weakref();

	m_hHudHint <- VS.CreateEntity("env_hudhint",null,true).weakref();

	m_hView <- VS.CreateEntity("point_viewcontrol",{ spawnflags = (1<<3)|(1<<7) }).weakref();

	PrecacheModel("keyframes/kf_circle_orange.vmt");

	m_hKeySprite <- VS.CreateEntity("env_sprite",
	{
		rendermode = 8,
		glowproxysize = 64.0, // MAX_GLOW_PROXY_SIZE
		effects = HELPER_EF.ON
	}, true).weakref();

	m_hKeySprite.__KeyValueFromInt( "effects", HELPER_EF.ON );

	m_hKeySprite.SetModel("keyframes/kf_circle_orange.vmt");

//--------------------------------------------------------

	PrecacheScriptSound( SND_EXPORT_SUCCESS );
};


// load materials
DrawLine( vec3_origin, vec3_origin, 0, 0, 0, true, 1 );
DrawBox( vec3_origin, vec3_origin, Vector(1,1,1), 0, 0, 0, 254, 1 );


//--------------------------------------------------------------
//--------------------------------------------------------------


function CameraSetAngles(v)
{
	return m_hView.SetAngles( v.x, v.y, v.z );
}

function CameraSetForward(v)
{
	return m_hView.SetForwardVector(v);
}

function CameraSetOrigin(v)
{
	return m_hView.SetAbsOrigin(v);
}

function CameraSetFov( n, f )
{
	return m_hView.SetFov( n, f );
}

function CameraSetEnabled( b )
{
	return EntFireByHandle( m_hView, b ? "Enable" : "Disable", "", 0.0, player.self );
}

function CameraSetThinkEnabled( b )
{
	return EntFireByHandle( m_hThinkCam, b ? "Enable" : "Disable" );
}


function PlaySound(s)
{
	return player.EmitSound(s);
}

function HintColor( msg, r, g, b ) : (CenterPrintAll)
{
	return CenterPrintAll(Fmt( "<font color='#%02x%02x%02x'>%s</font>", r&0xFF, g&0xFF, b&0xFF, msg ));
}

function Hint(s)
{
	m_hHudHint.__KeyValueFromString( "message", s );
	return EntFireByHandle( m_hHudHint, "ShowHudHint", "", 0.0, player.self );
}

function HideHudHint( t = 0.0 )
{
	return EntFireByHandle( m_hHudHint, "HideHudHint", "", t, player.self );
}

function Error(s)
{
	Msg(s);
	PlaySound( SND_ERROR );
}

function MsgFail(s)
{
	if ( !m_bCompiling )
	{
		Msg(s);
	}
	else
	{
		Msg("\n(\n\t");
		Msg(s);
		Msg(")");
	};

	PlaySound( SND_FAILURE );
}

function MsgHint(s)
{
	Msg(s);
	Hint(s);
}

function ArrayAppend( arr, val )
{
	return arr.insert( arr.len(), val );
}


function SetHelperVisible( state ) : (HELPER_EF)
{
	if ( state )
	{
		m_hKeySprite.__KeyValueFromInt( "effects", HELPER_EF.ON );
	}
	else
	{
		m_hKeySprite.__KeyValueFromInt( "effects", HELPER_EF.OFF );
	};
}

function SetHelperOrigin( vec )
{
	return m_hKeySprite.SetOrigin( vec );
}

function IsDucking()
{
	return player.GetBoundingMaxs().z != 72.0;
}

function SetViewOrigin( vec )
{
	local origin = player.GetOrigin();

	origin.x = vec.x;
	origin.y = vec.y;
	origin.z = vec.z - ( MainViewOrigin().z - origin.z );

	return player.SetAbsOrigin( origin );
}

function SetViewForward( vec )
{
	return player.SetForwardVector( vec );
}

function MainViewOrigin()
{
	// CSGO view render origin is offset from the eye position (origin+viewoffset)
	// Using GetAbsOrigin instead of EyePosition to reliably get the actual player position while in-camera view.
	local viewOrigin = player.GetOrigin();

	if ( IsDucking() )
	{
		viewOrigin.z += 46.062561;
	}
	else
	{
		viewOrigin.z += 64.062561;
	}

	return viewOrigin;
}

function MainViewAngles()
{
	return player.EyeAngles();
}

function MainViewForward()
{
	return player.EyeForward();
}

function MainViewRight()
{
	return player.EyeRight();
}

function MainViewUp()
{
	return player.EyeUp();
}

function CurrentViewOrigin()
{
	// NOTE: View entity origin/angles are slightly offset, return keyframe angles.
	if ( m_bSeeing )
		return m_KeyFrames[ m_nCurKeyframe ].origin;

	if ( m_bInPlayback && !m_bPreview )
		return m_PathData[ m_nPlaybackIdx ].origin;

	return MainViewOrigin();
}

function CurrentViewAngles()
{
	// NOTE: View entity origin/angles are slightly offset, return keyframe angles.
	if ( m_bSeeing )
		return m_KeyFrames[ m_nCurKeyframe ].angles;

	if ( m_bInPlayback && !m_bPreview )
		return m_PathData[ m_nPlaybackIdx ].angles;

	return MainViewAngles();
}

::MainViewOrigin	<- MainViewOrigin.bindenv(this);
::MainViewAngles	<- MainViewAngles.bindenv(this);
::MainViewForward	<- MainViewForward.bindenv(this);
::MainViewRight		<- MainViewRight.bindenv(this);
::MainViewUp		<- MainViewUp.bindenv(this);
::CurrentViewOrigin	<- CurrentViewOrigin.bindenv(this);
::CurrentViewAngles	<- CurrentViewAngles.bindenv(this);


class frame_t
{
	origin = null;
	angles = null;
	fov = null;
	fov_rate = null;

	function SetOrigin( input )
	{
		origin = input;
	}

	function SetAngles( input )
	{
		angles = input;
	}

	function SetFov( val, rate )
	{
		fov = val;
		fov_rate = rate;
	}
}

class keyframe_t //extends frame_t
{
	origin = null;		// Vector
	angles = null;		// QAngle
	forward = null;		// Vector
	right = null;		// Vector
	up = null;			// Vector
	orientation = null;	// Quaternion
	transform = null;	// matrix3x4_t
	fov = null;			// int
	_fovx = null;		// float
	samplecount = 0;	// int
	frametime = 0.0;	// float

	constructor() : (g_FrameTime)
	{
		samplecount = KF_SAMPLE_COUNT_DEFAULT;
		frametime = KF_SAMPLE_COUNT_DEFAULT * g_FrameTime;
		transform = matrix3x4_t();
		Init();
	}

	function Init()
	{
		origin = Vector();
		angles = Vector();
		forward = Vector();
		right = Vector();
		up = Vector();
		orientation = Quaternion();
		SetFov( null );
	}

	function SetOrigin( input )
	{
		VS.VectorCopy( input, origin );
		VS.MatrixSetColumn( origin, 3, transform );
	}

	// QAngle
	function SetAngles( input )
	{
		VS.VectorCopy( input, angles );
		VS.AngleMatrix( angles, origin, transform );

		VS.AngleQuaternion( angles, orientation );

		VS.MatrixVectors( transform, forward, right, up );
	}

	// Quaternion
	function SetQuaternion( input )
	{
		VS.VectorCopy( input, orientation ); orientation.w = input.w;
		VS.QuaternionMatrix( orientation, origin, transform );

		VS.MatrixVectors( transform, forward, right, up );

		VS.MatrixAngles( transform, angles );
	}

	// Vector
	function SetForward( input )
	{
		VS.VectorCopy( input, forward );
		VS.VectorVectors( forward, right, up );

		VS.VectorAngles( forward, angles );

		VS.AngleQuaternion( angles, orientation );

		VS.MatrixSetColumn( forward, 0, transform );
		VS.MatrixSetColumn( right * -1, 1, transform );
		VS.MatrixSetColumn( up, 2, transform );
	}

	function UpdateFromMatrix()
	{
		VS.MatrixGetColumn( transform, 3, origin );
		VS.MatrixAngles( transform, angles, origin );
		VS.MatrixVectors( transform, forward, right, up );
		VS.AngleQuaternion( angles, orientation );
	}

	function SetFov( val, rate = null )
	{
		if ( val )
		{
			fov = val.tointeger();
			_fovx = VS.CalcFovX( fov.tofloat(), 16./9. * 0.75 );
		}
		else
		{
			fov = null;
			_fovx = VS.CalcFovX( 90.0, 16./9. * 0.75 );
		};
	}

	function DrawFrustum( r, g, b, time )
	{
		// could just use a model
		return VS.DrawViewFrustum( origin,
			forward,
			right,
			up,
			_fovx,
			1.777778,
			4.0,
			32.0,
			r, g, b, false,
			time
		);
	}

	function Copy( src )
	{
		transform = clone src.transform;

		VS.MatrixGetColumn( transform, 3, origin );
		VS.MatrixVectors( transform, forward, right, up );
		VS.MatrixAngles( transform, angles );
		VS.MatrixQuaternionFast( transform, orientation );

		SetFov( src.fov );

		frametime = src.frametime;
		samplecount = src.samplecount;
	}

	function _cloned( src )
	{
		Init();
		Copy(src);
	}
}

class CUndoElement
{
	constructor( szDesc = "<unknown>" )
	{
		m_szDesc = szDesc;
	}

	function Undo() { Assert(0) }
	function Redo() { Assert(0) }
	function Desc() { return m_szDesc }

	function CanRedo() { return true; }

	m_szDesc = "";
	Fmt = Fmt;
	Base = this;
}


//--------------------------------------------------------------

//
// TODO: Fix this mess
//
fnMoveRight1 <- function(...) { return IN_ROLL_1(1); }.bindenv(this);
fnMoveRight0 <- function(...) { return IN_ROLL_1(0); }.bindenv(this);
fnMoveLeft1  <- function(...) { return IN_ROLL_0(1); }.bindenv(this);
fnMoveLeft0  <- function(...) { return IN_ROLL_0(0); }.bindenv(this);
fnForward1   <- function(...) { return IN_FOV_1(1); }.bindenv(this);
fnForward0   <- function(...) { return IN_FOV_1(0); }.bindenv(this);
fnBack1      <- function(...) { return IN_FOV_0(1); }.bindenv(this);
fnBack0      <- function(...) { return IN_FOV_0(0); }.bindenv(this);

const KF_CB_CONTEXT = "KEYFRAMES";;


function ListenKeys( i )
{
	if ( i == 1 )
	{
		ListenMouse(0);

		VS.SetInputCallback( player, "+moveright", fnMoveRight1, KF_CB_CONTEXT );
		VS.SetInputCallback( player, "-moveright", fnMoveRight0, KF_CB_CONTEXT );

		VS.SetInputCallback( player, "+moveleft", fnMoveLeft1, KF_CB_CONTEXT );
		VS.SetInputCallback( player, "-moveleft", fnMoveLeft0, KF_CB_CONTEXT );

		VS.SetInputCallback( player, "+forward", fnForward1, KF_CB_CONTEXT );
		VS.SetInputCallback( player, "-forward", fnForward0, KF_CB_CONTEXT );

		VS.SetInputCallback( player, "+back", fnBack1, KF_CB_CONTEXT );
		VS.SetInputCallback( player, "-back", fnBack0, KF_CB_CONTEXT );

		// freeze player
		player.SetMoveType( 0 );
	}
	else
	{
		VS.SetInputCallback( player, "+moveright", null, KF_CB_CONTEXT );
		VS.SetInputCallback( player, "-moveright", null, KF_CB_CONTEXT );

		VS.SetInputCallback( player, "+moveleft", null, KF_CB_CONTEXT );
		VS.SetInputCallback( player, "-moveleft", null, KF_CB_CONTEXT );

		VS.SetInputCallback( player, "+forward", null, KF_CB_CONTEXT );
		VS.SetInputCallback( player, "-forward", null, KF_CB_CONTEXT );

		VS.SetInputCallback( player, "+back", null, KF_CB_CONTEXT );
		VS.SetInputCallback( player, "-back", null, KF_CB_CONTEXT );

		// enable noclip
		player.SetMoveType( 8 );
	};
}

function ListenMouse( i )
{
	if (i)
	{
		ListenKeys(0);

		VS.SetInputCallback( player, "+attack", OnMouse1Pressed, KF_CB_CONTEXT );
		VS.SetInputCallback( player, "+attack2", OnMouse2Pressed, KF_CB_CONTEXT );
		VS.SetInputCallback( player, "-attack", OnMouse1Released, KF_CB_CONTEXT );
	}
	else
	{
		VS.SetInputCallback( player, "-attack", null, KF_CB_CONTEXT );
	};
}

VS.SetInputCallback( player, "+use", function(...)
{
	SeeKeyframe(0,1);

	EntFireByHandle( m_hThinkKeys, "Disable" );
	in_forward = false;
	in_back = false;
	in_moveleft = false;
	in_moveright = false;
}.bindenv(this), KF_CB_CONTEXT );

//--------------------------------------------------------------

// Think keys roll
function IN_ThinkRoll()
{
	if ( in_moveleft )
	{
		m_vecRollLastAngle.z = clamp( floor( m_vecRollLastAngle.z + 2.0 ), -180.0, 180.0 );
		CameraSetAngles( m_vecRollLastAngle );
		Hint( "Roll "+m_vecRollLastAngle.z );
	}
	else if ( in_moveright )
	{
		m_vecRollLastAngle.z = clamp( floor( m_vecRollLastAngle.z - 2.0 ), -180.0, 180.0 );
		CameraSetAngles( m_vecRollLastAngle );
		Hint( "Roll "+m_vecRollLastAngle.z );
	};;

	PlaySound( SND_TICKER );
}

// Think keys fov
function IN_ThinkFOV()
{
	local fFovRate = FrameTime()*6;

	if ( in_forward )
	{
		m_iLastFOV = clamp( m_iLastFOV - 1, 1, 179 );
		Hint( "FOV "+m_iLastFOV );
		CameraSetFov( m_iLastFOV, fFovRate );
	}
	else if ( in_back )
	{
		m_iLastFOV = clamp( m_iLastFOV + 1, 1, 179 );
		Hint( "FOV "+m_iLastFOV );
		CameraSetFov( m_iLastFOV, fFovRate );
	};;

	PlaySound( SND_TICKER );
}

// roll clockwise
function IN_ROLL_1(i)
{
	if (i)
	{
		if ( !m_bSeeing )
			return MsgFail("You need to be in see mode to use the key controls.\n");

		in_moveleft = true;
		m_vecRollLastAngle = m_KeyFrames[ m_nCurKeyframe ].angles * 1;

		VS.OnTimer( m_hThinkKeys, IN_ThinkRoll );
		EntFireByHandle( m_hThinkKeys, "Enable" );
	}
	else
	{
		if ( !m_bSeeing )
			return;

		in_moveleft = false;
		EntFireByHandle( m_hThinkKeys, "Disable" );

		local pUndo = CUndoKeyframeRoll();
		PushUndo( pUndo );
		pUndo.m_nKeyIndex = m_nCurKeyframe;
		pUndo.m_vecAnglesOld = m_KeyFrames[ m_nCurKeyframe ].angles * 1;
		pUndo.m_vecAnglesNew = m_vecRollLastAngle * 1;

		// save last set data
		m_KeyFrames[ m_nCurKeyframe ].SetAngles( m_vecRollLastAngle );

		m_bDirty = true;
	};
}

// roll counter-clockwise
function IN_ROLL_0(i)
{
	if (i)
	{
		if ( !m_bSeeing )
			return MsgFail("You need to be in see mode to use the key controls.\n");

		in_moveright = true;
		m_vecRollLastAngle = m_KeyFrames[ m_nCurKeyframe ].angles * 1;

		VS.OnTimer( m_hThinkKeys, IN_ThinkRoll );
		EntFireByHandle( m_hThinkKeys, "Enable" );
	}
	else
	{
		if ( !m_bSeeing )
			return;

		in_moveright = false;
		EntFireByHandle( m_hThinkKeys, "Disable" );

		local pUndo = CUndoKeyframeRoll();
		PushUndo( pUndo );
		pUndo.m_nKeyIndex = m_nCurKeyframe;
		pUndo.m_vecAnglesOld = m_KeyFrames[ m_nCurKeyframe ].angles * 1;
		pUndo.m_vecAnglesNew = m_vecRollLastAngle * 1;

		// save last set data
		m_KeyFrames[ m_nCurKeyframe ].SetAngles( m_vecRollLastAngle );

		m_bDirty = true;
	};
}

// fov in
function IN_FOV_1(i)
{
	if (i)
	{
		if ( !m_bSeeing )
			return MsgFail("You need to be in see mode to use the key controls.\n");

		in_forward = true;
		m_iLastFOV = 90;

		VS.OnTimer( m_hThinkKeys, IN_ThinkFOV );
		EntFireByHandle( m_hThinkKeys, "Enable" );

		local key = m_KeyFrames[ m_nCurKeyframe ];
		if ( key.fov )
		{
			// get current fov value
			m_iLastFOV = key.fov;
		};
	}
	else
	{
		if ( !m_bSeeing )
			return;

		in_forward = false;
		EntFireByHandle( m_hThinkKeys, "Disable" );

		local key = m_KeyFrames[ m_nCurKeyframe ];

		local pUndo = CUndoKeyframeFOV();
		PushUndo( pUndo );
		pUndo.m_nKeyIndex = m_nCurKeyframe;
		pUndo.m_nFovOld = key.fov ? key.fov : 90;
		pUndo.m_nFovNew = m_iLastFOV;

		key.SetFov( m_iLastFOV );

		m_bDirty = true;
	};
}

// fov out
function IN_FOV_0(i)
{
	if (i)
	{
		if ( !m_bSeeing )
			return MsgFail("You need to be in see mode to use the key controls.\n");

		in_back = true;
		m_iLastFOV = 90;

		VS.OnTimer( m_hThinkKeys, IN_ThinkFOV );
		EntFireByHandle( m_hThinkKeys, "Enable" );

		local key = m_KeyFrames[ m_nCurKeyframe ];
		if ( key.fov )
		{
			// get current fov value
			m_iLastFOV = key.fov;
		};
	}
	else
	{
		if ( !m_bSeeing )
			return;

		in_back = false;
		EntFireByHandle( m_hThinkKeys, "Disable" );

		local key = m_KeyFrames[ m_nCurKeyframe ];

		local pUndo = CUndoKeyframeFOV();
		PushUndo( pUndo );
		pUndo.m_nKeyIndex = m_nCurKeyframe;
		pUndo.m_nFovOld = key.fov ? key.fov : 90;
		pUndo.m_nFovNew = m_iLastFOV;

		key.SetFov( m_iLastFOV );

		m_bDirty = true;
	};
}

function IN_ThinkMoveVert()
{
	if ( in_moveup )
	{
		local u = 48.0;
		if ( IsDucking() )
		{
			u = 36.0;
		};

		local v = player.GetVelocity() + MainViewUp() * u;
		return player.SetVelocity( v );
	};

	if ( in_movedown )
	{
		local u = 48.0;
		if ( IsDucking() )
		{
			u = 36.0;
		};

		local v = player.GetVelocity() - MainViewUp() * u;
		return player.SetVelocity( v );
	};
}

function IN_Move(i)
{
	switch ( i )
	{
	case 0:
		in_moveup = in_movedown = false;

		m_hThinkKeys.__KeyValueFromFloat( "refiretime", FrameTime()*2.5 );
		return EntFireByHandle( m_hThinkKeys, "Disable" );

	case 1:
		in_moveup = true;
		break;

	case 2:
		in_movedown = true;
		break;
	}

	m_hThinkKeys.__KeyValueFromFloat( "refiretime", 0.01 );
	VS.OnTimer( m_hThinkKeys, IN_ThinkMoveVert );
	EntFireByHandle( m_hThinkKeys, "Enable" );
}

//--------------------------------------------------------------
//--------------------------------------------------------------

OnMouse1Pressed <- function(...)
{
	if ( m_bSeeing )
		return NextKeyframe();

	if ( m_bGizmoEnabled )
		return GizmoOnMouseDown();

	if ( m_bReplaceOnClick )
	{
		ReplaceKeyframe(1);
		return;
	};

	if ( m_bInsertOnClick )
	{
		InsertKeyframe(1);
		return;
	};

	if ( m_fPathSelection != 0 )
		return SelectPath(1);

	return AddKeyframe();
}.bindenv(this);

OnMouse1Released <- function(...)
{
	if ( m_bSeeing )
		return;

	if ( m_bGizmoEnabled )
		return GizmoOnMouseRelease();
}.bindenv(this);

OnMouse2Pressed <- function(...)
{
	if ( m_bReplaceOnClick || m_bInsertOnClick )
	{
		m_bReplaceOnClick = false;
		m_bInsertOnClick = false;
		m_nSelectedKeyframe = -1;

		MsgHint("Cancelled\n");
		PlaySound( SND_BUTTON );
		return;
	};

	if ( m_fPathSelection != 0 )
	{
		m_Selection[0] = m_Selection[1] = 0;
		m_fPathSelection = 0;
		MsgHint( "Cleared path selection.\n" );
		PlaySound( SND_BUTTON );
		return;
	};

	if ( m_bSeeing )
		return PrevKeyframe();

	if ( m_bGizmoEnabled )
		return;

	return RemoveKeyframe();
}.bindenv(this);

//--------------------------------------------------------------
//--------------------------------------------------------------

function ShowToggle(t)
{
	// kf_showpath
	if (t)
	{
		m_bShowPath = !m_bShowPath;
		Msg( m_bShowPath ? "Showing path\n" : "Hiding path\n" );
	}
	// kf_showkeys
	else
	{
		m_bShowKeys = !m_bShowKeys;
		EntFireByHandle( m_hThinkAnim, m_bShowKeys ? "Enable" : "Disable" );
		Msg( m_bShowKeys ? "Showing keyframes\n" : "Hiding keyframes\n" );
	};

	SendToConsole("clear_debug_overlays");
	PlaySound( SND_BUTTON );
}

// kf_edit
function SetEditMode( state = null, msg = true )
{
	if ( m_bCompiling )
		return MsgFail(Fmt( "Cannot %s edit mode while compiling!\n", (m_bInEditMode?"disable":"enable") ));

	if ( state == null )
		state = !m_bInEditMode;

	m_bInEditMode = !!state;

	// on
	if ( m_bInEditMode )
	{
		if ( developer() > 1 )
		{
			Msg("Setting developer level to 1\n");
			SendToConsole("developer 1");
		};

		SendToConsole( "cl_drawhud 1" );
		SetHelperVisible( true );
		EntFireByHandle( m_hThinkEdit, "Enable" );
		EntFireByHandle( m_hThinkAnim, "Enable" );
		EntFireByHandle( m_hThinkFrame, "Enable" );

		if (msg)
			Msg("Edit mode enabled.\n");
	}
	// off
	else
	{
		// unsee
		if ( m_bSeeing )
			SeeKeyframe(1);

		SetHelperVisible( false );
		EntFireByHandle( m_hThinkEdit, "Disable" );
		EntFireByHandle( m_hThinkAnim, "Disable" );
		EntFireByHandle( m_hThinkFrame, "Disable" );
		EntFireByHandle( m_hGameText2, "SetText", "" );
		EntFireByHandle( m_hGameText3, "SetText", "" );

		if (msg)
			Msg("Edit mode disabled.\n");
	};

	SendToConsole("clear_debug_overlays");

	if (msg)
		PlaySound( SND_BUTTON );
}

function SetEditModeTemp( state )
{
	if ( state )
	{
		m_hThinkEdit.__KeyValueFromFloat( "nextthink", 1 );
		m_hThinkAnim.__KeyValueFromFloat( "nextthink", 1 );
		m_hThinkFrame.__KeyValueFromFloat( "nextthink", 1 );
	}
	else
	{
		m_hThinkEdit.__KeyValueFromFloat( "nextthink", -1 );
		m_hThinkAnim.__KeyValueFromFloat( "nextthink", -1 );
		m_hThinkFrame.__KeyValueFromFloat( "nextthink", -1 );
	}
}

// kf_select_path
function SelectPath( bClick = 0 )
{
	if ( !m_bInEditMode )
		return MsgFail("You need to be in edit mode to select.\n");

	if ( !m_PathData.len() )
		return MsgFail("No path to select.\n");

	if ( !bClick )
	{
		if ( m_fPathSelection == 0 )
		{
			m_fPathSelection = 1;
			MsgHint( "Select path begin...\n" );
		}
		else
		{
			m_fPathSelection = 0;
			MsgHint( "Cancelled\n" );
		};

		PlaySound( SND_BUTTON );

		return;
	};

	if ( m_fPathSelection == 1 )
	{
		m_Selection[0] = m_nCurPathSelection;
		m_nAnimPathIdx = 0;

		Msg(Fmt( " [%d ->\n", m_Selection[0] ));

		MsgHint( "Select path end...\n" );
		m_fPathSelection = 2;
	}
	else if ( m_fPathSelection == 2 )
	{
		m_Selection[1] = m_nCurPathSelection;
		m_nAnimPathIdx = 0;

		// normalise
		if ( m_Selection[0] > m_Selection[1] )
		{
			local t = m_Selection[1];
			m_Selection[1] = m_Selection[0];
			m_Selection[0] = t;
		};

		if ( m_Selection[0] == 0 )
		{
			m_Selection[0] = 1;
		};

		if ( m_Selection[1] == 0 )
		{
			m_Selection[1] = 2;
		};

		if ( m_Selection[0] == m_Selection[1] )
		{
			m_Selection[1]++;
		};

		MsgHint( "Selected path" );
		Msg(Fmt( " [%d -> %d]\n", m_Selection[0], m_Selection[1] ));
		m_fPathSelection = 0;
	};;

	PlaySound( SND_BUTTON );
}

// kf_select
// TODO: remove - this doesn't have a purpose now
function SelectKeyframe( bShowMsg = 1 )
{
	if ( !m_bInEditMode )
		return MsgFail("You need to be in edit mode to select.\n");

	if ( m_nSelectedKeyframe == -1 )
	{
		m_nSelectedKeyframe = m_nCurKeyframe;

		if ( bShowMsg )
			MsgHint(Fmt( "Selected keyframe #%d\n", m_nSelectedKeyframe ));
	}
	else
	{
		if ( bShowMsg )
			MsgHint(Fmt( "Unselected keyframe #%d\n", m_nSelectedKeyframe ));

		// unsee silently
		if ( m_bSeeing )
			SeeKeyframe(1);

		m_nSelectedKeyframe = -1;
	};

	PlaySound( SND_BUTTON );
}

// kf_next
function NextKeyframe()
{
	if ( m_nSelectedKeyframe == -1 )
		return MsgFail("You need to have a keyframe selected to use kf_next.\n");

	local t = (m_nSelectedKeyframe+1) % m_KeyFrames.len();
	local b = m_bSeeing;		// hold current state

	// unsee silently
	if (b) SeeKeyframe(1,0);

	m_nSelectedKeyframe = t;
	m_nCurKeyframe = t;

	// then see again
	if (b) SeeKeyframe(0,0);
}

// kf_prev
function PrevKeyframe()
{
	if ( m_nSelectedKeyframe == -1 )
		return MsgFail("You need to have a keyframe selected to use kf_prev.\n");

	local n = m_nSelectedKeyframe-1;

	if ( n < 0 )
		n += m_KeyFrames.len();

	local t = n % m_KeyFrames.len();
	local b = m_bSeeing;		// hold current state

	// unsee silently
	if (b) SeeKeyframe(1,0);

	m_nSelectedKeyframe = t;
	m_nCurKeyframe = t;

	// then see again
	if (b) SeeKeyframe(0,0);
}

// kf_see
// TODO: a better method?
function SeeKeyframe( bUnsafeUnsee = 0, bShowMsg = 1 ) : (vec3_origin)
{
	if ( bUnsafeUnsee )
	{
		m_bSeeing = false;
		if ( m_nSelectedKeyframe != -1 )
			m_nSelectedKeyframe = -1;
		CameraSetFov( 0, 0.1 );
		CameraSetEnabled( false );
		ListenMouse(1);
		SetHelperVisible( true );

		return;
	};

	if ( m_bCompiling )
		return MsgFail("Cannot modify keyframes while compiling!\n");

	if ( m_bInPlayback || m_bPlaybackPending )
		return MsgFail("Cannot use see while in playback!\n");

	if ( !m_bInEditMode )
		return MsgFail("You need to be in edit mode to use see.\n");

	if ( !m_KeyFrames.len() )
		return MsgFail("No keyframes found.\n");

	m_bSeeing = !m_bSeeing;

	if ( m_bSeeing )
	{
		player.SetVelocity( vec3_origin );

		if ( m_nSelectedKeyframe == -1 )
			m_nSelectedKeyframe = m_nCurKeyframe;

		local key = m_KeyFrames[ m_nSelectedKeyframe ];

		// set fov and pos to selected
		if ( key.fov )
			CameraSetFov( key.fov, 0.25 );
		CameraSetOrigin( key.origin );
		CameraSetAngles( key.angles );

		CameraSetEnabled( true );

		ListenKeys(1);

		SetHelperVisible( false );

		if ( bShowMsg )
			MsgHint(Fmt( "Seeing keyframe #%d\n", m_nSelectedKeyframe ));
	}
	else
	{
		CompileFOV();

		if ( m_nSelectedKeyframe != -1 )
			m_nSelectedKeyframe = -1;

		CameraSetFov( 0, 0.1 );
		CameraSetEnabled( false );

		// ListenKeys(0);
		ListenMouse(1);

		SetHelperVisible( true );

		if ( bShowMsg )
		{
			Msg("Stopped seeing keyframe\n");
			HideHudHint();
		};
	};

	PlaySound( SND_BUTTON );
}


local s_vecMins = Vector();

function EditModeThink() : ( s_flDisplayTime, s_vecMins )
{
	local count = m_KeyFrames.len();
	local viewOrigin = MainViewOrigin();
	local viewForward = MainViewForward();
	local nNearestKey;

	if ( count )
	{
		local viewAngles = CurrentViewAngles();
		local curkey;

		if ( !m_bInPlayback )
		{
			local bSelected = m_nSelectedKeyframe != -1;

			// not selected any keyframe
			if ( !bSelected )
			{
				local nCur;
				local flThreshold = 0.9;
				local flBestDist = 1.e+37;

				foreach( i, key in m_KeyFrames )
				{
					local dir = key.origin - viewOrigin;
					local dist = dir.Norm();
					local dot = viewForward.Dot(dir);

					if ( dot > flThreshold )
					{
						nCur = i;
						flThreshold = dot;
					};

					if ( m_fPathSelection != 0 )
					{
						if ( dist < flBestDist )
						{
							flBestDist = dist;
							nNearestKey = i;
						};
					};
				}

				if ( nCur != null )
					m_nCurKeyframe = nCur;
			};

			curkey = m_KeyFrames[ m_nCurKeyframe ];

			if ( bSelected )
			{
				m_hGameText.__KeyValueFromString( "message", Fmt("KEY: %d (HOLD)", m_nCurKeyframe) );
			}
			else
			{
				m_hGameText.__KeyValueFromString( "message", "KEY: " + m_nCurKeyframe );
			};

			EntFireByHandle( m_hGameText, "Display", "", 0, player.self );

			if ( curkey.fov )
			{
				m_hGameText2.__KeyValueFromString( "message", "FOV: " + curkey.fov );
				EntFireByHandle( m_hGameText2, "Display", "", 0, player.self );
				EntFireByHandle( m_hGameText2, "SetText", "" );
			};

			if ( curkey.samplecount != KF_SAMPLE_COUNT_DEFAULT )
			{
				m_hGameText3.__KeyValueFromString( "message", "frametime: " + curkey.frametime );
				EntFireByHandle( m_hGameText3, "Display", "", 0, player.self );
				EntFireByHandle( m_hGameText3, "SetText", "" );
			};

			SetHelperOrigin( curkey.origin );
		};

		if ( m_bShowKeys )
		{
			// draw current keyframe - if not seeing and not in playback
			if ( !m_bSeeing && curkey )
			{
				if ( !m_bGizmoEnabled )
				{
					local dist = ( curkey.origin - viewOrigin ).Length();
					local s;
					if ( dist < 768.0 )
					{
						s = dist / 128.0;
						curkey.DrawFrustum( 255, 200, 255, s_flDisplayTime );
					}
					else
					{
						s = dist / 72.0;
					};

					DrawRectFilled( curkey.origin, s, 255, 120, 0, 255, s_flDisplayTime, viewAngles );
				};
			};

			// draw the rest
			foreach( i, key in m_KeyFrames )
			{
				if ( i == m_nCurKeyframe )
					continue;

				local dist = ( key.origin - viewOrigin ).Length();
				if ( dist < 768.0 )
				{
					key.DrawFrustum( 255, 200, 255, s_flDisplayTime );

					DrawRectFilled( key.origin, dist / 128.0, 255, 0, 0, 255, s_flDisplayTime, viewAngles );
				}
				else
				{
					if ( i != m_nAnimKeyframeIdx )
						DrawRectFilled( key.origin, 8.0, 255, 0, 0, 255, s_flDisplayTime, viewAngles );
				};
			}
		};
	};

	if ( m_bShowPath )
	{
		local pPath = m_PathData;
		// NOTE: When sampling rate was global and static, draw resolution could be precalculated.
		// This becomes complicated when keys can have variable amount of samples.
		local res = 10;
		local len = pPath.len() - res;
		local ToVector = VS.AngleVectors;

		if ( len > 0 )
		{
			local r = m_bDirty ? 255 : 128;

			for ( local i = 0; i < len; i+=res )
			{
				local pt = pPath[i].origin;

				DrawLine( pt, pPath[ i + res ].origin, r, 255, 0, true, s_flDisplayTime );

				// draw angles if close enough, for perf
				local dist = ( pt - viewOrigin ).LengthSqr();
				if ( dist < 2.3593e+6 )	// 1536
				{
					DrawLine( pt, pt + ToVector( pPath[i].angles ) * 16, 255, 128, 255, true, s_flDisplayTime );
				};
			}

			local bounds = false;
			local offset = 0;

			if ( m_Selection[0] )
			{
				bounds = true;
				VS.DrawSphere( m_PathData[ m_Selection[0] ].origin, 8.0, 6, 6, 255, 196, 0, true, s_flDisplayTime );
			};

			if ( m_Selection[1] )
			{
				bounds = true;
				VS.DrawSphere( m_PathData[ m_Selection[1] ].origin, 8.0, 6, 6, 255, 196, 0, true, s_flDisplayTime );
			};

			if ( bounds )
			{
				res = 2;

				if ( m_Selection[1] )
				{
					len = m_Selection[1] - m_Selection[0];
				}
				else
				{
					// in process of choosing the second point
					len = len - m_Selection[0];
				}

				offset = m_Selection[0];
			};

			m_nAnimPathIdx = (m_nAnimPathIdx + res) % len;
			local origin = pPath[ offset + m_nAnimPathIdx ].origin;
			s_vecMins.x = s_vecMins.y = 0.0; s_vecMins.z = 16.0;
			VS.DrawCapsule( origin - s_vecMins, origin + s_vecMins, 8, 0,255,255,true, s_flDisplayTime );

			// Path selection:
			// Find the frame on path the player is looking at around the nearest keyframe
			if ( m_fPathSelection != 0 )
			{
				if ( nNearestKey < 2 )
					nNearestKey = 2;
				else if ( nNearestKey > (count-4) )
					nNearestKey = count-4;;

				// Get the frame count up to this point
				local i = GetSampleCount( 1, nNearestKey-1 );

				local end = i +
					m_KeyFrames[nNearestKey-1].samplecount +
					m_KeyFrames[nNearestKey].samplecount +
					m_KeyFrames[nNearestKey+1].samplecount;

				local nSelect = 0;
				local flThreshold = 0.9;

				do
				{
					// This key might be out of the existing path range
					if ( !(i in m_PathData) )
						break;

					local dir = m_PathData[i].origin - viewOrigin;
					dir.Norm();
					local dot = viewForward.Dot( dir );

					if ( dot > flThreshold )
					{
						flThreshold = dot;
						nSelect = i;
					};
				} while ( ++i < end );

				m_nCurPathSelection = nSelect;

				VS.DrawSphere( m_PathData[nSelect].origin, 8.0, 6, 6, 255, 255, 0, true, s_flDisplayTime );
			}
		};
	};
}


function AnimThink()
{
	if ( m_bShowKeys )
	{
		local count = m_KeyFrames.len();
		if ( count )
		{
			++m_nAnimKeyframeIdx;
			m_nAnimKeyframeIdx %= count;

			local key = m_KeyFrames[ m_nAnimKeyframeIdx ];

			if ( m_nAnimKeyframeIdx != m_nSelectedKeyframe )
			{
				local dist = ( key.origin - CurrentViewOrigin() ).Length();
				if ( dist < 768.0 )
				{
					local s = dist / 128.0;

					DrawRectFilled( key.origin, s, 155, 255, 255, 255, 0.7, CurrentViewAngles() );
				}
				else
				{
					DrawRectFilled( key.origin, 8.0, 155, 255, 255, 255, 0.7, CurrentViewAngles() );
				}
			}
			else if ( m_bSeeing )
			{
				local mat = VMatrix();
				VS.WorldToScreenMatrix(
					mat,
					key.origin,
					key.forward,
					key.right,
					key.up,
					key._fovx, 1.77778, 4.0, 1024.0 );
				VS.MatrixInverseGeneral( mat, mat );

				local worldPos = VS.ScreenToWorld( 0.65, 0.35, mat );

				local s = key._fovx * 0.25;
				DrawRectFilled( worldPos, s, 155, 255, 255, 96, 0.25, key.angles );
				DrawRectFilled( worldPos, s, 155, 255, 255, 64, 0.5, key.angles );
			};;
		};
	};
}

// TODO: use SetThink
function FrameThink()
{
	if ( m_bGizmoEnabled )
		ManipulatorThink( m_KeyFrames[ m_nCurKeyframe ], MainViewOrigin(), MainViewForward(), MainViewAngles() );

	// indicate the camera is in a special state
	// TODO: use an overlay
	if ( m_bReplaceOnClick || m_bInsertOnClick )
	{
		local mat = VMatrix();
		VS.WorldToScreenMatrix(
			mat,
			MainViewOrigin(),
			MainViewForward(),
			MainViewRight(),
			MainViewUp(),
			106.26, 1.77778, 1.0, 16.0 );
		VS.MatrixInverseGeneral( mat, mat );

		local worldPos = VS.ScreenToWorld( 0.5, 0.63, mat );
		local angles = MainViewAngles();

		local maxs = Vector( 0.0, 5.0, 0.25 );
		local mins = Vector( 0.0, -5.0, -0.25 );

		local alpha = VS.SmoothCurve( Time() ) * 255;
		DrawBoxAnglesFilled( worldPos, mins, maxs, angles, 255, 120, 0, alpha, -1 );
	};

	// animate frustum
	if ( m_pLerpFrustum )
	{
		m_flLerpKeyAnim += 0.01;

		local out = KeyframeLerp( m_pLerpFrustum[0], m_pLerpFrustum[1], VS.SmoothCurve( m_flLerpKeyAnim ) );
		out.DrawFrustum( 155, 100, 155, 0.075 );

		if ( m_flLerpKeyAnim >= 1.0 )
		{
			m_flLerpKeyAnim = 0.0;
		};
	};

	// animate kf_transform
	if ( m_pLerpTransform )
	{
		local angles = MainViewAngles();

		local org = Vector();
		local c = m_pLerpTransform.len();
		for ( local i = 0; i < c; ++i )
		{
			VS.VectorLerp(
				m_pLerpTransform[i],
				m_KeyFrames[i].origin,
				VS.SmoothCurve( m_flLerpTransformAnim ),
				org );
			DrawRectFilled( org, 5, 155, 100, 155, 255, 0.075, angles )
		}

		m_flLerpTransformAnim += 0.01;

		if ( m_flLerpTransformAnim >= 1.0 )
		{
			m_flLerpTransformAnim = 0.0;
		};
	};
}

// write into static output
function KeyframeLerp( in1, in2, frac )
{
	local out = m_hLerpKeyframe;
	VS.VectorLerp( in1.origin, in2.origin, frac, out.origin );
	VS.QuaternionSlerp( in1.orientation, in2.orientation, frac, out.orientation );
	out.SetQuaternion( out.orientation ); // update transform matrix

	if ( in1._fovx != in2._fovx )
	{
		out.SetFov( VS.Lerp( in1._fovx, in2._fovx, frac ) );
	};

	return out;
}


//--------------------------------------------------------------
//--------------------------------------------------------------


g_v100 <- Vector(1,0,0);
g_v010 <- Vector(0,1,0);
g_v001 <- Vector(0,0,1);

local vAxisMin = Vector( -1, -1, -1 );
local vAxisMax = Vector( 32, 1, 1 );

local vPlaneMin = Vector();
local vPlaneMax = Vector();

local vRectMin = Vector();
local vRectMax = Vector();

function DrawRectFilled( pos, s, r, g, b, a, t, viewAngles ) : ( vRectMin, vRectMax )
{
	if ( s != vRectMax.z )
	{
		vRectMin.y = vRectMin.z = -s;
		vRectMax.y = vRectMax.z = s;
	};
	return DrawBoxAnglesFilled( pos, vRectMin, vRectMax, viewAngles, r, g, b, a, t );
}

function DrawRectOutlined( pos, s, r, g, b, a, t, viewAngles ) : ( vRectMin, vRectMax )
{
	local thickness = s * 0.25;
	local gap = s - thickness * 2.;

	vRectMin.x = vRectMax.x = 0.0;

	// left
	vRectMin.y = gap;		vRectMax.y = s;
	vRectMin.z = -s;		vRectMax.z = s;
	DrawBoxAnglesFilled( pos, vRectMin, vRectMax, viewAngles, r, g, b, a, t );

	// right
	vRectMin.y = -gap;		vRectMax.y = -s;
	vRectMin.z = -s;		vRectMax.z = s;
	DrawBoxAnglesFilled( pos, vRectMin, vRectMax, viewAngles, r, g, b, a, t );

	// bottom
	vRectMin.y = gap;		vRectMax.y = -s + gap;
	vRectMin.z = -s;		vRectMax.z = -gap;
	DrawBoxAnglesFilled( pos, vRectMin, vRectMax, viewAngles, r, g, b, a, t );

	// top
	vRectMin.y = -gap;		vRectMax.y = gap;
	vRectMin.z = gap;		vRectMax.z = s;
	DrawBoxAnglesFilled( pos, vRectMin, vRectMax, viewAngles, r, g, b, a, t );
}

function DrawCircle( pos, radius, r, g, b, z, t, viewUp, viewRight )
{
	local segment = 12;
	local step = PI * 2.0 / segment;

	local vecStart = pos + viewUp * radius;
	local vecPos = vecStart;

	while ( segment-- )
	{
		local s = sin( step * segment ) * radius;
		local c = cos( step * segment ) * radius;

		local vecLastPos = vecPos;
		vecPos = pos + viewUp * c + viewRight * s;

		DrawLine( vecLastPos, vecPos, r, g, b, z, t );
	}
}

function DrawGrid( pos, up, right, time )
{
	local scale = 16.0;
	local count = 8;
	local size = scale * count;

	// copy
	pos *= 1;
	// snap to grid
	pos.x = (pos.x / scale).tointeger() * scale;
	pos.y = (pos.y / scale).tointeger() * scale;
	pos.z = (pos.z / scale).tointeger() * scale;

	pos += up * (scale * count/2) - right * (scale * count/2);
	for ( local i = 0; i <= count; ++i )
	{
		pos += right * scale;
		local v1 = pos - up * size;
		v1.x = (v1.x / scale).tointeger() * scale;
		v1.y = (v1.y / scale).tointeger() * scale;
		v1.z = (v1.z / scale).tointeger() * scale;
		DrawLine( pos, v1, 100, 140, 220, true, time );
	}
	for ( local i = 0; i <= count; ++i )
	{
		local v1 = pos - right * size;
		v1.x = (v1.x / scale).tointeger() * scale;
		v1.y = (v1.y / scale).tointeger() * scale;
		v1.z = (v1.z / scale).tointeger() * scale;
		DrawLine( pos, v1, 100, 140, 220, true, time );
		pos -= up * scale;
	}
}

//
// Very basic screen plane, axis and plane translation manipulator.
// FIXME: Because of the drawing order, parts of the axes lag behind while moving
//
function ManipulatorThink( key, viewOrigin, viewForward, viewAngles )
	: ( vAxisMin, vAxisMax, vPlaneMin, vPlaneMax )
{
	local vecCursor;
	local nCursorG = 255, nCursorB = 255;

	local deltaOrigin = viewOrigin - key.origin;
	local flScale = deltaOrigin.Length() / 450.0;
	if ( flScale < 1.0 )
		flScale = 1.0;

	if ( !IsDucking() )
	{
		local flScaleX1 = 32.0 * flScale; // box length
		local flScaleX2 = 2.0 * flScale; // box thickness
		local flScaleXY1 = 11.0 * flScale; // plane distance
		local flScaleXY2 = 20.0 * flScale; // plane size

		// stopped ducking
		if ( m_vecCameraOffset )
		{
			CameraSetEnabled(0);
			m_vecCameraOffset = null;
			m_nSelectedKeyframe = -1;

			// if duck was let go before mouse while rotating,
			// remember this for when duck is held again without releasing mouse
			if ( m_bMouseDown )
			{
				m_bMouseDown = false;
				m_bMouseForceUp = true;
			};
		};

		// if not ducking and dont have a selection (axis or plane)
		if ( !m_nTranslation )
		{
			key.DrawFrustum( 255, 200, 255, -1 );

			local t;

			local rayDelta = viewForward * MAX_TRACE_LENGTH;
			local nSelection;

			// Screen plane translation
			if ( VS.IsRayIntersectingSphere( viewOrigin, rayDelta, key.origin, 6.0 ) )
			{
				nSelection = 1;
				DrawRectFilled( key.origin, 4, 0,255,255,255, -1, viewAngles );
			}
			else
			{
				DrawRectFilled( key.origin, 4, 255,120,0,255, -1, viewAngles );
			};


			// Local camera axes looking down +z

			// test Z
			vAxisMax.x = vAxisMax.y = flScaleX2; vAxisMax.z = flScaleX1;

			if ( !nSelection && VS.IsBoxIntersectingRay( key.origin + vAxisMin, key.origin + vAxisMax, viewOrigin, rayDelta ) )
			{
				nSelection = 2;
				t = VS.IntersectRayWithPlane( deltaOrigin, viewForward, g_v010, 0.0 );
				DrawBox( key.origin, vAxisMin, vAxisMax, 120,120,255,255, -1 );
			}
			else
			{
				DrawBox( key.origin, vAxisMin, vAxisMax, 0,0,255,255, -1 );
			};


			// test X
			vAxisMax.z = vAxisMax.y = flScaleX2; vAxisMax.x = flScaleX1;

			if ( !nSelection && VS.IsBoxIntersectingRay( key.origin + vAxisMin, key.origin + vAxisMax, viewOrigin, rayDelta ) )
			{
				nSelection = 3;
				t = VS.IntersectRayWithPlane( deltaOrigin, viewForward, g_v001, 0.0 );
				DrawBox( key.origin, vAxisMin, vAxisMax, 255,120,120,255, -1 );
			}
			else
			{
				DrawBox( key.origin, vAxisMin, vAxisMax, 255,0,0,255, -1 );
			};


			// test Y
			vAxisMax.x = vAxisMax.z = flScaleX2; vAxisMax.y = flScaleX1;

			if ( !nSelection && VS.IsBoxIntersectingRay( key.origin + vAxisMin, key.origin + vAxisMax, viewOrigin, rayDelta ) )
			{
				nSelection = 4;
				t = VS.IntersectRayWithPlane( deltaOrigin, viewForward, g_v001, 0.0 );
				DrawBox( key.origin, vAxisMin, vAxisMax, 180,255,120,255, -1 );
			}
			else
			{
				DrawBox( key.origin, vAxisMin, vAxisMax, 0,255,0,255, -1 );
			};


			// test XY
			vPlaneMin.z = 0.0; vPlaneMin.x = vPlaneMin.y = flScaleXY1;
			vPlaneMax.z = 0.0; vPlaneMax.x = vPlaneMax.y = flScaleXY2;

			if ( !nSelection && VS.IsBoxIntersectingRay( key.origin + vPlaneMin, key.origin + vPlaneMax, viewOrigin, rayDelta ) )
			{
				nSelection = 5;
				t = VS.IntersectRayWithPlane( deltaOrigin, viewForward, g_v001, 0.0 );
				DrawBox( key.origin, vPlaneMin, vPlaneMax, 120,120,255,255, -1 );
			}
			else
			{
				DrawBox( key.origin, vPlaneMin, vPlaneMax, 0,0,255,255, -1 );
			};


			// test YZ
			vPlaneMin.x = 0.0; vPlaneMin.y = vPlaneMin.z = flScaleXY1;
			vPlaneMax.x = 0.0; vPlaneMax.y = vPlaneMax.z = flScaleXY2;

			if ( !nSelection && VS.IsBoxIntersectingRay( key.origin + vPlaneMin, key.origin + vPlaneMax, viewOrigin, rayDelta ) )
			{
				nSelection = 6;
				t = VS.IntersectRayWithPlane( deltaOrigin, viewForward, g_v100, 0.0 );
				DrawBox( key.origin, vPlaneMin, vPlaneMax, 255,120,120,255, -1 );
			}
			else
			{
				DrawBox( key.origin, vPlaneMin, vPlaneMax, 255,0,0,255, -1 );
			};


			// test XZ
			vPlaneMin.y = 0.0; vPlaneMin.x = vPlaneMin.z = flScaleXY1;
			vPlaneMax.y = 0.0; vPlaneMax.x = vPlaneMax.z = flScaleXY2;

			if ( !nSelection && VS.IsBoxIntersectingRay( key.origin + vPlaneMin, key.origin + vPlaneMax, viewOrigin, rayDelta ) )
			{
				nSelection = 7;
				t = VS.IntersectRayWithPlane( deltaOrigin, viewForward, g_v010, 0.0 );
				DrawBox( key.origin, vPlaneMin, vPlaneMax, 180,255,180,255, -1 );
			}
			else
			{
				DrawBox( key.origin, vPlaneMin, vPlaneMax, 0,255,0,255, -1 );
			};


			// default to screen plane
			if ( !t )
				t = VS.IntersectRayWithPlane( deltaOrigin, viewForward, viewForward*-1, 0.0 );
			vecCursor = viewOrigin + viewForward * t;

			if ( nSelection )
			{
				if ( m_bMouseDown )
				{
					m_nTranslation = nSelection;
					m_nSelectedKeyframe = m_nCurKeyframe;

					m_vecOffset = vecCursor - key.origin;
					VS.VectorCopy( key.origin, m_vecLastKeyOrigin );
					m_vecLastDeltaOrigin = deltaOrigin;
					m_vecLastOrigin = viewOrigin;
					m_vecLastForward = viewForward;
					m_vecLastUp = MainViewUp();
					m_vecLastRight = MainViewRight();

					// HACKHACK: can't be bothered to find a proper solution to moving view angles while translating,
					// just freeze the player in place so the planes don't mess up
					player.SetMoveType( 0 );
				}
				else if ( m_nMouseOver != nSelection )
				{
					m_nMouseOver = nSelection;
					PlaySound( SND_TRANSLATOR_MOUSEOVER );
				};;
			}
			else if ( m_nMouseOver )
			{
				m_nMouseOver = 0;
			};;
		}
		// if not ducking and have a selection (axis or plane)
		else
		{
			local nSelection = m_nTranslation;
			// Assert( nSelection, "m_nTranslation == 0" );


			if ( nSelection == 1 )
			{
				local t = m_vecLastDeltaOrigin.Length();
				vecCursor = m_vecLastOrigin + viewForward * t;

				key.SetOrigin( vecCursor - m_vecOffset );

				DrawRectFilled( key.origin, 4, 255,255,0,255, -1, viewAngles );
				// Draw a sphere for spherical translation
				VS.DrawSphere( viewOrigin, 8, 32, 24, 100, 140, 220, true, -1 );
			}
			else
			{
				DrawRectFilled( key.origin, 4, 255,120,0,255, -1, viewAngles );
			};


			// Z
			vAxisMax.x = vAxisMax.y = flScaleX2; vAxisMax.z = flScaleX1;

			if ( nSelection == 2 )
			{
				local t = VS.IntersectRayWithPlane( m_vecLastDeltaOrigin, viewForward, g_v010, 0.0 );
				t = clamp( t, 0.0, 4096.0 );

				vecCursor = m_vecLastOrigin + viewForward * t;

				key.origin.z = vecCursor.z - m_vecOffset.z;
				key.SetOrigin( key.origin );

				DrawBox( key.origin, vAxisMin, vAxisMax, 255,255,0,255, -1 );
				DrawGrid( key.origin, g_v001, g_v100, -1 );
			}
			else
			{
				DrawBox( key.origin, vAxisMin, vAxisMax, 0,0,255,255, -1 );
			};


			// X
			vAxisMax.z = vAxisMax.y = flScaleX2; vAxisMax.x = flScaleX1;

			if ( nSelection == 3 )
			{
				local t = VS.IntersectRayWithPlane( m_vecLastDeltaOrigin, viewForward, g_v001, 0.0 );
				t = clamp( t, 0.0, 4096.0 );

				vecCursor = m_vecLastOrigin + viewForward * t;

				key.origin.x = vecCursor.x - m_vecOffset.x;
				key.SetOrigin( key.origin );

				DrawBox( key.origin, vAxisMin, vAxisMax, 255,255,0,255, -1 );
				DrawGrid( key.origin, g_v100, g_v010, -1 );
			}
			else
			{
				DrawBox( key.origin, vAxisMin, vAxisMax, 255,0,0,255, -1 );
			};


			// Y
			vAxisMax.x = vAxisMax.z = flScaleX2; vAxisMax.y = flScaleX1;

			if ( nSelection == 4 )
			{
				local t = VS.IntersectRayWithPlane( m_vecLastDeltaOrigin, viewForward, g_v001, 0.0 );
				t = clamp( t, 0.0, 4096.0 );

				vecCursor = m_vecLastOrigin + viewForward * t;

				key.origin.y = vecCursor.y - m_vecOffset.y;
				key.SetOrigin( key.origin );

				DrawBox( key.origin, vAxisMin, vAxisMax, 255,255,0,255, -1 );
				DrawGrid( key.origin, g_v010, g_v100, -1 );
			}
			else
			{
				DrawBox( key.origin, vAxisMin, vAxisMax, 0,255,0,255, -1 );
			};


			// XY
			vPlaneMin.z = 0.0; vPlaneMin.x = vPlaneMin.y = flScaleXY1;
			vPlaneMax.z = 0.0; vPlaneMax.x = vPlaneMax.y = flScaleXY2;

			if ( nSelection == 5 )
			{
				local t = VS.IntersectRayWithPlane( m_vecLastDeltaOrigin, viewForward, g_v001, 0.0 );
				t = clamp( t, 0.0, 4096.0 );

				vecCursor = m_vecLastOrigin + viewForward * t;

				key.origin.x = vecCursor.x - m_vecOffset.x;
				key.origin.y = vecCursor.y - m_vecOffset.y;
				key.SetOrigin( key.origin );

				DrawBox( key.origin, vPlaneMin, vPlaneMax, 255,255,0,255, -1 );
				DrawGrid( key.origin, g_v010, g_v100, -1 );
			}
			else
			{
				DrawBox( key.origin, vPlaneMin, vPlaneMax, 0,0,255,255, -1 );
			};


			// YZ
			vPlaneMin.x = 0.0; vPlaneMin.y = vPlaneMin.z = flScaleXY1;
			vPlaneMax.x = 0.0; vPlaneMax.y = vPlaneMax.z = flScaleXY2;

			if ( nSelection == 6 )
			{
				local t = VS.IntersectRayWithPlane( m_vecLastDeltaOrigin, viewForward, g_v100, 0.0 );
				t = clamp( t, 0.0, 4096.0 );

				vecCursor = m_vecLastOrigin + viewForward * t;

				key.origin.y = vecCursor.y - m_vecOffset.y;
				key.origin.z = vecCursor.z - m_vecOffset.z;
				key.SetOrigin( key.origin );

				DrawBox( key.origin, vPlaneMin, vPlaneMax, 255,255,0,255, -1 );
				DrawGrid( key.origin, g_v010, g_v001, -1 );
			}
			else
			{
				DrawBox( key.origin, vPlaneMin, vPlaneMax, 255,0,0,255, -1 );
			};


			// XZ
			vPlaneMin.y = 0.0; vPlaneMin.x = vPlaneMin.z = flScaleXY1;
			vPlaneMax.y = 0.0; vPlaneMax.x = vPlaneMax.z = flScaleXY2;

			if ( nSelection == 7 )
			{
				local t = VS.IntersectRayWithPlane( m_vecLastDeltaOrigin, viewForward, g_v010, 0.0 );
				t = clamp( t, 0.0, 4096.0 );

				vecCursor = m_vecLastOrigin + viewForward * t;

				key.origin.x = vecCursor.x - m_vecOffset.x;
				key.origin.z = vecCursor.z - m_vecOffset.z;
				key.SetOrigin( key.origin );

				DrawBox( key.origin, vPlaneMin, vPlaneMax, 255,255,0,255, -1 );
				DrawGrid( key.origin, g_v100, g_v001, -1 );
			}
			else
			{
				DrawBox( key.origin, vPlaneMin, vPlaneMax, 0,255,0,255, -1 );
			};


			vAxisMax.x = 0.0; vAxisMax.y = vAxisMax.z = 2.0;
			DrawBoxAnglesFilled( m_vecLastKeyOrigin, vAxisMax*-1, vAxisMax, viewAngles, 255,255,255,64, -1 );
			DrawLine( m_vecLastKeyOrigin, key.origin, 255,255,255,true, -1 );
		};

		if ( m_bDuckFixup )
		{
			local v = player.GetOrigin();
			v.z -= 9.017594;
			player.SetOrigin( v );
			m_bDuckFixup = false;
		};
	}
	// ducking, rotate camera around cursor
	else if ( !m_nTranslation )
	{
		if ( !m_bDuckFixup )
		{
			local v = player.GetOrigin();
			v.z += 9.017594;
			player.SetOrigin( v );
			m_bDuckFixup = true;
		};

		if ( m_bMouseForceUp )
		{
			m_bMouseDown = true;
			m_bMouseForceUp = false;
		};

		key.DrawFrustum( 255, 200, 255, -1 );

		local deltaOrigin = viewOrigin - key.origin;

		// If player is looking too far away from the current key, trace against the world for pivot point
		local vDt = deltaOrigin * -1; vDt.Norm();
		if ( vDt.Dot( viewForward ) < cos( DEG2RAD * 10 ) )
		{
			const MASK_SOLID = 0x200400b;
			local tr = VS.TraceLine( viewOrigin, viewOrigin + viewForward * MAX_COORD_FLOAT, player.self, MASK_SOLID );
			vecCursor = tr.GetPos();

			// different cursor colour
			nCursorG = 0;
			nCursorB = 0;
		}
		else
		{
			local t = VS.IntersectRayWithPlane( deltaOrigin, viewForward, viewForward*-1, 0.0 );
			vecCursor = viewOrigin + viewForward * t;
		};

		if ( m_bMouseDown )
		{
			if ( !m_vecCameraOffset )
			{
				CameraSetEnabled(1);
				CameraSetOrigin( viewOrigin );
				CameraSetForward( viewForward );

				m_vecPivotPoint = vecCursor;

				m_nSelectedKeyframe = m_nCurKeyframe;
				m_vecCameraOffset = viewOrigin - vecCursor;
				m_vecLastForwardFrame = viewForward;
			}
			else
			{
				local deltaForward = viewForward - m_vecLastForwardFrame;

				if ( !VS.VectorIsZero( deltaForward ) )
				{
					local pos = m_vecPivotPoint - viewForward * m_vecCameraOffset.Length();
					CameraSetOrigin( pos );
					CameraSetForward( viewForward );

					pos.z -= 46.0;
					player.SetOrigin( pos );
				};

				m_vecLastForwardFrame = viewForward;
			};
		}
		else if ( m_vecCameraOffset )
		{
			CameraSetEnabled(0);
			m_vecCameraOffset = null;
			m_nSelectedKeyframe = -1;
		};;
	}
	// ducking while translating
	else
	{
		vecCursor = key.origin;
	};;

	// draw cursor
	DrawRectFilled( vecCursor, 2 * flScale, 255, nCursorG, nCursorB, 255, -1, viewAngles );
}



class CUndoTranslation extends CUndoElement
{
	function Undo()
	{
		Base.m_KeyFrames[ m_nKeyIndex ].transform = clone m_xformOld;
		Base.m_KeyFrames[ m_nKeyIndex ].UpdateFromMatrix();
	}

	function Redo()
	{
		Base.m_KeyFrames[ m_nKeyIndex ].transform = clone m_xformNew;
		Base.m_KeyFrames[ m_nKeyIndex ].UpdateFromMatrix();
	}

	function Desc()
	{
		return "translation #" + m_nKeyIndex;
	}

	m_nKeyIndex = null;
	m_xformOld = null;
	m_xformNew = null;
}

function GizmoOnMouseDown()
{
	local pUndo = m_pUndoTranslation = CUndoTranslation();
	pUndo.m_nKeyIndex = m_nCurKeyframe;
	m_pUndoTranslation.m_xformOld = clone m_KeyFrames[ m_nCurKeyframe ].transform;

	m_bMouseDown = true;
}

function GizmoOnMouseRelease()
{
	if ( m_nTranslation )
	{
		m_pUndoTranslation.m_xformNew = clone m_KeyFrames[ m_nCurKeyframe ].transform;
		PushUndo( m_pUndoTranslation );
	};

	m_pUndoTranslation = null;

	m_bMouseDown = false;
	m_bMouseForceUp = false;
	player.SetMoveType( 8 );

	if ( m_nTranslation )
	{
		PlaySound( SND_TRANSLATOR_MOVED );
		m_nSelectedKeyframe = -1;
		m_nTranslation = 0;
		m_bDirty = true;

		//
		// Compile path around the current key frame for live feedback
		//

		// FIXME
		if ( m_bAutoFillBoundaries )
			return;

		local max = m_KeyFrames.len()-2;
		if ( max < 0 )
			return;

		local cur = m_nCurKeyframe;
		if ( cur < 2 )
			cur = 2;
		else if ( cur > max )
			cur = max;;

		// Get the frame count up to this point
		local offset = GetSampleCount( 1, cur-1 );

		// Copied from _Process::CompilePath
		for ( local nKeyIdx = cur-1; nKeyIdx <= cur; ++nKeyIdx )
		{
			if ( !( ( nKeyIdx + 2 ) in m_KeyFrames ) )
				break;

			local key = m_KeyFrames[nKeyIdx];

			local nSampleFrame = 0;

			local flCurTime = 0.0;
			local flKeyFrameTime = key.frametime;

			for ( ; flCurTime < flKeyFrameTime; flCurTime += g_FrameTime, ++nSampleFrame )
			{
				local i = offset + nSampleFrame;

				// This key might be out of the existing path range
				if ( !(i in m_PathData) )
					return;

				local t = flCurTime / flKeyFrameTime;

				local org = Vector();
				local ang = Vector();
				_Process.SplineOrigin( nKeyIdx, t, org );
				_Process.SplineAngles( nKeyIdx, t, ang );

				local frame = m_PathData[ i ];
				frame.origin = org;
				frame.angles = ang;
			}

			if ( nSampleFrame != (flKeyFrameTime / g_FrameTime).tointeger() )
				Msg(Fmt( "\nERROR: Compiled frame count does not match keyframe sample count value! %d, %d\n",
					nSampleFrame,
					(key.frametime / g_FrameTime).tointeger() ));

			offset += nSampleFrame;
		}
	};
}

function ShowGizmo( i = null )
{
	if ( i == null )
		i = !m_bGizmoEnabled;

	if ( i && !m_KeyFrames.len() )
		return MsgFail("No keyframes found.\n");

	m_bGizmoEnabled = !!i;

	Msg("Translation manipulator " + m_bGizmoEnabled.tointeger() + "\n");

	if ( m_bGizmoEnabled )
	{
		m_hThinkAnim.__KeyValueFromFloat( "nextthink", -1 );
		m_nAnimKeyframeIdx = -1;
	}
	else
	{
		m_hThinkAnim.__KeyValueFromFloat( "nextthink", 1 );
	};

	PlaySound( SND_BUTTON );
}


//--------------------------------------------------------------
//--------------------------------------------------------------


function PushUndo( pUndoElem )
{
	local nStackLen = m_UndoStack.len();

	// truncate future
	// check range to reduce unnecessary shrink reallocations
	if ( m_nUndoLevel < nStackLen )
		m_UndoStack.resize( m_nUndoLevel );

	if ( nStackLen >= m_nMaxUndoDepth )
	{
		m_nUndoLevel--;
		m_UndoStack.remove(0);
	};

	m_UndoStack.append( pUndoElem );
	m_nUndoLevel++;
}

// kf_undo
function Undo()
{
	if ( m_bCompiling )
		return MsgFail("Cannot modify keyframes while compiling!\n");

	if ( !m_UndoStack.len() || m_nUndoLevel <= 0 || m_pUndoTranslation || m_pUndoLoad )
		return MsgFail("cannot undo\n");

	m_nUndoLevel--;
	local undo = m_UndoStack[ m_nUndoLevel ];
	undo.Undo();

	// Truncate if there are no more redos
	if ( !undo.CanRedo() )
	{
		m_UndoStack.resize( m_nUndoLevel );
	};

	Msg(Fmt( "Undo: %s\n", undo.Desc() ));

	m_bDirty = true;

	PlaySound( SND_BUTTON );
}

// kf_redo
function Redo()
{
	if ( m_bCompiling )
		return MsgFail("Cannot modify keyframes while compiling!\n");

	if ( !m_UndoStack.len() || m_nUndoLevel > m_UndoStack.len() - 1 || m_pUndoTranslation || m_pUndoLoad )
		return MsgFail("cannot redo\n");

	local undo = m_UndoStack[ m_nUndoLevel ];
	m_nUndoLevel++;
	undo.Redo();

	Msg(Fmt( "Redo: %s\n", undo.Desc() ));

	m_bDirty = true;

	PlaySound( SND_BUTTON );
}

// kf_undo_history
function PrintUndoStack()
{
	local v = m_nUndoLevel - 1;
	local c = m_UndoStack.len() - 1;

	local i = v - 8;
	local j = v + 8;

	// lower limit
	if ( i < 0 )
	{
		i = 0;
		j = 16;
	};

	// upper limit
	if ( j > c )
	{
		j = c;
		i = j - 16;

		// less than 16 actions
		if ( i < 0 )
			i = 0;
	};

	local lower = i > 0, upper = j < c;

	Msg( "+-------------------------------+\n" );
	Msg(Fmt( "| Action history    [%3d / %3d] |\n", v, c ));

	if ( lower )
	{
		Msg( "|         ^\n" );
	}
	else
	{
		Msg( "+-------------------------------+\n" );
	}

	for ( ; i <= j; ++i )
	{
		if ( i == v ) // head
		{
			Msg(Fmt( "|===> %3d : %s\n", i, m_UndoStack[i].Desc() ));
		}
		else
		{
			Msg(Fmt( "|     %3d : %s\n", i, m_UndoStack[i].Desc() ));
		}
	}

	if ( upper )
	{
		Msg( "|         v\n" );
	}
	else
	{
		Msg( "+-------------------------------+\n" );
	}
}


//--------------------------------------------------------------
//--------------------------------------------------------------


// kf_copy
// Set player pos/ang to the current keyframe
function CopyKeyframe()
{
	if ( !m_KeyFrames.len() )
		return MsgFail("No keyframes found.\n");

	if ( !m_bInEditMode )
		return MsgFail("You need to be in edit mode to copy.\n");

	if ( m_bSeeing )
		return MsgFail("Cannot copy while seeing!\n");

	local key = m_KeyFrames[ m_nCurKeyframe ];

	SetViewOrigin( key.origin );
	SetViewForward( key.forward );

	MsgHint(Fmt( "Copied keyframe #%d\n", m_nCurKeyframe ));
	PlaySound( SND_BUTTON );
}

function StopReplaceLerp()
{
	m_pLerpFrustum = null;
	m_hLerpKeyframe = null;
	m_flLerpKeyAnim = null;
}


class CUndoReplaceKeyframe extends CUndoElement
{
	function Undo()
	{
		Base.m_KeyFrames[ m_nKeyIndex ].Copy( m_pOldFrame );
	}

	function Redo()
	{
		Base.m_KeyFrames[ m_nKeyIndex ].Copy( m_pNewFrame );
	}

	function Desc()
	{
		return "replace #" + m_nKeyIndex;
	}

	m_nKeyIndex = null;
	m_pOldFrame = null;
	m_pNewFrame = null;
}

// kf_replace
function ReplaceKeyframe( bClick = 0 )
{
	if ( m_bCompiling )
		return MsgFail("Cannot modify keyframes while compiling!\n");

	if ( !m_KeyFrames.len() )
		return MsgFail("No keyframes found.\n");

	if ( !m_bInEditMode )
		return MsgFail("You need to be in edit mode to insert keyframes.\n");

	// Unsee and activate click to replace at current position
	if ( m_bSeeing )
	{
		SeeKeyframe( 1, 0 );

		// copy
		local key = m_KeyFrames[ m_nCurKeyframe ];
		SetViewOrigin( key.origin );
		SetViewForward( key.forward );
	};

	if ( !bClick )
	{
		if ( m_nSelectedKeyframe == -1 )
		{
			m_bReplaceOnClick = true;
			m_nSelectedKeyframe = m_nCurKeyframe;

			MsgHint(Fmt( "Left click to replace keyframe #%d...\n", m_nCurKeyframe ));
			PlaySound( SND_BUTTON );
			return;
		};

		// Cancel if mouse was not clicked
		if ( m_bReplaceOnClick )
		{
			OnMouse2Pressed();
			return;
		};
	};

	m_bReplaceOnClick = false;
	m_nSelectedKeyframe = -1;

	local key = m_KeyFrames[ m_nCurKeyframe ];
	local keyCopy = clone key;

	m_pLerpFrustum = [ keyCopy, key ];
	m_hLerpKeyframe = keyframe_t();
	m_flLerpKeyAnim = 0.0;

	VS.EventQueue.CancelEventsByInput( StopReplaceLerp );
	// animate it 5 times
	VS.EventQueue.AddEvent( StopReplaceLerp, 5 * 100 * FrameTime(), this );

	local pos = MainViewOrigin();
	local ang = MainViewAngles();
	local dir = MainViewForward();

	key.SetAngles( ang );
	key.SetOrigin( pos );
	key.SetFov( null );

	local pUndo = CUndoReplaceKeyframe();
	PushUndo( pUndo );
	pUndo.m_nKeyIndex = m_nCurKeyframe;
	pUndo.m_pOldFrame = keyCopy;
	pUndo.m_pNewFrame = clone key;

	m_bDirty = true;

	DrawLine( pos, pos + dir * 64, 127, 255, 0, true, 1.5 );
	DrawBoxAnglesFilled( pos, Vector(-4,-4,-4), Vector(4,4,4), ang, 127, 255, 0, 127, 1.5 );

	MsgHint(Fmt( "Replaced keyframe #%d\n", m_nCurKeyframe ));
	PlaySound( SND_BUTTON );
}


class CUndoInsertKeyframe extends CUndoElement
{
	function Undo()
	{
		Base.m_KeyFrames.remove( m_nKeyIndex );

		// Reset selection
		if ( Base.m_nCurKeyframe == m_nKeyIndex || Base.m_nSelectedKeyframe == -1 )
		{
			Base.m_nCurKeyframe = 0;
			Base.m_nSelectedKeyframe = -1;
		}
	}

	function Redo()
	{
		Base.m_KeyFrames.insert( m_nKeyIndex, m_pNewFrame );
	}

	function Desc()
	{
		return "insert #" + m_nKeyIndex;
	}

	m_nKeyIndex = null;
	m_pNewFrame = null;
}

// kf_insert
function InsertKeyframe( bClick = 0 )
{
	if ( m_bCompiling )
		return MsgFail("Cannot modify keyframes while compiling!\n");

	if ( !m_KeyFrames.len() )
		return MsgFail("No keyframes found.\n");

	if ( !m_bInEditMode )
		return MsgFail("You need to be in edit mode to insert keyframes.\n");

	// Unsee and activate click to insert at current position
	if ( m_bSeeing )
	{
		SeeKeyframe( 1, 0 );

		// copy
		local key = m_KeyFrames[ m_nCurKeyframe ];
		SetViewOrigin( key.origin );
		SetViewForward( key.forward );
	};

	if ( !bClick )
	{
		if ( m_nSelectedKeyframe == -1 )
		{
			m_bInsertOnClick = true;
			m_nSelectedKeyframe = m_nCurKeyframe;

			MsgHint(Fmt( "Left click to insert keyframe at #%d...\n", m_nCurKeyframe ));
			PlaySound( SND_BUTTON );
			return;
		};

		// Cancel if mouse was not clicked
		if ( m_bInsertOnClick )
		{
			OnMouse2Pressed();
			return;
		};
	};

	m_bInsertOnClick = false;
	m_nSelectedKeyframe = -1;

	local pos = MainViewOrigin();
	local ang = MainViewAngles();
	local dir = MainViewForward();

	local key = keyframe_t();
	key.SetOrigin( pos );
	key.SetAngles( ang );
	m_KeyFrames.insert( m_nCurKeyframe, key );

	local pUndo = CUndoInsertKeyframe();
	PushUndo( pUndo );
	pUndo.m_nKeyIndex = m_nCurKeyframe;
	pUndo.m_pNewFrame = clone key;

	m_bDirty = true;

	DrawLine( pos, pos + dir * 64, 127, 255, 0, true, 1.5 );
	DrawBoxAnglesFilled( pos, Vector(-4,-4,-4), Vector(4,4,4), ang, 127, 255, 0, 127, 1.5 );

	MsgHint(Fmt( "Inserted keyframe #%d\n", m_nCurKeyframe ));
	PlaySound( SND_BUTTON );
}


class CUndoRemoveKeyframe extends CUndoElement
{
	function Undo()
	{
		Base.m_KeyFrames.insert( m_nKeyIndex, m_pOldFrame );
	}

	function Redo()
	{
		Base.m_KeyFrames.remove( m_nKeyIndex );

		// Reset selection
		if ( Base.m_nCurKeyframe == m_nKeyIndex || Base.m_nSelectedKeyframe == -1 )
		{
			Base.m_nCurKeyframe = 0;
			Base.m_nSelectedKeyframe = -1;
		}

		Base.CheckAnyKeysLeft();
	}

	function Desc()
	{
		return "remove #" + m_nKeyIndex;
	}

	m_nKeyIndex = null;
	m_pOldFrame = null;
}

// kf_remove
function RemoveKeyframe()
{
	if ( m_bCompiling )
		return MsgFail("Cannot modify keyframes while compiling!\n");

	if ( !m_KeyFrames.len() )
		return MsgFail("No keyframes found.\n");

	if ( !m_bInEditMode )
		return MsgFail("You need to be in edit mode to remove keyframes.\n");

	// unsee
	if ( m_bSeeing )
		SeeKeyframe(1);

	local key = m_KeyFrames.remove( m_nCurKeyframe );

	local pUndo = CUndoRemoveKeyframe();
	PushUndo( pUndo );
	pUndo.m_nKeyIndex = m_nCurKeyframe;
	pUndo.m_pOldFrame = clone key;

	if ( !m_KeyFrames.len() )
	{
		MsgHint("Removed all keyframes.\n");

		CheckAnyKeysLeft();
	}
	else
	{
		MsgHint(Fmt( "Removed keyframe #%d\n", m_nCurKeyframe ));

		// if out of bounds, reset
		if ( !(m_nCurKeyframe in m_KeyFrames) )
		{
			m_nCurKeyframe = 0;
			m_nSelectedKeyframe = -1;
		};
	};

	m_bDirty = true;

	PlaySound( SND_BUTTON );
}


class CUndoRemoveFOV extends CUndoElement
{
	function Undo()
	{
		Base.m_KeyFrames[ m_nKeyIndex ].SetFov( m_nFov );
	}

	function Redo()
	{
		Base.m_KeyFrames[ m_nKeyIndex ].SetFov( null );
	}

	function Desc()
	{
		return "remove fov #" + m_nKeyIndex;
	}

	m_nKeyIndex = null;
	m_nFov = null;
}

// kf_removefov
function RemoveFOV()
{
	if ( m_bCompiling )
		return MsgFail("Cannot modify keyframes while compiling!\n");

	if ( !m_bInEditMode )
		return MsgFail("You need to be in edit mode to remove FOV data.\n");

	// refresh
	if ( m_bSeeing )
		CameraSetFov( 0, 0.1 );

	local key = m_KeyFrames[ m_nCurKeyframe ];
	if ( !key.fov )
		return MsgFail(Fmt( "No FOV data on keyframe #%d found.\n", m_nCurKeyframe ));

	local pUndo = CUndoRemoveFOV();
	PushUndo( pUndo );
	pUndo.m_nKeyIndex = m_nCurKeyframe;
	pUndo.m_nFov = key.fov;

	key.SetFov( null );

	CompileFOV();

	MsgHint(Fmt( "Removed FOV data at keyframe #%d\n", m_nCurKeyframe ));
	PlaySound( SND_BUTTON );
}


class CUndoAddKeyframe extends CUndoElement
{
	function Undo()
	{
		Base.m_KeyFrames.pop();

		// Reset selection
		if ( Base.m_nCurKeyframe == Base.m_KeyFrames.len()-1 || Base.m_nSelectedKeyframe == -1 )
		{
			Base.m_nCurKeyframe = 0;
			Base.m_nSelectedKeyframe = -1;
		}

		Base.CheckAnyKeysLeft();
	}

	function Redo()
	{
		Base.ArrayAppend( Base.m_KeyFrames, m_pNewFrame );
	}

	m_pNewFrame = null;
}

// kf_add
function AddKeyframe()
{
	if ( m_bCompiling )
		return MsgFail("Cannot modify keyframes while compiling!\n");

	if ( m_bSeeing )
		return MsgFail("Cannot add new keyframe while seeing!\n");

	local pos = MainViewOrigin();
	local ang = MainViewAngles();
	local dir = MainViewForward();

	local key = keyframe_t();
	key.SetOrigin( pos );
	key.SetAngles( ang );
	ArrayAppend( m_KeyFrames, key );

	local pUndo = CUndoAddKeyframe( "add #" + (m_KeyFrames.len()-1) );
	PushUndo( pUndo );
	pUndo.m_pNewFrame = clone key;

	m_bDirty = true;

	local t = m_bInEditMode ? 1.5 : 7.0;
	DrawLine( pos, pos + dir * 64, 127, 255, 0, true, t );
	DrawBoxAnglesFilled( pos, Vector(-4,-4,-4), Vector(4,4,4), ang, 127, 255, 0, 127, t );

	MsgHint(Fmt( "Added keyframe #%d\n", (m_KeyFrames.len()-1) ));
	PlaySound( SND_BUTTON );
}


class CUndoRemoveAllKeyframes extends CUndoElement
{
	function Undo()
	{
		Base.m_KeyFrames.resize( m_pFrames.len() );

		foreach( i, v in m_pFrames )
		{
			Base.m_KeyFrames[i] = clone v;
		}
	}

	function Redo()
	{
		Base.m_KeyFrames.clear();
		Base.CheckAnyKeysLeft();
	}

	function Desc()
	{
		return "clear";
	}

	function Clone()
	{
		m_pFrames = clone Base.m_KeyFrames;

		foreach ( i, v in Base.m_KeyFrames )
		{
			m_pFrames[i] = clone v;
		}
	}

	m_pFrames = null;
}

// kf_clear
function RemoveAllKeyframes()
{
	if ( m_bCompiling )
		return MsgFail("Cannot modify keyframes while compiling!\n");

	if ( !m_KeyFrames.len() )
		return MsgFail("No keyframes found.\n");

	// unsee
	if ( m_bSeeing )
		SeeKeyframe(1);

	local pUndo = CUndoRemoveAllKeyframes();
	PushUndo( pUndo );
	pUndo.Clone();

	MsgHint(Fmt( "Removed %d keyframes.\n", m_KeyFrames.len() ));

	m_KeyFrames.clear();

	CheckAnyKeysLeft();

	m_bDirty = true;

	// cheap way to hide the sprite
	SetHelperOrigin( MAX_COORD_VEC );

	PlaySound( SND_BUTTON );
}

// Reset things
function CheckAnyKeysLeft()
{
	if ( !(0 in m_KeyFrames) )
	{
		m_nCurKeyframe = 0;
		m_nSelectedKeyframe = -1;

		m_bGizmoEnabled = false;

		// cheap way to hide the sprite
		SetHelperOrigin( MAX_COORD_VEC );
	};
}


const KF_INTERP_CATMULL_ROM			= 0;;
const KF_INTERP_CATMULL_ROM_NORM	= 1;;
const KF_INTERP_CATMULL_ROM_DIR		= 2;;
const KF_INTERP_LINEAR				= 3;;
const KF_INTERP_LINEAR_BLEND		= 4;;
const KF_INTERP_D3DX				= 5;;
const KF_INTERP_BSPLINE				= 6;;
const KF_INTERP_SIMPLE_CUBIC		= 7;;

const KF_INTERP_COUNT				= 8;;


// origin interpolator
local g_InterpolatorMap = array( KF_INTERP_COUNT );
g_InterpolatorMap[ KF_INTERP_CATMULL_ROM ]			= CONST.INTERPOLATE.CATMULL_ROM;
g_InterpolatorMap[ KF_INTERP_CATMULL_ROM_NORM ]		= CONST.INTERPOLATE.CATMULL_ROM_NORMALIZE;
g_InterpolatorMap[ KF_INTERP_LINEAR ]				= CONST.INTERPOLATE.LINEAR_INTERP;
g_InterpolatorMap[ KF_INTERP_BSPLINE ]				= CONST.INTERPOLATE.BSPLINE;
g_InterpolatorMap[ KF_INTERP_SIMPLE_CUBIC ]			= CONST.INTERPOLATE.SIMPLE_CUBIC;



// kf_mode_angles
function SetAngleInterp( i = null )
{
	if ( m_bCompiling )
		return MsgFail("Cannot change algorithm while compiling!\n");

	if ( i == null )
	{
		i = (m_nInterpolatorAngle + 1) % 6;
	};

	m_nInterpolatorAngle = i;
	switch (m_nInterpolatorAngle)
	{
		case KF_INTERP_D3DX:
			m_szInterpDescAngle = "KF_INTERP_D3DX";
			Msg(Fmt( "angle interp: KF_INTERP_D3DX\n" ));
			break;

		case KF_INTERP_LINEAR_BLEND:
			m_szInterpDescAngle = "KF_INTERP_LINEAR_BLEND";
			Msg(Fmt( "angle interp: KF_INTERP_LINEAR_BLEND\n" ));
			break;

		case KF_INTERP_LINEAR:
			m_szInterpDescAngle = "KF_INTERP_LINEAR";
			Msg(Fmt( "angle interp: KF_INTERP_LINEAR\n" ));
			break;

		case KF_INTERP_CATMULL_ROM_DIR:
			m_szInterpDescAngle = "KF_INTERP_CATMULL_ROM_DIR";
			Msg(Fmt( "angle interp: KF_INTERP_CATMULL_ROM_DIR\n" ));
			break;

		default:
			return SetAngleInterp( m_nInterpolatorAngle + 1 );
	}

	PlaySound( SND_BUTTON );
}

// kf_mode_origin
function SetOriginInterp( i = null )
{
	if ( m_bCompiling )
		return MsgFail("Cannot change algorithm while compiling!\n");

	if ( i == null )
	{
		i = (m_nInterpolatorOrigin + 1) % KF_INTERP_COUNT;
	};

	m_nInterpolatorOrigin = i;
	switch (m_nInterpolatorOrigin)
	{
		case KF_INTERP_CATMULL_ROM:
			m_szInterpDescOrigin = "KF_INTERP_CATMULL_ROM";
			Msg(Fmt( "origin interp: KF_INTERP_CATMULL_ROM\n" ));
			break;

		case KF_INTERP_CATMULL_ROM_NORM:
			m_szInterpDescOrigin = "KF_INTERP_CATMULL_ROM_NORM";
			Msg(Fmt( "origin interp: KF_INTERP_CATMULL_ROM_NORM\n" ));
			break;

		case KF_INTERP_LINEAR:
			m_szInterpDescOrigin = "KF_INTERP_LINEAR";
			Msg(Fmt( "origin interp: KF_INTERP_LINEAR\n" ));
			break;

		case KF_INTERP_BSPLINE:
			m_szInterpDescOrigin = "KF_INTERP_BSPLINE";
			Msg(Fmt( "origin interp: KF_INTERP_BSPLINE\n" ));
			break;

		case KF_INTERP_SIMPLE_CUBIC:
			m_szInterpDescOrigin = "KF_INTERP_SIMPLE_CUBIC";
			Msg(Fmt( "origin interp: KF_INTERP_SIMPLE_CUBIC\n" ));
			break;

		default:
			return SetOriginInterp( m_nInterpolatorOrigin + 1 );
	}

	PlaySound( SND_BUTTON );
}


class CUndoSetFrameTime extends CUndoElement
{
	function Undo()
	{
		Base.m_KeyFrames[ m_nKeyIndex ].frametime = m_flFrameTimeOld;
		Base.m_KeyFrames[ m_nKeyIndex ].samplecount = ( m_flFrameTimeOld / Base.g_FrameTime ).tointeger();
	}

	function Redo()
	{
		Base.m_KeyFrames[ m_nKeyIndex ].frametime = m_flFrameTimeNew;
		Base.m_KeyFrames[ m_nKeyIndex ].samplecount = ( m_flFrameTimeNew / Base.g_FrameTime ).tointeger();
	}

	function Desc()
	{
		return Fmt( "frametime #%i : %f -> %f", m_nKeyIndex, m_flFrameTimeOld, m_flFrameTimeNew );
	}

	m_nKeyIndex = null;
	m_flFrameTimeNew = null;
	m_flFrameTimeOld = null;
}

//
// Sets how many samples to take until the next keyframe.
//
// kf_samplecount
//
function SetSampleCount( nSampleCount = KF_NOPARAM, nKey = -1 )
{
	if ( nSampleCount == KF_NOPARAM )
		throw "wrong number of parameters";

	if ( m_bCompiling || m_bPreview )
		return MsgFail("Cannot change sampling rate while compiling!\n");

	if ( nKey == -1 )
		nKey = m_nCurKeyframe;

	if ( nKey == -1 )
		return MsgFail("No keyframe is selected\n");

	nSampleCount = nSampleCount.tointeger();

	if ( nSampleCount < 0 )
		return MsgFail("Invalid input "+nSampleCount+"\n");

	if ( nSampleCount == 0 )
		nSampleCount = KF_SAMPLE_COUNT_DEFAULT;

	local flTime = g_FrameTime * nSampleCount;

	local key = m_KeyFrames[ nKey ];

	local pUndo = CUndoSetFrameTime();
	PushUndo( pUndo );
	pUndo.m_nKeyIndex = nKey;
	pUndo.m_flFrameTimeNew = flTime;
	pUndo.m_flFrameTimeOld = key.frametime;

	if ( key.samplecount != nSampleCount )
	{
		key.frametime = flTime;
		key.samplecount = nSampleCount;
		m_bDirty = true;
	};

	Msg(Fmt( "Interpolation sample count on keyframe #%d is set to: %d (%fs)\n", nKey, nSampleCount, flTime ));
	PlaySound( SND_BUTTON );
}

//
// Sets the time it takes to travel until the next keyframe.
//
// kf_frametime
//
function SetFrameTime( flTime = KF_NOPARAM, nKey = -1 )
{
	if ( flTime == KF_NOPARAM )
		throw "wrong number of parameters";

	if ( m_bCompiling || m_bPreview )
		return MsgFail("Cannot change sampling rate while compiling!\n");

	if ( nKey == -1 )
		nKey = m_nCurKeyframe;

	if ( nKey == -1 )
		return MsgFail("No keyframe is selected\n");

	flTime = flTime.tofloat();

	if ( flTime < 0.0 )
		return MsgFail("Invalid input "+flTime+"\n");

	if ( flTime == 0.0 )
		flTime = g_FrameTime * KF_SAMPLE_COUNT_DEFAULT;

	local nSampleCount = ( flTime / g_FrameTime ).tointeger();

	// How long it will take on this server. Precision depends on the server tickrate and g_FrameTime.
	flTime = g_FrameTime * nSampleCount;

	local key = m_KeyFrames[ nKey ];

	local pUndo = CUndoSetFrameTime();
	PushUndo( pUndo );
	pUndo.m_nKeyIndex = nKey;
	pUndo.m_flFrameTimeNew = flTime;
	pUndo.m_flFrameTimeOld = key.frametime;

	if ( key.samplecount != nSampleCount )
	{
		key.frametime = flTime;
		key.samplecount = nSampleCount;
		m_bDirty = true;
	};

	Msg(Fmt( "Interpolation sample count on keyframe #%d is set to: %d (%fs)\n", nKey, nSampleCount, flTime ));
	PlaySound( SND_BUTTON );
}

// kf_auto_fill_boundaries
function SetAutoFillBoundaries( i = null )
{
	if ( m_bCompiling || m_bPreview )
		return MsgFail("Cannot change algorithm while compiling!\n");

	if ( i == null )
		i = !m_bAutoFillBoundaries;

	m_bAutoFillBoundaries = !!i;

	Msg(Fmt( "Auto fill boundaries : %d\n", m_bAutoFillBoundaries.tointeger() ));
	PlaySound( SND_BUTTON );
}

//--------------------------------------------------------------

//
// Gets the frame count in the specified key range
//
function GetSampleCount( first, last )
{
	if ( !(first in m_KeyFrames && last in m_KeyFrames) )
		throw "out of range";

	local c = 0;
	for ( ; first < last; ++first )
		c += (m_KeyFrames[first].frametime / g_FrameTime).tointeger();
	return c;
}

// kf_compile
function Compile()
{
	if ( m_bCompiling )
		return MsgFail("Compilation in progress...\n");

	if ( m_bInPlayback || m_bPlaybackPending )
		return MsgFail("Cannot compile while in playback!\n");

	if ( !m_KeyFrames.len() )
		return MsgFail("No keyframes found.\n");

	if ( m_KeyFrames.len() < ( m_bAutoFillBoundaries ? 2 : 4 ) )
		return MsgFail(Fmt( "Not enough keyframes to compile. (Required minimum amount: %d)\n",
			( m_bAutoFillBoundaries ? 2 : 4 ) ));

	m_bCompiling = true;
	m_bDirty = false;
	m_pSquadErrors = null;

	// stop seeing
	SeeKeyframe(1);

	SetEditModeTemp( false );
	SendToConsole("clear_debug_overlays");
	SetHelperOrigin( MAX_COORD_VEC );

	Msg("\n");
	Msg("Preparing...\n");
	PlaySound( SND_BUTTON );

	_Process.CreateThread( _Process.StartCompile, _Process );
	return _Process.StartThread();
}


// Supports only 1 active thread at once
// Usage:
//	_Process.CreateThread( ThreadFunc, this );
//	_Process.StartThread( <optional parameters> );
//
// Can be called inside the thread:
//	_Process.ThreadSleep( <duration> );
//
{
	_Process._thread <- null;

	function _Process::CreateThread( func, env = null ) : (newthread)
	{
		if ( _thread && (_thread.getstatus() != "idle") )
			Assert( 0, "Tried to create a thread while one was already running" );

		_thread = newthread( func.bindenv( env ? env : VS.GetCaller() ) );
	}

	function _Process::StartThread( ... )
	{
		switch ( vargc )
		{
			case 0: return _thread.call();
			case 1: return _thread.call( vargv[0] );
			case 2: return _thread.call( vargv[0], vargv[1] );
			case 3: return _thread.call( vargv[0], vargv[1], vargv[2] );
			case 4: return _thread.call( vargv[0], vargv[1], vargv[2], vargv[3] );
		}
	}

	function _Process::ThreadSleep( duration ) : (suspend)
	{
		if ( duration > 0.0 )
		{
			suspend( AddEvent( ThreadResume, duration, this ) );
		}
		else if ( duration == -1 )
		{
			suspend();
		}
	}

	function _Process::ThreadResume()
	{
		if ( _thread.getstatus() == "suspended" )
		{
			_thread.wakeup();
		}
	}

	function _Process::ThreadIsSuspended()
	{
		return _thread.getstatus() == "suspended";
	}
}


function _Process::FillBoundariesRevert()
{
	// end
	m_KeyFrames.remove( m_KeyFrames.len() - 1 );

	// start
	m_KeyFrames.remove( 0 );
}

function _Process::FillBoundaries()
{
	local key, tmp0, tmp1;

	// end
	key = m_KeyFrames.top();
	tmp1 = keyframe_t();
	tmp1.Copy( key );
	ArrayAppend( m_KeyFrames, tmp1 );

	// start
	key = m_KeyFrames[0];
	tmp0 = keyframe_t();
	tmp0.Copy( key );
	m_KeyFrames.insert( 0, tmp0 );

	if ( m_nInterpolatorAngle == KF_INTERP_D3DX )
	{
		// HACKHACK: interpolator cannot interpolate identical angles
		tmp0.angles.x += 0.05;
		tmp0.angles.y += 0.05;
		tmp0.angles.z += 0.05;

		tmp1.angles.x += 0.05;
		tmp1.angles.y += 0.05;
		tmp1.angles.z += 0.05;

		tmp0.SetAngles( tmp0.angles );
		tmp1.SetAngles( tmp1.angles );
	};
}

// TODO: Implement consistent speed
function _Process::StartCompile()
{
	if ( m_bAutoFillBoundaries )
		FillBoundaries();

	// Calculate total frame count
	local size = GetSampleCount( 1, m_KeyFrames.len() - 2 );

	// init path
	m_PathData.clear();
	m_PathData.resize( size );
	for ( local i = 0; i < size; ++i )
	{
		m_PathData[i] = frame_t();
	}

	Msg(Fmt( "Keyframe count  : %d\n", m_KeyFrames.len() ));
	Msg(Fmt( "Frame count     : %d\n", size ));
	Msg(Fmt( "Angle interp    : %s\n", m_szInterpDescAngle ));
	Msg(Fmt( "Origin interp   : %s\n", m_szInterpDescOrigin ));
	Msg(Fmt( "Fill boundaries : %d\n", m_bAutoFillBoundaries.tointeger() ));

	Msg("\nCompiling");

	return CompilePath();
}

function _Process::SplineOrigin( i, frac, out ) : ( g_InterpolatorMap )
{
	VS.Interpolator_CurveInterpolate( g_InterpolatorMap[ m_nInterpolatorOrigin ],
		m_KeyFrames[i-1].origin,
		m_KeyFrames[i].origin,
		m_KeyFrames[i+1].origin,
		m_KeyFrames[i+2].origin,
		frac,
		out );
}

function _Process::SplineAngles( i, frac, out )
{
	switch ( m_nInterpolatorAngle )
	{
		case KF_INTERP_D3DX:
		{
			local spline = Quaternion();

			local q0 = m_KeyFrames[i-1].orientation;
			local q1 = m_KeyFrames[i].orientation;
			local q2 = m_KeyFrames[i+1].orientation;
			local q3 = m_KeyFrames[i+2].orientation;

			local p1 = Quaternion();
			local p2 = Quaternion();
			local p3 = Quaternion();

			VS.QuaternionAlign( q0, q1, p1 );
			VS.QuaternionAlign( q1, q2, p2 );
			VS.QuaternionAlign( q2, q3, p3 );

			VS.QuaternionSquad(
				q0,
				p1,
				p2,
				p3,
				frac,
				spline );

			if ( spline.IsValid() )
			{
				VS.QuaternionAngles( spline, out );
			}
			// FIXME
			else
			{
				if ( !m_pSquadErrors )
				{
					m_pSquadErrors = [i];
				}
				else if ( m_pSquadErrors.top() != i )
				{
					ArrayAppend( m_pSquadErrors, i );
				};;

				VS.VectorCopy( m_KeyFrames[i+1].angles, out );
			};
			return;
		}
		case KF_INTERP_LINEAR_BLEND:
		case KF_INTERP_LINEAR:
		{
			local spline = Quaternion();
			VS.QuaternionSlerp(
				m_KeyFrames[i].orientation,
				m_KeyFrames[i+1].orientation,
				frac,
				spline );
			VS.QuaternionAngles( spline, out );
			return;
		}
		case KF_INTERP_CATMULL_ROM_DIR:
		{
			VS.Catmull_Rom_Spline(
				m_KeyFrames[i-1].forward,
				m_KeyFrames[i].forward,
				m_KeyFrames[i+1].forward,
				m_KeyFrames[i+2].forward,
				frac,
				out );
			VS.VectorAngles( out, out );
			return;
		}
		// case KF_INTERP_AFX:
	}
}

function _Process::CompilePath()
{
	local len = m_KeyFrames.len()-3;
	local offset = 0;

	for ( local nKeyIdx = 1; nKeyIdx <= len; ++nKeyIdx )
	{
		local key = m_KeyFrames[nKeyIdx];

		local nSampleFrame = 0;

		local flCurTime = 0.0;
		local flKeyFrameTime = key.frametime;

		for ( ; flCurTime < flKeyFrameTime; flCurTime += g_FrameTime, ++nSampleFrame )
		{
			local t = flCurTime / flKeyFrameTime;

			local org = Vector();
			local ang = Vector();
			SplineOrigin( nKeyIdx, t, org );
			SplineAngles( nKeyIdx, t, ang );

			local frame = m_PathData[ offset + nSampleFrame ];
			frame.origin = org;
			frame.angles = ang;
		}

		if ( nSampleFrame != (flKeyFrameTime / g_FrameTime).tointeger() )
			Msg(Fmt( "\nERROR: Compiled frame count does not match keyframe sample count value! %d, %d\n",
				nSampleFrame,
				(key.frametime / g_FrameTime).tointeger() ));

		offset += nSampleFrame;

		// Sleeping on every other section of sampling is a good trade off between
		// decreased compilation time and game strain.
		// 3+ completely halts the game, which is undesirable however short the duration.
		if ( !(nKeyIdx % 2) )
		{
			Msg(".");
			ThreadSleep( g_FrameTime );
		};
	}

	if ( m_nInterpolatorAngle == KF_INTERP_LINEAR_BLEND )
	{
		Msg("|");
		// smooth twice?
		SmoothAngles( 10 );
		ThreadSleep( g_FrameTime );
		SmoothAngles( 10 );
	};

	CompileFOV();

	ThreadSleep( g_FrameTime );

	return FinishCompile();
}

function _Process::FinishCompile()
{
	if ( m_bAutoFillBoundaries )
		FillBoundariesRevert();

	// Assert compilation
	local c = m_PathData.len();
	for ( local i = 0; i < c; i++ )
	{
		if ( !m_PathData[i] || !m_PathData[i].origin )
		{
			Msg("\nNULL POINT! ["+i+" / "+c+"]\n");
			m_PathData.resize( i-1 );
			break;
		};
	}

	if ( m_pSquadErrors )
	{
		Msg( "\n\nERROR: Angle interp errors at keyframes:" );
		foreach( i in m_pSquadErrors )
			Msg(Fmt( "  %d", i+1 ));
		Msg("\n");

		m_pSquadErrors = null;
	};

	if ( m_Selection[1] >= m_PathData.len() )
	{
		m_Selection[0] = m_Selection[1] = 0;
	};

	m_bCompiling = false;
	SetEditModeTemp( m_bInEditMode );

	Msg("\nCompilation complete.\n");
	Msg(Fmt( "Path length: %g seconds\n\n", m_PathData.len() * g_FrameTime ));
	PlaySound( SND_BUTTON );
}

function _Process::CompileFOV()
{
	// Compile only if there was no change to keyframes
	if ( m_bDirty )
		return;

	if ( !m_KeyFrames.len() )
		return;

	if ( !m_PathData.len() )
		return;

	// FOV data at keyframe 0 is invalid
	if ( m_KeyFrames[0].fov )
		m_KeyFrames[0].SetFov( 0 );

	// if keyframe 1 does not have an FOV value, set to 90
	if ( !m_KeyFrames[1].fov )
	{
		m_KeyFrames[1].SetFov( 90 );

		m_nPathInitialFOV = 0;
	}
	else
	{
		// HACKHACK: save the initial FOV separately, export it on its own field
		m_nPathInitialFOV = m_KeyFrames[1].fov;
	};

	local i = 0, c = m_KeyFrames.len()-1;

	while ( ++i < c )
	{
		// first fov key
		local f0 = m_KeyFrames[i];
		if ( !f0.fov )
			continue;

		// next fov key
		for ( local j = i+1; j < c; ++j )
		{
			local f1 = m_KeyFrames[j];
			if ( !f1.fov )
				continue;

			// time to move between previous and current fov keys
			local rate = GetSampleCount( i, j ) * g_FrameTime;

			// frame to start fov lerping
			local frame = GetSampleCount( 1, i );

			// not ready to compile
			if ( !(frame in m_PathData) )
				break;

			local pt = m_PathData[ frame ];
			pt.fov = f1.fov;
			pt.fov_rate = rate;

			break;
		}
	}
}

function _Process::SmoothAngles( r )
{
	// These differences save seconds in especially large data sets.
	local nSleepRate;

	if ( m_bSmoothExponential )
	{
		nSleepRate = 5200 / r;
	}
	else
	{
		// Quaternion alignment in QuaternionBlend slows this down significantly.
		nSleepRate = 4200 / r;
	};

	local i, c;

	if ( m_Selection[0] && m_Selection[1] )
	{
		i = m_Selection[0];
		c = m_Selection[1];
	}
	else
	{
		i = 0;
		c = m_PathData.len();
	};

	local stack = [];
	for ( ; i < c; i++ )
	{
		if ( !(i % nSleepRate) )
		{
			Msg(".");
			ThreadSleep( g_FrameTime );
		};

		if ( stack.len() > r )
		{
			stack.remove(0);
		};

		local pt = m_PathData[i];

		local q = Quaternion();
		VS.AngleQuaternion( pt.angles, q );

		stack.append(q);

		local s = SmoothAnglesStack( stack );
		VS.QuaternionAngles( s, pt.angles );
	}
}

// Blend stack
function _Process::SmoothAnglesStack( stack )
{
	local c = stack.len();
	if ( !c )
		MsgFail("stack empty.\n");

	local out = Quaternion();

	if ( m_bSmoothExponential )
	{
		VS.QuaternionAverageExponential( out, c, stack )
	}
	else
	{
		local w = 1.0 / c;
		for ( local i = 0; i < c; i++ )
		{
			local t = stack[i];
			VS.QuaternionBlend( out, t, w, out );
		}
	};
	return out;
}

function _Process::SmoothOrigin( r )
{
	local nSleepRate = 4200 / r;

	local i, c;

	if ( m_Selection[0] && m_Selection[1] )
	{
		i = m_Selection[0] + r;
		c = m_Selection[1] - r;
	}
	else
	{
		i = r;
		c = m_PathData.len() - r;
	};

	local stack = [];
	for ( ; i < c; i++ )
	{
		if ( !(i % nSleepRate) )
		{
			Msg(".");
			ThreadSleep( g_FrameTime );
		};

		stack.clear();

		for ( local j = -r; j <= r; j++ )
		{
			stack.append( m_PathData[ i + j ].origin );
		}

		local s = SmoothOriginStack( stack );
		m_PathData[i].origin = s;
	}
}

// Blend stack
function _Process::SmoothOriginStack( stack )
{
	local c = stack.len();
	if ( !c )
		MsgFail("stack empty.\n");

	local w = 1.0 / c.tofloat();
	local out = Vector();

	for ( local i = 0; i < c; ++i )
	{
		local t = stack[i];
		VS.VectorAdd( out, t, out );
	}

	VS.VectorScale( out, w, out );

	return out;
}

function StopTransformLerp()
{
	m_pLerpTransform = null;
	m_flLerpTransformAnim = null;
}


class CUndoTransformKeyframes extends CUndoElement
{
	function Undo()
	{
		Base.m_KeyFrames.resize( m_pFramesOld.len() );

		foreach( i, v in m_pFramesOld )
		{
			Base.m_KeyFrames[i] = clone v;
		}
	}

	function Redo()
	{
		Base.m_KeyFrames.resize( m_pFramesNew.len() );

		foreach( i, v in m_pFramesNew )
		{
			Base.m_KeyFrames[i] = clone v;
		}
	}

	function Desc()
	{
		return "transform";
	}

	function ClonePre()
	{
		m_pFramesOld = clone Base.m_KeyFrames;

		foreach ( i, v in Base.m_KeyFrames )
		{
			m_pFramesOld[i] = clone v;
		}
	}

	function ClonePost()
	{
		m_pFramesNew = clone Base.m_KeyFrames;

		foreach ( i, v in Base.m_KeyFrames )
		{
			m_pFramesNew[i] = clone v;
		}
	}

	m_pFramesOld = null;
	m_pFramesNew = null;
}

//
// void TransformKeyframes( Vector offset )
// void TransformKeyframes( Vector|null offset, Vector angles )
// void TransformKeyframes( int pivot, Vector offset, Vector angles )
//
function TransformKeyframes( p1 = null, p2 = null, p3 = null ) : (array, vec3_origin)
{
	if ( m_bCompiling )
		return MsgFail("Cannot modify keyframes while compiling!\n");

	if ( !m_KeyFrames.len() )
		return MsgFail("No keyframes found.\n");

	local vecPivot, vecOffset, vecAngle;
	local t1 = typeof p1, t2 = typeof p2, t3 = typeof p3;

	//
	// void TransformKeyframes( Vector offset )
	//
	if ( t1 == "Vector" && t2 == "null" && t3 == "null" )
	{
		vecPivot = vec3_origin;
		vecOffset = p1;
		vecAngle = vec3_origin;
	};

	//
	// void TransformKeyframes( null, Vector angles )
	//
	if ( t1 == "null" && t2 == "Vector" && t3 == "null" )
	{
		t1 = "Vector";
		p1 = vec3_origin;
	};

	//
	// void TransformKeyframes( Vector offset, Vector angles )
	//
	if ( t1 == "Vector" && t2 == "Vector" && t3 == "null" )
	{
		// p2 -> p3
		t3 = t2;
		p3 = p2;

		// p1 -> p2
		t2 = t1;
		p2 = p1;

		// pivot average
		t1 = "integer";
		p1 = -1;
	};

	//
	// void TransformKeyframes( int pivot, null, Vector angles )
	//
	if ( t1 == "integer" && t2 == "null" && t3 == "Vector" )
	{
		t2 = "Vector";
		p2 = vec3_origin;
	};

	//
	// void TransformKeyframes( int pivot, Vector offset, Vector angles )
	//
	if ( t1 == "integer" && t2 == "Vector" && t3 == "Vector" )
	{
		vecOffset = p2;
		vecAngle = p3;

		local pivot = p1;

		// view origin
		if ( pivot == -2 )
		{
			vecPivot = Vector();
			VS.VectorCopy( CurrentViewOrigin(), vecPivot );
		}
		// average
		else if ( pivot == -1 )
		{
			local sum = Vector();
			local c = m_KeyFrames.len();
			for ( local i = 0; i < c; ++i )
			{
				VS.VectorAdd( m_KeyFrames[i].origin, sum, sum );
			}
			vecPivot = sum * ( 1.0 / c.tofloat() );
		}
		// keyframe index
		else
		{
			local c = m_KeyFrames.len();
			if ( (c < 0) || (pivot >= c) )
				return MsgFail("Invalid keyframe index.\n");

			vecPivot = Vector();
			VS.VectorCopy( m_KeyFrames[pivot].origin, vecPivot );
		};;
	};

	if (	typeof vecPivot != "Vector"		||
			typeof vecOffset != "Vector"	||
			typeof vecAngle != "Vector"		)
	{
		return MsgFail("Invalid parameters\n");
	};

	local pUndo = CUndoTransformKeyframes();
	PushUndo( pUndo );
	pUndo.ClonePre();

	local matRotate = matrix3x4_t();
	VS.AngleMatrix( vecAngle, null, matRotate );

	local c = m_KeyFrames.len();

	m_pLerpTransform = array(c);
	m_flLerpTransformAnim = 0.0;

	for ( local i = 0; i < c; ++i )
	{
		local key = m_KeyFrames[i];

		local v = Vector();
		VS.VectorCopy( key.origin, v );
		m_pLerpTransform[i] = v;

		VS.MatrixSetColumn( key.origin - vecPivot, 3, key.transform );
		local tmp = clone key.transform;
		VS.ConcatTransforms( matRotate, tmp, key.transform );
		VS.MatrixGetColumn( key.transform, 3, key.origin );
		VS.MatrixSetColumn( key.origin + vecPivot + vecOffset, 3, key.transform );

		key.UpdateFromMatrix();
	}

	pUndo.ClonePost();

	m_bDirty = true;

	VS.EventQueue.CancelEventsByInput( StopTransformLerp );
	// animate it 5 times
	local t = 5 * 100 * FrameTime();
	VS.EventQueue.AddEvent( StopTransformLerp, t, this );

	DrawBox( vecPivot, Vector(-4,-4,-4), Vector(4,4,4), 255,255,255,255, t );
	PlaySound( SND_BUTTON );
}


local ThreadHelper = function( func, param, msg, exp = false )
{
	m_bCompiling = true;
	local t = m_bSmoothExponential;
	m_bSmoothExponential = exp;
	func( param );
	m_bSmoothExponential = t;
	Msg( msg );
	m_bCompiling = false;
}

// kf_smooth_origin
function SmoothOrigin( r = 4 ) : (ThreadHelper)
{
	if ( m_bCompiling )
		return MsgFail("Cannot smooth path while compiling!\n");

	if ( m_bInPlayback || m_bPlaybackPending )
		return MsgFail("Cannot smooth path while in playback!\n");

	if ( !m_PathData.len() )
		return MsgFail("No path found.\n");

	r = r.tointeger() / 2;

	if ( r < 2 )
		return MsgFail("Invalid input.\n");

	Msg(Fmt( "Smoothing origins... (%d) %s\n", r, m_bDirty ? " (dirty)" : "" ));
	PlaySound( SND_BUTTON );

	local msg;
	if ( m_Selection[0] && m_Selection[1] )
	{
		msg = Fmt( "\nSmooth origin done. [%d -> %d]\n", m_Selection[0], m_Selection[1] );
	}
	else
	{
		msg = "\nSmooth origin done.\n";
	};

	_Process.CreateThread( ThreadHelper, _Process );
	_Process.StartThread( _Process.SmoothOrigin, r, msg );
}

// kf_smooth_angles
// kf_smooth_angles_exp
function SmoothAngles( exp = 0, r = 10 ) : (ThreadHelper)
{
	if ( m_bCompiling )
		return MsgFail("Cannot smooth path while compiling!\n");

	if ( m_bInPlayback || m_bPlaybackPending )
		return MsgFail("Cannot smooth angles while in playback!\n");

	if ( !m_PathData.len() )
		return MsgFail("No path found.\n");

	r = r.tointeger();

	Msg(Fmt( "Smoothing angles... (%d) %s\n", r, m_bDirty ? " (dirty)" : "" ));
	PlaySound( SND_BUTTON );

	local msg;
	if ( m_Selection[0] && m_Selection[1] )
	{
		msg = Fmt( "\nSmooth angles done. [%d -> %d]", m_Selection[0], m_Selection[1] );
	}
	else
	{
		msg = "\nSmooth angles done.";
	};

	if ( exp )
	{
		msg += " (exponential)\n";
	}
	else
	{
		msg += "\n";
	};

	_Process.CreateThread( ThreadHelper, _Process );
	_Process.StartThread( _Process.SmoothAngles, r, msg, !!exp );
}


//--------------------------------------------------------------
//--------------------------------------------------------------

//--------------------------------------------------------------
// Save/load


//
// TODO:
//
{
	function IsValidCoord( f )
	{
		return ( f <= MAX_COORD_FLOAT ) && ( f >= -MAX_COORD_FLOAT );
	}

	function WriteCoord( v )
	{
		if ( VS.CloseEnough( v, 0.0, 1.e-5 ) )
			v = 0.0;

		return Fmt( "%f", v );
	}

	function ReadCoord( v )
	{
		return v;
	}
}

function WriteFrame( outKey )
{
	local origin = outKey.origin;
	local angles = outKey.angles;

	local tx = WriteCoord( origin.x );
	local ty = WriteCoord( origin.y );
	local tz = WriteCoord( origin.z );

	local rx = WriteCoord( angles.x );
	local ry = WriteCoord( angles.y );
	local rz = WriteCoord( angles.z );

	local n = 0x00;

	local fov = outKey.fov;
	if ( !fov )
	{
		return Fmt( "\t%d,%s,%s,%s,%s,%s,%s,\n", n,
			tx, ty, tz,
			rx, ry, rz );
	}
	else
	{
		return Fmt( "\t%d,%s,%s,%s,%s,%s,%s,%d,%s,\n", (n | 0x01),
			tx, ty, tz,
			rx, ry, rz,
			fov,
			("fov_rate" in outKey ? WriteCoord(outKey.fov_rate) : "0") );
	};
}

// returns index of next block to read
function ReadFrame( inKey, data, idx )
{
	local n = data[idx++];

	local tx = ReadCoord( data[idx]   );
	local ty = ReadCoord( data[idx+1] );
	local tz = ReadCoord( data[idx+2] );

	local rx = ReadCoord( data[idx+3] );
	local ry = ReadCoord( data[idx+4] );
	local rz = ReadCoord( data[idx+5] );

	inKey.SetOrigin( Vector( tx, ty, tz ) );
	inKey.SetAngles( Vector( rx, ry, rz ) );

	if ( n & 0x01 )
	{
		inKey.SetFov( data[idx+6], ReadCoord( data[idx+7] ) );
		return idx + 8;
	};
	return idx + 6;
}


const KF_DATA_TYPE_KEYFRAMES	= 1;;
const KF_DATA_TYPE_PATH			= 2;;


const KF_SAVE_V1				= 1;;

// Complete rework
// PATCH: field init_fov
const KF_SAVE_V2				= 2;;

// Current version
const KF_SAVE_VERSION			= 2;;


// kf_save, kf_savepath, kf_savekeys
function Save( i = null )
{
	if ( m_bCompiling )
		return MsgFail("Cannot save while compiling!\n");

	if ( m_bSaveInProgress )
		return MsgFail("A save is in progress!\n");

	if ( i == null )
	{
		MsgFail("No data type to save specified.\n");
		Msg("   Save compiled path data with 'kf_savepath'\n");
		Msg("   Save keyframe data with 'kf_savekeys'\n\n");
		return;
	};

	if ( i == KF_DATA_TYPE_PATH )
	{
		m_pSaveData = m_PathData.weakref();
	}
	else if ( i == KF_DATA_TYPE_KEYFRAMES )
	{
		m_pSaveData = m_KeyFrames.weakref();
	}
	else
	{
		return Error("Invalid save type\n");
	};;

	if ( !m_pSaveData.len() )
	{
		m_pSaveData = null;
		return MsgFail("Empty save data.\n");
	};

	m_nSaveType = i;
	m_bSaveInProgress = true;

	VS.Log.file_prefix = "scripts/vscripts/kf_data";
	VS.Log.export = true;
	VS.Log.filter = "L ";

	Msg( "Saving, please wait...\n" );

	_Process.CreateThread( _Save.Process, _Save );
	_Process.StartThread();
}

function _Save::Process()
{
	_Process.ThreadSleep( g_FrameTime );

	VS.Log.Clear();

	Write();
	EndWrite();
}

function _Save::Write()
{
	// header ---

	local header = array(6);
	header[2] = g_szMapName;
	header[3] = KF_SAVE_VERSION;
	header[4] = m_nSaveType;
	header[5] = m_pSaveData.len();

	if ( m_nSaveType == KF_DATA_TYPE_PATH )
	{
		header[1] = "l_%s <- { version = %i, type = %i, framecount = %i, frames =\n[\n";
	}
	else if ( m_nSaveType == KF_DATA_TYPE_KEYFRAMES )
	{
		header[1] = "lk_%s <- { version = %i, type = %i, framecount = %i, frames =\n[\n";
	};;

	Add( Fmt.acall(header) );

	// body ---

	local c = m_pSaveData.len();

	for ( local i = 0; i < c; i++ )
	{
		Add( WriteFrame( m_pSaveData[i] ) );

		if ( !(i % 200) )
		{
			_Process.ThreadSleep( g_FrameTime );
		};
	}

	_Process.ThreadSleep( g_FrameTime );

	// strip trailing separator ",\n"
	Add( VS.Log.Pop().slice( 0, -2 ) + "\n]" );

	// HACKHACK
	if ( m_nPathInitialFOV )
	{
		Add( ", init_fov = " + m_nPathInitialFOV.tointeger() );
	};

	// tail ---
	Add( "\n}\n\0" );
}

function _Save::EndWrite()
{
	VS.Log.Run( function( file )
	{
		m_bSaveInProgress = false;
		PlaySound( SND_EXPORT_SUCCESS );

		if ( m_nSaveType == KF_DATA_TYPE_PATH )
		{
			Msg(Fmt( "Exported path data: /csgo/%s.log\n\n", file ));
		}
		else if ( m_nSaveType == KF_DATA_TYPE_KEYFRAMES )
		{
			Msg(Fmt( "Exported keyframe data: /csgo/%s.log\n\n", file ));
		};;
	}, this );
}


//--------------------------------------------------------------
//--------------------------------------------------------------


if ( !m_FileBuffer.parent )
{
	local m_LoadedData = m_LoadedData;
	local root = getroottable();
	local meta =
	{
		_newslot = function( k, v ) : ( root, m_LoadedData )
		{
			m_LoadedData.rawset( k, v );
			if ( k in root && root[k] )
			{
				// TODO: compare?
				k = k + "_01";
				Msg( "Conflicting data name, renaming to : " + k + "\n" );
			};
			root[k] <- v.weakref();
			Msg("\t~ Loaded: " + k + "\n");
		}
	}
	delegate meta : m_FileBuffer;
};

function LoadFile( msg = true )
{
	if (msg)
	{
		Msg("Loading file...\n")
	};

	try( DoIncludeScript( "keyframes_data", m_FileBuffer ) )
	catch(e)
	{
		return Error("Failed to load keyframes_data.nut file!\n");
	}

	if (msg)
	{
		Msg("...done.\n");
		PlaySound( SND_FILE_LOAD_SUCCESS );
	}
}

function LoadFileError()
{
	Msg("Use 'kf_loadfile' to reload the keyframes_data.nut file.\n");
	Msg("Use 'script kf_load( name )' to load a named data from the data file.\n");
	PlaySound( SND_FAILURE );
}


class CUndoLoad extends CUndoTransformKeyframes
{
	function Desc()
	{
		return "load keyframes";
	}
}

// TODO: cleanup
function _Load::LoadData( input = null )
{
	if ( m_bCompiling )
		return MsgFail("Cannot load file while compiling!\n");

	// load prefix_mapname data by default
	if ( input == null )
	{
		input = "lk_" + g_szMapName;

		if ( !( input in m_LoadedData ) && !( input in getroottable() ) )
		{
			input = "l_" + g_szMapName;
		};
	};

	// convert string input to handle
	if ( typeof input == "string" )
	{
		if ( input in getroottable() )
		{
			input = getroottable()[input];
		}
		else if ( input in m_LoadedData )
		{
			input = m_LoadedData[input];
		}
		else
		{
			return MsgFail(Fmt( "Invalid input '%s' (does not exist)\n", input ));
		};;
	};

	if ( typeof input != "table" )
		return MsgFail("Invalid input. (invalid type <"+typeof input+">)\n");

	local datasize, framecount;

	if ( "version" in input )
	{
		m_nLoadVer = input.version;
		m_nLoadType = input.type;
		datasize = input.frames.len();
		framecount = input.framecount;
	}
	else
	{
		m_nLoadVer = KF_SAVE_V1;
	};

	if ( m_nLoadVer == KF_SAVE_V1 )
	{
		if ( !("pos" in input) || !("ang" in input) )
			return MsgFail("Invalid input.\n");

		if ( !input.pos.len() || !input.ang.len() )
			return MsgFail("Empty input.\n");

		if ( "anq" in input )
		{
			input.quat <- delete input.anq;
		};

		if ( "quat" in input )
		{
			if ( input.pos.len() != input.quat.len() )
				return Error("[ERROR] Corrupted data!\n");

			m_nLoadType = KF_DATA_TYPE_KEYFRAMES;
		}
		else
		{
			if ( input.pos.len() != input.ang.len() )
				return Error("[ERROR] Corrupted data!\n");

			m_nLoadType = KF_DATA_TYPE_PATH;
		};

		datasize = input.pos.len();
		framecount = datasize;
	};

	// data from the future?
	if ( m_nLoadVer > KF_SAVE_VERSION || m_nLoadVer < KF_SAVE_V1 )
		return MsgFail(Fmt( "Unrecognised data version! [%i]\n", m_nLoadVer ));

	if ( m_nLoadType == KF_DATA_TYPE_KEYFRAMES )
	{
		m_pLoadData = m_KeyFrames.weakref();
	}
	else if ( m_nLoadType == KF_DATA_TYPE_PATH )
	{
		m_pLoadData = m_PathData.weakref();
	}
	else
	{
		return MsgFail("Invalid data type!\n");
	};;

	if ( m_nLoadType == KF_DATA_TYPE_KEYFRAMES )
	{
		local pUndo = m_pUndoLoad = CUndoLoad();
		pUndo.ClonePre();
	};

	m_pLoadData.clear();
	m_pLoadData.resize( framecount );
	m_pLoadInput = input.weakref();

	// HACKHACK
	if ( ("init_fov" in input) && (typeof input.init_fov == "integer") )
	{
		m_nPathInitialFOV = input.init_fov;
	};

	Msg("Preparing to load...\n");
	PlaySound( SND_BUTTON );
	Msg("\tversion     : " + m_nLoadVer + "\n");
	Msg("\ttype        : " + m_nLoadType + "\n");
	Msg("\tframe count : " + framecount + "\n");
	Msg("\tdata size   : " + datasize + "\n");

	Msg("Loading");

	SetEditModeTemp( false );

	_Process.CreateThread( LoadInternal, this );
	_Process.StartThread();
}


local NewFrame = function()
{
	if ( m_nLoadType == KF_DATA_TYPE_KEYFRAMES )
		return keyframe_t();

	if ( m_nLoadType == KF_DATA_TYPE_PATH )
		return frame_t();
}

function _Load::LoadInternal() : ( NewFrame )
{
	Msg(".");

	if ( m_nLoadVer == KF_SAVE_V2 )
	{
		local data = m_pLoadInput.frames;
		local c = data.len();
		local frame = 0;

		for ( local i = 0; i < c; )
		{
			local p = NewFrame();
			m_pLoadData[ frame++ ] = p;
			i = ReadFrame( p, data, i );

			// Loading is fast, put a high limit
			if ( !(i % 10000) )
			{
				Msg(".");
				_Process.ThreadSleep( g_FrameTime );
			};
		}

		_Process.ThreadSleep( g_FrameTime );

		return LoadFinishInternal();
	};

	if ( m_nLoadVer == KF_SAVE_V1 )
	{
		local rotGet, rotSet;

		if ( m_nLoadType == KF_DATA_TYPE_KEYFRAMES )
		{
			rotGet = "quat";
			rotSet = "SetQuaternion";
		}
		else if ( m_nLoadType == KF_DATA_TYPE_PATH )
		{
			rotGet = "ang";
			rotSet = "SetAngles";
		};;

		local c = m_pLoadInput.pos.len();

		for ( local i = 0; i < c; ++i )
		{
			local org = m_pLoadInput.pos[i];
			local rot = m_pLoadInput[rotGet][i];

			local p = NewFrame();
			m_pLoadData[i] = p;

			p.SetOrigin( org );
			p[rotSet]( rot );

			if ( !(i % 10000) )
			{
				Msg(".");
				_Process.ThreadSleep( g_FrameTime );
			};
		}

		_Process.ThreadSleep( g_FrameTime );

		if ( "fov" in m_pLoadInput )
		{
			foreach( i, a in m_pLoadInput.fov )
			{
				local idx = a[0];
				if ( !( idx in m_pLoadData ) )
				{
					Msg("Corrupted FOV data: invalid index!\n");
					continue;
				};
				m_pLoadData[idx].SetFov( a[1], a[2] );
			}
		};

		_Process.ThreadSleep( g_FrameTime );

		return LoadFinishInternal();
	};

	Assert( 0, "LoadInternal()" );
}

function LoadFinishInternal()
{
	// Assert
	local c = m_pLoadData.len();
	for ( local i = 0; i < c; i++ )
	{
		if ( !m_pLoadData[i] )
		{
			Msg("\n\nNULL POINT! ["+i+" / "+c+"]\n");
			Msg("Corrupt data?\n");
			m_pLoadData.resize( i-1 );
			break;
		};
	}

	// No longer dirty
	if ( m_nLoadType & KF_DATA_TYPE_PATH )
	{
		m_bDirty = false;
	};

	local szInput = VS.GetVarName( m_pLoadInput );

	PlaySound( SND_BUTTON );
	Msg(Fmt( "\nLoading complete! \"%s\" ( %s )\n",
		szInput,
		(
			( m_nLoadType & KF_DATA_TYPE_PATH ) ?
			m_PathData.len() * g_FrameTime + " seconds" :
			m_KeyFrames.len() + " keyframes"
		)
	));

	if ( szInput in m_LoadedData )
		delete m_LoadedData[szInput];

	if ( szInput in getroottable() )
		delete getroottable()[szInput];;

	if ( m_pUndoLoad )
	{
		m_pUndoLoad.ClonePost();
		PushUndo( m_pUndoLoad );
		m_pUndoLoad = null;
	};

	SetEditModeTemp( m_bInEditMode );
}


//--------------------------------------------------------------
//--------------------------------------------------------------


function CameraThink()
{
	if ( !m_bPreview )
	{
		local pt = m_PathData[m_nPlaybackIdx];
		CameraSetOrigin( pt.origin );

		local ang = pt.angles;
		CameraSetAngles( ang );

		// NOTE: This is here for external effects that may use player angles (such as flashbangs)
		player.SetAngles( ang.x, ang.y, 0 );

		if ( pt.fov )
			CameraSetFov( pt.fov, pt.fov_rate );

		if ( m_nPlaybackTarget <= ++m_nPlaybackIdx )
		{
			if ( m_bPlaybackLoop )
			{
				if ( m_Selection[0] && m_Selection[1] )
				{
					m_nPlaybackIdx = m_Selection[0];
				}
				else
				{
					m_nPlaybackIdx = 0;
				};
			}
			else
			{
				return Stop();
			};
		};
	}
	else
	{
		local pos = Vector();
		local ang = Vector();
		_Process.SplineOrigin( m_nPlaybackIdx, m_flPreviewFrac, pos );
		_Process.SplineAngles( m_nPlaybackIdx, m_flPreviewFrac, ang );

		CameraSetOrigin( pos );
		CameraSetAngles( ang );

		// HACKHACK: set player angles as well to get the correct angle in CurrentViewAngles in edit mode
		player.SetAngles( ang.x, ang.y, 0 );

		local key = m_KeyFrames[ m_nPlaybackIdx ];

		m_flPreviewFrac += 1.0 / key.samplecount + FLT_EPSILON;

		if ( m_flPreviewFrac >= 1.0 )
		{
			m_flPreviewFrac = 0.0;

			if ( m_nPlaybackTarget <= ++m_nPlaybackIdx )
				return Stop();
		};
	};
}


const KF_PLAY_DEFAULT = 0;;
const KF_PLAY_LOOP = 2;;
const KF_PLAY_PREVIEW = 1;;

function Play( type = KF_PLAY_DEFAULT )
{
	if ( m_bCompiling )
		return MsgFail("Cannot start playback while compiling!\n");

	if ( m_bPlaybackPending )
		return MsgFail("Playback has not started yet!\n");

	if ( m_bInPlayback )
		return MsgFail("Playback is already running.\n");

	// unsee
	if ( m_bSeeing )
		SeeKeyframe(1);

	if ( ((type == KF_PLAY_DEFAULT) || (type == KF_PLAY_LOOP)) && !m_PathData.len() )
		return MsgFail("No compiled data found.\n");

	if ( (type == KF_PLAY_PREVIEW) && !m_KeyFrames.len() )
		return MsgFail("No keyframe data found.\n");

	if ( developer() > 1 )
	{
		Msg("Setting developer level to 1\n");
		SendToConsole("developer 1");
	};

	if ( ((type == KF_PLAY_DEFAULT) || (type == KF_PLAY_LOOP)) && m_bDirty )
	{
		Msg("Playing back outdated path; compile to see changes, or use kf_preview\n");
	};

	m_bPlaybackLoop = ( type == KF_PLAY_LOOP );
	m_bPreview = ( type == KF_PLAY_PREVIEW );
	local ang;

	if ( m_bPlaybackLoop )
	{
		Msg("loop\n");
	};

	if ( (type == KF_PLAY_DEFAULT) || (type == KF_PLAY_LOOP) )
	{
		if ( m_Selection[0] && m_Selection[1] )
		{
			m_nPlaybackTarget = m_Selection[1];
			m_nPlaybackIdx = m_Selection[0];

			Msg(Fmt( "selection [%d -> %d]\n", m_Selection[0], m_Selection[1] ));
		}
		else
		{
			m_nPlaybackTarget = m_PathData.len();
			m_nPlaybackIdx = 0;

			CameraSetFov( m_nPathInitialFOV, 0.0 );
		};

		local firstpt = m_PathData[m_nPlaybackIdx];
		CameraSetOrigin( firstpt.origin );
		CameraSetAngles( firstpt.angles );

		ang = firstpt.angles;
	}
	else
	{
		Msg("preview mode\n");

		if ( m_bAutoFillBoundaries )
			_Process.FillBoundaries();

		m_nPlaybackTarget = m_KeyFrames.len() - 2;
		m_nPlaybackIdx = 1;
		m_flPreviewFrac = 0.0;

		local pos = Vector();
		ang = Vector();
		_Process.SplineOrigin( m_nPlaybackIdx, m_flPreviewFrac, pos );
		_Process.SplineAngles( m_nPlaybackIdx, m_flPreviewFrac, ang );

		CameraSetOrigin( pos );
		CameraSetAngles( ang );
	};

	// HACKHACK: set player angles as well to get the correct angle in CurrentViewAngles in edit mode
	local curang = MainViewAngles();
	m_AnglesRestore = [ player, curang.x, curang.y, 0 ];
	player.SetAngles( ang.x, ang.y, 0 );

	CameraSetEnabled( true );
	CameraSetThinkEnabled( false );

	MsgHint("Starting in 3...\n");
	PlaySound( SND_COUNTDOWN_BEEP );

	AddEvent( MsgHint,   1.0, [this, "Starting in 2...\n"] );
	AddEvent( PlaySound, 1.0, [this, SND_COUNTDOWN_BEEP]   );

	AddEvent( MsgHint,   2.0, [this, "Starting in 1...\n"] );
	AddEvent( PlaySound, 2.0, [this, SND_COUNTDOWN_BEEP]   );

	player.SetHealth(1337);
	HideHudHint( 3.0 );

	m_bPlaybackPending = true;
	AddEvent( _Play, 3.0, this );
}

function _Play()
{
	m_bPlaybackPending = false;
	m_bInPlayback = true;
	Msg("Playback has started...\n\n");
	CameraSetThinkEnabled( true );
}

// kf_stop
function Stop()
{
	if ( m_bPlaybackPending )
	{
		m_bPlaybackPending = false;
		VS.EventQueue.CancelEventsByInput( _Play );
		VS.EventQueue.CancelEventsByInput( MsgHint );
		VS.EventQueue.CancelEventsByInput( PlaySound );
		HideHudHint();
	}
	else if ( !m_bInPlayback )
	{
		return MsgFail("Playback is not running.\n");
	};;

	if ( m_bPreview )
	{
		Msg("Preview has ended.\n");

		if ( m_bAutoFillBoundaries )
			_Process.FillBoundariesRevert();
	}
	else
	{
		Msg("Playback has ended.\n");
	};

	m_bInPlayback = false;
	m_bPreview = false;

	CameraSetEnabled( false );
	CameraSetThinkEnabled( false );

	CameraSetFov(0,0);

	VS.EventQueue.AddEvent( player.SetAngles, 0.025, m_AnglesRestore );

	SetEditModeTemp( m_bInEditMode );

	PlaySound( SND_PLAY_END );
}


//--------------------------------------------------------------


class CUndoKeyframeFOV extends CUndoElement
{
	function Undo()
	{
		Base.m_KeyFrames[ m_nKeyIndex ].SetFov( m_nFovOld );
	}

	function Redo()
	{
		Base.m_KeyFrames[ m_nKeyIndex ].SetFov( m_nFovNew );
	}

	function Desc()
	{
		return Fmt( "fov #%i : %i -> %i", m_nKeyIndex, m_nFovOld, m_nFovNew );
	}

	m_nKeyIndex = null;
	m_nFovOld = null;
	m_nFovNew = null;
}

function SetKeyframeFOV( input )
{
	if ( m_bCompiling )
		return MsgFail("Cannot modify keyframes while compiling!\n");

	if ( !m_KeyFrames.len() )
		return MsgFail("No keyframes found.\n");

	if ( !m_bInEditMode )
		return MsgFail("You need to be in edit mode to add new FOV data.\n");

	input = input.tointeger();

	// refresh
	if ( m_bSeeing )
		CameraSetFov( input, 0.25 );

	local key = m_KeyFrames[ m_nCurKeyframe ];

	local pUndo = CUndoKeyframeFOV();
	PushUndo( pUndo );
	pUndo.m_nKeyIndex = m_nCurKeyframe;
	pUndo.m_nFovOld = key.fov ? key.fov : 90;
	pUndo.m_nFovNew = input;

	key.SetFov( input );

	CompileFOV();

	MsgHint(Fmt( "Set keyframe #%d FOV to %d\n", m_nCurKeyframe, input ));
	PlaySound( SND_BUTTON );
}


class CUndoKeyframeRoll extends CUndoElement
{
	function Undo()
	{
		Base.m_KeyFrames[ m_nKeyIndex ].SetAngles( m_vecAnglesOld );
	}

	function Redo()
	{
		Base.m_KeyFrames[ m_nKeyIndex ].SetAngles( m_vecAnglesNew );
	}

	function Desc()
	{
		return Fmt( "roll #%i : %g -> %g", m_nKeyIndex, m_vecAnglesOld.z, m_vecAnglesNew.z );
	}

	m_nKeyIndex = null;
	m_vecAnglesOld = null;
	m_vecAnglesNew = null;
}

function SetKeyframeRoll( input )
{
	if ( m_bCompiling )
		return MsgFail("Cannot modify keyframes while compiling!\n");

	if ( !m_bInEditMode )
		return MsgFail("You need to be in edit mode to use camera roll.\n");

	input = VS.AngleNormalize( input.tofloat() );

	local key = m_KeyFrames[ m_nCurKeyframe ];

	local pUndo = CUndoKeyframeRoll();
	PushUndo( pUndo );
	pUndo.m_nKeyIndex = m_nCurKeyframe;
	pUndo.m_vecAnglesOld = key.angles * 1;

	key.angles.z = input;
	key.SetAngles( key.angles );

	pUndo.m_vecAnglesNew = key.angles * 1;

	// refresh
	if ( m_bSeeing )
	{
		if ( m_nSelectedKeyframe == -1 )
			return Error("[ERROR] Assertion failed. Seeing while no keyframe is selected.\n");

		CameraSetAngles( key.angles );
	};

	MsgHint(Fmt( "Set keyframe #%d roll to %g\n", m_nCurKeyframe, input ));
	PlaySound( SND_BUTTON );
}

function Trim( flInputLen = KF_NOPARAM, bDirection = 1 )
{
	if ( flInputLen == KF_NOPARAM )
		throw "wrong number of parameters";

	if ( m_bCompiling )
		return MsgFail("Cannot trim while compiling!\n");

	if ( m_bInPlayback || m_bPlaybackPending )
		return MsgFail("Cannot trim while in playback!\n");

	if ( !m_PathData.len() )
		return MsgFail("No compiled data found.\n");

	flInputLen = max( 0, flInputLen.tofloat() );

	local flCurLen = m_PathData.len() * g_FrameTime;

	if ( flInputLen > flCurLen )
		return MsgFail("Trim value larger than current length!\n");

	local nFramesToRemove = ( m_PathData.len() - ( flInputLen / g_FrameTime ) ).tointeger();
	if ( nFramesToRemove <= 0 )
		return MsgFail("No data to trim.\n");

	if ( !m_TrimData )
	{
		m_TrimData = [];
	};

	m_bTrimDirection = !!bDirection;

	if ( m_bTrimDirection )
	{
		for ( local i = nFramesToRemove; i--; )
		{
			ArrayAppend( m_TrimData, m_PathData.pop() );
		}

		m_TrimData.reverse();
	}
	else
	{
		for ( local i = nFramesToRemove; i--; )
		{
			ArrayAppend( m_TrimData, m_PathData.remove(0) );
		}
	};

	Msg(Fmt( "Trimmed: %g -> %g\n", flCurLen, m_PathData.len() * g_FrameTime ));
	PlaySound( SND_BUTTON );
}

function UndoTrim()
{
	if ( m_bCompiling )
		return MsgFail("Cannot undo trim while compiling!\n");

	if ( m_bInPlayback || m_bPlaybackPending )
		return MsgFail("Cannot undo trim while in playback!\n");

	if ( !m_TrimData || !m_TrimData.len() )
		return MsgFail("No trimmed data found.\n");

	local flCurLen = m_PathData.len() * g_FrameTime;

	if ( m_bTrimDirection )
	{
		for ( local i = 0; i < m_TrimData.len(); ++i )
		{
			ArrayAppend( m_PathData, m_TrimData[i] );
		}
	}
	else
	{
		for ( local i = 0; i < m_TrimData.len(); ++i )
		{
			m_PathData.insert( i, m_TrimData[i] );
		}
	};

	m_TrimData.clear();

	Msg(Fmt( "Undone trim: %g -> %g\n", flCurLen, m_PathData.len() * g_FrameTime ));
	PlaySound( SND_BUTTON );
}


CompileFOV <- _Process.CompileFOV.bindenv(_Process);

// global bindings for easy use with 'script kf_XX()'
::kf_roll <- SetKeyframeRoll.bindenv(this);
::kf_fov <- SetKeyframeFOV.bindenv(this);
::kf_samplecount <- SetSampleCount.bindenv(this);
::kf_frametime <- SetFrameTime.bindenv(this);
::kf_load <- _Load.LoadData.bindenv(_Load);
::kf_trim <- Trim.bindenv(this);
::kf_transform <- TransformKeyframes.bindenv(this);


//--------------------------------------------------------------
//--------------------------------------------------------------

VS.OnTimer( m_hThinkEdit, EditModeThink, this );
VS.OnTimer( m_hThinkAnim, AnimThink, this );
VS.OnTimer( m_hThinkCam, CameraThink, this );
VS.OnTimer( m_hThinkFrame, FrameThink, this );

function PostSpawn()
{
	if ( player.GetTeam() != 2 && player.GetTeam() != 3 )
		player.SetTeam(2);
	player.SetHealth(1337);

	SendToConsole("drop;drop;drop;drop;drop");

	PlaySound( SND_SPAWN );

	if ( !m_bPlaybackPending && !m_bInPlayback )
	{
		// init
		CameraSetEnabled( true );
		CameraSetEnabled( false );
	};

	if ( m_nInterpolatorAngle == null )
	{
		m_nInterpolatorAngle = KF_INTERP_D3DX;
		m_nInterpolatorOrigin = KF_INTERP_CATMULL_ROM;
	};

	ListenMouse(1);
	SetAngleInterp( m_nInterpolatorAngle );
	SetOriginInterp( m_nInterpolatorOrigin );
	SetEditMode( m_bInEditMode );
	SetHelperOrigin( MAX_COORD_VEC );

	// print after Steamworks Msg
	if ( GetDeveloperLevel() > 0 )
	{
		AddEvent( SendToConsole, 0.75, [null, "clear;script _KF_.WelcomeMsg()"] );
	}
	else
	{
		SendToConsole("clear");
		WelcomeMsg();
	};

	delete PostSpawn;
}

function WelcomeMsg()
{
	Msg("\n");
	PrintCmd();

	local tr = 1.0/FrameTime();

	if ( !VS.IsInteger( 128.0 / tr ) )
	{
		Msg(Fmt( "[!] Invalid tickrate (%g)! Only 128 and 64 tickrates are supported.\n\n", tr ));
	}
	else
	{
		Msg(Fmt( "Server tickrate: %g\n\n", tr ));
	};

	delete WelcomeMsg;

	LoadFile(false);
}

// kf_cmd
function PrintCmd()
{
	Msg("\n");
	Msg(Fmt( "   [v%s]     github.com/samisalreadytaken/keyframes\n", version ));
	Msg("\n");
	Msg("kf_add                  : Add new keyframe\n");
	Msg("kf_remove               : Remove the selected keyframe\n");
	Msg("kf_removefov            : Remove the FOV data from the selected keyframe\n");
	Msg("kf_clear                : Remove all keyframes\n");
	Msg("kf_insert               : Insert new keyframe before the selected keyframe\n");
	Msg("kf_replace              : Replace the current keyframe\n");
	Msg("kf_copy                 : Set player pos/ang to the current keyframe\n");
	Msg("kf_undo                 : Undo last action\n");
	Msg("kf_redo                 : Redo last action\n");
	Msg("kf_undo_history         : Show action history\n");
	Msg("                        :\n");
	Msg("kf_compile              : Compile the keyframe data\n");
	Msg("kf_smooth_angles        : Smooth compiled path angles\n");
	Msg("kf_smooth_angles_exp    : Smooth compiled path angles exponentially\n");
	Msg("kf_smooth_origin        : Smooth compiled path origin\n");
	Msg("kf_play                 : Play the compiled data\n");
	Msg("kf_play_loop            : Play the compiled data looped\n");
	Msg("kf_preview              : Play the keyframe data without compiling\n");
	Msg("kf_stop                 : Stop playback\n");
	Msg("kf_savepath             : Export the compiled data\n");
	Msg("kf_savekeys             : Export the keyframe data\n");
	Msg("                        :\n");
	Msg("kf_mode_angles          : Cycle through angle interpolation types\n");
	Msg("kf_mode_origin          : Cycle through position interpolation types\n");
	Msg("kf_auto_fill_boundaries : Duplicate the first and last keyframes in compilation\n");
	Msg("                        :\n");
	Msg("kf_edit                 : Toggle edit mode\n");
	Msg("kf_translate            : Toggle 3D translation manipulator\n");
	Msg("kf_select_path          : In edit mode, select path\n");
	Msg("kf_see                  : In edit mode, see the current selection\n");
	Msg("kf_next                 : While holding a keyframe, select the next one\n");
	Msg("kf_prev                 : While holding a keyframe, select the previous one\n");
	Msg("kf_showkeys             : In edit mode, toggle showing keyframes\n");
	Msg("kf_showpath             : In edit mode, toggle showing the path\n");
	Msg("                        :\n");
	Msg("script kf_fov(val)      : Set FOV data on the selected keyframe\n");
	Msg("script kf_roll(val)     : Set camera roll on the selected keyframe\n");
	Msg("script kf_frametime(val): Sets the time it takes to travel until the next keyframe\n");
	Msg("script kf_samplecount(val): Sets how many samples to take until the next keyframe\n");
	Msg("                        :\n");
	Msg("script kf_transform()   : Rotate all keyframes around key with optional translation offset (idx,offset,rotation)\n");
	Msg("                        :\n");
	Msg("kf_loadfile             : Load data file\n");
	Msg("script kf_load(input)   : Load new data from file\n");
	Msg("script kf_trim(val)     : Trim compiled path to specified length\n");
	Msg("kf_trim_undo            : Undo last trim action\n");
	Msg("                        :\n");
	Msg("kf_cmd                  : List all commands\n");
	Msg("\n");
	Msg("--- --- --- --- --- ---\n");
	Msg("\n");
	Msg("MOUSE1                  : kf_add\n");
	Msg("MOUSE2                  : kf_remove\n");
	Msg("E                       : kf_see\n");
	Msg("A / D                   : (In see mode) Set camera roll\n");
	Msg("W / S                   : (In see mode) Set camera FOV\n");
	Msg("MOUSE1                  : (In see mode) kf_next\n");
	Msg("MOUSE2                  : (In see mode) kf_prev\n");
	Msg("\n");
}

}.call(_KF_);
