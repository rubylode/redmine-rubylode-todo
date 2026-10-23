require "redmine"

Redmine::Plugin.register :redmine_rubylode_todo do
  name "Rubylode To-do"
  author "Rubylode"
  author_url "https://github.com/rubylode"
  description "A to-do list over a project's tickets: nested lines, checkboxes, drag and drop, keyboard editing"
  version "0.0.1"
  requires_redmine version_or_higher: "7.0.0"

  project_module :rubylode_todo do
    permission :use_rubylode_todo, { todo: %i[index create update close reopen move] }
  end

  menu :project_menu, :rubylode_todo, { controller: "todo", action: "index" },
       caption: :label_todo, after: :issues, param: :project_id
end
