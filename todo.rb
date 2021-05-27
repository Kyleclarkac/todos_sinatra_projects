require 'sinatra'
require 'sinatra/reloader'
require 'tilt/erubis'
require 'sinatra/content_for'

configure do
  enable :sessions
  set :session_secret, 'secret'
end

before do
  session[:lists] ||= []
end

# View all lists
get '/lists' do
  @lists = session[:lists].sort_by!{|list| list[:complete] ? 1:0 }
  p @lists
  erb :lists, layout: :layout
end

get '/' do
  redirect('/lists')
end

# Render New list form
get '/lists/new' do
  erb :new_list, layout: :layout
end

# Retrun error message for invalid list name.
def error_for_list_name(name)
  if !(1..100).cover?(name.size)
    'Name must be between 1 and 100 chars'
  elsif session[:lists].any? { |list| list[:name] == name }
    'List name must be unique'
  end
end

# Create new list
post '/lists' do
  list_name = params[:list_name].strip
  error = error_for_list_name(list_name)
  if error
    session[:error] = error
    erb :new_list, layout: :layout
  else
    session[:lists] << { name: list_name, todos: [], completed: false }
    session[:success] = 'The list was created.'
    redirect '/lists'
  end
end

get '/lists/:index' do 
  @index = params[:index].to_i
  list = session[:lists][@index]
  @todos = session[:lists][@index][:todos].sort_by!{|todo| todo.complete ? 1:0 }
  if @todos.all?{ |todo| todo.complete} && @todos.size > 0
    list[:complete] = true
  else
    list[:complete] = false
  end
  erb :todos
end

get '/lists/:index/edit' do 
  @index = params[:index].to_i
  erb :edit
end

get '/lists/:index/todos' do
  redirect "/lists/#{params[:index]}"
end

post '/lists/:index/edit' do
  @index = params[:index].to_i
  list_name = params[:list_name].strip
  error = error_for_list_name(list_name)
  if error
    session[:error] = error
    erb :edit, layout: :layout
  else
    session[:lists][@index][:name] = list_name
    session[:success] = 'The list name was edited.'
    redirect "/lists/#{@index}"
  end
end

get '/lists/:index/edit/delete' do
  @index = params[:index].to_i
  session[:lists].delete_at @index
  puts "this"
  p session[:lists]
  session[:success] = 'The list was deleted.'
  redirect "/lists"

end

post '/lists/:index/todos' do
  @index = params[:index].to_i
  @todo = params[:todo].strip
  session[:lists][@index][:todos] << Todo.new(@todo)

  @todos = session[:lists][@index][:todos]
  error = error_for_list_name(@todo)
  if error
    session[:error] = error
  end
  redirect "/lists/#{@index}"
end

post '/lists/:list_id/delete_item/:todo_id' do
  list_index = params[:list_id].to_i
  todo_index = params[:todo_id].to_i
  session[:lists][list_index][:todos].delete_at(todo_index)
  redirect "/lists/#{list_index}"
end

post '/lists/:list_id/:todo_id/complete' do
  list_index = params[:list_id].to_i
  todo_index = params[:todo_id].to_i
  session[:lists][list_index][:todos][todo_index].complete = !session[:lists][list_index][:todos][todo_index].complete
  redirect "/lists/#{list_index}"
end

post '/lists/:list_id/complete_all' do
  list_id = params[:list_id].to_i
  session[:lists][list_id][:todos].each {|todo| todo.complete = true}
  redirect "/lists/#{list_id}"
end


class Todo
  attr_accessor :name, :complete
  def initialize(name)
    @name = name
    @complete = false
  end
end

helpers do
  def complete_count(list)
    list[:todos].count {|todo| todo.complete}
  end

  def unfinished_count(list)
    list[:todos].count {|todo| !todo.complete}
  end
end

