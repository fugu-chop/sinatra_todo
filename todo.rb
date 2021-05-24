# frozen_string_literal: true

require 'sinatra'
require 'sinatra/reloader' if development?
require 'sinatra/content_for'
require 'tilt/erubis'

# This sets up Sinatra to use sessions
configure do
  # Sanitise HTML input
  set(:erb, :escape_html => true)
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
  def sort_lists(lists)
    complete_lists, incomplete_lists = lists.partition { |list| all_complete?(list) }

    incomplete_lists.sort_by { |list| list[:name] }.each { |list| yield(list, lists.index(list)) }
    complete_lists.sort_by { |list| list[:name] }.each { |list| yield(list, lists.index(list)) }
  end

  def sort_todos(todos)
    complete_todos, incomplete_todos = todos.partition { |todo| todo[:completed] }

    incomplete_todos.sort_by { |todo| todo[:name] }.each { |todo| yield(todo, todos.index(todo)) }
    complete_todos.sort_by { |todo| todo[:name] }.each { |todo| yield(todo, todos.index(todo)) }
  end

  def all_complete?(list)
    list[:todos].all? { |todo| todo[:completed] } && !list[:todos].empty?
  end
end

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
  redirect '/lists'
end

def create_todo(list_id)
  @list[:todos] << { name: params[:todo].to_s, completed: false }
  session[:success] = "'#{params[:todo]}' was added to the '#{@list[:name]}' list."
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

def delete_todo(todo_id)
  deleted_item = @list[:todos].delete_at(todo_id)
  session[:success] = "'#{deleted_item[:name]}' has been deleted from the '#{@list[:name]}' list."
  redirect "/lists/#{@idx}"
end

def flip_completion(todo)
  todo[:completed] = todo[:completed] != true
end

def display_todo_status(status)
  status ? 'completed' : 'unchecked'
end

def check_todo(todo_id)
  changed_item = @list[:todos][todo_id]
  flip_completion(changed_item)
  status = display_todo_status(changed_item[:completed])
  session[:success] =
    "'#{changed_item[:name]}' has been #{status}."
  redirect "/lists/#{@idx}"
end

def complete_all_todos
  @list[:todos].each do |todo|
    todo[:completed] = true
  end
  session[:success] = "All items on the '#{@list[:name]}' list have been marked as completed."
  # We can't use an instance variable here, as it's not populated on initial get request
  session[:status] = 'Uncheck'
  redirect "/lists/#{@idx}"
end

def uncheck_all_todos
  @list[:todos].each do |todo|
    todo[:completed] = false
  end
  session[:status] = 'Complete'
  session[:success] = "All items on the '#{@list[:name]}' list have been unchecked."
  redirect "/lists/#{@idx}"
end

def todos_completed(list)
  list[:todos].select { |todo| todo[:completed] }.size
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
  @idx = params[:id].to_i
  @list = session[:lists][@idx]
  session[:status] = all_complete?(@list) ? 'Uncheck' : 'Complete'
  erb(:list)
end

get '/lists/:id/edit' do
  @idx = params[:id].to_i
  @list = session[:lists][@idx]
  erb(:edit_list)
end

post '/lists/:id' do
  @idx = params[:id].to_i
  @list = session[:lists][@idx]
  original_name = @list[:name]
  @list_name = params[:list_name].strip
  return update_list(@idx) if valid_list_input? && !duplicate_list_name_except_current?(original_name)

  set_list_error_message
  erb(:edit_list)
end

post '/lists/:id/delete' do
  @idx = params[:id].to_i
  @list_name = session[:lists][@idx][:name]
  delete_list(@idx)
end

post '/lists/:list_id/todos' do
  @idx = params[:list_id].to_i
  @list = session[:lists][@idx]
  return create_todo(@idx) if !duplicate_todo_input? && valid_todo_input?

  set_todo_error_message
  erb(:list)
end

post '/lists/:list_id/todos/:id/delete' do
  @idx = params[:list_id].to_i
  @list = session[:lists][@idx]
  todo_id = params[:id].to_i
  delete_todo(todo_id)
end

post '/lists/:list_id/todos/:id' do
  @idx = params[:list_id].to_i
  @list = session[:lists][@idx]
  todo_id = params[:id].to_i
  check_todo(todo_id)
end

post '/lists/:list_id/complete_all' do
  @idx = params[:list_id].to_i
  @list = session[:lists][@idx]
  all_complete?(@list) ? uncheck_all_todos : complete_all_todos
end
