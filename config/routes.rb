get "projects/:project_id/todo", to: "todo#index", as: :project_todo
post "projects/:project_id/todo/lines", to: "todo#create", as: :project_todo_lines
patch "projects/:project_id/todo/lines/:id", to: "todo#update", as: :project_todo_line
post "projects/:project_id/todo/lines/:id/close", to: "todo#close", as: :project_todo_line_close
delete "projects/:project_id/todo/lines/:id/close", to: "todo#reopen"
patch "projects/:project_id/todo/lines/:id/move", to: "todo#move", as: :project_todo_line_move
