package server

import "core:net"
import "core:sync"

ClientsStore :: struct {
    store: map[net.TCP_Socket]i32,
    mutex: sync.Mutex,
}

create_clients :: proc() -> ClientsStore {
    return ClientsStore {
        store = make(map[net.TCP_Socket]i32),
    }
}

delete_clients :: proc(clients: ^ClientsStore) {
    clients_lock(clients)
    defer clients_unlock(clients)
    delete(clients.store)
}

clients_lock :: proc(clients: ^ClientsStore) {
    sync.lock(&clients.mutex)
}

clients_unlock :: proc(clients: ^ClientsStore) {
    sync.unlock(&clients.mutex)
}

clients_get :: proc(clients: ^ClientsStore, key: net.TCP_Socket) -> (val: i32, ok: bool) {
    clients_lock(clients)
    defer clients_unlock(clients)
    return clients.store[key]
}

clients_set :: proc(clients: ^ClientsStore, key: net.TCP_Socket, val: i32) {
    clients_lock(clients)
    defer clients_unlock(clients)
    clients.store[key] = val
}

clients_erase :: proc(clients: ^ClientsStore, key: net.TCP_Socket) -> (deleted_key: net.TCP_Socket, deleted_val: i32) {
    clients_lock(clients)
    defer clients_unlock(clients)
    return delete_key(&clients.store, key)
}