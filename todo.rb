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

helpers do
  def valid_input?
    (1..100).cover?(@list_name.size)
  end

  def create_list
    session[:lists] << { name: @list_name, todos: [] }
    session[:success] = "The list has been created."
    redirect "/lists"
  end

  def set_error_message
    session[:error] = "The list name must be between 1 and 100 characters." if !valid_input?
    session[:error] = "The list name must be unique." if duplicate_list_name?
  end

  def duplicate_list_name?
    session[:lists].any? { |list| list[:name] == @list_name }
  end
end

get "/" do 
  redirect "/lists"
end

# View all lists
get "/lists" do
  @lists = session[:lists]
  erb(:lists)
end

# Render the new list form
get "/lists/new" do 
  erb(:new_list)
end

# Create a new list
post "/lists" do
  # params[:list_name] comes from the name of the input field in our erb file
  # With a POST request, the name:value are captured as invisible query params within the response body
  @list_name = params[:list_name].strip
  return create_list if valid_input? && !duplicate_list_name?
  set_error_message
  erb(:new_list)
end
