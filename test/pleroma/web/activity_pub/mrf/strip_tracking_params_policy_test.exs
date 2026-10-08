defmodule Pleroma.Web.ActivityPub.MRF.StripTrackingParamsPolicyTest do
  use Pleroma.DataCase, async: true
  alias Pleroma.Web.ActivityPub.MRF
  alias Pleroma.Object
  alias Pleroma.Web.ActivityPub.MRF.StripTrackingParamsPolicy
  alias Pleroma.Web.CommonAPI

  import Pleroma.Factory

  describe "strip_url/1" do
    test "removes AT Internet parameters" do
      assert StripTrackingParamsPolicy.strip_url(
               "https://www.tagesschau.de/ausland/europa/proteste-frankreich-lecornu-100.html?at_medium=mastodon&at_campaign=tagesschau.de"
             ) ==
               "https://www.tagesschau.de/ausland/europa/proteste-frankreich-lecornu-100.html"
    end

    test "removes YouTube share ids but keeps the timestamp" do
      assert StripTrackingParamsPolicy.strip_url(
               "https://youtu.be/FOzijIeBGCg?si=TaRR3fHzlSIhMP-k"
             ) ==
               "https://youtu.be/FOzijIeBGCg"

      assert StripTrackingParamsPolicy.strip_url(
               "https://www.youtube.com/watch?v=FOzijIeBGCg&si=abc&t=42"
             ) == "https://www.youtube.com/watch?v=FOzijIeBGCg&t=42"
    end

    test "keeps other parameters, their order and the fragment" do
      assert StripTrackingParamsPolicy.strip_url(
               "https://example.com/a?utm_source=x&id=5&UTM_Medium=y&b=%20c&fbclid=1#frag"
             ) == "https://example.com/a?id=5&b=%20c#frag"
    end

    test "only applies site rules to their sites" do
      assert StripTrackingParamsPolicy.strip_url("https://example.com/a?si=1&ref=2") ==
               "https://example.com/a?si=1&ref=2"

      assert StripTrackingParamsPolicy.strip_url(
               "https://www.amazon.co.uk/dp/B000?ref_=abc&pf_rd_r=X&th=1"
             ) == "https://www.amazon.co.uk/dp/B000?th=1"

      assert StripTrackingParamsPolicy.strip_url("https://amazon.example.org/dp?ref=1") ==
               "https://amazon.example.org/dp?ref=1"

      assert StripTrackingParamsPolicy.strip_url("https://amazon.foo.com/dp?ref=1") ==
               "https://amazon.foo.com/dp?ref=1"

      assert StripTrackingParamsPolicy.strip_url("https://google.co.com/search?q=a&ved=1") ==
               "https://google.co.com/search?q=a&ved=1"

      assert StripTrackingParamsPolicy.strip_url("https://www.amazon.com.au/dp/B0?ref=1") ==
               "https://www.amazon.com.au/dp/B0"

      assert StripTrackingParamsPolicy.strip_url(
               "https://www.facebook.com/a?__cft__%5B0%5D=1&id=2"
             ) == "https://www.facebook.com/a?id=2"

      assert StripTrackingParamsPolicy.strip_url("https://www.youtube.com./watch?v=x&si=secret") ==
               "https://www.youtube.com./watch?v=x"
    end

    test "leaves parameters followed by a ; separator alone" do
      for url <- [
            "https://example.com/?utm_source=x;id=5",
            "https://example.com/?id=5;utm_source=x"
          ] do
        assert StripTrackingParamsPolicy.strip_url(url) == url
      end
    end

    test "leaves non-http URLs and queries inside fragments alone" do
      for url <- [
            "mailto:a@example.com?utm_source=x",
            "https://example.com/#/route?utm_source=x",
            "https://example.com/a?",
            "https://example.com/a?b=%zz"
          ] do
        assert StripTrackingParamsPolicy.strip_url(url) == url
      end
    end
  end

  describe "strip_html/1" do
    test "cleans the href and the link text" do
      html =
        ~s(<p>look <a href="https://youtu.be/FOzijIeBGCg?si=TaRR3fHzlSIhMP-k&amp;t=4" rel="ugc">https://youtu.be/FOzijIeBGCg?si=TaRR3fHzlSIhMP-k&amp;t=4</a>.</p>)

      assert StripTrackingParamsPolicy.strip_html(html) ==
               ~s(<p>look <a href="https://youtu.be/FOzijIeBGCg?t=4" rel="ugc">https://youtu.be/FOzijIeBGCg?t=4</a>.</p>)
    end

    test "cleans Mastodon's split link text" do
      html =
        ~s(<p><a href="https://www.tagesschau.de/ausland/europa/proteste-frankreich-lecornu-100.html?at_medium=mastodon&amp;at_campaign=tagesschau.de" target="_blank" rel="nofollow noopener noreferrer" translate="no"><span class="invisible">https://www.</span><span class="ellipsis">tagesschau.de/ausland/europa/p</span><span class="invisible">roteste-frankreich-lecornu-100.html?at_medium=mastodon&amp;at_campaign=tagesschau.de</span></a></p>)

      assert StripTrackingParamsPolicy.strip_html(html) ==
               ~s(<p><a href="https://www.tagesschau.de/ausland/europa/proteste-frankreich-lecornu-100.html" target="_blank" rel="nofollow noopener noreferrer" translate="no"><span class="invisible">https://www.</span><span class="ellipsis">tagesschau.de/ausland/europa/p</span><span class="invisible">roteste-frankreich-lecornu-100.html</span></a></p>)
    end

    test "cleans scheme-less www. link text" do
      html =
        ~s(<a href="http://www.example.com/?utm_source=x&amp;id=1">www.example.com/?utm_source=x&amp;id=1</a>)

      assert StripTrackingParamsPolicy.strip_html(html) ==
               ~s(<a href="http://www.example.com/?id=1">www.example.com/?id=1</a>)
    end

    test "finds hrefs whose ? is written as a character reference" do
      for question_mark <- ["&#63;", "&#x3F;", "&quest;"] do
        html = ~s(<a href="https://example.com/#{question_mark}utm_source=x">link</a>)

        assert StripTrackingParamsPolicy.strip_html(html) ==
                 ~s(<a href="https://example.com/">link</a>)
      end
    end

    test "keeps link text whose separators differ from the href" do
      html =
        ~s(<a href="https://example.com/?utm_source=x%26id=5">https://example.com/?utm_source=x&amp;id=5</a>)

      assert StripTrackingParamsPolicy.strip_html(html) ==
               ~s(<a href="https://example.com/">https://example.com/?utm_source=x&amp;id=5</a>)
    end

    test "handles percent escapes that aren't UTF-8" do
      html =
        ~s(<a href="https://example.com/?utm_source=x&amp;%FF=1&amp;id=%FF">https://example.com/?utm_source=x&amp;%FF=1&amp;id=%FF</a>)

      assert StripTrackingParamsPolicy.strip_html(html) ==
               ~s(<a href="https://example.com/?%FF=1&amp;id=%FF">https://example.com/?%FF=1&amp;id=%FF</a>)
    end

    test "keeps link text that isn't the link's URL" do
      html = ~s(<a href="https://example.com/?utm_source=x">help?utm_source=x</a>)

      assert StripTrackingParamsPolicy.strip_html(html) ==
               ~s(<a href="https://example.com/">help?utm_source=x</a>)
    end

    test "decodes every spelling of & in the href" do
      for amp <- ["&#38;", "&#x26;", "&amp;", "&AMP;"] do
        html = ~s(<a href="https://example.com/?utm_source=x#{amp}id=5">link</a>)

        assert StripTrackingParamsPolicy.strip_html(html) ==
                 ~s(<a href="https://example.com/?id=5">link</a>)
      end
    end

    test "keeps trailing punctuation with the href, quoted or not" do
      for html <- [
            ~s(<a href="https://example.com/?id=1&amp;utm_campaign=sale!" class="x">link</a>),
            ~s(<a href=https://example.com/?id=1&amp;utm_campaign=sale! class=x>link</a>),
            ~s(<a href=https://example.com/?id=1&amp;utm_campaign=sale!>link</a>)
          ] do
        assert StripTrackingParamsPolicy.strip_html(html) =~
                 ~s(<a href="https://example.com/?id=1")
      end
    end

    test "leaves URLs outside links alone" do
      for html <- [
            ~s(<pre><code>curl https://example.com/?utm_source=x&amp;id=5</code></pre>),
            ~s(<p>see https://example.com/?utm_source=x&frac12; rest</p>)
          ] do
        assert StripTrackingParamsPolicy.strip_html(html) == html
      end
    end

    test "leaves content without tracking parameters untouched" do
      html = ~s(<p>Hello? <a href="https://example.com/?q=1&amp;page=2">link</a><br>x</p>)
      assert StripTrackingParamsPolicy.strip_html(html) == html
    end
  end

  describe "filter/1" do
    test "cleans content, contentMap and source" do
      message = %{
        "type" => "Create",
        "object" => %{
          "content" =>
            ~s(<a href="https://example.com/?utm_source=a">https://example.com/?utm_source=a</a>),
          "contentMap" => %{
            "en" =>
              ~s(<a href="https://example.com/?utm_source=a">https://example.com/?utm_source=a</a>)
          },
          "source" => %{
            "content" => "https://example.com/?utm_source=a",
            "mediaType" => "text/plain"
          }
        }
      }

      assert {:ok, %{"object" => object}} = StripTrackingParamsPolicy.filter(message)

      assert object["content"] ==
               ~s(<a href="https://example.com/">https://example.com/</a>)

      assert object["contentMap"]["en"] == object["content"]

      assert object["source"] == %{
               "content" => "https://example.com/",
               "mediaType" => "text/plain"
             }
    end

    test "cleans source text with the replacements made to the content's links" do
      cases = [
        {"https://x.com/user/status/1?s=20", "See https://x.com/user/status/1?s=20.",
         "See https://x.com/user/status/1."},
        {"https://example.com/?id=1&utm_campaign=sale!",
         "[x](https://example.com/?id=1&utm_campaign=sale!) and <https://example.com/?id=1&utm_campaign=sale!>",
         "[x](https://example.com/?id=1) and <https://example.com/?id=1>"},
        {"http://www.example.com/?utm_source=x", "go to www.example.com/?utm_source=x now",
         "go to www.example.com/ now"},
        # A longer URL that merely starts with the link's address is left alone
        {"https://example.com/?s=1&utm_source=x",
         "https://example.com/?s=1&utm_source=x2 https://example.com/?s=1&utm_source=x",
         "https://example.com/?s=1&utm_source=x2 https://example.com/?s=1"},
        # Code spans and fenced blocks keep their copy of the URL
        {"https://example.com/?utm_source=x",
         "[sale](https://example.com/?utm_source=x) `https://example.com/?utm_source=x`\n```\ncurl https://example.com/?utm_source=x\n```",
         "[sale](https://example.com/) `https://example.com/?utm_source=x`\n```\ncurl https://example.com/?utm_source=x\n```"},
        {"https://example.com/?utm_source=x",
         "[a](https://example.com/?utm_source=x) ``https://example.com/?utm_source=x`` ~~~\nhttps://example.com/?utm_source=x\n~~~ https://example.com/?utm_source=x",
         "[a](https://example.com/) ``https://example.com/?utm_source=x`` ~~~\nhttps://example.com/?utm_source=x\n~~~ https://example.com/"},
        # Spelled differently from the href: left alone rather than guessed at
        {"https://example.com/?utm_source=x&id=5", "<https://example.com/?utm_source=x&#38;id=5>",
         "<https://example.com/?utm_source=x&#38;id=5>"}
      ]

      for {href, source, expected} <- cases do
        message = %{
          "type" => "Create",
          "object" => %{
            "content" => ~s(<a href="#{HtmlEntities.encode(href)}">link</a>),
            "source" => %{"content" => source, "mediaType" => "text/markdown", "name" => href}
          }
        }

        assert {:ok, %{"object" => %{"source" => result}}} =
                 StripTrackingParamsPolicy.filter(message)

        assert result == %{"content" => expected, "mediaType" => "text/markdown", "name" => href}
      end
    end

    test "cleans HTML source as HTML" do
      for media_type <- ["text/html", "TEXT/HTML", "text/html; charset=utf-8"] do
        message = %{
          "type" => "Create",
          "object" => %{
            "source" => %{
              "content" => ~s(<a href="https://example.com/?utm_source=x&#38;id=5">link</a>),
              "mediaType" => media_type
            }
          }
        }

        assert {:ok, %{"object" => %{"source" => source}}} =
                 StripTrackingParamsPolicy.filter(message)

        assert source["content"] == ~s(<a href="https://example.com/?id=5">link</a>)
      end
    end

    test "is history-aware" do
      message = %{
        "type" => "Update",
        "object" => %{
          "content" => ~s(<a href="https://example.com/?fbclid=1">x</a>),
          "formerRepresentations" => %{
            "orderedItems" => [%{"content" => ~s(<a href="https://example.com/?gclid=1">x</a>)}]
          }
        }
      }

      assert {:ok, %{"object" => object}} = MRF.filter_one(StripTrackingParamsPolicy, message)

      assert %{
               "content" => ~s(<a href="https://example.com/">x</a>),
               "formerRepresentations" => %{
                 "orderedItems" => [%{"content" => ~s(<a href="https://example.com/">x</a>)}]
               }
             } = object
    end

    test "is applied to local posts" do
      user = insert(:user)

      {:ok, activity} =
        CommonAPI.post(user, %{status: "watch https://youtu.be/FOzijIeBGCg?si=TaRR3fHzlSIhMP-k"})

      object = Object.normalize(activity, fetch: false)

      assert object.data["content"] =~ ~s(href="https://youtu.be/FOzijIeBGCg")
      refute object.data["content"] =~ "si="
      assert object.data["source"]["content"] == "watch https://youtu.be/FOzijIeBGCg"
    end

    test "is applied to local Markdown posts" do
      user = insert(:user)

      {:ok, activity} =
        CommonAPI.post(user, %{
          status:
            "[sale](https://example.com/?id=1&utm_campaign=sale!), `https://example.com/?utm_source=code`",
          content_type: "text/markdown"
        })

      object = Object.normalize(activity, fetch: false)

      assert object.data["content"] =~ ~s(href="https://example.com/?id=1")
      assert object.data["content"] =~ "https://example.com/?utm_source=code"

      assert object.data["source"]["content"] ==
               "[sale](https://example.com/?id=1), `https://example.com/?utm_source=code`"
    end

    test "ignores other activities" do
      message = %{"type" => "Like", "object" => "https://example.com/?utm_source=a"}
      assert {:ok, ^message} = StripTrackingParamsPolicy.filter(message)
    end
  end
end
