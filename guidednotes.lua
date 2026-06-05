--- guidednotes.lua
--- YAML config parser and course-schedule table generator for guidednotes.cls.
---
--- Merged from the original guidednotes-config.lua and courseschedule.lua.
--- This is the only Lua file required by the class.
---
--- Supported YAML subset:
---   scalar   key: value  (bare, "double-quoted", or 'single-quoted')
---   mapping  key:        followed by indented key: value lines
---   sequence key:        followed by indented - item or - date: label lines
---   comments # ...       full-line or inline (space before # required)
---
--- Public API:
---   M.apply(filename)        parse YAML, set TeX metadata macros, define colours
---   M.print_calendars()      emit schedule tables for all calendar=true sections

local M = {}

----------------------------------------------------------------------
-- §1  Julian Day Number arithmetic
----------------------------------------------------------------------

--- Gregorian calendar → JDN.  Algorithm: Meeus §7.
local function to_jdn(y, m, d)
  local a  = math.floor((14 - m) / 12)
  local y2 = y + 4800 - a
  local m2 = m + 12 * a - 3
  return d
       + math.floor((153 * m2 + 2) / 5)
       + 365 * y2
       + math.floor(y2 / 4)
       - math.floor(y2 / 100)
       + math.floor(y2 / 400)
       - 32045
end

--- JDN → Gregorian calendar.  Returns year, month (1–12), day (1–31).
local function from_jdn(n)
  local a  = n + 32044
  local b  = math.floor((4 * a + 3) / 146097)
  local c  = a - math.floor(b * 146097 / 4)
  local d2 = math.floor((4 * c + 3) / 1461)
  local e  = c - math.floor(1461 * d2 / 4)
  local m2 = math.floor((5 * e + 2) / 153)
  return 100 * b + d2 - 4800 + math.floor(m2 / 10),
         m2 + 3 - 12 * math.floor(m2 / 10),
         e - math.floor((153 * m2 + 2) / 5) + 1
end

--- Weekday of JDN n: 0 = Mon … 5 = Sat, 6 = Sun.
local function weekday(n)  return n % 7  end

--- JDN of the Sunday that opens the display-week containing n.
local function week_sunday(n)
  return n - (weekday(n) + 1) % 7
end

--- Parse "yyyy-mm-dd" → JDN.
local function parse_date(s)
  local y, m, d = s:match "^(%d%d%d%d)%-(%d%d)%-(%d%d)$"
  assert(y,
    ("guidednotes: cannot parse date %q  (expected yyyy-mm-dd)"):format(tostring(s)))
  return to_jdn(tonumber(y), tonumber(m), tonumber(d))
end

--- Three-letter month abbreviations, 1-indexed.
local MONTH = { "Jan","Feb","Mar","Apr","May","Jun",
                "Jul","Aug","Sep","Oct","Nov","Dec" }

--- Day-name string → weekday number (0 = Mon … 6 = Sun).
local DAY_NUM = { Mon=0, Tue=1, Wed=2, Thu=3, Fri=4, Sat=5, Sun=6 }

--- Canonical left-to-right column order (Sunday first in display).
local COL_ORDER = { "Sun","Mon","Tue","Wed","Thu","Fri","Sat" }

----------------------------------------------------------------------
-- §2  Per-schedule state  (reset by each call to schedule_setup)
----------------------------------------------------------------------

local sch        = {}   -- schedule-wide settings
local specials   = {}   -- JDN → string
local non_instr  = {}   -- JDN set
local assessments = {}  -- JDN → {string…}

----------------------------------------------------------------------
-- §3  Schedule configuration
----------------------------------------------------------------------

local function schedule_setup(opts)
  sch.term_start   = parse_date(opts.start)
  sch.term_end     = parse_date(opts["end"])
  sch.term         = (opts.term or ""):match "^%s*(.-)%s*$"
  sch.course       = opts.course  or ""
  sch.section      = opts.section or ""
  sch.time         = opts.time    or ""

  local rw = opts.readingweek
  sch.reading_week = (rw and rw ~= "") and parse_date(rw) or nil

  sch.lec = {}
  for name in (opts.days or ""):gmatch "[^,%s]+" do
    local n = DAY_NUM[name]
    if n then sch.lec[n] = true end
  end

  specials    = {}
  non_instr   = {}
  assessments = {}

  local function trim(s) return s:match "^%s*(.-)%s*$" end
  local function strip_braces(s) return s:match "^{(.*)}$" or s end

  local nc = opts.noclass
  if nc and nc ~= "" then
    for entry in nc:gmatch "[^;]+" do
      local d = trim(entry)
      if d ~= "" then non_instr[parse_date(d)] = true end
    end
  end

  local sp = opts.special
  if sp and sp ~= "" then
    for entry in sp:gmatch "[^;]+" do
      local d, label = trim(entry):match "^([^=]+)=(.+)$"
      if d then specials[parse_date(trim(d))] = strip_braces(trim(label)) end
    end
  end

  local as = opts.assessment
  if as and as ~= "" then
    for entry in as:gmatch "[^;]+" do
      local d, label = trim(entry):match "^([^=]+)=(.+)$"
      if d then
        local n = parse_date(trim(d))
        assessments[n] = assessments[n] or {}
        table.insert(assessments[n], strip_braces(trim(label)))
      end
    end
  end
end

----------------------------------------------------------------------
-- §4  Schedule computation
----------------------------------------------------------------------

local function build_weeks()
  local first_sun = week_sunday(sch.term_start)
  local last_sun  = week_sunday(sch.term_end)

  local class_count = 0
  local weeks       = {}
  local week_num    = 0

  for sun = first_sun, last_sun, 7 do
    week_num = week_num + 1
    local is_rw = sch.reading_week ~= nil and (sun + 1 == sch.reading_week)
    local week  = { num = week_num, is_rw = is_rw, days = {} }

    for i = 0, 6 do
      local n       = sun + i
      local y, m, d = from_jdn(n)
      local wd      = weekday(n)

      local in_term = n >= sch.term_start and n <= sch.term_end
      local is_lec  = in_term
                      and sch.lec[wd]
                      and not is_rw
                      and not non_instr[n]
      local class_no = nil

      if is_lec and not specials[n] then
        class_count = class_count + 1
        class_no    = class_count
      end

      week.days[i] = {
        n        = n,
        y        = y, m = m, d = d,
        wd       = wd,
        in_term  = in_term,
        is_lec   = is_lec,
        class_no = class_no,
        special  = specials[n],
        assess   = assessments[n],
      }
    end

    table.insert(weeks, week)
  end

  return weeks
end

----------------------------------------------------------------------
-- §5  LaTeX table generation
----------------------------------------------------------------------

local function build_lines()
  local weeks = build_weeks()

  local seen_months = {}
  local function date_label(y, m, d, is_coloured)
    local key   = y * 100 + m
    local first = not seen_months[key]
    seen_months[key] = true
    if first and not is_coloured then
      return MONTH[m] .. "~" .. d
    end
    return tostring(d)
  end

  local lines = {}
  local function emit(s)  table.insert(lines, s)  end

  local title_parts = {}
  if sch.term    ~= "" then table.insert(title_parts, "\\textbf{" .. sch.term .. "}") end
  if sch.course  ~= "" then table.insert(title_parts, sch.course)  end
  if sch.section ~= "" then table.insert(title_parts, "section " .. sch.section) end
  if sch.time    ~= "" then table.insert(title_parts, sch.time)    end
  local title = table.concat(title_parts, ", ")

  local COL_T = [[>{\centering\arraybackslash}p{1em}]]
  local COL_R = [[>{\raggedleft\arraybackslash}p{2cm}]]

  local col_hdrs = {}
  for _, name in ipairs(COL_ORDER) do
    local wd = DAY_NUM[name]
    table.insert(col_hdrs,
      sch.lec[wd] and ("\\textbf{" .. name .. "}") or name)
  end
  local header_row = "  W & " .. table.concat(col_hdrs, " & ") .. " \\\\"

  local col_spec = "|" .. COL_T .. "|" .. (COL_R .. "|"):rep(7)
  emit("\\begin{longtable}[t]{" .. col_spec .. "}")
  emit("  \\multicolumn{8}{c}{\\makebox[0pt]{" .. title .. "}}\\\\")
  emit "  \\toprule"
  emit(header_row)
  emit "  \\midrule"
  emit "  \\endfirsthead"
  emit "  \\toprule"
  emit(header_row)
  emit "  \\midrule"
  emit "  \\endhead"
  emit "  \\midrule"
  emit "  \\endfoot"
  emit "  \\bottomrule"
  emit "  \\endlastfoot"
  emit ""

  for _, week in ipairs(weeks) do
    local r1 = { "  \\textbf{" .. week.num .. "}" }
    for i = 0, 6 do
      local day = week.days[i]
      local is_coloured = day.is_lec
      local lbl = date_label(day.y, day.m, day.d, is_coloured)
      if is_coloured then
        table.insert(r1, "\\cellcolor{" .. MONTH[day.m] .. "}" .. lbl)
      else
        table.insert(r1, lbl)
      end
    end
    emit(table.concat(r1, " & ") .. " \\\\")

    if week.is_rw then
      emit "  & & \\multicolumn{5}{c|}{Reading Week} & \\\\"
    else
      local r2 = { "  " }
      for i = 0, 6 do
        local day   = week.days[i]
        local parts = {}

        if day.assess then
          for _, a in ipairs(day.assess) do
            table.insert(parts, "\\assessment{" .. a .. "}")
          end
        end

        if day.is_lec then
          local colour = "\\cellcolor{" .. MONTH[day.m] .. "}"
          if day.class_no then
            table.insert(parts, colour .. "\\classno{" .. day.class_no .. "}")
          elseif day.special then
            table.insert(parts, colour .. "\\assessment{" .. day.special .. "}")
          end
        end

        table.insert(r2, table.concat(parts, " "))
      end
      emit(table.concat(r2, " & ") .. " \\\\")
    end

    emit "  \\midrule"
  end

  emit [[\end{longtable}]]
  return lines
end

----------------------------------------------------------------------
-- §6  String helpers
----------------------------------------------------------------------

local function trim(s)
  return s:match "^%s*(.-)%s*$"
end

local function unquote(s)
  s = trim(s)
  local dq = s:match '^"(.*)"$'
  if dq then
    return dq:gsub('\\"',  '"')
              :gsub("\\n", "\n")
              :gsub("\\\\","\\")
  end
  local sq = s:match "^'(.*)'$"
  if sq then return sq:gsub("''", "'") end
  return trim(s:match "^(.-)%s+#.*$" or s)
end

----------------------------------------------------------------------
-- §7  YAML parser
----------------------------------------------------------------------

local function key_rest(content)
  local k, r = content:match '^"([^"]+)":%s*(.-)%s*$'
  if k then return k, r end
  return content:match '^([%w][%w%-_]*):%s*(.-)%s*$'
end

function M.parse(filename)
  local f, err = io.open(filename, "r")
  if not f then
    texio.write_nl("guidednotes: cannot open '" .. filename
                   .. "': " .. (err or ""))
    return {}
  end

  local lns = {}
  for line in f:lines() do
    if not (line:match "^%s*$" or line:match "^%s*#") then
      local spaces = line:match "^( *)"
      table.insert(lns, { indent = #spaces, content = trim(line) })
    end
  end
  f:close()

  local pos = 1

  local function parse_sequence(base_indent)
    local result = {}
    while pos <= #lns
          and lns[pos].indent == base_indent
          and lns[pos].content:match "^%-" do
      local item = lns[pos].content:match "^%-%s+(.+)$"
      pos = pos + 1
      if item then
        local d, v = item:match "^([^:]+):%s+(.+)$"
        if d then
          table.insert(result, { key = trim(d), value = unquote(v) })
        else
          table.insert(result, { key = unquote(item) })
        end
      end
    end
    return result
  end

  local parse_mapping
  parse_mapping = function(base_indent)
    local result = {}
    while pos <= #lns and lns[pos].indent == base_indent do
      local k, rest = key_rest(lns[pos].content)
      if not k then
        pos = pos + 1
      elseif rest == "" or rest:match "^#" then
        pos = pos + 1
        if pos <= #lns and lns[pos].indent > base_indent then
          local child_indent = lns[pos].indent
          if lns[pos].content:match "^%-" then
            result[k] = parse_sequence(child_indent)
          else
            result[k] = parse_mapping(child_indent)
          end
        else
          result[k] = ""
        end
      else
        result[k] = unquote(rest)
        pos = pos + 1
      end
    end
    return result
  end

  return parse_mapping(0)
end

----------------------------------------------------------------------
-- §8  Conversion helpers for schedule_setup()
----------------------------------------------------------------------

local function list_pairs(t)
  if type(t) ~= "table" or #t == 0 then return "" end
  local out = {}
  for _, item in ipairs(t) do
    if item.value then
      table.insert(out, item.key .. "={" .. item.value .. "}")
    end
  end
  return table.concat(out, ";")
end

local function list_dates(t)
  if type(t) ~= "table" or #t == 0 then return "" end
  local out = {}
  for _, item in ipairs(t) do table.insert(out, item.key) end
  return table.concat(out, ";")
end

local function list_csv(t)
  if type(t) == "string" then return t end
  if type(t) ~= "table"  then return "" end
  local out = {}
  for _, item in ipairs(t) do table.insert(out, item.key) end
  return table.concat(out, ", ")
end

local DAY_ABBR = {
  Mon="M", Tue="Tu", Wed="W", Thu="Th", Fri="F", Sat="Sa", Sun="Su"
}

local function days_abbrev(t)
  local out = {}
  if type(t) == "string" then
    for d in t:gmatch "[^,%s]+" do
      table.insert(out, DAY_ABBR[d] or d)
    end
  elseif type(t) == "table" then
    for _, item in ipairs(t) do
      table.insert(out, DAY_ABBR[item.key] or item.key)
    end
  end
  return table.concat(out)
end

----------------------------------------------------------------------
-- §9  Public API
----------------------------------------------------------------------

--- Colour definitions emitted by M.apply().
local COLORS = {
  "\\definecolor{ScheduleClassNo}{RGB}{79,38,131}",    -- WesternPurple
  "\\definecolor{ScheduleAssessment}{RGB}{240,167,87}",-- WesternTiger
  "\\definecolor{Jan}{RGB}{210,218,240}",  -- periwinkle
  "\\definecolor{Feb}{RGB}{242,210,220}",  -- rose
  "\\definecolor{Mar}{RGB}{198,236,216}",  -- mint
  "\\definecolor{Apr}{RGB}{216,240,198}",  -- lime
  "\\definecolor{May}{RGB}{248,244,188}",  -- lemon
  "\\definecolor{Jun}{RGB}{248,224,196}",  -- apricot
  "\\definecolor{Jul}{RGB}{188,228,244}",  -- sky
  "\\definecolor{Aug}{RGB}{248,236,188}",  -- gold
  "\\definecolor{Sep}{RGB}{220,210,240}",  -- lavender
  "\\definecolor{Oct}{RGB}{248,220,188}",  -- amber
  "\\definecolor{Nov}{RGB}{224,214,204}",  -- taupe
  "\\definecolor{Dec}{RGB}{196,222,240}",  -- ice
}

local loaded_cfg = nil

--- Parse filename, set TeX document-metadata macros, and define calendar colours.
--- Called by \loadconfig in the preamble.
function M.apply(filename)
  local data = M.parse(filename)
  loaded_cfg = data

  local function setm(name, val)
    token.set_macro(name, tostring(val or ""))
  end

  local term = type(data.term) == "table" and data.term or {}

  setm("@theauthor",             data.author          or "")
  setm("@theauthorshort",        data["author-short"] or "")
  setm("@theinstitute",          data.institute       or "")
  setm("@thelogo",               data.logo            or "")
  setm("@thecoursesubject",      data.subject         or "")
  setm("@thecoursename",         data.subject         or "")
  setm("@thecoursesubj",         data.subj            or "")
  setm("@thecoursenumb",         data.number          or "")
  setm("@thecoursenamesubtitle", data.subtitle        or "")
  setm("@thecourseterm",         term.name            or "")

  tex.print(COLORS)
end

--- Configure the schedule engine for the named section.
local function setup_section(section_name)
  assert(loaded_cfg,
    "guidednotes: \\loadconfig must be called before printing a schedule")
  local data     = loaded_cfg
  local term     = type(data.term)     == "table" and data.term     or {}
  local sections = type(data.sections) == "table" and data.sections or {}
  local sec      = sections[section_name]
  assert(sec,
    "guidednotes: section '" .. section_name .. "' not found in config")

  local time_str = trim(days_abbrev(sec.days) .. " " .. (sec.time or ""))

  schedule_setup({
    start       = term.start       or "",
    ["end"]     = term["end"]      or "",
    term        = term.name        or "",
    course      = trim((data.subj or "") .. " " .. (data.number or "")),
    section     = section_name,
    time        = time_str,
    days        = list_csv(sec.days),
    readingweek = term.readingweek or "",
    noclass     = list_dates(term.noclass),
    special     = list_pairs(term.special),
    assessment  = list_pairs(term.assessment),
  })
end

--- Set up and emit the schedule table for one section.
local function print_schedule(section_name)
  setup_section(section_name)
  tex.print("\\begingroup")
  tex.print("\\def\\classno#1{\\parbox{2cm}{\\begin{tikzpicture}\\draw[thick,dotted,gray](0,0)circle[radius=2ex];\\node at(0,0){\\color{ScheduleClassNo}#1};\\end{tikzpicture}}}")
  tex.print("\\def\\assessment#1{\\parbox{1in}{\\footnotesize\\color{ScheduleAssessment}#1}}")
  tex.print(build_lines())
  tex.print("\\endgroup")
end

--- Emit a schedule for every section with calendar=true, in sorted name order.
--- Called automatically from \AtBeginDocument in the class front matter.
function M.print_calendars()
  if not loaded_cfg then return end
  local sections = type(loaded_cfg.sections) == "table" and loaded_cfg.sections or {}
  local names = {}
  for name in pairs(sections) do table.insert(names, name) end
  table.sort(names)
  for _, name in ipairs(names) do
    local sec = sections[name]
    if type(sec) == "table" and sec.calendar == "true" then
      print_schedule(name)
      tex.print("\\clearpage")
    end
  end
end

return M
