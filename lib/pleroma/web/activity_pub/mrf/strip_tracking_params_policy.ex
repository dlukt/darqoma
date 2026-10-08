defmodule Pleroma.Web.ActivityPub.MRF.StripTrackingParamsPolicy do
  @moduledoc """
  Removes tracking query parameters (utm_*, at_*, fbclid, YouTube's si=, ...)
  from links in post content and source text.
  """
  @behaviour Pleroma.Web.ActivityPub.MRF.Policy

  # Parameters that only exist to attribute clicks to campaigns, ads,
  # newsletters or the person who shared a link. Names are matched
  # case-insensitively after percent-decoding.
  #
  # Keep in sync with src/lib/tracking-params.ts in darq-fe, which strips the
  # same parameters when rendering posts.
  @global_params MapSet.new([
                   # Google Ads / Analytics / Shopping
                   "gclid",
                   "gclsrc",
                   "dclid",
                   "gbraid",
                   "wbraid",
                   "gad_source",
                   "gad_campaignid",
                   "srsltid",
                   "_ga",
                   "_gl",
                   "utm",
                   # Ad and social click ids
                   "fbclid",
                   "mibextid",
                   "sfnsn",
                   "fb_action_ids",
                   "fb_action_types",
                   "fb_ref",
                   "fb_source",
                   "action_object_map",
                   "action_type_map",
                   "action_ref_map",
                   "igshid",
                   "igsh",
                   "msclkid",
                   "twclid",
                   "ttclid",
                   "li_fat_id",
                   "epik",
                   "sccid",
                   "rdt_cid",
                   "yclid",
                   "ysclid",
                   "_openstat",
                   "irclickid",
                   "irgwc",
                   "obclid",
                   "dicbo",
                   "tblci",
                   "wickedid",
                   "rb_clickid",
                   # Newsletter and marketing automation
                   "mc_cid",
                   "mc_eid",
                   "mc_tc",
                   "_hsenc",
                   "_hsmi",
                   "__hstc",
                   "__hssc",
                   "__hsfp",
                   "hsctatracking",
                   "mkt_tok",
                   "oly_anon_id",
                   "oly_enc_id",
                   "vero_id",
                   "vero_conv",
                   "__s",
                   "_kx",
                   "ml_subscriber",
                   "ml_subscriber_hash",
                   "ck_subscriber_id",
                   # Adobe, Matomo, AT Internet, Webtrekk, comScore and friends
                   "s_cid",
                   "s_kwcid",
                   "ef_id",
                   "pk_campaign",
                   "pk_kwd",
                   "pk_keyword",
                   "pk_source",
                   "pk_medium",
                   "pk_content",
                   "pk_cid",
                   "xtor",
                   "wt_mc",
                   "wt_zmc",
                   "wtmc",
                   "wtrid",
                   "ns_campaign",
                   "ns_mchannel",
                   "ns_source",
                   "ns_linkname",
                   "ns_fee",
                   "cmpid",
                   "echobox",
                   "spm"
                 ])

  @global_prefixes [
    # Google Analytics campaigns
    "utm_",
    # AT Internet / Piano Analytics (at_medium, at_campaign, ...)
    "at_",
    # Matomo
    "mtm_",
    "piwik_",
    "matomo_",
    # HubSpot ads
    "hsa_",
    "ga_",
    "itm_",
    "hmb_",
    # Blueshift
    "bsft_",
    # Branch.io deep links
    "_branch_",
    # Webtrends (WT.mc_id, ...)
    "wt."
  ]

  # {domains, params, prefixes}; "example.com" also covers subdomains,
  # "example.*" covers any TLD.
  @site_rules [
    {["youtube.com", "youtu.be", "youtube-nocookie.com"],
     [
       "si",
       "feature",
       "pp",
       "embeds_referring_euri",
       "embeds_referring_origin",
       "source_ve_path"
     ], []},
    {["spotify.com"], ["si", "nd", "dlsi"], []},
    {["twitter.com", "x.com"], ["s", "t", "ref_src", "ref_url"], []},
    {["facebook.com", "fb.com", "fb.watch"],
     [
       "__tn__",
       "fref",
       "hc_ref",
       "ref",
       "refsrc",
       "rdid",
       "eav",
       "paipv",
       "comment_tracking",
       "notif_id",
       "notif_t"
     ], ["__cft__", "__xts__"]},
    {["threads.net", "threads.com"], ["xmt", "slof"], []},
    {["tiktok.com"],
     [
       "_d",
       "_r",
       "_t",
       "checksum",
       "enter_from",
       "is_copy_url",
       "is_from_webapp",
       "sec_user_id",
       "sender_device",
       "sender_web_id",
       "share_app_id",
       "share_author_id",
       "share_item_id",
       "share_link_id",
       "social_sharing",
       "timestamp",
       "tt_from",
       "u_code",
       "user_id",
       "web_id"
     ], []},
    {["reddit.com", "redd.it"],
     ["share_id", "rdt", "ref", "ref_source", "ref_campaign", "correlation_id"], []},
    {["linkedin.com", "lnkd.in"],
     [
       "trk",
       "trkinfo",
       "trkemail",
       "trackingid",
       "refid",
       "lipi",
       "lici",
       "midtoken",
       "midsig",
       "eid",
       "rcm"
     ], []},
    {["amazon.*"],
     [
       "ref",
       "ref_",
       "_encoding",
       "ascsubtag",
       "camp",
       "content-id",
       "creative",
       "creativeasin",
       "crid",
       "dchild",
       "dib",
       "dib_tag",
       "linkcode",
       "linkid",
       "qid",
       "qualifier",
       "refrid",
       "skiptwisterog",
       "social_share",
       "spia",
       "sprefix",
       "sr",
       "starsleft"
     ], ["pf_rd_", "pd_rd_"]},
    {["imdb.com"], ["ref_"], ["pf_rd_", "pd_rd_"]},
    {["google.*"],
     [
       "ved",
       "ei",
       "sxsrf",
       "sca_esv",
       "sca_upv",
       "gs_lcp",
       "gs_lp",
       "gs_ssp",
       "gs_l",
       "oq",
       "aqs",
       "uact",
       "rlz",
       "sourceid",
       "sclient",
       "bih",
       "biw",
       "dpr",
       "iflsig"
     ], []},
    {["bing.com"], ["form", "cvid", "pq", "qs", "sc", "sk", "sp"], []},
    {["msn.com"], ["ocid", "cvid", "pc", "ei"], []},
    {["yahoo.com"],
     [
       "guccounter",
       "guce_referrer",
       "guce_referrer_sig",
       "soc_src",
       "soc_trk",
       "ncid",
       "tsrc",
       ".tsrc",
       "sr_share"
     ], []},
    {["ebay.*"],
     [
       "_trkparms",
       "_trksid",
       "amdata",
       "campid",
       "customid",
       "mkcid",
       "mkevt",
       "mkrid",
       "toolid"
     ], []},
    {["aliexpress.*"],
     [
       "aff_fcid",
       "aff_fsk",
       "aff_platform",
       "aff_trace_key",
       "afsmartredirect",
       "algo_expid",
       "algo_pvid",
       "btsid",
       "gatewayadapt",
       "pdp_ext_f",
       "pdp_npi",
       "pvid",
       "scm",
       "scm_id",
       "scm-url",
       "sk",
       "srcsns",
       "terminal_id",
       "ws_ab_test"
     ], []},
    {["etsy.com"], ["click_key", "click_sum", "organic_search_click", "plkey", "rec_type", "ref"],
     []},
    {["nytimes.com"],
     [
       "smid",
       "smtyp",
       "partner",
       "emc",
       "nl",
       "campaign_id",
       "instance_id",
       "segment_id",
       "user_id",
       "regi_id",
       "te"
     ], []},
    {["washingtonpost.com"], ["itid", "wpisrc", "wpmk", "pwapi_token"], []},
    {["bloomberg.com"], ["srnd", "sref", "leadsource"], []},
    {["forbes.com"], ["sh", "ss"], []},
    {["theguardian.com"], ["cmp"], []},
    {["medium.com"], ["source"], []},
    {["substack.com"], ["r", "triedredirect"], []},
    {["apple.com"], ["itscg", "itsct", "uo"], []},
    {["twitch.tv"], ["tt_content", "tt_medium"], []},
    {["spiegel.de", "manager-magazin.de"], [], ["sara_"]},
    {["faz.net"], ["gepc"], []},
    {["welt.de"], ["cid"], []}
  ]

  # "&" in a URL may be written &amp;, &#38; or &#x26;. Any other entity
  # (&quot;, &#39;, &lt;, ...) stands for a character URLs don't contain.
  @amp "&(?:amp|#0*38|#x0*26);"
  @entity "&(?:[a-z][a-z0-9]*|#[0-9]+|#x[0-9a-f]+);"
  @trailing_punctuation "[.,;:!?)\\]}]*"

  # A URL in HTML runs up to markup or a non-& entity. Trailing punctuation
  # belongs to it at the end of an attribute value or link text, and to the
  # surrounding prose anywhere else ("see https://example.com/?s=20.").
  @html_url Regex.compile!(
              "https?://(?:[^\\s<>\"'&]|#{@amp}|&(?!#{@entity}))+?" <>
                "(?=[\"'>]|</a[\\s>]|#{@trailing_punctuation}" <>
                "(?:\\s|<(?!/a[\\s>])|(?!#{@amp})#{@entity}|$))",
              "i"
            )

  # The same for plain text and Markdown, where only an autolink's ">" ends
  # the URL itself ("<https://example.com/?s=20!>").
  @text_url Regex.compile!(
              "https?://[^\\s<>\"']+?(?=>|#{@trailing_punctuation}(?:[\\s<\"']|$))",
              "i"
            )

  # Mastodon spells out links as <span class="invisible">https://www.</span>,
  # <span class="ellipsis">first 30 characters</span>,
  # <span class="invisible">the rest</span>.
  @mastodon_link_text ~r/(<span class="invisible">)(https?:\/\/(?:www\.)?)(<\/span><span class="(?:ellipsis)?">)([^<]*)(<\/span><span class="invisible">)([^<]*)(<\/span>)/

  @impl true
  def history_awareness, do: :auto

  @impl true
  def filter(%{"type" => type, "object" => %{} = object} = activity)
      when type in ["Create", "Update"] do
    object =
      object
      |> update_present("content", &map_strings(&1, fn html -> strip_html(html) end))
      |> update_present("contentMap", &map_strings(&1, fn html -> strip_html(html) end))
      |> update_present("source", &strip_source/1)

    {:ok, Map.put(activity, "object", object)}
  end

  def filter(activity), do: {:ok, activity}

  @impl true
  def describe, do: {:ok, %{}}

  defp update_present(object, field, fun) do
    case object do
      %{^field => value} -> Map.put(object, field, fun.(value))
      _ -> object
    end
  end

  defp map_strings(value, fun) when is_binary(value), do: fun.(value)

  defp map_strings(%{} = map, fun) do
    Map.new(map, fn
      {key, value} when is_binary(value) -> {key, fun.(value)}
      pair -> pair
    end)
  end

  defp map_strings(value, _fun), do: value

  defp strip_source(%{"mediaType" => media_type} = source) when is_binary(media_type) do
    # Compare the base type only: "text/html; charset=utf-8", "TEXT/HTML"
    base_type = media_type |> String.split(";", parts: 2) |> hd() |> String.trim()

    if String.downcase(base_type) == "text/html" do
      map_strings(source, &strip_html/1)
    else
      map_strings(source, &strip_text/1)
    end
  end

  defp strip_source(source), do: map_strings(source, &strip_text/1)

  @doc "Removes tracking parameters from links in an HTML fragment."
  @spec strip_html(String.t()) :: String.t()
  def strip_html(html) do
    if String.contains?(html, "?") do
      html
      |> strip_mastodon_link_text()
      |> then(&Regex.replace(@html_url, &1, fn url -> strip_html_url(url) end))
    else
      html
    end
  end

  @doc "Removes tracking parameters from links in plain text or Markdown."
  @spec strip_text(String.t()) :: String.t()
  def strip_text(text) do
    if String.contains?(text, "?") do
      Regex.replace(@text_url, text, fn url -> strip_text_url(url) end)
    else
      text
    end
  end

  defp strip_html_url(url) do
    decoded = HtmlEntities.decode(url)
    stripped = strip_url(decoded)

    if stripped == decoded, do: url, else: HtmlEntities.encode(stripped)
  end

  defp strip_text_url(url) do
    # Markdown may spell "&" as &amp;; keep whichever spelling was used.
    escaped? = String.contains?(url, "&amp;")
    decoded = if escaped?, do: String.replace(url, "&amp;", "&"), else: url
    stripped = strip_url(decoded)

    cond do
      stripped == decoded -> url
      escaped? -> String.replace(stripped, "&", "&amp;")
      true -> stripped
    end
  end

  # The full URL is split over three spans; the stripped URL is written back at
  # the same offsets, so a link cut off after 30 characters stays cut off.
  defp strip_mastodon_link_text(html) do
    Regex.replace(@mastodon_link_text, html, fn whole,
                                                open,
                                                prefix,
                                                middle,
                                                display,
                                                close_middle,
                                                rest,
                                                close ->
      display = HtmlEntities.decode(display)
      url = prefix <> display <> HtmlEntities.decode(rest)
      stripped = strip_url(url)

      if stripped == url do
        whole
      else
        offset = String.length(prefix) + String.length(display)

        Enum.join([
          open,
          prefix,
          middle,
          HtmlEntities.encode(String.slice(stripped, String.length(prefix)..(offset - 1)//1)),
          close_middle,
          HtmlEntities.encode(String.slice(stripped, offset..-1//1)),
          close
        ])
      end
    end)
  end

  @doc """
  Removes tracking parameters from an http(s) URL. Everything else, including
  the order and encoding of the remaining parameters, is left untouched.
  """
  @spec strip_url(String.t()) :: String.t()
  def strip_url(url) do
    with [base, rest] <- :binary.split(url, "?"),
         false <- String.contains?(base, "#"),
         [_, host] <- Regex.run(~r/^https?:\/\/(?:[^\/?#@]*@)?([^\/?#:]+)/i, base) do
      {query, fragment} =
        case :binary.split(rest, "#") do
          [query, fragment] -> {query, "#" <> fragment}
          [query] -> {query, ""}
        end

      rules = site_rules(String.downcase(host))
      pairs = String.split(query, "&")
      # A ";" may separate further parameters, so such pairs are left alone.
      kept =
        Enum.reject(pairs, fn pair ->
          not String.contains?(pair, ";") and tracking_param?(param_name(pair), rules)
        end)

      cond do
        length(kept) == length(pairs) -> url
        Enum.all?(kept, &(&1 == "")) -> base <> fragment
        true -> base <> "?" <> Enum.join(Enum.reject(kept, &(&1 == "")), "&") <> fragment
      end
    else
      _ -> url
    end
  end

  defp param_name(pair) do
    raw = pair |> String.split("=", parts: 2) |> hd() |> String.replace("+", " ")

    try do
      raw |> URI.decode() |> String.downcase()
    rescue
      ArgumentError -> String.downcase(raw)
    end
  end

  defp tracking_param?(name, rules) do
    MapSet.member?(@global_params, name) or String.starts_with?(name, @global_prefixes) or
      Enum.any?(rules, fn {params, prefixes} ->
        name in params or String.starts_with?(name, prefixes)
      end)
  end

  defp site_rules(host) do
    for {domains, params, prefixes} <- @site_rules,
        Enum.any?(domains, &matches_domain?(host, &1)),
        do: {params, prefixes}
  end

  # "amazon.*" matches amazon.de, www.amazon.co.uk, smile.amazon.com, ...
  # but not amazon.example.org, amazon.foo.com or amazon.co.com.
  defp matches_domain?(host, domain) do
    case String.split(domain, ".*", parts: 2) do
      [name, ""] ->
        case host |> String.split(".") |> Enum.reverse() do
          [_tld, ^name | _] ->
            true

          [tld, second_level, ^name | _] ->
            second_level in ["co", "com"] and String.length(tld) == 2

          _ ->
            false
        end

      _ ->
        host == domain or String.ends_with?(host, "." <> domain)
    end
  end
end
