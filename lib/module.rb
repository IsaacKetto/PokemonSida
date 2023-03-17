def special_name(name)
    pokemon_name = name
    case pokemon_name
    when "Mr. Mime"
        pokemon_name = "mr-mime"
    when "Nidoran♂"
        pokemon_name = "nidoran-m"
    when "Nidoran♀"
        pokemon_name = "nidoran-f"
    when "Farfetch'd"
        pokemon_name = "farfetchd"
    end
    return pokemon_name
end

def catch_pokemon(user_id, pokemon_id, db)
    db.execute('INSERT INTO user_pokemon_relation (user_id, pokemon_id) VALUES (?, ?)', user_id, pokemon_id)
end

def pokemon_data(db, id)
    return db.execute('SELECT * FROM pokemons WHERE id=?', id)
end

def admin_check(user_id, db)
    return 1 == db.execute('SELECT permission FROM users WHERE user_id=?', user_id)
end

TypeColours = {
    normal: "#aa9",
    fire: "#FF4422",
    water: "#3399FF",
    electric: "#FFCC33",
    grass: "#77CC55",
    ice: "#66CCFF",
    fighting: "#BB5544",
    poison: "#AA5599",
    ground: "#DDBB55",
    flying: "#8899FF",
    psychic: "#FF5599",
    bug: "#AABB22",
    rock: "#BBAA66",
    ghost: "#6666BB",
    dragon: "#7766EE",
    dark: "#775544",
    steel: "#AAAABB",
    fairy: "#EE99EE"
}