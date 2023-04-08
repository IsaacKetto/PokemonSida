require 'sinatra'
require 'sinatra/reloader'
require 'SQLite3'
require 'bcrypt'
require 'slim'
require 'execjs'
require 'sinatra/flash'
require_relative 'lib/module'

enable :sessions
$js_functions = ExecJS.compile(File.read('public/js/main.js'))
$db = SQLite3::Database.new('db/database.db')
$db.results_as_hash = true
guest_routes = ["/", "/login", "/signup", "/pokemon"] 

before do
    @type_colors = TypeColours
    if session[:logged_in] != true && !guest_routes.include?(request.path_info)
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
    @pokemons, @relation_data = fetch_inventory(session[:current_user])
    slim(:"inventory/index")
end

get '/team' do
    @teams = fetch_teams(session[:current_user])
    slim(:"team/index")
end

get '/team/new' do
    @your_pokemons, @relation_data = fetch_inventory(session[:current_user])
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

post '/team' do
    selected_pokemons = $js_functions.call("addQuotesToArray", params[:pokemons])
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