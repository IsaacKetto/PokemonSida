require 'sinatra'
require 'sinatra/reloader'
require 'SQLite3'
require 'bcrypt'
require 'slim'
require 'json'
require 'sinatra/flash'
require_relative 'lib/model'

enable :sessions
$db = SQLite3::Database.new('db/database.db')
$db.results_as_hash = true
guest_routes = ["/", "/login", "/signup", "/pokemon", "/showcase", "/pokemon/type"] 
admin_routes = ["/admin/users", "/admin/teams"]

before do
    @type_colors = TypeColours
    if session[:logged_in] != true && !guest_routes.include?(request.path_info) && !request.path_info.match?(/^\/pokemon\/\d+$/)
        redirect('/')
    end

    if admin_routes.include?(request.path_info) && !admin_check(session[:current_user][:user_id])
        flash[:notice] = "You have no permission to enter that side"
        redirect('/')
    end
end

get '/' do
    if logged_in?()
        random_number = rand(1..151)
        @pokemon = $db.execute('SELECT * FROM pokemons WHERE id=?', random_number).first
        session[:pokemon] = @pokemon
    end
    slim(:index)
end

post '/catch' do
    catch_pokemon(session[:current_user][:user_id], session[:pokemon]["id"])   
    redirect('/')
end

get '/inventory' do
    @pokemons, @relation_data = fetch_inventory(session[:current_user][:user_id])
    slim(:"inventory/index")
end

get '/team' do
    @teams = fetch_teams(session[:current_user])
    slim(:"team/index")
end

get '/admin/users' do
    if admin_check(session[:current_user][:user_id])
        @users = $db.execute('SELECT * FROM users')
        slim(:"admin/users/index")
    end
end

get '/admin/teams' do
    if admin_check(session[:current_user][:user_id])
        @teams = $db.execute('SELECT * FROM user_team_relation')
        slim(:"admin/teams/index")
    end
end

get '/admin/teams/:id/edit' do
    if admin_check(session[:current_user][:user_id])
        user_id = $db.execute('SELECT user_id FROM user_team_relation WHERE team_id=?', params[:id]).first["user_id"]
        @your_pokemons, @relation_data = fetch_inventory(user_id)
        @team_id = params[:id]
        slim(:"admin/teams/edit")
    end   
end

post '/admin/teams/:id/update' do
    if admin_check(session[:current_user][:user_id])
        selected_pokemons = JSON.generate(params[:pokemons].map { |value| JSON.parse(value) })
        update_team(params["team_name"], selected_pokemons, params[:id])
    end
    redirect('/admin/teams')
end

post '/admin/teams/:id/delete' do
    if admin_check(session[:current_user][:user_id])
        delete_team(params[:id])
    else
        flash[:notice] = "You dont have permission to do that"
    end
    redirect('/admin/teams')
end

get '/team/:id/edit' do
    @your_pokemons, @relation_data = fetch_inventory(session[:current_user][:user_id])
    @team_id = params[:id]
    slim(:"/team/edit")
end

get '/showcase' do
    @teams = $db.execute('SELECT * FROM user_team_relation')
    p session[:current_user]
    slim(:showcase)
end

post '/team/:id/update' do
    selected_pokemons = JSON.generate(params[:pokemons].map { |value| JSON.parse(value) })
    update_team(params["team_name"], selected_pokemons, params[:id])
    redirect("/team")
end

get '/team/new' do
    @your_pokemons, @relation_data = fetch_inventory(session[:current_user][:user_id])
    slim(:"team/new")
end

get '/pokemon' do
    @pokemons = fetch_pokemons()
    slim(:"pokemon/index")
end

get '/pokemon/:id' do
    @pokemon = pokemon_data(params[:id]).first
    slim(:"pokemon/show")
end

get '/signup' do
    slim(:signup)
end

get '/login' do
    slim(:login)
end

get '/logout' do
    session.delete(:current_user)
    session[:logged_in] = false
    flash[:notice] = "You have been logged out!"
    redirect('/')
end

post '/admin/users/:id/update' do
    if admin_check(session[:current_user][:user_id])
        update_user(params["username"], params[:id])
    end
    redirect(:'/admin/users')
end

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

post '/delete_user' do
    if admin_check(session[:current_user][:user_id])
        flash[:notice] = "You cannot delete the Admin user"
    else
        delete_user(session[:current_user][:user_id])
        if user_id == session[:current_user][:user_id]
            session[:logged_in] = false
            session[:current_user] = {}
        end
    end
end

post '/team' do
    selected_pokemons = JSON.generate(params[:pokemons].map { |value| JSON.parse(value) })
    create_team(selected_pokemons, params["team_name"])
    redirect(:"/team")
end

post '/signup' do
  username = params[:username]
  password = params[:password]
  password_repeat = params[:password_repeat]
  if password == password_repeat
    signup(username, password)
    redirect '/login'
  else
    flash[:notice] = "Incorrect password in password repeat or password"
    redirect '/signup'
  end
end

post '/login' do
    username = params[:username]
    password = params[:password]
    row = fetch_row(username)
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
    else 
        flash[:notice] = "Incorrect password or username!"
        redirect('/login')
    end
end

# fix secured delete
post '/pokemon/:id/delete' do
    $db.execute('DELETE FROM user_pokemon_relation WHERE id=?', params[:id])
    redirect('/inventory')
end

post '/pokemon/type' do
    type = params["type"]
    type_fetch(type)
    @filter = params["type"]
    slim(:"pokemon/index")
end