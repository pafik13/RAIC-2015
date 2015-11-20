unit MyStrategy;

interface

uses
  StrategyControl, BonusControl, BonusTypeControl, CarControl, CarTypeControl, DirectionControl, GameControl,
  MoveControl, OilSlickControl, PlayerControl, ProjectileControl, ProjectileTypeControl, TileTypeControl, TypeControl,
  WorldControl;

type
  TMyStrategy = class (TStrategy)
  public
    procedure Move(me: TCar; world: TWorld; game: TGame; move: TMove); override;

  end;

implementation

uses
  Math;

const
  _UNKNOWN_TILE_TYPE_= -1;
  EMPTY              = 0;
  VERTICAL           = 1;
  HORIZONTAL         = 2;
  LEFT_TOP_CORNER    = 3;
  RIGHT_TOP_CORNER   = 4;
  LEFT_BOTTOM_CORNER = 5;
  RIGHT_BOTTOM_CORNER= 6;
  LEFT_HEADED_T      = 7;
  RIGHT_HEADED_T     = 8;
  TOP_HEADED_T       = 9;
  BOTTOM_HEADED_T    = 10;
  CROSSROADS         = 11;
  UNKNOWN            = 12;
  _TILE_TYPE_COUNT_  = 13;

procedure TMyStrategy.Move(me: TCar; world: TWorld; game: TGame; move: TMove);
var
  nextWaypointX, nextWaypointY: Extended;
  cornerTileOffset, angleToWaypoint: Extended;
  speedModule : Extended;
  tile: ShortInt;
begin
  nextWaypointX := (me.GetNextWaypointX + 0.5) * game.GetTrackTileSize;
  nextWaypointY := (me.GetNextWaypointY + 0.5) * game.GetTrackTileSize;

  cornerTileOffset := 0.25 * game.GetTrackTileSize;

  tile := world.GetTilesXY[me.GetNextWaypointX, me.GetNextWaypointY];

  case tile of
     //CORNERS
  LEFT_TOP_CORNER:
     begin
       nextWaypointX := nextWaypointX + cornerTileOffset;
       nextWaypointY := nextWaypointY + cornerTileOffset;
     end;
  RIGHT_TOP_CORNER:
     begin
       nextWaypointX := nextWaypointX - cornerTileOffset;
       nextWaypointY := nextWaypointY + cornerTileOffset;
     end;
  LEFT_BOTTOM_CORNER:
     begin
       nextWaypointX := nextWaypointX + cornerTileOffset;
       nextWaypointY := nextWaypointY - cornerTileOffset;
     end;
  RIGHT_BOTTOM_CORNER:
     begin
       nextWaypointX := nextWaypointX - cornerTileOffset;
       nextWaypointY := nextWaypointY - cornerTileOffset;
     end;
  end;

  angleToWaypoint := me.GetAngleTo(nextWaypointX, nextWaypointY);
  speedModule := Math.Hypot(me.GetSpeedX(), me.GetSpeedY());

  move.setWheelTurn(angleToWaypoint * 32.0 / PI);
  move.setEnginePower(0.75);

  if (speedModule * speedModule * abs(angleToWaypoint) > 2.5 * 2.5 * PI) then
  begin
    move.SetBrake(true);
  end;
end;

end.
