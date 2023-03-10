require 'sinatra'
require 'sinatra/reloader'
require 'SQLite3'
require 'bcrypt'
require 'slim'
require 'sinatra/flash'
require_relative 'lib/module'

enable :sessions
db = SQLite3::Database.new('db/database.db')
db.results_as_hash = true

before do
    @type_colors = TypeColours
end

get '/' do
    if session[:logged_in]
        random_number = rand(1..151)
        @pokemon = db.execute('SELECT * FROM pokemons WHERE id=?', random_number).first
        session[:pokemon] = @pokemon
    end
    slim(:index)
end

post '/catch' do
    catch_pokemon(session[:current_user][:user_id], session[:pokemon]["id"], db)   
    redirect('/')
end

get '/inventory' do
    @pokemons = db.execute('SELECT * FROM pokemons WHERE id IN (SELECT pokemon_id FROM user_pokemon_relation WHERE user_id = ?)', session[:current_user][:user_id])
    slim(:"inventory/index")
end

get '/pokemon' do
    @pokemons = db.execute('SELECT * FROM pokemons')
    slim(:"pokemon/index")
end

get '/pokemon/:id' do
    @pokemon = pokemon_data(db, params[:id]).first
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

post '/signup' do
  username = params[:username]
  password = params[:password]
  password_repeat = params[:password_repeat]
  if password == password_repeat
    password_digest = BCrypt::Password.create(password)
    db.execute("INSERT INTO users (username, password) VALUES (?,?)", username, password_digest)
    redirect '/login'
  else
    flash[:notice] = "Incorrect password in password repeat or password"
    redirect '/signup'
  end
end

post '/login' do
    username = params[:username]
    password = params[:password]
    row = db.execute("SELECT password FROM users WHERE username=?", username).first
    password_digest = row["password"]

    if BCrypt::Password.new(password_digest) == password
        flash[:notice] = "Successful login"
        session[:logged_in] = true
        session[:current_user] = {
            username: username, 
            user_id: db.execute('SELECT user_id FROM users WHERE username=? LIMIT 1', username).first["user_id"]
        }
        redirect '/'
    else 
        flash[:notice] = "Incorrect password or username!"
        redirect('/login')
    end
end

post '/pokemon/type' do
    if params["type"] == "all"
        @pokemons = db.execute('SELECT * FROM pokemons')
    else
        @pokemons = db.execute('SELECT * FROM pokemons WHERE type_1=? OR type_2=?', params["type"].capitalize, params["type"].capitalize)
    end
    @filter = params["type"]
    slim(:"pokemon/index")
end