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