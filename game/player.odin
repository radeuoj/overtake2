package game

import "core:math"
import "vendor:raylib"

Player :: struct {
    position: [2]f32,
    rotation: f32,
    texture: raylib.Texture2D,
}

PLAYER_WIDTH :: 250
PLAYER_HEIGHT :: 500
PLAYER_SPEED :: 10000
PLAYER_ROTATION_SPEED :: 2 * math.PI
CAR_COUNT :: 14
SELECTED_CAR :: 11

create_player :: proc() -> Player {
    @(rodata, static) PLAYER_IMAGE := #load("../textures/cars.png")

    image := raylib.LoadImageFromMemory(".jpg", raw_data(PLAYER_IMAGE), i32(len(PLAYER_IMAGE)))
    texture := raylib.LoadTextureFromImage(image)
    raylib.UnloadImage(image)

    return Player{
        position = {5000, 100},
        rotation = 0,
        texture = texture,
    }
}

update_player :: proc(player: ^Player) {
    move_dir: f32
    rotation_dir: f32

    if raylib.IsKeyDown(.W) {
        move_dir -= 1
    }

    if raylib.IsKeyDown(.S) {
        move_dir += 1
    }

    if raylib.IsKeyDown(.A) {
        rotation_dir += move_dir
    }

    if raylib.IsKeyDown(.D) {
        rotation_dir -= move_dir
    }

    player.rotation += rotation_dir * raylib.GetFrameTime() * PLAYER_ROTATION_SPEED
    dir := [2]f32{math.cos(player.rotation + math.PI / 2), math.sin(player.rotation + math.PI / 2)}
    move_delta := dir * move_dir * PLAYER_SPEED
    player.position += move_delta * raylib.GetFrameTime()
}

draw_player :: proc(game: ^Game) {
    screen_pos := game_to_screen(game, game.player.position)

    source_rect := raylib.Rectangle{
        x = f32(game.player.texture.width / CAR_COUNT * SELECTED_CAR),
        y = 0,
        width = f32(game.player.texture.width / CAR_COUNT),
        height = f32(game.player.texture.height),
    }

    dest_rect := raylib.Rectangle{
        x = screen_pos.x,
        y = screen_pos.y,
        width = PLAYER_WIDTH,
        height = PLAYER_HEIGHT,
    }
    
    origin := [2]f32{PLAYER_WIDTH / 2, PLAYER_HEIGHT / 2}

    raylib.DrawTexturePro(
        game.player.texture, 
        source_rect,
        dest_rect,
        origin,
        math.to_degrees(game.player.rotation),
        raylib.WHITE,
    )
}