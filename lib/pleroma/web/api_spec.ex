# Pleroma: A lightweight social networking server
# Copyright © 2017-2021 Pleroma Authors <https://pleroma.social/>
# SPDX-License-Identifier: AGPL-3.0-only

defmodule Pleroma.Web.ApiSpec do
  alias OpenApiSpex.OpenApi
  alias OpenApiSpex.Operation
  alias Pleroma.Web.Endpoint
  alias Pleroma.Web.Router

  @behaviour OpenApi

  @impl OpenApi
  def spec(opts \\ []) do
    %OpenApi{
      servers:
        if opts[:server_specific] do
          [
            # Populate the Server info from a phoenix endpoint
            OpenApiSpex.Server.from_endpoint(Endpoint)
          ]
        else
          []
        end,
      info: %OpenApiSpex.Info{
        title: "Akkoma API",
        description: """
        This is documentation for the Akkoma API. Most of the endpoints and entities come
        from Mastodon API and have custom extensions on top.

        While this document aims to be a complete guide to the client API Akkoma exposes,
        it may not be complete. Some endpoints may have incomplete or poorly worded documentation.
        You might want to check the following resources if something is not clear:
        - [Legacy Pleroma-specific endpoint documentation](https://docs-develop.pleroma.social/backend/development/API/pleroma_api/)
        - [Mastodon API documentation](https://docs.joinmastodon.org/client/intro/)
        - [Differences in Mastodon API responses from vanilla Mastodon](https://docs.akkoma.dev/stable/development/API/differences_in_mastoapi_responses/)

        Please report such occurrences on our [issue tracker](https://akkoma.dev/AkkomaGang/akkoma). Feel free to submit API questions or proposals there too!
        """,
        # Strip environment from the version
        version: Application.spec(:pleroma, :vsn) |> to_string() |> String.replace(~r/\+.*$/, ""),
        extensions: %{
          # Logo path should be picked so that the path exists both on Pleroma instances and on api.pleroma.social
          "x-logo": %{"url" => "/static/logo.svg", "altText" => "Pleroma logo"}
        }
      },
      # populate the paths from a phoenix router
      paths: OpenApiSpex.Paths.from_router(Router),
      components: %OpenApiSpex.Components{
        parameters: %{
          "accountIdOrNickname" =>
            Operation.parameter(:id, :path, :string, "Account ID or nickname",
              example: "123",
              required: true
            )
        },
        securitySchemes: %{
          "oAuth" => %OpenApiSpex.SecurityScheme{
            type: "oauth2",
            flows: %OpenApiSpex.OAuthFlows{
              password: %OpenApiSpex.OAuthFlow{
                authorizationUrl: "/oauth/authorize",
                tokenUrl: "/oauth/token",
                scopes: %{
                  "read" => "Read everything",
                  "write" => "Write everything",
                  "follow" => "Manage relationships",
                  "push" => "Web Push API subscriptions",
                  "admin" => "Manage everything",
                  "admin:read" => "Read all admin data",
                  "admin:read:accounts" => "Read admin accounts data",
                  "admin:read:invites" => "Read admin invites data",
                  "admin:read:media_proxy_caches" => "Read admin media proxy caches data",
                  "admin:read:reports" => "Read admin reports data",
                  "admin:read:statuses" => "Read admin statuses data",
                  "admin:write" => "Write all admin data",
                  "admin:write:accounts" => "Write admin accounts data",
                  "admin:write:follows" => "Write admin follows data",
                  "admin:write:invites" => "Write admin invites data",
                  "admin:write:media_proxy_caches" => "Write admin media proxy caches data",
                  "admin:write:reports" => "Write admin reports data",
                  "admin:write:statuses" => "Write admin statuses data",
                  "read:accounts" => "Read accounts data",
                  "read:backups" => "Read backups data",
                  "read:blocks" => "Read blocks data",
                  "read:bookmarks" => "Read bookmarks data",
                  "read:favourites" => "Read favourites data",
                  "read:filters" => "Read filters data",
                  "read:follows" => "Read follows data",
                  "read:lists" => "Read lists data",
                  "read:media" => "Read media data",
                  "read:mutes" => "Read mutes data",
                  "read:notifications" => "Read notifications data",
                  "read:reports" => "Read reports data",
                  "read:search" => "Read search data",
                  "read:security" => "Read security data",
                  "read:statuses" => "Read statuses data",
                  "write:accounts" => "Write accounts data",
                  "write:blocks" => "Write blocks data",
                  "write:bookmarks" => "Write bookmarks data",
                  "write:conversations" => "Write conversations data",
                  "write:favourites" => "Write favourites data",
                  "write:filters" => "Write filters data",
                  "write:follows" => "Write follows data",
                  "write:lists" => "Write lists data",
                  "write:media" => "Write media data",
                  "write:mutes" => "Write mutes data",
                  "write:notifications" => "Write notifications data",
                  "write:reports" => "Write reports data",
                  "write:security" => "Write security data",
                  "write:statuses" => "Write statuses data"
                }
              }
            }
          }
        }
      },
      extensions: %{
        # Redoc-specific extension, every time a new tag is added it should be reflected here,
        # otherwise it won't be shown.
        "x-tagGroups": [
          %{
            "name" => "Accounts",
            "tags" => ["Account actions", "Retrieve account information"]
          },
          %{
            "name" => "Administration",
            "tags" => [
              "Emoji pack administration",
              "Frontend managment",
              "Instance configuration",
              "Instance documents",
              "Invites",
              "MediaProxy cache",
              "OAuth application managment",
              "Relays",
              "Report managment",
              "Status administration",
              "User administration"
            ]
          },
          %{"name" => "Applications", "tags" => ["Applications", "Push subscriptions"]},
          %{
            "name" => "Current account",
            "tags" => [
              "Account credentials",
              "Backups",
              "Blocks and mutes",
              "Data import",
              "Domain blocks",
              "Follow requests",
              "Mascot",
              "Markers",
              "Notifications"
            ]
          },
          %{"name" => "Instance", "tags" => ["Custom emojis"]},
          %{
            "name" => "Statuses",
            "tags" => [
              "Emoji reactions",
              "Lists",
              "Polls",
              "Timelines",
              "Retrieve status information",
              "Scheduled statuses",
              "Search",
              "Status actions"
            ]
          },
          %{"name" => "Miscellaneous", "tags" => ["Emoji packs", "Reports", "Suggestions"]}
        ]
      }
    }
    # discover request/response schemas from path specs
    |> OpenApiSpex.resolve_schema_modules()
  end
end
