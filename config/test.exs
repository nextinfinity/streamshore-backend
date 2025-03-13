import Config

config :streamshore, Streamshore.Repo,
  pool: Ecto.Adapters.SQL.Sandbox

config :streamshore, StreamshoreWeb.Endpoint,
  server: false

# Print only warnings and errors during test
config :logger, level: :warning

# Test junit output configuration
config :junit_formatter,
       report_dir: "/output",
       print_report_file: true,
       prepend_project_name?: true,
       include_filename?: true,
       include_file_line?: true,
       automatic_create_dir?: true
