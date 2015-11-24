unit MyStrategy;

interface

uses
  StrategyControl, BonusControl, BonusTypeControl, CarControl, CarTypeControl, DirectionControl, GameControl,
  MoveControl, OilSlickControl, PlayerControl, ProjectileControl, ProjectileTypeControl, TileTypeControl, TypeControl,
  WorldControl, Classes, SysUtils;

type
  TMyStrategy = class (TStrategy)
  private
    FNitroFreeze: Extended;
  public
    procedure Move(me: TCar; world: TWorld; game: TGame; move: TMove); override;
    property NitroFreeze: Extended read FNitroFreeze write FNitroFreeze;
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

  WALL = -1;
  BLANK = -2;

procedure TMyStrategy.Move(me: TCar; world: TWorld; game: TGame; move: TMove);
var
  nextWaypointX, nextWaypointY: Extended;
  cornerTileOffset, angleToWaypoint: Extended;
  speedModule : Extended;
  tile: ShortInt;
  cars: TCarArray;

  i: Integer;
  x, y: Integer;

  map: Array of array of boolean;
  
  isRaceStart: Boolean;

  mapRow: String;

  strings : TStringList;
begin
  isRaceStart := (world.GetTick() > game.GetInitialFreezeDurationTicks());

  if not isRaceStart then NitroFreeze := 0;
  SetLength(map, world.Width * 3, world.Height * 3);

  for x := 0 to world.Height - 1 do
  begin
    for y := 0 to world.Width - 1 do
    begin
      tile := world.TilesXY[x][y];
      case tile of
      VERTICAL:
          begin
            map[3*x + 0][3*y + 0] := false;
            map[3*x + 0][3*y + 1] := false;
            map[3*x + 0][3*y + 2] := false;              
            map[3*x + 1][3*y + 0] := true;
            map[3*x + 1][3*y + 1] := true;
            map[3*x + 1][3*y + 2] := true;              
            map[3*x + 2][3*y + 0] := false;
            map[3*x + 2][3*y + 1] := false;
            map[3*x + 2][3*y + 2] := false;              
          end;
      HORIZONTAL:
          begin
            map[3*x + 0][3*y + 0] := false;
            map[3*x + 0][3*y + 1] := true;
            map[3*x + 0][3*y + 2] := false;              
            map[3*x + 1][3*y + 0] := false;
            map[3*x + 1][3*y + 1] := true;
            map[3*x + 1][3*y + 2] := false;              
            map[3*x + 2][3*y + 0] := false;
            map[3*x + 2][3*y + 1] := true;
            map[3*x + 2][3*y + 2] := false;              
          end;
      LEFT_TOP_CORNER:
          begin
            map[3*x + 0][3*y + 0] := false;
            map[3*x + 0][3*y + 1] := false;
            map[3*x + 0][3*y + 2] := false;              
            map[3*x + 1][3*y + 0] := false;
            map[3*x + 1][3*y + 1] := true;
            map[3*x + 1][3*y + 2] := true;              
            map[3*x + 2][3*y + 0] := false;
            map[3*x + 2][3*y + 1] := true;
            map[3*x + 2][3*y + 2] := false;              
          end;
      RIGHT_TOP_CORNER:
          begin
            map[3*x + 0][3*y + 0] := false;
            map[3*x + 0][3*y + 1] := true;
            map[3*x + 0][3*y + 2] := false;              
            map[3*x + 1][3*y + 0] := false;
            map[3*x + 1][3*y + 1] := true;
            map[3*x + 1][3*y + 2] := true;              
            map[3*x + 2][3*y + 0] := false;
            map[3*x + 2][3*y + 1] := false;
            map[3*x + 2][3*y + 2] := false;              
          end;
      LEFT_BOTTOM_CORNER:
          begin
            map[3*x + 0][3*y + 0] := false;
            map[3*x + 0][3*y + 1] := false;
            map[3*x + 0][3*y + 2] := false;              
            map[3*x + 1][3*y + 0] := true;
            map[3*x + 1][3*y + 1] := true;
            map[3*x + 1][3*y + 2] := false;              
            map[3*x + 2][3*y + 0] := false;
            map[3*x + 2][3*y + 1] := true;
            map[3*x + 2][3*y + 2] := false;              
          end;
      RIGHT_BOTTOM_CORNER:
          begin
            map[3*x + 0][3*y + 0] := false;
            map[3*x + 0][3*y + 1] := true;
            map[3*x + 0][3*y + 2] := false;              
            map[3*x + 1][3*y + 0] := true;
            map[3*x + 1][3*y + 1] := true;
            map[3*x + 1][3*y + 2] := false;              
            map[3*x + 2][3*y + 0] := false;
            map[3*x + 2][3*y + 1] := false;
            map[3*x + 2][3*y + 2] := false;              
          end;
      LEFT_HEADED_T:
          begin
            map[3*x + 0][3*y + 0] := false;
            map[3*x + 0][3*y + 1] := true;
            map[3*x + 0][3*y + 2] := false;              
            map[3*x + 1][3*y + 0] := true;
            map[3*x + 1][3*y + 1] := true;
            map[3*x + 1][3*y + 2] := true;              
            map[3*x + 2][3*y + 0] := false;
            map[3*x + 2][3*y + 1] := false;
            map[3*x + 2][3*y + 2] := false;              
          end;
      RIGHT_HEADED_T:
          begin
            map[3*x + 0][3*y + 0] := false;
            map[3*x + 0][3*y + 1] := false;
            map[3*x + 0][3*y + 2] := false;              
            map[3*x + 1][3*y + 0] := true;
            map[3*x + 1][3*y + 1] := true;
            map[3*x + 1][3*y + 2] := true;              
            map[3*x + 2][3*y + 0] := false;
            map[3*x + 2][3*y + 1] := true;
            map[3*x + 2][3*y + 2] := false;              
          end; 
      TOP_HEADED_T:
          begin
            map[3*x + 0][3*y + 0] := false;
            map[3*x + 0][3*y + 1] := true;
            map[3*x + 0][3*y + 2] := false;              
            map[3*x + 1][3*y + 0] := true;
            map[3*x + 1][3*y + 1] := true;
            map[3*x + 1][3*y + 2] := false;              
            map[3*x + 2][3*y + 0] := false;
            map[3*x + 2][3*y + 1] := true;
            map[3*x + 2][3*y + 2] := false;              
          end; 
      BOTTOM_HEADED_T:
          begin
            map[3*x + 0][3*y + 0] := false;
            map[3*x + 0][3*y + 1] := true;
            map[3*x + 0][3*y + 2] := false;              
            map[3*x + 1][3*y + 0] := false;
            map[3*x + 1][3*y + 1] := true;
            map[3*x + 1][3*y + 2] := true;              
            map[3*x + 2][3*y + 0] := false;
            map[3*x + 2][3*y + 1] := true;
            map[3*x + 2][3*y + 2] := false;              
          end; 
//      CROSSROADS:
      end;
    end;
  end;

  strings := TStringList.Create();
  for y := 0 to world.Height * 3 - 1 do
  begin
    mapRow := '';
    for x := 0 to world.Width * 3 - 1 do
    begin
       if map[x][y]
       then mapRow := mapRow + ' '
       else mapRow := mapRow + 'X';
    end;
       
    strings.Append(mapRow);
  end;

  strings.SaveToFile('1.map');     
  
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
  else
    begin
      if isRaceStart and (world.GetTick >  NitroFreeze)
      then
      begin
        move.SetUseNitro(true);
        NitroFreeze := world.GetTick + 3 * game.GetNitroDurationTicks;
      end;
    end;
  end;

  angleToWaypoint := me.GetAngleTo(nextWaypointX, nextWaypointY);
  speedModule := Math.Hypot(me.GetSpeedX(), me.GetSpeedY());

  move.setWheelTurn(angleToWaypoint * 32.0 / PI);
  move.setEnginePower(0.75);

  if (speedModule * speedModule * abs(angleToWaypoint) > ( 2.5 * 2.5 * PI) ) then
  begin
    move.SetBrake(true);
  end;

  // Actions
  if isRaceStart then
  begin
    // Attacks
    cars := world.GetCars();
    for i := Low(cars) to High(cars) do
    begin
      if cars[i].GetPlayerId = me.GetPlayerId then Continue;

      if (abs(me.GetAngleTo(cars[i].GetX, cars[i].GetY)) < (PI / 18)) then
        if me.GetDistanceTo(cars[i].GetX, cars[i].GetY) < ( 2 *  game.GetTrackTileSize)
        then move.SetThrowProjectile(true);

      if (abs(me.GetAngleTo(cars[i].GetX, cars[i].GetY)) > ( PI * 7 / 8)) then
        move.SetSpillOil(true);
    end;  
  end;

end;

end.
