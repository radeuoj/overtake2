package main

import "vendor:raylib"

Player :: struct {
    position: [2]f32,
    texture: raylib.Texture2D,
}

PLAYER_WIDTH :: 250
PLAYER_HEIGHT :: 500
PLAYER_SPEED :: 10000
CAR_COUNT :: 14
SELECTED_CAR :: 11

create_player :: proc() -> Player {
    @(rodata, static) PLAYER_IMAGE := #load("textures/cars.png")

    image := raylib.LoadImageFromMemory(".jpg", raw_data(PLAYER_IMAGE), i32(len(PLAYER_IMAGE)))
    texture := raylib.LoadTextureFromImage(image)
    raylib.UnloadImage(image)

    return Player{
        position = {5000, 100},
        texture = texture,
    }
}

update_player :: proc(player: ^Player) {
    move_dir: [2]f32

    if raylib.IsKeyDown(.W) {
        move_dir.y -= 1
    }

    if raylib.IsKeyDown(.S) {
        move_dir.y += 1
    }

    if raylib.IsKeyDown(.A) {
        move_dir.x -= 1
    }

    if raylib.IsKeyDown(.D) {
        move_dir.x += 1
    }

    player.position += move_dir * PLAYER_SPEED * raylib.GetFrameTime()
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
    
    origin := [2]f32{0, 0}

    raylib.DrawTexturePro(
        game.player.texture, 
        source_rect,
        dest_rect,
        origin,
        0,
        raylib.WHITE,
    )
}