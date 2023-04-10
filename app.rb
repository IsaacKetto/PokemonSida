require 'sinatra'
require 'sinatra/reloader'
require 'SQLite3'
require 'bcrypt'
require 'slim'
require 'execjs'
require 'sinatra/flash'
require_relative 'lib/model'

enable :sessions
$js_functions = ExecJS.compile(File.read('public/js/main.js'))
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
        fixed_array = $js_functions.call("fixArray", params[:pokemons])
        selected_pokemons = $js_functions.call("addQuotesToArray", fixed_array)
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
    fixed_array = $js_functions.call("fixArray", params[:pokemons])
    selected_pokemons = $js_functions.call("addQuotesToArray", fixed_array)
    update_team(params["team_name"], selected_pokemons, params[:id])
    redirect("/team")
end

get '/team/new' do
    @your_pokemons, @relation_data = fetch_inventory(session[:current_user][:user_id])
    slim(:"team/new")
end

get '/pokemon' do
    @pokemons = $db.execute('SELECT * FROM pokemons')
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
    logout()
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
    end

    redirect(:"admin/users")
end

post '/delete_user' do
    if admin_check(session[:current_user][:user_id])
        flash[:notice] = "You cannot delete the Admin user"
    else
        delete_user(session[:current_user][:user_id])
    end
end

post '/team' do
    fixed_array = $js_functions.call("fixArray", params[:pokemons])
    selected_pokemons = $js_functions.call("addQuotesToArray", fixed_array)
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
    row = $db.execute("SELECT password FROM users WHERE username=?", username).first
    password_digest = row["password"]
    if BCrypt::Password.new(password_digest) == password
        login(username)
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
    if params["type"] == "all"
        @pokemons = $db.execute('SELECT * FROM pokemons')
    else
        @pokemons = $db.execute('SELECT * FROM pokemons WHERE type_1=? OR type_2=?', params["type"].capitalize, params["type"].capitalize)
    end
    @filter = params["type"]
    slim(:"pokemon/index")
end