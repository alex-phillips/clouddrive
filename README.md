# CloudDrive SDK and CLI

This i a Ruby project built to interact with Amazon's CloudDrive API. It works as both an SDK and a CLI in the sense that I've built the code to easily be implemented in your own projects but it also includes an executable to run many common processes right from the command line.

## Obtaining Credentials

To obtain credentials for the client you must have an Amazon Developer account.

1. Register for an Amazon Developer account at [https://developer.amazon.com/](https://developer.amazon.com/)
2. Create a Security Profile at
   [https://developer.amazon.com/lwa/sp/overview.html](https://developer.amazon.com/lwa/sp/overview.html). Note the
   Client ID and Client Secret that are generated for you
2. Request that your Security Profile be whitelisted for the Cloud Drive API at
   [https://developer.amazon.com/cd/sp/overview.html](https://developer.amazon.com/cd/sp/overview.html)
   1. For **Account Access Control** select all options
   2. For **Permission Level** select **Read and Write**
   3. For **Platform Support** select **Amazon**
3. Follow [these
   instructions](https://developer.amazon.com/public/apis/engage/login-with-amazon/docs/adding_website.html) to add the
   website **http://localhost** to **Allowed Return URLs** for your Security Profile

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'clouddrive'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install clouddrive

Create a file at `~/.cache/clouddrive-ruby/config.json` with the following contents:
```json
{
  "email": "YOUR EMAIL",
  "client-id": "YOUR CLIENT ID",
  "client-secret": "YOUR CLIENT SECRET"
}

Set the credentials on the file so that others cannot read it:

    $ chmod 600 ~/.cache/clouddrive-ruby/config.json

```

## CLI Usage

The CLI is used by running `clouddrive` with one of the following commands followed by any necessary arguments (use `help` argument before any of the following commands for more information).

```bash
init        Initialize the CLI with your Amazon email and CloudDrive API credentials
sync        Sync the local cache with Amazon CloudDrive
clearcache  Clear the local cache
metadata    Output JSON-formatted metadata related to the remote file give its remote path
```

## SDK Usage

### Account

#### Initialization

The CloudDrive SDK first needs have an authenticated `Account` object which can then be passed into the different classes for API calls.

The `Account` class is created by passing in the `email`, `client_id`, and `client_secret` into the constructor and calling the `authorize` method. This will handle authorizing and (if necessary) renewing authorization.

The initial `authorize` method call will return false with an `auth_url` key in its `data`. This URL can then be passed into a second `authorize` call which will parse out the `code` parameter and complete the initial OAuth process.

```ruby
account = CloudDrive::Account.new("me@example.com", "my-client-id", "clientsecret")
account.authorize
...
account.authorize(auth_url)
```

The `authorize` method call will still need to be called periodically to renew its authorization as the OAuth token expires every 60 minutes.

####  Local Cache

By default, the SDK stores all necessary information (OAuth token information, local account caches, etc) into `~/.clouddrive`. Each account (email), has its own cache file and local cache database of its remote filesystem. Once authenticated, the local cache is initially synced with the remote CloudDrive by calling the `sync` method.

```ruby
account.sync
```

Every time `sync` is called, it will update the local cache with all changes since the last `sync` call. The local cache can be cleared out and reset by calling `clear_cache`.

```ruby
account.clear_cache
```

## Contributing

1. Fork it ( https://github.com/[my-github-username]/clouddrive/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
