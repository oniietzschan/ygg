max_line_length = false
allow_defined = false -- Do NOT allow implicitly defined globals.
allow_defined_top = false -- Do NOT allow implicitly defined globals.

files = {
  ['ygg.lua'] = {
    std = 'luajit',
  },
  ['spec.lua'] = {
    std = 'luajit+busted',
  },
}

exclude_files = {
  'lua_install/*', -- CI: hererocks
}