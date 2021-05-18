require "sinatra"
require "sinatra/reloader"
require "tilt/erubis"

# This sets up Sinatra to use sessions
configure do
  enable(:sessions)
  # We need to set the session secret here. 
  # If we don't specify a value here, Sinatra will randomly create a session secret every time it starts.
  # This means that every time Sinatra starts up again, a new secret will be generated, invalidating any old sessions.
  set(:session_secret, 'secret')
end

before do
  session[:lists] ||= []
end

get "/" do 
  redirect "/lists"
end

get "/lists" do
  @lists = session[:lists]
  erb(:lists)
end

get "/lists/new" do 
  erb(:new_list)
end

post "/lists" do
  session[:lists] << { name: params[:list_name], todos: [] }
  redirect "/lists"
end
