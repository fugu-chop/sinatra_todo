# frozen_string_literal: true

require 'sinatra'
require 'sinatra/reloader'
require 'sinatra/content_for'
require 'tilt/erubis'

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
  def valid_list_input?
    (1..100).cover?(@list_name.size)
  end

  def create_list
    session[:lists] << { name: @list_name, todos: [] }
    session[:success] = "The '#{@list_name}' list has been created."
    redirect '/lists'
  end

  def update_list(id)
    @list[:name] = @list_name
    session[:success] = "The '#{@list[:name]}' list has been updated."
    redirect "/lists/#{id}"
  end

  # I think this can be refactored to be universal. I need to make available the relevant variables
  def set_list_error_message
    session[:error] = 'The list name must be between 1 and 100 characters.' unless valid_list_input?
    session[:error] = 'The list name must be unique.' if duplicate_list_name?
  end

  def duplicate_list_name?
    session[:lists].any? { |list| list[:name] == @list_name }
  end

  # We want to handle the edge case where we want to enable users to rename their list the same existing name
  def duplicate_list_name_except_current?(list_name)
    remove_orig = session[:lists].reject { |list| list[:name] == list_name }
    remove_orig.any? { |list| list[:name] == @list_name }
  end

  def delete_list(idx)
    session[:lists].delete_at(idx)
    session[:success] = "The '#{@list_name}' list has been deleted."
    redirect "/lists"
  end

  def create_todo(list_id)
    @list[:todos] << { name: "#{params[:todo]}", completed: false }
    session[:success] = "The '#{params[:todo]}' item was added to the list."
    redirect "/lists/#{list_id}"
  end

  def duplicate_todo_input?
    @list[:todos].any? { |list| list[:name] == params[:todo] }
  end

  def valid_todo_input?
    todo_name = params[:todo].strip
    (1..100).cover?(todo_name.size)
  end

  # Have created this since a lot of the instance variables required for set_list_error_message errors aren't available
  # There are also dependencies in the template files to have access to instance variables for rendering
  def set_todo_error_message
    session[:error] = 'The todo name must be unique.' if duplicate_todo_input?
    session[:error] = 'The todo name must be between 1 and 100 characters.' unless valid_todo_input?
  end
end

get '/' do
  redirect '/lists'
end

get '/lists' do
  @lists = session[:lists]
  erb(:lists)
end

get '/lists/new' do
  erb(:new_list)
end

# Create a new list
post '/lists' do
  # params[:list_name] comes from the name of the input field in our erb file
  # With a POST request, the name:value are captured as invisible query params within the response body
  @list_name = params[:list_name].strip
  return create_list if valid_list_input? && !duplicate_list_name?

  set_list_error_message
  erb(:new_list)
end

get '/lists/:id' do
  # Params are passed as strings from Sinatra
  idx = params[:id].to_i
  @list = session[:lists][idx]
  erb(:list)
end

get '/lists/:id/edit' do
  idx = params[:id].to_i
  @list = session[:lists][idx]
  erb(:edit_list)
end

post '/lists/:id' do
  idx = params[:id].to_i
  @list = session[:lists][idx]
  original_name = @list[:name]
  @list_name = params[:list_name].strip
  return update_list(idx) if valid_list_input? && !duplicate_list_name_except_current?(original_name)

  set_list_error_message
  erb(:edit_list)
end

post '/lists/:id/delete' do
  idx = params[:id].to_i
  @list_name = session[:lists][idx][:name]
  delete_list(idx)
end

post '/lists/:list_id/todos' do
  list_id = params[:list_id].to_i
  @list = session[:lists][list_id]
  # Needs more validation around blank todo
  return create_todo(list_id) if !duplicate_todo_input? && valid_todo_input?

  set_todo_error_message
  redirect "/lists/#{list_id}"
end
