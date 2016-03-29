class CasClientGenerator < Rails::Generator::NamedBase
  def manifest
    record do |m|
      m.migration_template 'create_cas_sessions.rb', 'db/migrate', :migration_file_name => 'create_cas_sessions'
    end
  end
end
