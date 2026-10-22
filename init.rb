require "redmine"

Redmine::Plugin.register :redmine_todo do
  name "redmine-todo"
  author "Nick Gorbikoff"
  description "A to-do list over Redmine tickets"
  version "0.0.1"
  requires_redmine version_or_higher: "7.0.0"

  project_module :todo do
    permission :use_todo, { todo: %i[index create update] }
  end

  menu :project_menu, :todo, { controller: "todo", action: "index" },
       caption: :label_todo, after: :issues, param: :project_id
end
