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
    FMap: Array of array of Integer;
    FMapH: Integer;
    FMapW: Integer;
    FPathX: Array of Integer;
    FPathY: Array of Integer;
    FPathLen: Integer;
  public
    procedure Move(me: TCar; world: TWorld; game: TGame; move: TMove); override;
    function Lee(ax, ay, bx, by: Integer): Boolean;
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

  WALL  = -1;
  BLANK = -2;

// Direction
  _UNKNOWN_DIRECTION_ = -1;
  LEFT                = 0;
  RIGHT               = 1;
  UP                  = 2;
  DOWN                = 3;
  _DIRECTION_COUNT_   = 4;

var
  dx: Array [0..3] of Integer = (1, 0, -1, 0);  // смещени€, соответствующие сосед€м €чейки
  dy: Array [0..3] of Integer = (0, 1, 0, -1);  // справа, снизу, слева и сверху

function TMyStrategy.Lee(ax, ay, bx, by: Integer): Boolean;
var
//  dx: Array [0..3] of Integer = (1, 0, -1, 0);  // смещени€, соответствующие сосед€м €чейки
//  dy: Array [0..3] of Integer = (0, 1, 0, -1);  // справа, снизу, слева и сверху
  d, x, y, k, ix, iy: Integer;
  stop: boolean;
begin
  Result := false;

  if ((FMap[ax][ay] = WALL) or (FMap[bx][by] = WALL)) then Exit;  // €чейка (ax, ay) или (bx, by) - стена

  // распространение волны
  d := 0;
  FMap[ax][ay] := 0;            // стартова€ €чейка помечена 0
  repeat
    stop := true;               // предполагаем, что все свободные клетки уже помечены
    for y := 0 to FMapH - 1 do
      for x := 0 to FMapW - 1 do
        if FMap[x][y] = d then    // €чейка (x, y) помечена числом d
          for k := 0 to 3 do      // проходим по всем непомеченным сосед€м
          begin
            ix := x + dx[k];
            iy := y + dy[k];

            if (ix >= 0) and (ix < FMapW)
              and (iy >= 0) and (iy < FMapH)
              and (FMap[ix][iy] = BLANK) then
            begin
              stop := false;           // найдены непомеченные клетки
              FMap[ix][iy] := d + 1;   // распростран€ем волну
            end;
          end;

    Inc(d);
  until ( not ((not stop) and (FMap[bx][by] = BLANK)) );

  if (FMap[bx][by] = BLANK) then Exit;  // путь не найден

  // восстановление пути
  FPathLen := FMap[bx][by];   // длина кратчайшего пути из (ax, ay) в (bx, by)
  x := bx;
  y := by;
  d := FPathLen;
  while ( d > 0 ) do
  begin
    FPathX[d] := x;
    FPathY[d] := y;           // записываем €чейку (x, y) в путь
    Dec(d);
    for k := 0 to 3 do
    begin
      ix := x + dx[k];
      iy := y + dy[k];

      if ((iy >= 0) and (iy < FMapH)
        and (ix >= 0) and (ix < FMapW)
        and (FMap[ix][iy] = d)) then
        begin
          x := x + dx[k];
          y := y + dy[k];     // переходим в €чейку, котора€ на 1 ближе к старту
          Continue;
        end;
    end;
  end;

  FPathX[0] := ax;
  FPathY[0] := ay;    // теперь px[0..len] и py[0..len] - координаты €чеек пути

  Result := true;
end;

procedure TMyStrategy.Move(me: TCar; world: TWorld; game: TGame; move: TMove);
var
  nextWaypointX, nextWaypointY: Extended;
  cornerTileOffset, angleToWaypoint: Extended;
  speedModule : Extended;
  tile: ShortInt;
  cars: TCarArray;

  i: Integer;
  x, y: Integer;

  isRaceStart: Boolean;

  mapRow: String;

  tx, ty: Integer;

  strings : TStringList;
begin
  isRaceStart := (world.GetTick() > game.GetInitialFreezeDurationTicks());

  if not isRaceStart then NitroFreeze := 0;

  if world.GetTick = 0 then
  begin

    FMapW := world.Width * 3;
    FMapH := world.Height * 3;

    SetLength(FMap, FMapW, FMapH);

    SetLength(FPathX, FMapW * FMapH);
    SetLength(FPathY, FMapW * FMapH);

    for x := 0 to world.Height - 1 do
    begin
      for y := 0 to world.Width - 1 do
      begin
        tile := world.TilesXY[x][y];
        case tile of
        VERTICAL:
            begin
              FMap[3*x + 0][3*y + 0] := WALL;
              FMap[3*x + 0][3*y + 1] := WALL;
              FMap[3*x + 0][3*y + 2] := WALL;
              FMap[3*x + 1][3*y + 0] := BLANK;
              FMap[3*x + 1][3*y + 1] := BLANK;
              FMap[3*x + 1][3*y + 2] := BLANK;
              FMap[3*x + 2][3*y + 0] := WALL;
              FMap[3*x + 2][3*y + 1] := WALL;
              FMap[3*x + 2][3*y + 2] := WALL;
            end;
        HORIZONTAL:
            begin
              FMap[3*x + 0][3*y + 0] := WALL;
              FMap[3*x + 0][3*y + 1] := BLANK;
              FMap[3*x + 0][3*y + 2] := WALL;
              FMap[3*x + 1][3*y + 0] := WALL;
              FMap[3*x + 1][3*y + 1] := BLANK;
              FMap[3*x + 1][3*y + 2] := WALL;
              FMap[3*x + 2][3*y + 0] := WALL;
              FMap[3*x + 2][3*y + 1] := BLANK;
              FMap[3*x + 2][3*y + 2] := WALL;
            end;
        LEFT_TOP_CORNER:
            begin
              FMap[3*x + 0][3*y + 0] := WALL;
              FMap[3*x + 0][3*y + 1] := WALL;
              FMap[3*x + 0][3*y + 2] := WALL;
              FMap[3*x + 1][3*y + 0] := WALL;
              FMap[3*x + 1][3*y + 1] := BLANK;
              FMap[3*x + 1][3*y + 2] := BLANK;
              FMap[3*x + 2][3*y + 0] := WALL;
              FMap[3*x + 2][3*y + 1] := BLANK;
              FMap[3*x + 2][3*y + 2] := WALL;
            end;
        RIGHT_TOP_CORNER:
            begin
              FMap[3*x + 0][3*y + 0] := WALL;
              FMap[3*x + 0][3*y + 1] := BLANK;
              FMap[3*x + 0][3*y + 2] := WALL;
              FMap[3*x + 1][3*y + 0] := WALL;
              FMap[3*x + 1][3*y + 1] := BLANK;
              FMap[3*x + 1][3*y + 2] := BLANK;
              FMap[3*x + 2][3*y + 0] := WALL;
              FMap[3*x + 2][3*y + 1] := WALL;
              FMap[3*x + 2][3*y + 2] := WALL;
            end;
        LEFT_BOTTOM_CORNER:
            begin
              FMap[3*x + 0][3*y + 0] := WALL;
              FMap[3*x + 0][3*y + 1] := WALL;
              FMap[3*x + 0][3*y + 2] := WALL;
              FMap[3*x + 1][3*y + 0] := BLANK;
              FMap[3*x + 1][3*y + 1] := BLANK;
              FMap[3*x + 1][3*y + 2] := WALL;
              FMap[3*x + 2][3*y + 0] := WALL;
              FMap[3*x + 2][3*y + 1] := BLANK;
              FMap[3*x + 2][3*y + 2] := WALL;
            end;
        RIGHT_BOTTOM_CORNER:
            begin
              FMap[3*x + 0][3*y + 0] := WALL;
              FMap[3*x + 0][3*y + 1] := BLANK;
              FMap[3*x + 0][3*y + 2] := WALL;
              FMap[3*x + 1][3*y + 0] := BLANK;
              FMap[3*x + 1][3*y + 1] := BLANK;
              FMap[3*x + 1][3*y + 2] := WALL;
              FMap[3*x + 2][3*y + 0] := WALL;
              FMap[3*x + 2][3*y + 1] := WALL;
              FMap[3*x + 2][3*y + 2] := WALL;
            end;
        LEFT_HEADED_T:
            begin
              FMap[3*x + 0][3*y + 0] := WALL;
              FMap[3*x + 0][3*y + 1] := BLANK;
              FMap[3*x + 0][3*y + 2] := WALL;
              FMap[3*x + 1][3*y + 0] := BLANK;
              FMap[3*x + 1][3*y + 1] := BLANK;
              FMap[3*x + 1][3*y + 2] := BLANK;
              FMap[3*x + 2][3*y + 0] := WALL;
              FMap[3*x + 2][3*y + 1] := WALL;
              FMap[3*x + 2][3*y + 2] := WALL;
            end;
        RIGHT_HEADED_T:
            begin
              FMap[3*x + 0][3*y + 0] := WALL;
              FMap[3*x + 0][3*y + 1] := WALL;
              FMap[3*x + 0][3*y + 2] := WALL;
              FMap[3*x + 1][3*y + 0] := BLANK;
              FMap[3*x + 1][3*y + 1] := BLANK;
              FMap[3*x + 1][3*y + 2] := BLANK;
              FMap[3*x + 2][3*y + 0] := WALL;
              FMap[3*x + 2][3*y + 1] := BLANK;
              FMap[3*x + 2][3*y + 2] := WALL;
            end;
        TOP_HEADED_T:
            begin
              FMap[3*x + 0][3*y + 0] := WALL;
              FMap[3*x + 0][3*y + 1] := BLANK;
              FMap[3*x + 0][3*y + 2] := WALL;
              FMap[3*x + 1][3*y + 0] := BLANK;
              FMap[3*x + 1][3*y + 1] := BLANK;
              FMap[3*x + 1][3*y + 2] := WALL;
              FMap[3*x + 2][3*y + 0] := WALL;
              FMap[3*x + 2][3*y + 1] := BLANK;
              FMap[3*x + 2][3*y + 2] := WALL;
            end;
        BOTTOM_HEADED_T:
            begin
              FMap[3*x + 0][3*y + 0] := WALL;
              FMap[3*x + 0][3*y + 1] := BLANK;
              FMap[3*x + 0][3*y + 2] := WALL;
              FMap[3*x + 1][3*y + 0] := WALL;
              FMap[3*x + 1][3*y + 1] := BLANK;
              FMap[3*x + 1][3*y + 2] := BLANK;
              FMap[3*x + 2][3*y + 0] := WALL;
              FMap[3*x + 2][3*y + 1] := BLANK;
              FMap[3*x + 2][3*y + 2] := WALL;
            end;
        CROSSROADS:
            begin
              FMap[3*x + 0][3*y + 0] := WALL;
              FMap[3*x + 0][3*y + 1] := BLANK;
              FMap[3*x + 0][3*y + 2] := WALL;
              FMap[3*x + 1][3*y + 0] := BLANK;
              FMap[3*x + 1][3*y + 1] := BLANK;
              FMap[3*x + 1][3*y + 2] := BLANK;
              FMap[3*x + 2][3*y + 0] := WALL;
              FMap[3*x + 2][3*y + 1] := BLANK;
              FMap[3*x + 2][3*y + 2] := WALL;
            end;
        end;
      end;
    end;

    for x := 0 to FMapW - 1 do
      for y := 0 to FMapH - 1 do
        if (FMap[x][y] = 0) then FMap[x][y] := WALL;

    tx := Trunc(me.GetX / game.GetTrackTileSize);
    ty := Trunc(me.GetY / game.GetTrackTileSize);
    FMap[(3 * tx + 1)][(3* ty + 1)] := 0;

    strings := TStringList.Create();
    for y := 0 to world.Height * 3 - 1 do
    begin
      mapRow := '';
      for x := 0 to world.Width * 3 - 1 do
      begin
//        if (x = (3 * tx + 1)) and (y = (3* ty + 1)) then
//        begin
//          mapRow := mapRow + 'O';
//          Continue;
//        end;

//        if FMap[x][y] = BLANK
//        then mapRow := mapRow + ' '
//        else mapRow := mapRow + 'X';
        case FMap[x][y] of
          BLANK: mapRow := mapRow + ' ';
          WALL: mapRow := mapRow + 'X';
        else mapRow := mapRow +IntToStr(FMap[x][y]);
        end;
      end;

      strings.Append(mapRow);
    end;

    strings.SaveToFile('2.map');

    //FMap[(3 * tx + 1)][(3* ty + 1)] := WALL;

    case world.GetStartingDirection of
      UP: begin
        FMap[(3 * tx + 1)][(3* ty + 1)] := WALL;
        if Lee((3 * tx + 1), (3* ty ),(3 * tx + 1), (3* ty + 2)) then
        begin
          strings := TStringList.Create();
          for y := 0 to FMapH - 1 do
          begin
            mapRow := '';
            for x := 0 to FMapW - 1 do
            begin
              case FMap[x][y] of
                BLANK: mapRow := mapRow + ' ';
                WALL: mapRow := mapRow + 'X';
                else begin
                  mapRow := mapRow + '*';//IntToStr(FMap[x][y]);
                  FMap[x][y] := BLANK;
                end;
              end;
            end;
            strings.Append(mapRow);
          end;
          strings.SaveToFile('3.map');
        end;
      end;
    end;

  end;

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
