package game

import "core:math"
import rl "vendor:raylib"

Player :: struct {
    position: [2]f32,
    rotation: f32,
    texture: rl.Texture2D,
}

PLAYER_WIDTH :: 120
PLAYER_HEIGHT :: 240
PLAYER_SPEED :: 5000
PLAYER_ROTATION_SPEED :: 2 * math.PI
CAR_COUNT :: 14
SELECTED_CAR :: 11

create_player :: proc() -> Player {
    @(rodata, static) PLAYER_IMAGE := #load("../textures/cars.png")

    image := rl.LoadImageFromMemory(".jpg", raw_data(PLAYER_IMAGE), i32(len(PLAYER_IMAGE)))
    texture := rl.LoadTextureFromImage(image)
    rl.UnloadImage(image)

    return Player{
        position = {2500, 100},
        rotation = 0,
        texture = texture,
    }
}

update_player :: proc(player: ^Player) {
    move_dir: f32
    rotation_dir: f32

    if rl.IsKeyDown(.W) {
        move_dir -= 1
    }

    if rl.IsKeyDown(.S) {
        move_dir += 1
    }

    if rl.IsKeyDown(.A) {
        rotation_dir += move_dir
    }

    if rl.IsKeyDown(.D) {
        rotation_dir -= move_dir
    }

    player.rotation += rotation_dir * rl.GetFrameTime() * PLAYER_ROTATION_SPEED
    dir := [2]f32{math.cos(player.rotation + math.PI / 2), math.sin(player.rotation + math.PI / 2)}
    move_delta := dir * move_dir * PLAYER_SPEED
    player.position += move_delta * rl.GetFrameTime()
}

draw_player :: proc(player: ^Player, camera: [2]f32) {
    screen_pos := game_to_screen(camera, player.position)

    source_rect := rl.Rectangle{
        x = f32(player.texture.width / CAR_COUNT * SELECTED_CAR),
        y = 0,
        width = f32(player.texture.width / CAR_COUNT),
        height = f32(player.texture.height),
    }

    dest_rect := rl.Rectangle{
        x = screen_pos.x,
        y = screen_pos.y,
        width = PLAYER_WIDTH,
        height = PLAYER_HEIGHT,
    }
    
    origin := [2]f32{PLAYER_WIDTH / 2, PLAYER_HEIGHT / 2}

    rl.DrawTexturePro(
        player.texture, 
        source_rect,
        dest_rect,
        origin,
        math.to_degrees(player.rotation),
        rl.WHITE,
    )
}