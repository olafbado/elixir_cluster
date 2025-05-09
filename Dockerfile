ARG ELIXIR_VERSION=1.18.3
ARG OTP_VERSION=27

# BUILD

FROM elixir:${ELIXIR_VERSION}-otp-${OTP_VERSION}-slim AS builder

ENV MIX_ENV=prod

WORKDIR /app

COPY mix.exs ./
COPY mix.lock ./
COPY config ./config
COPY lib ./lib

RUN apt-get update -y
RUN apt-get install ca-certificates -y

RUN mix deps.get
RUN mix compile

RUN mix release

# RUNTIME

FROM elixir:${ELIXIR_VERSION}-otp-${OTP_VERSION}-slim

WORKDIR /app

ENV MIX_ENV=prod

RUN apt-get update -y
RUN apt-get install ca-certificates -y

COPY --from=builder /app/_build/${MIX_ENV}/rel/cluster_demo ./

CMD ["/app/bin/cluster_demo" , "start"]
