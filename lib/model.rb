$db = SQLite3::Database.new('db/database.db')
$db.results_as_hash = true
# Fetch pokemons from database
#
# @param id [Integer] The id of a pokemon
# @return [Array/Hashmap] A list of hashmaps containing pokemon data
def fetch_pokemons(id)
    if id == nil
        return $db.execute('SELECT * FROM pokemons')
    else
        return $db.execute('SELECT * FROM pokemons WHERE id=?', id).first
    end
end
# Inserts relation ids in user_pokemon_relation table in $db database
#
# @param user_id [Integer] Id of the user
# @param pokemon_id [Integer] Id of the corresponding pokemon
# @return [Void] Inserts data into the table - No return
def catch_pokemon(user_id, pokemon_id)
    $db.execute('INSERT INTO user_pokemon_relation (user_id, pokemon_id) VALUES (?, ?)', user_id, pokemon_id)
end
# Deletes user corresponding to the param user_id's value thorugh a CASCADE ON DELETE format
#
# @param user_id [Integer] Id of the user
# @return [Void] Deletes user information from the databse - No return
def delete_user(user_id)
    $db.execute('DELETE FROM users WHERE user_id=?', user_id)
    $db.execute('DELETE FROM user_pokemon_relation WHERE user_id=?', user_id)
    $db.execute('DELETE FROM user_team_relation WHERE user_id=?', user_id)
end
# Checks if current user is the same as the user corresponding to the team
#
# @param user_id [Integer] Id of the user
# @param unique_id [Integer] Id of the team, unique
# @return [Boolean] Returns true or false
def correct_user_team?(user_id, unique_id)
    return $db.execute('SELECT user_id FROM user_team_relation WHERE team_id=?', unique_id).first["user_id"] == user_id
end
# Checks if current user is the same as the user corresponding to the inventory
#
# @param user_id [Integer] Id of the user
# @param unique_id [Integer] Id to fetch the user_id for the inventory, unique
# @return [Boolean] Returns true or false
def correct_user_inventory?(user_id, unique_id)
    return $db.execute('SELECT user_id FROM user_pokemon_relation WHERE id=?', unique_id).first["user_id"] == user_id
end
# Updates a users name
#
# @param new_name [String] The new name
# @param id [Integer] The user id
# @return [Void] Updates information on the user - No return
def update_user(new_name, id)
    $db.execute("UPDATE users SET username=? WHERE user_id=?", new_name, id)
end
# Encrypts a password for security
#
# @param password_digest [String] The password to encrypt
# @return [Blob] The encrypted password
def crypt_password(password_digest)
    return BCrypt::Password.new(password_digest)
end
# Checks if user exists
#
# @param username [String] The users profile name
# @return [Boolean] Returns true or false
def user_exists?(username)
    return !$db.execute('SELECT * FROM users WHERE username=?', username).empty?
end
# Fetches pokemons that have the same type as the param type
#
# @param type [String] The pokemon type
# @return [Array] List containing pokemons with the same type as @param type
def type_fetch(type)
    return $db.execute('SELECT * FROM pokemons WHERE type_1=? OR type_2=?', type.capitalize, type.capitalize)
end
# Fetches encrypted password from the user
#
# @param username [String] The profile name of the user
# @return [HashWithTypesAndFields] The encrypted password of the user
def fetch_row(username)
    return $db.execute("SELECT password FROM users WHERE username=?", username).first
end
# Fetches user_id
#
# @param username [String] The username of the user
# @return [Integer] The user_id
def fetch_user_id(username)
    return $db.execute('SELECT user_id FROM users WHERE username=? LIMIT 1', username).first["user_id"]
end
# Inserts data into the user_team_relation table
#
# @param pokemons [String] A list of pokemon data
# @param user_id [Integer] Id of the user
# @param team_name [String] The team name
# @return [Void] Creates team - No return
def create_team(pokemons, user_id, team_name)
    $db.execute('INSERT INTO user_team_relation (user_id, pokemons, team_name) VALUES (?,?,?)', user_id, pokemons, team_name)
end
# Creates a new user by inserting data into users table
#
# @param username [String] The username of the new user
# @param password [String] The uncrypted password
# @return [Void] Inserts data into the users table - No return
def signup(username, password)
    password_digest = BCrypt::Password.create(password)
    $db.execute("INSERT INTO users (username, password) VALUES (?,?)", username, password_digest)
end
# Updates user_team_relation data 
#
# @param new_name [String] The new name
# @param pokemon_list [String] A list of pokemons - maximum is six
# @param team_id [Integer] The id of the team
# @return [Void] Updates the table - No return
def update_team(new_name, pokemon_list, team_id) 
    if new_name == ""
        $db.execute('UPDATE user_team_relation SET pokemons=? WHERE team_id=?', pokemon_list, team_id)
    else
        $db.execute('UPDATE user_team_relation SET pokemons=?, team_name=? WHERE team_id=?', pokemon_list, new_name, team_id)
    end
end
# Deletes table instances from user_team_relation
# 
# @param team_id [Integer] An Id to determine which team to delete
# @return [Void] Deletes data - No return
def delete_team(team_id)
    $db.execute('DELETE FROM user_team_relation WHERE team_id=?', team_id)
end
# Fetches data from the user_pokemon_relation table
# 
# @param user_id [Integer] An id to fetch correct data
# @return [Array, Array] Returns two lists, one containing pokemon data and the other containing useful data
def fetch_inventory(user_id)
    pokemons = []
    pokemon_ids = $db.execute('SELECT pokemon_id, id FROM user_pokemon_relation INNER JOIN users ON user_pokemon_relation.user_id = users.user_id AND user_pokemon_relation.user_id=?', user_id)
    pokemon_ids.each do |pokemon_id|
       pokemons.append($db.execute('SELECT * FROM pokemons WHERE id=?', pokemon_id["pokemon_id"].to_i)) 
    end
    relation_data = $db.execute('SELECT pokemon_id, id FROM user_pokemon_relation WHERE user_id=?', user_id)
    return pokemons, relation_data
end
# Fetches all data from the user_team_relation table
#
# @return [Array] A list containing the relation data
def all_teams()
    return $db.execute('SELECT * FROM user_team_relation')
end
# Fetches user_id from user_team_relation table
# 
# @param id [Integer] An id to fetch correct data
# @return [Integer] Returns the user_id
def fetch_user_id_from_team(id)
    return $db.execute('SELECT user_id FROM user_team_relation WHERE team_id=?', id).first["user_id"]
end
# Deletes instance of data from the user_pokemon_relation table
#
# @param id [Integer] An id to determine which instance to delete
# @return [Void] Removes data from the table - No return
def delete_pokemon_from_inv(id)
    $db.execute('DELETE FROM user_pokemon_relation WHERE id=?', params[:id])
end
# Fetches all data from the users table
# 
# @return [Array] A list containing user data
def all_users()
    return $db.execute('SELECT * FROM users')
end
# fetches a user's teams
#
# @param user [Hashmap] A user's data
# @return [Array] A list containing pokemons, team_name, and team_id data
def fetch_teams(user)
    $db.execute('SELECT pokemons, team_name, team_id FROM user_team_relation INNER JOIN users ON user_team_relation.user_id = users.user_id AND users.user_id=?', user[:user_id])
end
# Fetches a pokemon's data
#
# @param id [Integer] An id to determine which pokemon to fetch data from
# @return [Array] A list containing a pokemon's data
def pokemon_data(id)
    return $db.execute('SELECT * FROM pokemons WHERE id=?', id)
end
# Checks if the user is an administrator
#
# @param user_id [Integer] The current user's id
# @return [Boolean] Returns true or false - result from the comparison operator "=="
def admin_check(user_id)
    return 1 == $db.execute('SELECT permission FROM users WHERE user_id=?', user_id).first["permission"]
end