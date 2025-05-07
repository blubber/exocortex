FROM elixir:1.18

WORKDIR /usr/src/app

RUN \
	set -ex \
	&& apt-get -y update \
	&& apt-get -y upgrade \
	&& apt-get -y install --no-install-recommends \
		nodejs \
		node-npm \
		postgresql-client \
	&& rm -rf /var/lib/apt/lists/* \
	&& :

ENV MIX_ENV=prod

COPY mix.exs .
COPY mix.lock .
COPY package.json .
COPY package-lock.json .
COPY assets/ ./assets
COPY config ./config
COPY priv/ ./priv
COPY lib/ ./lib

RUN \
	set -ex \
	&& npm install --production \
	&& mix deps.get --only prod \
	&& mix compile \
	&& mix assets.deploy \
	&& :

CMD ["mix", "phx.server"]
