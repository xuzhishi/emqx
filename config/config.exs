import Config

config :logger,
  format: "$message\n",
  level: :debug,
  handle_otp_reports: true,
  handle_sasl_reports: true
