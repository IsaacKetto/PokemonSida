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

def pokemon_data(db, id)
    return db.execute('SELECT * FROM pokemons WHERE id=?', id)
end

def type_color(type)
    case type
    when "normal"
        return "#aa9"
    when "fire"
        return "#FF4422"
    when "water"
        return "#3399FF"
    when "electric"
        return "#FFCC33"
    when "grass"
        return "#77CC55"
    when "ice"
        return "#66CCFF"
    when "fighting"
        return "#BB5544"
    when "poison"
        return "#AA5599"
    when "ground"
        return "#DDBB55"
    when "flying"
        return "#8899FF"
    when "psychic"
        return "#FF5599"
    when "bug"
        return "#AABB22"
    when "rock"
        return "#BBAA66"
    when "ghost"
        return "#6666BB"
    when "dragon"
        return "#7766EE"
    when "dark"
        return "#775544"
    when "steel"
        return "#AAAABB"
    when "fairy"
        return "#EE99EE"
    end
end