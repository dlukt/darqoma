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

    test "does not swallow entities following a URL" do
      html =
        ~s(&#39;https://example.com/?utm_source=x&#39; &quot;https://example.com/?fbclid=1&quot;)

      assert StripTrackingParamsPolicy.strip_html(html) ==
               ~s(&#39;https://example.com/&#39; &quot;https://example.com/&quot;)
    end

    test "treats numeric entities for & as parameter separators" do
      for amp <- ["&#38;", "&#x26;", "&amp;"] do
        html = ~s(<a href="https://example.com/?utm_source=x#{amp}id=5">link</a>)

        assert StripTrackingParamsPolicy.strip_html(html) ==
                 ~s(<a href="https://example.com/?id=5">link</a>)
      end
    end

    test "keeps trailing punctuation with the URL in attributes and link text" do
      html =
        ~s(<a href="https://example.com/?id=1&amp;utm_campaign=sale!">https://example.com/?id=1&amp;utm_campaign=sale!</a>)

      assert StripTrackingParamsPolicy.strip_html(html) ==
               ~s(<a href="https://example.com/?id=1">https://example.com/?id=1</a>)
    end

    test "keeps trailing punctuation with the URL in unquoted attributes" do
      assert StripTrackingParamsPolicy.strip_html(
               "<a href=https://example.com/?id=1&amp;utm_campaign=sale!>link</a>"
             ) == "<a href=https://example.com/?id=1>link</a>"
    end

    test "stops at named entities containing digits" do
      assert StripTrackingParamsPolicy.strip_html(
               "<p>https://example.com/?utm_source=x&frac12; rest</p>"
             ) == "<p>https://example.com/&frac12; rest</p>"
    end

    test "leaves trailing punctuation of prose in place" do
      assert StripTrackingParamsPolicy.strip_html(
               "<p>see https://x.com/a?s=20. or (https://x.com/b?s=20)</p>"
             ) == "<p>see https://x.com/a. or (https://x.com/b)</p>"
    end

    test "leaves content without tracking parameters untouched" do
      html = ~s(<p>Hello? <a href="https://example.com/?q=1&amp;page=2">link</a></p>)
      assert StripTrackingParamsPolicy.strip_html(html) == html
    end
  end

  describe "strip_text/1" do
    test "keeps the &amp; spelling of Markdown sources" do
      assert StripTrackingParamsPolicy.strip_text(
               "<https://example.com/?utm_source=x&amp;id=5&amp;b=2>"
             ) == "<https://example.com/?id=5&amp;b=2>"
    end

    test "keeps trailing punctuation with the URL in Markdown autolinks" do
      assert StripTrackingParamsPolicy.strip_text(
               "<https://example.com/?id=1&utm_campaign=sale!>"
             ) ==
               "<https://example.com/?id=1>"
    end

    test "keeps trailing punctuation and Markdown syntax" do
      assert StripTrackingParamsPolicy.strip_text(
               "See https://x.com/user/status/1?s=20. Or [this](https://example.com/?utm_source=a&id=1)!"
             ) == "See https://x.com/user/status/1. Or [this](https://example.com/?id=1)!"
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
          "content" => "https://example.com/?fbclid=1",
          "formerRepresentations" => %{
            "orderedItems" => [%{"content" => "https://example.com/?gclid=1"}]
          }
        }
      }

      assert {:ok, %{"object" => object}} = MRF.filter_one(StripTrackingParamsPolicy, message)

      assert %{
               "content" => "https://example.com/",
               "formerRepresentations" => %{
                 "orderedItems" => [%{"content" => "https://example.com/"}]
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

    test "ignores other activities" do
      message = %{"type" => "Like", "object" => "https://example.com/?utm_source=a"}
      assert {:ok, ^message} = StripTrackingParamsPolicy.filter(message)
    end
  end
end
