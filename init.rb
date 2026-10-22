require "redmine"

Redmine::Plugin.register :redmine_todo do
  name "redmine-todo"
  author "Nick Gorbikoff"
  description "A to-do list over Redmine tickets"
  version "0.0.1"
  requires_redmine version_or_higher: "7.0.0"
end
