# syntax=docker/dockerfile:1

FROM ruby:3.3-slim

WORKDIR /site

# System deps needed to compile native gems (e.g. nokogiri/eventmachine/iconv)
RUN apt-get update -y \
  && apt-get install -y --no-install-recommends \
    build-essential \
    git \
    pkg-config \
    libffi-dev \
    libxml2-dev \
    libxslt1-dev \
    zlib1g-dev \
  && rm -rf /var/lib/apt/lists/*

# Install the Bundler version pinned in Gemfile.lock
COPY Gemfile Gemfile.lock ./
RUN gem install bundler -v 2.7.1 \
  && bundle install

# Entrypoint lives outside the bind-mounted /site
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# Copy the rest of the site
COPY . .

EXPOSE 4000 35729

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]

# Jekyll dev server (access the site at http://localhost:4000/blog/)
CMD ["bundle", "exec", "jekyll", "serve", "--host", "0.0.0.0", "--port", "4000", "--baseurl", "/blog", "--livereload", "--livereload-port", "35729"]
