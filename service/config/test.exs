import Config

config :service, Service.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4001]
