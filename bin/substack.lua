-- Pandoc Lua filter: Substack body_html -> clean GFM.
--   * YouTube, Vimeo, TikTok, Instagram and embedded-post widgets become "▶" link lines
--   * captioned images become plain images; inline SVG icons are dropped
--   * pull quotes become blockquotes
--   * subscribe widgets and buttons are dropped
--   * styled spans (text color, highlight) are kept as raw HTML; bare spans are unwrapped

local function attrs(el)
  -- pandoc's HTML reader strips the "data-" prefix from attribute names
  local a = el.attributes['data-attrs'] or el.attributes['attrs']
  if not a then return nil end
  return pandoc.json.decode(a, false)
end

local function strip(s)
  return ((s or ''):gsub('^%s+', ''):gsub('%s+$', ''))
end

local function play(url, label)
  -- a single Str keeps the embed title's spacing exactly as Substack has it
  local text = label and { pandoc.Str(label) } or { pandoc.Str(url) }
  return pandoc.Para({ pandoc.Str('▶'), pandoc.Space(), pandoc.Link(text, url) })
end

local function has(el, c)
  return el.classes and el.classes:includes(c)
end

local function is_data_uri(src)
  return src:sub(1, 5) == 'data:'
end

local function images(el)
  local out = {}
  el:walk({
    Image = function(i)
      if not is_data_uri(i.src) then
        table.insert(out, pandoc.Para({ pandoc.Image({}, i.src) }))
      end
    end,
  })
  return out
end

local DROP = {
  'subscription-widget-wrap-editor', 'subscription-widget-wrap',
  'button-wrapper', 'captioned-button-wrap',
}

function Div(el)
  local d = attrs(el)
  if has(el, 'youtube-wrap') and d then
    return play('https://www.youtube.com/watch?v=' .. d.videoId)
  elseif has(el, 'vimeo-wrap') and d then
    return play('https://vimeo.com/' .. d.videoId)
  elseif has(el, 'tiktok-wrap') and d then
    return play(d.url, 'TikTok — ' .. strip(d.author) .. ': ' .. strip(d.title))
  elseif has(el, 'instagram-embed-wrap') and d then
    return play('https://www.instagram.com/p/' .. d.instagram_id .. '/', 'Instagram — ' .. strip(d.title))
  elseif has(el, 'embedded-post-wrap') and d then
    return play(d.url, strip(d.publication_name) .. ' — ' .. strip(d.title))
  elseif has(el, 'captioned-image-container') then
    return images(el)
  elseif has(el, 'pullquote') then
    return pandoc.BlockQuote(el.content)
  end
  for _, c in ipairs(DROP) do
    if has(el, c) then return {} end
  end
  return el.content
end

function Figure(el)
  return images(el)
end

function Image(el)
  if is_data_uri(el.src) then return {} end
end

function Span(el)
  if #el.attributes == 0 and #el.classes == 0 then return el.content end
end
