FROM ruby:2.3

ENV LANG en_US.UTF-8

# throw errors if Gemfile has been modified since Gemfile.lock
RUN bundle config --global frozen 1

COPY . /usr/src/horobot2
WORKDIR /usr/src/horobot2

RUN bundle install
RUN mkdir var

CMD ["rake", "docker:run_inside"]
