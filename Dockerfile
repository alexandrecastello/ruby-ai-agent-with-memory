FROM ruby:3.2-slim

RUN apt-get update && apt-get install -y \
    build-essential \
    sqlite3 \
    libsqlite3-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY Gemfile Gemfile.lock* ./
RUN bundle install

COPY . .

RUN mkdir -p db

EXPOSE 3000

CMD ["ruby", "bin/agent"]

