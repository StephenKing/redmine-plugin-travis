module ProjectsHelperPatch
  def self.included(base) # :nodoc:
    base.send(:include, InstanceMethods)
    base.class_eval do
      unloadable # Send unloadable so it will not be unloaded in development

      alias_method_chain :project_settings_tabs, :typo3
    end
  end

  module InstanceMethods
    def project_settings_tabs_with_typo3
      tabs = [{:name => 'info', :action => :edit_project, :partial => 'projects/edit', :label => :label_information_plural},
        {:name => 'modules', :action => :select_project_modules, :partial => 'projects/settings/modules', :label => :label_module_plural},
        {:name => 'members', :action => :manage_members, :partial => 'projects/settings/members', :label => :label_member_plural},
        {:name => 'versions', :action => :manage_versions, :partial => 'projects/settings/versions', :label => :label_version_plural},
        {:name => 'categories', :action => :manage_categories, :partial => 'projects/settings/issue_categories', :label => :label_issue_category_plural},
        {:name => 'wiki', :action => :manage_wiki, :partial => 'projects/settings/wiki', :label => :label_wiki},
        {:name => 'repository', :action => :manage_repository, :partial => 'projects/settings/repositories', :label => :label_repository},
        {:name => 'boards', :action => :manage_boards, :partial => 'projects/settings/boards', :label => :label_board_plural},
        {:name => 'newsgroup', :action => :newsgroup_show, :partial => 'newsgroup/settings', :label => 'Newsgroups'},
        {:name => 'hudson', :action => :hudson_show, :partial => 'hudson/settings', :label => 'Continuous Integration'}
      ]
      tabs.select {|tab| User.current.allowed_to?(tab[:action], @project)}
    end
  end
end
