require 'sinatra'
require 'sinatra/reloader'
require 'SQLite3'
require 'bcrypt'
require 'slim'
require 'json'
require 'sinatra/flash'
Dir[File.dirname(__FILE__) + '/lib/*.rb'].each {|file| require file }

enable :sessions
guest_routes = ["/", "/login", "/signup", "/pokemon", "/showcase", "/pokemon/type"] 
admin_routes = ["/admin/users", "/admin/teams"]

before do
    @type_colors = TypeColours
    if session[:logged_in] != true && !guest_routes.include?(request.path_info) && !request.path_info.match?(/^\/pokemon\/\d+$/) && !request.path_info.match?(/^\/pokemon\/type\/\w+$/)
        redirect('/')
    end

    if admin_routes.include?(request.path_info) && !admin_check(session[:current_user][:user_id])
        flash[:notice] = "You have no permission to enter that side"
        redirect('/')
    end
end

# Display Landing page
#
get '/' do
    if session[:logged_in] == true
        random_number = rand(1..151)
        @pokemon = fetch_pokemons(random_number)
        session[:pokemon] = @pokemon
    end
    slim(:index)
end

# Catches pokemon by insterting its data into user_pokemon_relation and redirects back to landing route
#
# @see Model#catch_pokemon
post '/catch' do
    catch_pokemon(session[:current_user][:user_id], session[:pokemon]["id"])   
    redirect('/')
end

# Displays current user's inventory
#
# @see Model#fetch_inventory
get '/inventory' do
    @pokemons, @relation_data = fetch_inventory(session[:current_user][:user_id])
    slim(:"inventory/index")
end

# Displays a user's teams
#
# @see Model#fetch_teams
get '/team' do
    @teams = fetch_teams(session[:current_user])
    slim(:"team/index")
end

# Displays an admin page containing every user logged in the databse
#
# @see Model#all_users
# @see Model#admin_check
get '/admin/users' do
    if admin_check(session[:current_user][:user_id])
        @users = all_users()
        slim(:"admin/users/index")
    end
end

# Displays an admin page containing every team logged in the database
#
# @see Model#admin_check
# @see Model#all_teams
get '/admin/teams' do
    if admin_check(session[:current_user][:user_id])
        @teams = all_teams()
        slim(:"admin/teams/index")
    end
end

# Displays am admin edit form to change a user's team
#
# @see Model#admin_check
# @see Model#fetch_user_id_from_team
# @see Model#fetch_inventory
get '/admin/teams/:id/edit' do
    if admin_check(session[:current_user][:user_id])
        @team_id = params[:id]
        user_id = fetch_user_id_from_team(@team_id)
        @your_pokemons, @relation_data = fetch_inventory(user_id)
        slim(:"admin/teams/edit")
    else
       flash[:notice] = "You do not have permission to enter this route"
       redirect('/')
    end
end

# Updates a teams information and redirects to admin/teams route
#
# @param pokemon [Array] A list containing pokemon data
# @param id [Integer] An id to indentify the correct team
# @see Model#admin_check
# @see Model#update_team
post '/admin/teams/:id/update' do
    if params[:pokemons] != nil
        if admin_check(session[:current_user][:user_id])
            selected_pokemons = JSON.generate(params[:pokemons].map { |value| JSON.parse(value) })
            update_team(params["team_name"], selected_pokemons, params[:id])
            redirect('/admin/teams')
        end
    end
    flash[:notice] = "Team name was not a string or you didnt select any pokemons"
    redirect(back)
end

# Deletes data from user_team_relation table and redirects to admin/teams route
#
# @param id [Integer] An id to identify the correct team
# @see Model#admin_check
# @see Model#delete_team
post '/admin/teams/:id/delete' do
    if admin_check(session[:current_user][:user_id])
        delete_team(params[:id])
    else
        flash[:notice] = "You dont have permission to do that"
    end
    redirect('/admin/teams')
end

# Displays an edit form to change a team's information
#
# @param id [Integer] An id to identify the correct team
# @see Model#fetch_inventory
get '/team/:id/edit' do
    @your_pokemons, @relation_data = fetch_inventory(session[:current_user][:user_id])
    @team_id = params[:id]
    slim(:"/team/edit")
end

# Displays all existing teams from the databse
#
# @see Model#all_teams
get '/showcase' do
    @teams = all_teams()
    slim(:showcase)
end

# Updates a team's information and redirects to /team route
#
# @param id [Integer] An id to identity the correct team
# @param pokemons [Array] A list containing pokemon data
# @see Model#correct_user_team?
# @see Model#update_team
post '/team/:id/update' do
    if params[:pokemons] != nil
        if correct_user_team?(session[:current_user][:user_id], params[:id])
            selected_pokemons = JSON.generate(params[:pokemons].map { |value| JSON.parse(value) })
            update_team(params["team_name"], selected_pokemons, params[:id])
            redirect("/team")
        end
        flash[:notice] = "You do not have permission to edit the user's team"
        redirect('/')
    end
    flash[:notice] = "You need to select pokemons"
    redirect(back)
end

# Displays a form to create a new team
#
# @see Model#fetch_inventory
get '/team/new' do
    @your_pokemons, @relation_data = fetch_inventory(session[:current_user][:user_id])
    slim(:"team/new")
end

# Displays all pokemons
#
# @see Model#fetch_pokemons
get '/pokemon' do
    @pokemons = fetch_pokemons(nil)
    slim(:"pokemon/index")
end    

# Displays pokemons that have the same type as the input
#
# @param type [String] The type to check
# @see Model#type_fetch
get '/pokemon/type/:type' do |type|

    if type == "all"
        redirect('/pokemon')
    end

    @pokemons = type_fetch(type)
    @filter = type
    
    slim(:'pokemon/index')
end

# Displays a specific pokemons data
#
# @param id [Integer] The unique id of the pokemon
# @see Model#pokemon_data
get '/pokemon/:id' do
    @pokemon = pokemon_data(params[:id]).first
    slim(:"pokemon/show")
end

# Displays a signup form
#
get '/signup' do
    slim(:signup)
end

# Displays a login form
#
get '/login' do
    slim(:login)
end

# Logs out user by deleting sessions and redirects to Landing route
#
get '/logout' do
    session.delete(:current_user)
    session[:logged_in] = false
    flash[:notice] = "You have been logged out!"
    redirect('/')
end

# Updates a user's information and redirects to admin/users route
#
# @param id [Integer] The id of the user
# @see Model#update_user
# @see Model#admin_check
post '/admin/users/:id/update' do
    if admin_check(session[:current_user][:user_id])
        update_user(params["username"], params[:id])
    end
    redirect(:'/admin/users')
end

# Deletes a user from the database and redirects to admin/users
#
# @param id [Integer] The id of the user
# @see Model#admin_check
# @see Model#delete_user
post '/admin/users/:id/delete' do
    if admin_check(params[:id])
        flash[:notice] = "You cannot delete the Admin user"
    end

    if !admin_check(params[:id]) && admin_check(session[:current_user][:user_id])
        delete_user(params[:id])
        if user_id == session[:current_user][:user_id]
            session[:logged_in] = false
            session[:current_user] = {}
        end
    end

    redirect(:"admin/users")
end

# Creates a new team and redirects back to team route
#
# @param pokemons [Array] List containing pokemon data
# @param team_name [String] The name of the team
# @see Model#create_team
post '/team' do
    if params[:pokemons] == nil || params["team_name"] == ""
        flash[:notice] = "You didnt select pokemons or didnt add a team name"
        redirect(back)
    elsif params[:pokemons] != nil && params["team_name"] != ""
        selected_pokemons = JSON.generate(params[:pokemons].map { |value| JSON.parse(value) })
        create_team(selected_pokemons, session[:current_user][:user_id], params["team_name"])
        redirect(:"/team")
    end
end

# Adds a new user in the databse and redirects to login route
# 
# @param username [String] The username of the user
# @param password [String] The password, obviously
# @param password_repeat [String] Password, again
# @see Model#signup
post '/signup' do
  username = params[:username]
  password = params[:password]
  password_repeat = params[:password_repeat]
  if password.length < 3
    flash[:notice] = "Password is too short"
  else
    if password == password_repeat
        signup(username, password)
        redirect '/login'
    else
        flash[:notice] = "Incorrect password in password repeat or password"
        redirect '/signup'
    end
  end
end

login_attemps = {}
# Attemps to login a user
#
# @param username [String] The username
# @param password [String] The password
# @see Model#fetch_row
# @see Model#user_exists?
# @see Model#crypt_password
post '/login' do
    username = params[:username]
    password = params[:password]
    row = fetch_row(username)
    if user_exists?(username)
        password_digest = row["password"]
        crypted_password = crypt_password(password_digest)
        if crypted_password == password
            flash[:notice] = "Successful login"
            session[:logged_in] = true
            session[:current_user] = {
                username: username, 
                user_id: fetch_user_id(username)
            }
            redirect('/')
        end
    end

    if login_attemps[request.ip] && (Time.now.to_i - login_attemps[request.ip].last) < 2
        flash[:notice] = "Too many login attemps! Please try again later."
        redirect('/login')
    else
        login_attemps[request.ip] ||= []
        login_attemps[request.ip].append(Time.now.to_i) 
    end

    flash[:notice] = "Incorrect password or username!"
    redirect('/login')
end

# Deletes a pokemon from a user's inventory and redirects back to previous page
#
# @param id [Integer] The id of the pokemon
# @see Model#correct_user_inventory?
# @see Model#delete_pokemon_from_inv
post '/pokemon/:id/delete' do
    if correct_user_inventory?(session[:current_user][:user_id], params[:id])
        delete_pokemon_from_inv(params[:id])
        redirect('/inventory')
    end
    flash[:notice] = "You do not have permission to delete this user's pokemon"
    redirect('/')
end

# Filters the "all pokemon" display by type and redirects to pokemon/type/:type route
#
# @param type [String] The type to filter for
post '/pokemon/type' do
    type = params["type"]
    redirect("/pokemon/type/#{type}")
end