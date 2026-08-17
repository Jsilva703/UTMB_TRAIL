FROM ruby:3.2.3-slim AS base

WORKDIR /app

RUN apt-get update -qq && \
    apt-get install -y --no-install-recommends build-essential libpq-dev postgresql-client && \
    rm -rf /var/lib/apt/lists/*

COPY Gemfile Gemfile.lock ./

FROM base AS development
RUN bundle install

COPY . .

EXPOSE 3000

CMD ["sh", "-c", "bundle exec rails db:prepare && bundle exec rails server -b 0.0.0.0 -p ${PORT:-3000}"]

FROM base AS production

ENV RAILS_ENV=production \
    RACK_ENV=production \
    BUNDLE_DEPLOYMENT=true \
    BUNDLE_WITHOUT=development:test

RUN bundle install && \
    rm -rf /usr/local/bundle/cache/*.gem

COPY . .

EXPOSE 3000

CMD ["sh", "-c", "bundle exec rails server -b 0.0.0.0 -p ${PORT:-3000}"]
