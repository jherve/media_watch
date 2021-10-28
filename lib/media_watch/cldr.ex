defmodule MediaWatch.Cldr do
  use Cldr,
    locales: ["fr"],
    providers: [Cldr.Number, Cldr.Calendar, Cldr.DateTime],
    otp_app: :media_watch
end
