package game

import rl "vendor:raylib"

GameBackground :: struct {
    texture: rl.Texture2D,
}

CHUNK_SIZE :: 10000

create_background :: proc() -> GameBackground {
    @(rodata, static) HIGHWAY_IMAGE := #load("../textures/highway.jpg")

    image := rl.LoadImageFromMemory(".jpg", raw_data(HIGHWAY_IMAGE), i32(len(HIGHWAY_IMAGE)))
    texture := rl.LoadTextureFromImage(image)
    rl.UnloadImage(image)

    return GameBackground{
        texture,
    }
}

draw_background_at :: proc(game: ^Game, chunk: [2]i32) {
    position := [2]f32{f32(chunk.x), f32(chunk.y)} * CHUNK_SIZE

    screen_pos := game_to_screen(game.camera, position)

    source_rect := rl.Rectangle{
        x = 0,
        y = 0,
        width = f32(game.background.texture.width),
        height = f32(game.background.texture.height),
    }

    dest_rect := rl.Rectangle{
        x = screen_pos.x,
        y = screen_pos.y,
        width = CHUNK_SIZE,
        height = CHUNK_SIZE,
    }
    
    origin := [2]f32{0, 0}

    rl.DrawTexturePro(
        game.background.texture, 
        source_rect,
        dest_rect,
        origin,
        0,
        rl.WHITE,
    )
}

get_player_chunk :: proc(player: ^Player) -> [2]i32 {
    chunk := [2]i32{i32(player.position.x), i32(player.position.y)} / CHUNK_SIZE

    for i in 0..<2 {
        if player.position[i] < 0 {
            chunk[i] -= 1
        }
    }

    return chunk
}

draw_background :: proc(game: ^Game) {
    chunk := get_player_chunk(&game.player)
    
    for i in -1..=1 {
        draw_background_at(game, chunk + {0, i32(i)})
    }
}