FROM ruby:3.1.2 AS builder

# Set the working directory in the builder stage
WORKDIR /app

# Copy Gemfile and Gemfile.lock to the builder stage
COPY Gemfile Gemfile.lock ./

# Install Ruby dependencies
RUN bundle install

# Copy the entire application to the builder stage
COPY . .

# Install Node.js and npm
RUN apt-get update && apt-get install -y dos2unix &&\
    apt-get install -y nodejs npm && \
    rm -rf /var/lib/apt/lists/*

# Install Node.js dependencies and run other Node.js-related commands
RUN npm install
RUN npm install --save-dev stylelint@13.x stylelint-scss@3.x stylelint-config-standard@21.x stylelint-csstree-validator@1.x
# RUN rubocop .
RUN npx stylelint "**/*.{css,scss}" --fix

# RUN gem install rubocop
# RUN dos2unix *.rb
# RUN rubocop .

# Now the builder stage is ready with both Ruby and Node.js dependencies

# Create the final stage
FROM ruby:3.1.2

# Set the working directory in the final stage
WORKDIR /app

# Copy the entire application from the builder stage
COPY --from=builder /app .

# Precompile assets
RUN rake assets:precompile

# Expose port 3000
EXPOSE 3000

# Database setup (drop, create, migrate, seed)
RUN rails db:drop db:create db:migrate db:seed

# Expose port 3000 again (just to be explicit)
EXPOSE 3000

# Command to run the application
CMD ["rails", "server", "-b", "0.0.0.0"]