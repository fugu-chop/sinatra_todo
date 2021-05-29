# Sinatra To-Do App
A repo to contain a web-based personal task manager using Sinatra.

### Basic Overview
This is a Sinatra based To-Do app that allows users to create multiple lists, where each list can contain multiple to-do items, all through the web browser. Both individual to-do items and lists can be created, renamed and deleted, with some validation built in (i.e. preventing duplicate lists, duplicate to-do items on the same list, empty names).

Lists and to-dos are persisted using the `sessions` feature in Sinatra, which enables a cookie to be stored in the browser for usage between sessions. For the actual session key, I've used the `dotenv` gem, which allows me to create a `.env` file locally in the root project directory, and store it there. I've added that file to my `.gitignore` so it can't be seen in the repo.

A layout was used to reduce the number of `.erb` view templates required. Most of the styling was provided as a CSS template file. 

### How to run
The app has been deployed on Heroku: https://todo-list-dw.herokuapp.com/

To get it running locally:
1. Clone the repo locally
2. Make sure you have the `bundle` gem installed.
2. Run `bundle install` in your CLI
3. Run `ruby todo.rb` in your CLI
4. Visit `http://localhost:4567` in your web browser
5. If you need to reset the app (i.e. delete all information), please delete the associated cookie through your browser.

### Design Choices
To-dos (and lists) exist within hashes, stored within an array. This means it's relatively easy to maintain ordering of items based on when they were added, and maintains the ease of fetching entries by hash key. The templates iterate through the array to display entries, so deleting lists or to-do items doesn't require complex logic - there are simply fewer items to iterate through when rendering the template.

Many of the golden path 'verbs' within the app (e.g. creating a list, deleting a to-do) are extracted to methods. This causes some degree of code bloat, with a lot of methods being necessary for each individual action. Failure states _aren't_ extracted to methods, because 'failing' doesn't seem to match the equivalent of succeeding (e.g. `failed_create_list` versus `create_list`).

I've chosen to reduce the amount of conditionals/`if` statements in my code on advice from other programmers. There's obviously a balance, but just as an exercise, I've tried to completely avoid `if/else` statements..

Routing for the 'golden' path is also handled within individual methods, and run within the relevant route block. I've chosen to do this because I have chosen to forgo `if` statements - within the requests within Sinatra, I need to `return` the golden path, as my fail code is directly below the golden path (i.e. displaying errors, other routing).

### Challenges
Avoiding `if` statements made me think about how to sequentially structure my code - `if` does provide a lot of convenience, but it was an interesting exercise. It meant I had to make sure to `return` certain methods, and that those methods did absolutely everything needed before being returned. In retrospect they probably do a little too much (usually they perform some action __as well as__ handle redirects).

Working with both instance and local variables was a bit of a challenge. Because blocks create their own scope (i.e. for each request method in Sinatra), and routes are mutually exclusive, there's little risk of overwriting/conflicting instance variables. The lazy programmer in me just wants to use instance variables everywhere, as they allow access to the relevant `.erb` template.

As a proof of concept, jQuery has been integrated into this app to use AJAX for deleting todos and lists. This presented some challenges with the initial design of the app, where lists/todos were referenced by index. As XHR requests don't cause a re-render of the template, deleting a list or todo would not trigger the indices to update (the indices were based on order on __render__ of the page), meaning their old indices remained. 

This meant that if a user interacted with a list or todo, the app would perform the action on a different list/todo compared to what they were pointing at (the routes had not updated and were different compared to the order in which the elements appear on the page). This was solved by creating persistent ids for objects, independent of their position in the array.
