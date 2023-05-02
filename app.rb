require 'sinatra'
require 'sinatra/reloader'
require 'SQLite3'
require 'bcrypt'
require 'slim'
require 'json'
require 'sinatra/flash'
require 'yardoc'
require 'yard-sinatra'
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

# Displays 
get '/' do
    if session[:logged_in] == true
        random_number = rand(1..151)
        @pokemon = fetch_pokemons(random_number)
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
        @users = all_users()
        slim(:"admin/users/index")
    end
end

get '/admin/teams' do
    if admin_check(session[:current_user][:user_id])
        @teams = all_teams()
        slim(:"admin/teams/index")
    end
end

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
    @teams = all_teams()
    slim(:showcase)
end

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

get '/team/new' do
    @your_pokemons, @relation_data = fetch_inventory(session[:current_user][:user_id])
    slim(:"team/new")
end

get '/pokemon' do
    @pokemons = fetch_pokemons(nil)
    slim(:"pokemon/index")
end    

get '/pokemon/type/:type' do |type|

    if type == "all"
        redirect('/pokemon')
    end

    @pokemons = type_fetch(type)
    @filter = type
    
    slim(:'pokemon/index')
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

post '/team' do
    if params[:pokemons] == nil || params["team_name"] == ""
        flash[:notice] = "You didnt select pokemons or didnt add a team name"
        redirect(back)
    elsif params[:pokemons] != nil || params["team_name"] != ""
        selected_pokemons = JSON.generate(params[:pokemons].map { |value| JSON.parse(value) })
        create_team(selected_pokemons, session[:current_user][:user_id], params["team_name"])
        redirect(:"/team")
    end
end

post '/signup' do
  username = params[:username]
  password = params[:password]
  password_repeat = params[:password_repeat]
  if password.length < 5
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

# fix secured delete
post '/pokemon/:id/delete' do
    if correct_user_inventory?(session[:current_user][:user_id], params[:id])
        delete_pokemon_from_inv(params[:id])
        redirect('/inventory')
    end
    flash[:notice] = "You do not have permission to delete this user's pokemon"
    redirect('/')
end

post '/pokemon/type' do
    type = params["type"]
    redirect("/pokemon/type/#{type}")
end