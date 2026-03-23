package game

main :: proc() {
    game := create_game()
    run_game(&game)
}