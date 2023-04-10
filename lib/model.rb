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

def catch_pokemon(user_id, pokemon_id)
    $db.execute('INSERT INTO user_pokemon_relation (user_id, pokemon_id) VALUES (?, ?)', user_id, pokemon_id)
end

def logout()
    session.delete(:current_user)
    session[:logged_in] = false
    flash[:notice] = "You have been logged out!"
end

def delete_user(user_id)
    $db.execute('DELETE FROM users WHERE user_id=?', user_id)
    $db.execute('DELETE FROM user_pokemon_relation WHERE user_id=?', user_id)
    $db.execute('DELETE FROM user_team_relation WHERE user_id=?', user_id)
    if user_id == session[:current_user][:user_id]
        session[:logged_in] = false
        session[:current_user] = {}
    end
end

def update_user(new_name, id)
    $db.execute("UPDATE users SET username=? WHERE user_id=?", new_name, id)
end

def login(username)
    flash[:notice] = "Successful login"
    session[:logged_in] = true
    session[:current_user] = {
        username: username, 
        user_id: $db.execute('SELECT user_id FROM users WHERE username=? LIMIT 1', username).first["user_id"]
    }
end

def create_team(pokemons, team_name)
    $db.execute('INSERT INTO user_team_relation (user_id, pokemons, team_name) VALUES (?,?,?)', session[:current_user][:user_id], pokemons, team_name)
end

def signup(username, password)
    password_digest = BCrypt::Password.create(password)
    $db.execute("INSERT INTO users (username, password) VALUES (?,?)", username, password_digest)
end

def update_team(new_name, pokemon_list, team_id) 
    if new_name == ""
        $db.execute('UPDATE user_team_relation SET pokemons=? WHERE team_id=?', pokemon_list, team_id)
    else
        $db.execute('UPDATE user_team_relation SET pokemons=?, team_name=? WHERE team_id=?', pokemon_list, new_name, team_id)
    end
end

def delete_team(team_id)
    $db.execute('DELETE FROM user_team_relation WHERE team_id=?', team_id)
end

def fetch_inventory(user_id)
    pokemons = []
    pokemon_ids = $db.execute('SELECT pokemon_id, id FROM user_pokemon_relation INNER JOIN users ON user_pokemon_relation.user_id = users.user_id AND user_pokemon_relation.user_id=?', user_id)
    pokemon_ids.each do |pokemon_id|
       pokemons.append($db.execute('SELECT * FROM pokemons WHERE id=?', pokemon_id["pokemon_id"].to_i)) 
    end
    relation_data = $db.execute('SELECT pokemon_id, id FROM user_pokemon_relation WHERE user_id=?', user_id)
    return pokemons, relation_data
end

def fetch_teams(user)
    $db.execute('SELECT pokemons, team_name, team_id FROM user_team_relation INNER JOIN users ON user_team_relation.user_id = users.user_id AND users.user_id=?', user[:user_id])
end

def pokemon_data(id)
    return $db.execute('SELECT * FROM pokemons WHERE id=?', id)
end

def admin_check(user_id)
    return 1 == $db.execute('SELECT permission FROM users WHERE user_id=?', user_id).first["permission"]
end

def logged_in?()
    return session[:logged_in] == true
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