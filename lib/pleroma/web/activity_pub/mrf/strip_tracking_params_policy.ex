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

  # Characters that can continue a URL, used to tell where a link address
  # ends inside source text.
  @url_char "[\\w\\-~%/=&#+@]"

  # "?" as written in HTML, also as a character reference
  @question_mark ~r/\?|&#0*63;|&#x0*3f;|&quest;/i

  # Markdown/MFM code spans and fenced blocks, which source replacements skip
  @code ~r/```[\s\S]*?```|`[^`\n]*`/

  @impl true
  def history_awareness, do: :auto

  @impl true
  def filter(%{"type" => type, "object" => %{} = object} = activity)
      when type in ["Create", "Update"] do
    {object, replaced} =
      Enum.reduce(["content", "contentMap"], {object, %{}}, fn field, {object, replaced} ->
        case object do
          %{^field => value} ->
            {value, field_replaced} = clean_html_values(value)
            {Map.put(object, field, value), Map.merge(replaced, field_replaced)}

          _ ->
            {object, replaced}
        end
      end)

    {:ok, Map.put(activity, "object", clean_source(object, replaced))}
  end

  def filter(activity), do: {:ok, activity}

  @impl true
  def describe, do: {:ok, %{}}

  defp clean_html_values(html) when is_binary(html), do: clean_html(html)

  defp clean_html_values(%{} = map) do
    Enum.reduce(map, {map, %{}}, fn
      {key, html}, {map, replaced} when is_binary(html) ->
        {html, html_replaced} = clean_html(html)
        {Map.put(map, key, html), Map.merge(replaced, html_replaced)}

      _, acc ->
        acc
    end)
  end

  defp clean_html_values(value), do: {value, %{}}

  # Source text has no markup to say where a link ends, so instead of guessing
  # it gets exactly the replacements made to the links in the content.
  defp clean_source(%{"source" => %{"content" => content} = source} = object, replaced)
       when is_binary(content) do
    content =
      if html_media_type?(source["mediaType"]) do
        content |> clean_html() |> elem(0)
      else
        replace_urls(content, replaced)
      end

    Map.put(object, "source", Map.put(source, "content", content))
  end

  defp clean_source(%{"source" => source} = object, replaced) when is_binary(source) do
    Map.put(object, "source", replace_urls(source, replaced))
  end

  defp clean_source(object, _replaced), do: object

  # Compare the base type only: "text/html; charset=utf-8", "TEXT/HTML"
  defp html_media_type?(media_type) when is_binary(media_type) do
    media_type
    |> String.split(";", parts: 2)
    |> hd()
    |> String.trim()
    |> String.downcase()
    |> Kernel.==("text/html")
  end

  defp html_media_type?(_), do: false

  # Linkify turns "www.example.com/?utm_source=x" into an http:// link, so the
  # address is also looked for without its scheme. Longer addresses go first,
  # a match must not continue into a longer URL, and code is left as written.
  defp replace_urls(text, replaced) do
    replacements = source_replacements(replaced)

    # Regex.split with captures alternates text and code, starting with text
    @code
    |> Regex.split(text, include_captures: true)
    |> Enum.with_index()
    |> Enum.map_join(fn
      {segment, index} when rem(index, 2) == 0 -> replace_in_segment(segment, replacements)
      {code, _index} -> code
    end)
  end

  defp source_replacements(replaced) do
    replaced
    |> Enum.flat_map(fn {original, cleaned} ->
      case Regex.run(~r/^https?:\/\//i, original) do
        [scheme] ->
          if String.starts_with?(cleaned, scheme) do
            [
              {original, cleaned},
              {String.replace_prefix(original, scheme, ""),
               String.replace_prefix(cleaned, scheme, "")}
            ]
          else
            [{original, cleaned}]
          end

        nil ->
          [{original, cleaned}]
      end
    end)
    |> Enum.sort_by(fn {original, _} -> -String.length(original) end)
  end

  defp replace_in_segment(text, replacements) do
    Enum.reduce(replacements, text, fn {original, cleaned}, text ->
      Regex.replace(
        ~r/(?<![\w.\-\/@:])#{Regex.escape(original)}(?!#{@url_char}|[.,;:!?]+#{@url_char})/u,
        text,
        fn _ -> cleaned end
      )
    end)
  end

  @doc "Removes tracking parameters from the links in an HTML fragment."
  @spec strip_html(String.t()) :: String.t()
  def strip_html(html), do: html |> clean_html() |> elem(0)

  # Only <a href> and link text that spells out the link's own URL are
  # changed; URLs in code blocks or prose are left as written. Returns the
  # cleaned HTML and the replaced link addresses.
  defp clean_html(html) do
    with true <- Regex.match?(@question_mark, html),
         {:ok, tree} <- Floki.parse_fragment(html),
         {tree, replaced} when replaced != %{} <-
           Floki.traverse_and_update(tree, %{}, &clean_link/2) do
      {Floki.raw_html(tree), replaced}
    else
      _ -> {html, %{}}
    end
  end

  defp clean_link({"a", attrs, children} = link, replaced) do
    with {"href", href} <- List.keyfind(attrs, "href", 0),
         cleaned when cleaned != href <- strip_url(href) do
      attrs = List.keystore(attrs, "href", 0, {"href", cleaned})
      {{"a", attrs, clean_link_text(children, href)}, Map.put(replaced, href, cleaned)}
    else
      _ -> {link, replaced}
    end
  end

  defp clean_link(node, replaced), do: {node, replaced}

  # Mastodon splits link text over several spans (scheme, first 30
  # characters, rest), so the cleaned text is written back over the original
  # text nodes at the same offsets.
  defp clean_link_text(children, href) do
    text = Floki.text(children)

    if display_form(text) == display_form(href) do
      cleaned =
        if Regex.match?(~r/^https?:\/\//i, text) do
          strip_url(text)
        else
          ("https://" <> text) |> strip_url() |> String.replace_prefix("https://", "")
        end

      {children, _} = rewrite_text_nodes(children, cleaned, count_text_nodes(children))
      children
    else
      children
    end
  end

  # URL without scheme and "www.", decoded like JavaScript's decodeURI, to
  # compare link text with the link it belongs to. Reserved characters stay
  # escaped, so "?a=1%26b=2" and "?a=1&b=2" don't compare equal.
  defp display_form(url) do
    ~r/%([0-9a-f]{2})/i
    |> Regex.replace(url, fn escape, hex ->
      char = String.to_integer(hex, 16)
      if char in ~c";/?:@&=+$,#", do: String.upcase(escape), else: <<char>>
    end)
    |> String.replace(~r/^(https?:\/\/)?(www\.)?/i, "")
  end

  defp count_text_nodes(nodes) do
    Enum.reduce(nodes, 0, fn
      text, count when is_binary(text) -> count + 1
      {_tag, _attrs, children}, count -> count + count_text_nodes(children)
      _, count -> count
    end)
  end

  # Walks text nodes in order; each takes as many characters as it had, the
  # last one takes the rest. The accumulator is {offset, text nodes left}.
  defp rewrite_text_nodes(nodes, cleaned, remaining, offset \\ 0) do
    Enum.map_reduce(nodes, {offset, remaining}, fn
      text, {offset, 1} when is_binary(text) ->
        {String.slice(cleaned, offset..-1//1), {offset + String.length(text), 0}}

      text, {offset, remaining} when is_binary(text) ->
        length = String.length(text)
        {String.slice(cleaned, offset, length), {offset + length, remaining - 1}}

      {tag, attrs, children}, {offset, remaining} ->
        {children, {offset, remaining}} = rewrite_text_nodes(children, cleaned, remaining, offset)
        {{tag, attrs, children}, {offset, remaining}}

      node, acc ->
        {node, acc}
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
