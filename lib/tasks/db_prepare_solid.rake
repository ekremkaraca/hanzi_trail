namespace :db do
  desc "Create Solid Cache/Queue/Cable tables if missing " \
       "(db:prepare only migrates the primary database; the solid trio " \
       "ship schema-dump files, and db:schema:load:* is blocked in production)"
  task prepare_solid: :environment do
    connection = ActiveRecord::Base.connection

    {
      "solid_cache_entries" => "db/cache_schema.rb",
      "solid_queue_jobs" => "db/queue_schema.rb",
      "solid_cable_messages" => "db/cable_schema.rb"
    }.each do |table, schema_path|
      next if connection.table_exists?(table)

      path = Rails.root.join(schema_path)
      abort "missing #{schema_path} while bootstrapping #{table}" unless path.exist?

      puts "Creating #{table} from #{schema_path}"
      load path
    end
  end
end
