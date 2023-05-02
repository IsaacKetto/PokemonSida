# Changes the pokemon name if it is written in a special way
#
# @param name [String] The name of the pokemon
# @return [String] The correct/fixed name of the pokemon
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

# Checks if the input object is a String
#
# @param object [Object] An object to check
# @return [Boolean] Returns true or false
def string?(object)
    return object.class == String
end

# A Hashmap containing different colours for different pokemons types - used for css
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